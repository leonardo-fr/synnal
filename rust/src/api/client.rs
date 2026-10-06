use std::{sync::Arc, time::Duration};

use crate::frb_generated::StreamSink;

use matrix_sdk::{
    authentication::matrix::MatrixSession,
    config::SyncSettings,
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest,
            room::{
                create_room::v3::{Request as CreateRoomRequest, RoomPreset},
                Visibility,
            },
            uiaa::{AuthData, Dummy},
        },
        OwnedRoomId, OwnedUserId,
    },
    store::RoomLoadSettings,
    Client, LoopCtrl,
};

use tokio::sync::Mutex;

#[derive(Clone, Debug)]
pub struct MatrixRoomSummary {
    pub room_id: String,
    pub name: String,
    pub creator_id: Option<String>,
    pub participant_ids: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct MatrixRoomsSnapshot {
    pub rooms: Vec<MatrixRoomSummary>,
    pub invited_rooms: Vec<MatrixRoomSummary>,
}

pub(super) struct MatrixClient {
    client: Client,
    auth_lock: Mutex<()>,
}

impl MatrixClient {
    pub(super) async fn new(
        homeserver: String,
        store_path: String,
        store_passphrase: String,
    ) -> Result<Self, String> {
        let client = Client::builder()
            .homeserver_url(&homeserver)
            .sqlite_store(&store_path, Some(&store_passphrase))
            .build()
            .await
            .map_err(|e| e.to_string())?;

        Ok(Self {
            client,
            auth_lock: Mutex::new(()),
        })
    }

    async fn room_summary(&self, room: &matrix_sdk::Room) -> Result<MatrixRoomSummary, String> {
        let name = match room.name() {
            Some(name) if !name.trim().is_empty() => name,

            _ => room
                .display_name()
                .await
                .map_err(|e| e.to_string())?
                .to_string(),
        };

        let creator_id = room
            .creators()
            .and_then(|creators| creators.into_iter().next())
            .map(|user_id| user_id.to_string());

        let participant_ids = room
            .joined_user_ids()
            .await
            .map_err(|e| e.to_string())?
            .into_iter()
            .map(|user_id| user_id.to_string())
            .collect();

        Ok(MatrixRoomSummary {
            room_id: room.room_id().to_string(),
            name,
            creator_id,
            participant_ids,
        })
    }
    pub(super) async fn get_display_name(&self) -> Result<Option<String>, String> {
        self.client
            .account()
            .get_display_name()
            .await
            .map_err(|e| e.to_string())
    }

    pub(super) async fn login_password(
        &self,
        username: String,
        password: String,
        device_id: Option<String>,
    ) -> Result<String, String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        if auth.session().is_some() {
            return Err(
                "MatrixClient já possui uma sessão; recrie o client antes de fazer login."
                    .to_string(),
            );
        }

        let mut login = auth
            .login_username(&username, &password)
            .initial_device_display_name("Synnal Desktop");

        if let Some(device_id) = device_id {
            login = login.device_id(&device_id);
        }

        login.send().await.map_err(|e| e.to_string())?;

        let session = auth
            .session()
            .ok_or_else(|| "Sessão indisponível após login".to_string())?;

        serde_json::to_string(&session).map_err(|e| e.to_string())
    }

    pub(super) async fn restore_session(&self, session_json: String) -> Result<(), String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        // Já existe sessão no client.
        if auth.session().is_some() {
            return Ok(());
        }

        let session: MatrixSession =
            serde_json::from_str(&session_json).map_err(|e| e.to_string())?;

        auth.restore_session(session, RoomLoadSettings::default())
            .await
            .map_err(|e| e.to_string())
    }

    pub(super) fn is_logged_in(&self) -> bool {
        self.client.matrix_auth().logged_in()
    }

    pub(super) async fn register_user(
        &self,
        username: String,
        password: String,
        display_name: String,
    ) -> Result<String, String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        if auth.session().is_some() {
            return Err("O cliente Matrix já possui uma sessão. \
                É necessário recriar o MatrixClient antes \
                de cadastrar outro usuário."
                .to_string());
        }

        // Primeira tentativa de cadastro.
        let mut request = RegistrationRequest::new();

        request.username = Some(username.clone());
        request.password = Some(password.clone());
        request.initial_device_display_name = Some("Synnal Desktop".to_string());
        request.refresh_token = false;

        let resultado = auth.register(request).await;

        match resultado {
            Ok(_) => {
                // Cadastro realizado diretamente.
            }

            Err(error) => {
                // O Synapse pode exigir UIAA,
                // normalmente usando m.login.dummy.
                let uiaa = match error.as_uiaa_response() {
                    Some(uiaa) => uiaa,

                    None => {
                        return Err(error.to_string());
                    }
                };

                let mut dummy = Dummy::new();

                dummy.session = uiaa.session.clone();

                let mut request = RegistrationRequest::new();

                request.username = Some(username);
                request.password = Some(password);
                request.initial_device_display_name = Some("Synnal Desktop".to_string());
                request.refresh_token = false;
                request.auth = Some(AuthData::Dummy(dummy));

                auth.register(request).await.map_err(|e| e.to_string())?;
            }
        }

        // Neste ponto o register() já deve ter
        // configurado a sessão do Client.
        let session = auth
            .session()
            .ok_or_else(|| "Usuário criado, mas nenhuma sessão foi retornada".to_string())?;

        // O nome não faz parte do RegistrationRequest.
        // Ele é configurado no perfil depois que
        // a conta está autenticada.
        self.client
            .account()
            .set_display_name(Some(display_name.as_str()))
            .await
            .map_err(|e| {
                format!(
                    "Usuário criado, mas não foi possível \
                        definir o nome de exibição: {e}"
                )
            })?;

        serde_json::to_string(&session).map_err(|e| e.to_string())
    }

    pub(super) async fn logout(&self) -> Result<(), String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        if auth.session().is_none() {
            return Ok(());
        }

        self.client.logout().await.map_err(|e| e.to_string())
    }

    pub(super) async fn list_rooms(&self) -> Result<MatrixRoomsSnapshot, String> {
        self.client
            .sync_once(SyncSettings::default())
            .await
            .map_err(|e| e.to_string())?;

        self.rooms_snapshot().await
    }

    pub(super) async fn create_private_room(
        &self,
        name: String,
        invited_user_ids: Vec<String>,
    ) -> Result<MatrixRoomSummary, String> {
        if invited_user_ids.is_empty() {
            return Err("Informe pelo menos um usuário para convidar.".to_string());
        }

        let invited_users = invited_user_ids
            .into_iter()
            .map(|user_id| {
                user_id
                    .parse::<OwnedUserId>()
                    .map_err(|e| format!("ID Matrix inválido '{user_id}': {e}"))
            })
            .collect::<Result<Vec<_>, _>>()?;

        let mut request = CreateRoomRequest::new();

        request.name = Some(name.clone());
        request.preset = Some(RoomPreset::PrivateChat);
        request.visibility = Visibility::Private;
        request.invite = invited_users;

        let room = self
            .client
            .create_room(request)
            .await
            .map_err(|e| e.to_string())?;
        let creator_id = self.client.user_id().map(|user_id| user_id.to_string());

        let participant_ids = creator_id.clone().into_iter().collect();
        Ok(MatrixRoomSummary {
            room_id: room.room_id().to_string(),
            name,
            creator_id,
            participant_ids,
        })
    }

    pub(super) async fn join_invited_room(
        &self,
        room_id: String,
    ) -> Result<MatrixRoomSummary, String> {
        let room_id = room_id
            .parse::<OwnedRoomId>()
            .map_err(|e| format!("Room ID inválido '{room_id}': {e}"))?;

        let room = self
            .client
            .join_room_by_id(&room_id)
            .await
            .map_err(|e| e.to_string())?;

        self.room_summary(&room).await
    }

    async fn remove_room(&self, room_id: &matrix_sdk::ruma::RoomId) -> Result<(), String> {
        let was_invited = self
            .client
            .invited_rooms()
            .iter()
            .any(|room| room.room_id() == room_id);

        let room = self
            .client
            .get_room(room_id)
            .ok_or_else(|| format!("Sala não encontrada: {room_id}"))?;

        room.leave().await.map_err(|e| e.to_string())?;

        // Room::leave já esquece automaticamente
        // uma sala que estava apenas como convite.
        if !was_invited {
            room.forget().await.map_err(|e| e.to_string())?;
        }

        Ok(())
    }

    pub(super) async fn delete_room(&self, room_id: String) -> Result<(), String> {
        let room_id = room_id
            .parse::<OwnedRoomId>()
            .map_err(|e| format!("Room ID inválido '{room_id}': {e}"))?;

        self.remove_room(&room_id).await
    }

    pub(super) async fn clear_rooms(&self) -> Result<(), String> {
        self.client
            .sync_once(SyncSettings::default())
            .await
            .map_err(|e| e.to_string())?;

        let room_ids = self
            .client
            .joined_rooms()
            .into_iter()
            .chain(self.client.invited_rooms().into_iter())
            .map(|room| room.room_id().to_owned())
            .collect::<Vec<_>>();

        for room_id in room_ids {
            self.remove_room(&room_id).await?;
        }

        Ok(())
    }
    async fn rooms_snapshot(&self) -> Result<MatrixRoomsSnapshot, String> {
        let mut rooms = Vec::new();

        for room in self.client.joined_rooms() {
            rooms.push(self.room_summary(&room).await?);
        }

        let mut invited_rooms = Vec::new();

        for room in self.client.invited_rooms() {
            let name = match room.name() {
                Some(name) if !name.trim().is_empty() => name,

                _ => room
                    .display_name()
                    .await
                    .map_err(|e| e.to_string())?
                    .to_string(),
            };

            let creator_id = room
                .creators()
                .and_then(|creators| creators.into_iter().next())
                .map(|user_id| user_id.to_string());

            invited_rooms.push(MatrixRoomSummary {
                room_id: room.room_id().to_string(),
                name,
                creator_id,
                participant_ids: Vec::new(),
            });
        }

        rooms.sort_by_key(|room| room.name.to_lowercase());

        invited_rooms.sort_by_key(|room| room.name.to_lowercase());

        Ok(MatrixRoomsSnapshot {
            rooms,
            invited_rooms,
        })
    }

    pub(super) async fn watch_rooms(
        self: Arc<Self>,
        sink: StreamSink<MatrixRoomsSnapshot>,
    ) -> Result<(), String> {
        let client = self.client.clone();

        let matrix_client = self.clone();

        let settings = SyncSettings::new()
            .timeout(Duration::from_secs(30))
            .ignore_timeout_on_first_sync(true);

        client
            .sync_with_callback(settings, move |_response| {
                let matrix_client = matrix_client.clone();

                let sink = sink.clone();

                async move {
                    let snapshot = match matrix_client.rooms_snapshot().await {
                        Ok(snapshot) => snapshot,

                        Err(error) => {
                            eprintln!("Erro ao atualizar salas: {error}");

                            return LoopCtrl::Continue;
                        }
                    };

                    if sink.add(snapshot).is_err() {
                        // O Flutter cancelou o stream,
                        // por exemplo ao sair da conta.
                        return LoopCtrl::Break;
                    }

                    LoopCtrl::Continue
                }
            })
            .await
            .map_err(|e| e.to_string())
    }
}

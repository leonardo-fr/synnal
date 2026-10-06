use matrix_sdk::{
    authentication::matrix::MatrixSession,
    config::SyncSettings,
    ruma::api::client::{
        account::register::v3::Request as RegistrationRequest,
        uiaa::{
            AuthData,
            Dummy,
        },
    },
    store::RoomLoadSettings,
    Client,
};

use tokio::sync::Mutex;

#[derive(Clone, Debug)]
pub struct MatrixRoomSummary {
    pub room_id: String,
    pub name: String,
}

pub struct MatrixClient {
    client: Client,
    auth_lock: Mutex<()>,
}

impl MatrixClient {
    pub async fn new(
        homeserver: String,
        store_path: String,
        store_passphrase: String,
    ) -> Result<Self, String> {
        let client = Client::builder()
            .homeserver_url(&homeserver)
            .sqlite_store(
                &store_path,
                Some(&store_passphrase),
            )
            .build()
            .await
            .map_err(|e| e.to_string())?;

        Ok(Self {
            client,
            auth_lock: Mutex::new(()),
        })
    }
    pub async fn get_display_name(
        &self,
    ) -> Result<Option<String>, String> {
        self.client
            .account()
            .get_display_name()
            .await
            .map_err(|e| e.to_string())
    }

    pub async fn login_password(
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
            .login_username(
                &username,
                &password,
            )
            .initial_device_display_name(
                "Synnal Desktop",
            );

        if let Some(device_id) = device_id {
            login = login.device_id(&device_id);
        }

        login
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let session = auth
            .session()
            .ok_or_else(|| {
                "Sessão indisponível após login".to_string()
            })?;

        serde_json::to_string(&session)
            .map_err(|e| e.to_string())
    }

    pub async fn restore_session(
        &self,
        session_json: String,
    ) -> Result<(), String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        // Já existe sessão no client.
        if auth.session().is_some() {
            return Ok(());
        }

        let session: MatrixSession =
            serde_json::from_str(
                &session_json,
            )
            .map_err(|e| e.to_string())?;

        auth.restore_session(
            session,
            RoomLoadSettings::default(),
        )
        .await
        .map_err(|e| e.to_string())
    }

    pub fn is_logged_in(&self) -> bool {
        self.client
            .matrix_auth()
            .logged_in()
    }

    pub async fn register_user(
        &self,
        username: String,
        password: String,
        display_name: String,
    ) -> Result<String, String> {
        let _guard =
            self.auth_lock.lock().await;

        let auth =
            self.client.matrix_auth();

        if auth.session().is_some() {
            return Err(
                "O cliente Matrix já possui uma sessão. \
                É necessário recriar o MatrixClient antes \
                de cadastrar outro usuário."
                    .to_string(),
            );
        }

        // Primeira tentativa de cadastro.
        let mut request =
            RegistrationRequest::new();

        request.username =
            Some(
                username.clone(),
            );

        request.password =
            Some(
                password.clone(),
            );

        request.initial_device_display_name =
            Some(
                "Synnal Desktop"
                    .to_string(),
            );

        request.refresh_token =
            false;

        let resultado =
            auth.register(
                request,
            )
            .await;

        match resultado {
            Ok(_) => {
                // Cadastro realizado diretamente.
            }

            Err(error) => {
                // O Synapse pode exigir UIAA,
                // normalmente usando m.login.dummy.
                let uiaa =
                    match error
                        .as_uiaa_response()
                    {
                        Some(uiaa) =>
                            uiaa,

                        None => {
                            return Err(
                                error.to_string(),
                            );
                        }
                    };

                let mut dummy =
                    Dummy::new();

                dummy.session =
                    uiaa.session.clone();

                let mut request =
                    RegistrationRequest::new();

                request.username =
                    Some(
                        username,
                    );

                request.password =
                    Some(
                        password,
                    );

                request.initial_device_display_name =
                    Some(
                        "Synnal Desktop"
                            .to_string(),
                    );

                request.refresh_token =
                    false;

                request.auth =
                    Some(
                        AuthData::Dummy(
                            dummy,
                        ),
                    );

                auth.register(
                    request,
                )
                .await
                .map_err(
                    |e| e.to_string(),
                )?;
            }
        }

        // Neste ponto o register() já deve ter
        // configurado a sessão do Client.
        let session =
            auth.session()
                .ok_or_else(|| {
                    "Usuário criado, mas nenhuma sessão foi retornada"
                        .to_string()
                })?;

        // O nome não faz parte do RegistrationRequest.
        // Ele é configurado no perfil depois que
        // a conta está autenticada.
        self.client
            .account()
            .set_display_name(
                Some(
                    display_name.as_str(),
                ),
            )
            .await
            .map_err(
                |e| {
                    format!(
                        "Usuário criado, mas não foi possível \
                        definir o nome de exibição: {e}"
                    )
                },
            )?;

        serde_json::to_string(
            &session,
        )
        .map_err(
            |e| e.to_string(),
        )
    }

    pub async fn logout(
        &self,
    ) -> Result<(), String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        if auth.session().is_none() {
            return Ok(());
        }

        self.client
            .logout()
            .await
            .map_err(|e| e.to_string())
    }

    pub async fn list_joined_rooms(
        &self,
    ) -> Result<Vec<MatrixRoomSummary>, String> {
        self.client
            .sync_once(SyncSettings::default())
            .await
            .map_err(|e| e.to_string())?;

        let mut rooms = Vec::new();

        for room in self.client.joined_rooms() {
            let name = room
                .display_name()
                .await
                .map_err(|e| e.to_string())?
                .to_string();

            rooms.push(
                MatrixRoomSummary {
                    room_id: room.room_id().to_string(),
                    name,
                },
            );
        }

        rooms.sort_by_key(
            |room| room.name.to_lowercase(),
        );

        Ok(rooms)
    }
}
use matrix_sdk::{
    authentication::matrix::MatrixSession,
    ruma::api::client::{
        account::register::v3::Request
            as RegistrationRequest,
        uiaa::{
            AuthData,
            Dummy,
        },
    },
    store::RoomLoadSettings,
    Client,
};

use tokio::sync::Mutex;

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

    pub async fn login_password(
        &self,
        username: String,
        password: String,
    ) -> Result<String, String> {
        let _guard = self.auth_lock.lock().await;

        let auth = self.client.matrix_auth();

        if let Some(session) = auth.session() {
            return serde_json::to_string(&session)
                .map_err(|e| e.to_string());
        }

        auth.login_username(
            &username,
            &password,
        )
        .initial_device_display_name(
            "Synnal Desktop",
        )
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
    ) -> Result<String, String> {
        let _guard =
            self.auth_lock.lock().await;

        let auth =
            self.client.matrix_auth();

        let mut request =
            RegistrationRequest::new();

        request.username =
            Some(username.clone());

        request.password =
            Some(password.clone());

        request.initial_device_display_name =
            Some(
                "Synnal Desktop".to_string(),
            );

        request.refresh_token = false;

        let resultado =
            auth.register(request).await;

        match resultado {
            Ok(_) => {}

            Err(error) => {
                // O primeiro cadastro pode retornar UIAA.
                let uiaa =
                    match error.as_uiaa_response() {
                        Some(uiaa) => uiaa,
                        None => {
                            return Err(
                                error.to_string(),
                            );
                        }
                    };

                let session =
                    uiaa.session.clone();

                let mut dummy =
                    Dummy::new();

                dummy.session =
                    session;

                let mut request =
                    RegistrationRequest::new();

                request.username =
                    Some(username);

                request.password =
                    Some(password);

                request
                    .initial_device_display_name =
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

                auth.register(request)
                    .await
                    .map_err(
                        |e| e.to_string(),
                    )?;
            }
        }

        let session = auth
            .session()
            .ok_or_else(|| {
                "Usuário criado, mas nenhuma sessão foi retornada"
                    .to_string()
            })?;

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
}
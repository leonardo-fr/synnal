use std::sync::Arc;

use super::client::MatrixClient;

pub struct MatrixService{
    client: Arc<MatrixClient>,
}

impl MatrixService {
    pub async fn create(
        homeserver: String,
        store_path: String,
        store_passphrase: String,
    ) -> Result<Self, String> {
        let client = MatrixClient:: new(
            homeserver,
            store_path,
            store_passphrase,
        )
        .await?;

        Ok(Self {
            client: Arc::new(client)
        })
    }

    pub async fn login(
        &self,
        username: String,
        password: String,
    ) -> Result<String, String> {
        self.client
        .login_password(username, password)
        .await
    }
    pub async fn get_display_name(
        &self,
    ) -> Result<Option<String>, String> {
        self.client
            .get_display_name()
            .await
    }

    pub async fn restore(&self,
        session_json: String,
    ) -> Result<(), String> {
        self.client
        .restore_session(session_json)
        .await
    } 

    pub fn is_logged_in(&self) -> bool {
        self.client.is_logged_in()
    }

    pub async fn register_user(
    &self,
    username: String,
    password: String,
    displayName: String,
) -> Result<String, String> {
    self.client
        .register_user(
            username,
            password,
            displayName,
        )
        .await
}

    pub async fn logout(&self) -> Result<(), String> {
        self.client.logout().await
    }
}
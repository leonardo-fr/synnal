use std::sync::Arc;

use tokio::sync::RwLock;

use super::client::{
    MatrixClient,
    MatrixRoomSummary,
};

pub struct MatrixService {
    homeserver: String,
    store_path: String,
    store_passphrase: String,
    client: RwLock<Option<Arc<MatrixClient>>>,
}

impl MatrixService {
    pub async fn create(
        homeserver: String,
        store_path: String,
        store_passphrase: String,
    ) -> Result<Self, String> {
        let client = MatrixClient::new(
            homeserver.clone(),
            store_path.clone(),
            store_passphrase.clone(),
        )
        .await?;

        Ok(Self {
            homeserver,
            store_path,
            store_passphrase,
            client: RwLock::new(
                Some(Arc::new(client)),
            ),
        })
    }

    async fn current_client(
        &self,
    ) -> Result<Arc<MatrixClient>, String> {
        self.client
            .read()
            .await
            .as_ref()
            .cloned()
            .ok_or_else(|| {
                "MatrixClient não está inicializado".to_string()
            })
    }

    /// Descarta completamente o Client atual e cria outro.
    ///
    /// Isso é necessário quando uma sessão restaurada fica inválida,
    /// pois o Matrix SDK não permite substituir a autenticação de um
    /// Client que já teve uma sessão configurada.
    pub async fn reset_client(
        &self,
    ) -> Result<(), String> {
        // Primeiro remove o Client antigo.
        //
        // Isso garante que a sessão carregada em memória seja
        // realmente descartada antes de criarmos outro Client.
        {
            let mut client = self.client
                .write()
                .await;

            *client = None;
        }

        let novo_client = MatrixClient::new(
            self.homeserver.clone(),
            self.store_path.clone(),
            self.store_passphrase.clone(),
        )
        .await?;

        {
            let mut client = self.client
                .write()
                .await;

            *client = Some(
                Arc::new(novo_client),
            );
        }

        Ok(())
    }

    pub async fn login(
        &self,
        username: String,
        password: String,
        device_id: Option<String>,
    ) -> Result<String, String> {
        self.reset_client().await?;

        self.current_client()
            .await?
            .login_password(
                username,
                password,
                device_id,
            )
            .await
    }

    pub async fn get_display_name(
        &self,
    ) -> Result<Option<String>, String> {
        self.current_client()
            .await?
            .get_display_name()
            .await
    }

    pub async fn restore(
        &self,
        session_json: String,
    ) -> Result<(), String> {
        self.current_client()
            .await?
            .restore_session(
                session_json,
            )
            .await
    }

    pub async fn is_logged_in(
        &self,
    ) -> Result<bool, String> {
        Ok(
            self.current_client()
                .await?
                .is_logged_in(),
        )
    }

    pub async fn register_user(
        &self,
        username: String,
        password: String,
        display_name: String,
    ) -> Result<String, String> {
        self.current_client()
            .await?
            .register_user(
                username,
                password,
                display_name,
            )
            .await
    }

    pub async fn logout(
        &self,
    ) -> Result<(), String> {
        let client = self.current_client().await?;

        let logout_result = client.logout().await;

        // Independente de o servidor aceitar o logout ou não,
        // descartamos o Client local.
        //
        // Isso também cobre casos como M_UNKNOWN_TOKEN.
        self.reset_client().await?;

        logout_result
    }

    pub async fn list_joined_rooms(
        &self,
    ) -> Result<Vec<MatrixRoomSummary>, String> {
        self.current_client()
            .await?
            .list_joined_rooms()
            .await
    }
}
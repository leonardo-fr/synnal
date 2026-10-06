use super::client::{MatrixChatMessage, MatrixClient, MatrixRoomSummary, MatrixRoomsSnapshot};

use crate::frb_generated::StreamSink;

use std::sync::Arc;

use tokio::sync::RwLock;

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
            client: RwLock::new(Some(Arc::new(client))),
        })
    }

    async fn current_client(&self) -> Result<Arc<MatrixClient>, String> {
        self.client
            .read()
            .await
            .as_ref()
            .cloned()
            .ok_or_else(|| "MatrixClient não está inicializado".to_string())
    }

    pub async fn reset_client(&self) -> Result<(), String> {
        {
            let mut client = self.client.write().await;

            *client = None;
        }

        let novo_client = MatrixClient::new(
            self.homeserver.clone(),
            self.store_path.clone(),
            self.store_passphrase.clone(),
        )
        .await?;

        {
            let mut client = self.client.write().await;

            *client = Some(Arc::new(novo_client));
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
            .login_password(username, password, device_id)
            .await
    }

    pub async fn get_display_name(&self) -> Result<Option<String>, String> {
        self.current_client().await?.get_display_name().await
    }

    pub async fn restore(&self, session_json: String) -> Result<(), String> {
        self.current_client()
            .await?
            .restore_session(session_json)
            .await
    }

    pub async fn is_logged_in(&self) -> Result<bool, String> {
        Ok(self.current_client().await?.is_logged_in())
    }

    pub async fn register_user(
        &self,
        username: String,
        password: String,
        display_name: String,
    ) -> Result<String, String> {
        self.current_client()
            .await?
            .register_user(username, password, display_name)
            .await
    }

    pub async fn logout(&self) -> Result<(), String> {
        let client = self.current_client().await?;

        let logout_result = client.logout().await;

        self.reset_client().await?;

        logout_result
    }

    pub async fn list_rooms(&self) -> Result<MatrixRoomsSnapshot, String> {
        self.current_client().await?.list_rooms().await
    }

    pub async fn create_private_room(
        &self,
        name: String,
        invited_user_ids: Vec<String>,
    ) -> Result<MatrixRoomSummary, String> {
        self.current_client()
            .await?
            .create_private_room(name, invited_user_ids)
            .await
    }

    pub async fn join_invited_room(&self, room_id: String) -> Result<MatrixRoomSummary, String> {
        self.current_client()
            .await?
            .join_invited_room(room_id)
            .await
    }

    pub async fn delete_room(&self, room_id: String) -> Result<(), String> {
        self.current_client().await?.delete_room(room_id).await
    }

    pub async fn clear_rooms(&self) -> Result<(), String> {
        self.current_client().await?.clear_rooms().await
    }

    pub async fn watch_rooms(&self, sink: StreamSink<MatrixRoomsSnapshot>) -> Result<(), String> {
        let client = self.current_client().await?;

        client.watch_rooms(sink).await
    }

    pub async fn list_messages(&self, room_id: String) -> Result<Vec<MatrixChatMessage>, String> {
        self.current_client().await?.list_messages(room_id).await
    }

    pub async fn send_message(&self, room_id: String, body: String) -> Result<(), String> {
        self.current_client()
            .await?
            .send_message(room_id, body)
            .await
    }

    pub async fn watch_messages(
        &self,
        room_id: String,
        sink: StreamSink<Vec<MatrixChatMessage>>,
    ) -> Result<(), String> {
        let client = self.current_client().await?;

        client.watch_messages(room_id, sink).await
    }
}

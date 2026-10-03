use matrix_sdk::Client;

pub async fn matrix_test_connection(
    homeserver: String,
) -> Result<String, String> {
    Client:: builder()
    .homeserver_url(&homeserver)
    .build()
    .await
    .map_err(|error| error.to_string())?;

    Ok("Matrix SDK configurado com sucesso".to_string())
}
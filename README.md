# Synnal
Uma aplicação desktop de mensageria para Linux, macOS e Windows usando Flutter, Rust e Matrix Rust SDK.

## Tecnologias e versões utilizadas
- FVM `4.1.2`
- Flutter `3.44.4` — stable
- Dart `3.12.2`
- Rust `1.99.0`
- Cargo `1.99.0`
- Rustup `1.29.1`
- flutter_rust_bridge `2.13.0`
- flutter_rust_bridge_codegen `2.13.0`
- matrix-sdk `0.19.1`
- cargo-expand `1.0.112`
- Docker `29.4.3` — build `055a478`

## Ambiente de desenvolvimento
- Máquina: Mac mini M4 16 GB RAM
- Sistema operacional: macOS `26.5.1`
- Flutter gerenciado com FVM
- Integração Flutter/Rust com `flutter_rust_bridge`
- Synapse executado localmente usando Docker

# Para analisar o projeto Flutter
```bash
fvm flutter analyze
```

# Para verificar as principais dependências Rust:
```bash
cd rust
cargo tree --depth 1
```

## Synapse local
Durante o desenvolvimento, o Synnal utiliza uma instância local do Matrix Synapse executada com Docker.

# O homeserver local fica disponível em:
```text
http://127.0.0.1:8008
```

# O `server_name` usado no ambiente local é:
```text
localhost
```

Por isso, os usuários Matrix criados localmente possuem identificadores no formato:

```text
@usuario:localhost
```

## Arquivo `homeserver.yaml`
# O arquivo de configuração do Synapse é mantido na raiz do projeto:
```text
synnal/
├── homeserver.yaml
├── lib/
├── macos/
├── rust/
└── ...
```

O container Docker utiliza diretamente esse mesmo arquivo através de um bind mount.
Isso evita manter duas cópias diferentes do `homeserver.yaml`.

Fluxo:
```text
/Users/frreserve/synnal/homeserver.yaml
                    ↓
        /data/homeserver.yaml
                    ↓
                 Synapse
```

## Configuração utilizada no ambiente local

No `homeserver.yaml`, o ambiente local utiliza:

```yaml
server_name: "localhost"
```

Para permitir cadastro de usuários pelo Synnal durante o desenvolvimento:

```yaml
enable_registration: true
enable_registration_without_verification: true
```

O banco local utilizado é SQLite:

```yaml
database:
  name: sqlite3
  args:
    database: /data/homeserver.db
```

> `enable_registration_without_verification: true` deve ser usado somente em ambiente local de desenvolvimento.

## Primeira configuração do Synapse

Entre na raiz do projeto:

```bash
cd /Users/frreserve/synnal
```

Crie o volume Docker usado para os dados persistentes:

```bash
docker volume create synapse-data
```

Gere a configuração inicial do Synapse:

```bash
docker run -it --rm \
  --mount type=volume,src=synapse-data,dst=/data \
  -e SYNAPSE_SERVER_NAME=localhost \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

Esse comando gera arquivos como:

```text
/data/homeserver.yaml
/data/localhost.log.config
/data/localhost.signing.key
```

Para copiar o `homeserver.yaml` gerado para a raiz do projeto:

```bash
docker run --rm \
  --mount type=volume,src=synapse-data,dst=/data \
  --entrypoint cat \
  matrixdotorg/synapse:latest \
  /data/homeserver.yaml > /Users/frreserve/synnal/homeserver.yaml
```

Depois disso, edite o arquivo localizado em:

```text
/Users/frreserve/synnal/homeserver.yaml
```

## Rodando o Synapse usando o mesmo `homeserver.yaml` do projeto

Na raiz do projeto:

```bash
cd /Users/frreserve/synnal
```

Crie o container usando:

```bash
docker run -d \
  --name synapse \
  --mount type=volume,src=synapse-data,dst=/data \
  --mount type=bind,src=/Users/frreserve/synnal/homeserver.yaml,dst=/data/homeserver.yaml,readonly \
  -p 8008:8008 \
  matrixdotorg/synapse:latest
```

Nesse formato:
- o banco e os demais dados persistentes continuam no volume `synapse-data`;
- o `homeserver.yaml` utilizado pelo Synapse é exatamente o arquivo da raiz do projeto;
- não é necessário executar `docker cp` sempre que o arquivo for alterado.

## Se já existir um container `synapse`
Se o container atual foi criado sem o bind mount do `homeserver.yaml`, ele precisa ser recriado uma única vez.

Pare o container:

```bash
docker stop synapse
```

Remova o container:

```bash
docker rm synapse
```

O volume `synapse-data` não será removido, portanto o banco e os demais dados persistentes continuarão disponíveis.

Recrie o container:

```bash
docker run -d \
  --name synapse \
  --mount type=volume,src=synapse-data,dst=/data \
  --mount type=bind,src=/Users/frreserve/synnal/homeserver.yaml,dst=/data/homeserver.yaml,readonly \
  -p 8008:8008 \
  matrixdotorg/synapse:latest
```

## Uso no dia a dia

Para iniciar o Synapse:

```bash
docker start synapse
```

Para parar:

```bash
docker stop synapse
```

Para reiniciar:

```bash
docker restart synapse
```

Para acompanhar os logs:

```bash
docker logs -f synapse
```

Para verificar se está rodando:

```bash
docker ps
```

Para listar também containers parados:

```bash
docker ps -a
```

## Alterando o `homeserver.yaml`

Abra o arquivo no VS Code:

```bash
code /Users/frreserve/synnal/homeserver.yaml
```

Após salvar uma alteração, reinicie o Synapse:

```bash
docker restart synapse
```

Como o arquivo está montado diretamente no container, não é necessário copiá-lo novamente.

## Validando o Synapse

Para verificar se o servidor está respondendo:

```bash
curl http://127.0.0.1:8008/_matrix/client/versions
```

Para verificar os métodos de login disponíveis:

```bash
curl http://127.0.0.1:8008/_matrix/client/v3/login
```

Entre os métodos disponíveis deve aparecer:

```text
m.login.password
```

## Criando usuário pela linha de comando

Também é possível criar usuários diretamente no Synapse:

```bash
docker exec -it synapse \
  register_new_matrix_user \
  http://localhost:8008 \
  -c /data/homeserver.yaml
```

Para esse comando funcionar, o `homeserver.yaml` precisa possuir um `registration_shared_secret`.

Exemplo de usuário local:

```text
@userteste:localhost
```

## Configuração do Synnal

Durante o desenvolvimento local, o `MatrixService` deve apontar para:

```dart
homeserver: 'http://127.0.0.1:8008',
```

Fluxo local:

```text
Synnal
  ↓
Matrix Rust SDK
  ↓
http://127.0.0.1:8008
  ↓
Docker
  ↓
Synapse
  ↓
homeserver.yaml da raiz do projeto
```

## Atenção aos segredos

O `homeserver.yaml` pode conter valores sensíveis, como:

```text
registration_shared_secret
macaroon_secret_key
form_secret
```

A configuração atual é destinada ao ambiente local de desenvolvimento.

Caso o repositório seja público, não é recomendado versionar segredos reais. Nesse cenário, prefira manter um arquivo como:

```text
homeserver.example.yaml
```

e adicionar o arquivo real ao `.gitignore`.

## Executando o projeto

Com o Synapse iniciado:

```bash
docker start synapse
```

Execute o Synnal no macOS:

```bash
cd /Users/frreserve/synnal
fvm flutter run -d macos
```

Quando houver alterações em código Rust, gere novamente o bridge antes de executar:

```bash
flutter_rust_bridge_codegen generate
fvm flutter run -d macos
```

## Plataformas suportadas

- Linux
- macOS
- Windows

## Stack

- Flutter
- Dart
- Rust
- Matrix Rust SDK
- flutter_rust_bridge
- Matrix Synapse
- Docker

## Organização do projeto
A organização de pastas do projeto é baseada em **features**.

Cada feature concentra os componentes relacionados à sua própria responsabilidade e possui, entre outras, as seguintes pastas:

- `bloc/` — gerenciamento de estado e lógica de apresentação.
- `repositories/` — abstração e acesso às fontes de dados.
- `clients/` — comunicação com serviços, APIs e integrações externas.
- `ui/` — componentes visuais, páginas e widgets da feature.

A estrutura básica de uma feature segue este formato:

```text
feature/
├── bloc/
├── repositories/
├── clients/
└── ui/
```

Essa organização mantém as responsabilidades agrupadas por domínio funcional e facilita a evolução independente de cada feature.

## Getting Started
A few resources to get started with Flutter:
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For additional Flutter documentation, see the
[official Flutter documentation](https://docs.flutter.dev/).

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
Durante o desenvolvimento, o Synnal utiliza uma instância local do Matrix Synapse executada com Docker Compose.

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
├── docker-compose.yml
├── homeserver.yaml
├── lib/
├── macos/
├── rust/
└── ...
```

O container Docker utiliza diretamente esse mesmo arquivo através de um bind mount configurado no `docker-compose.yml`.
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

## Arquivo `docker-compose.yml`
O arquivo `docker-compose.yml` também é mantido na raiz do projeto e é responsável por definir o container do Synapse, a porta utilizada, o volume persistente e o bind mount do `homeserver.yaml`.

#Explicação do docker-compose.yml:
- o banco, mídia, signing key, logs e demais dados persistentes ficam no volume `synapse-data`;
- o `homeserver.yaml` utilizado pelo Synapse é exatamente o arquivo da raiz do projeto;
- o `homeserver.yaml` é montado como somente leitura dentro do container;
- a porta `8008` do Synapse é exposta para o host;
- não é necessário executar `docker cp` sempre que o `homeserver.yaml` for alterado.

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

Com o `homeserver.yaml` disponível na raiz do projeto, o Synapse passa a ser executado pelo Docker Compose.

## Rodando o Synapse usando o mesmo `homeserver.yaml` do projeto

Na raiz do projeto:

```bash
cd /Users/frreserve/synnal
```

Suba o Synapse:

```bash
docker compose up -d
```

O Docker Compose utilizará o arquivo:

```text
/Users/frreserve/synnal/docker-compose.yml
```

e montará automaticamente:

```text
./homeserver.yaml
        ↓
/data/homeserver.yaml
```

Para verificar o container:

```bash
docker compose ps
```

Para acompanhar os logs:

```bash
docker compose logs -f synapse
```

## Se já existir um container `synapse`
Se o container atual foi criado anteriormente com `docker run`, ele precisa ser removido uma única vez antes de passar a ser gerenciado pelo Docker Compose.

Pare o container:

```bash
docker stop synapse
```

Remova o container:

```bash
docker rm synapse
```

O volume `synapse-data` não será removido, portanto o banco e os demais dados persistentes continuarão disponíveis.

Depois, na raiz do projeto:

```bash
cd /Users/frreserve/synnal
```

Suba novamente o Synapse usando o Docker Compose:

```bash
docker compose up -d
```

A partir desse momento, o container passa a ser gerenciado pelo `docker-compose.yml`.

## Uso no dia a dia

Para iniciar ou criar o container do Synapse:

```bash
docker compose up -d
```

Para parar o Synapse sem remover o container:

```bash
docker compose stop
```

Para iniciar novamente um container parado:

```bash
docker compose start
```

Para reiniciar:

```bash
docker compose restart synapse
```

Para acompanhar os logs:

```bash
docker compose logs -f synapse
```

Para verificar o estado do serviço:

```bash
docker compose ps
```

Para parar e remover o container e a rede criados pelo Compose:

```bash
docker compose down
```

O comando acima mantém o volume `synapse-data`.

> Não utilize `docker compose down -v` se quiser preservar os usuários, o banco e os demais dados persistentes do Synapse.

## Alterando o `homeserver.yaml`

Abra o arquivo no VS Code:

```bash
code /Users/frreserve/synnal/homeserver.yaml
```

Após salvar uma alteração, reinicie o Synapse:

```bash
docker compose restart synapse
```

Como o arquivo está montado diretamente no container pelo `docker-compose.yml`, não é necessário copiá-lo novamente.

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
docker compose exec synapse \
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
Docker Compose
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
docker compose up -d
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

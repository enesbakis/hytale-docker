# Hytale Docker Server

[![Docker Hub](https://img.shields.io/docker/v/enesbakis/hytale-docker?label=Docker%20Hub&sort=semver)](https://hub.docker.com/r/enesbakis/hytale-docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/enesbakis/hytale-docker)](https://hub.docker.com/r/enesbakis/hytale-docker)
[![Docker Image Size](https://img.shields.io/docker/image-size/enesbakis/hytale-docker/latest)](https://hub.docker.com/r/enesbakis/hytale-docker)

A ready-to-use Docker configuration for running a Hytale server.

## Pre-built Image

You can use the pre-built image from Docker Hub:

```bash
docker pull enesbakis/hytale-docker:latest
```

Or build locally from source (see below).

## Requirements

- Docker and Docker Compose
- Hytale game license (to download server files)
- Minimum 4GB RAM

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/enesbakis/hytale-docker.git
cd hytale-docker
```

### 2. Obtain server files

Hytale server files are not included in this repository due to license restrictions.

If you have the Hytale Launcher installed, copy the files from:

**Windows:**
```
%appdata%\Hytale\install\release\package\game\latest
```

**Linux:**
```
$XDG_DATA_HOME/Hytale/install/release/package/game/latest
```

**macOS:**
```
~/Application Support/Hytale/install/release/package/game/latest
```

Copy the contents of the `Server` folder and the `Assets.zip` file to the `data/` directory:

```
data/
├── HytaleServer.jar
├── Assets.zip
└── (other files...)
```

### 3. Configuration

Edit the environment file:

```bash
cp .env.example .env
```

Modify the values in `.env` if needed.

### 4. Start the server

```bash
docker compose up -d
```

### 5. Server authentication

On first run, authentication is triggered automatically. Watch the logs for the verification link:

```bash
docker compose logs -f
```

You will see something like:

```
Visit: https://oauth.accounts.hytale.com/oauth2/device/verify
Enter code: XXXX-XXXX
```

Open the link in your browser and enter the code to authenticate.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY` | `4G` | Amount of memory to allocate |
| `INIT_MEMORY` | - | Initial memory allocation (optional) |
| `MAX_MEMORY` | - | Maximum memory allocation (optional) |
| `SERVER_PORT` | `5520` | Server port (UDP) |
| `SERVER_HOST` | `0.0.0.0` | Bind address |
| `TZ` | `UTC` | Timezone |
| `UID` | `1000` | Linux user ID |
| `GID` | `1000` | Linux group ID |
| `ENABLE_AOT` | `false` | AOT cache support |
| `JVM_OPTS` | - | Additional JVM parameters |
| `EXTRA_ARGS` | - | Additional server arguments |
| `DEBUG` | `false` | Debug mode |

## Volumes

| Path | Description |
|------|-------------|
| `/data` | All server data (world, logs, mods, config) |
| `/data/universe` | Game world data |
| `/data/logs` | Server logs |
| `/data/mods` | Mod files |

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `5520` | UDP | Game connection (QUIC) |

Make sure to open this port as **UDP** in your firewall or router configuration.

## Commands

View server logs:
```bash
docker compose logs -f
```

Stop the server:
```bash
docker compose down
```

Restart the server:
```bash
docker compose restart
```

Attach to server console:
```bash
docker attach hytale-server
```

To detach from console: `Ctrl+P`, `Ctrl+Q`

## AOT Cache

AOT (Ahead-of-Time) cache reduces server startup time. To use it:

1. Copy `HytaleServer.aot` file to the `data/` directory
2. Set `ENABLE_AOT=true` in the `.env` file

## Installing Mods

Copy mods to the `data/mods/` directory. They can be in `.zip` or `.jar` format.

## Troubleshooting

**Server won't start:**
- Make sure `HytaleServer.jar` and `Assets.zip` are in the `data/` directory
- Check the logs: `docker compose logs`

**Cannot connect:**
- Verify that UDP port 5520 is open in your firewall
- Check port forwarding configuration in your router

**Out of memory:**
- Increase the `MEMORY` value in the `.env` file
- Update resource limits in `docker-compose.yml`

## License

MIT

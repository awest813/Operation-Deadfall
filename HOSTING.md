# Hosting Operation Deadfall

This guide covers running a **dedicated multiplayer server** and the easiest ways to **build** a reproducible Linux binary for deployment.

For client setup and local play, see [RUNNING_THE_GAME.md](RUNNING_THE_GAME.md).

---

## Quick reference

| Goal | Command |
|------|---------|
| Local dedicated server | `./scripts/run-dedicated-server.sh` |
| Docker dedicated server | `docker compose up --build` |
| Reproducible engine build | `docker build --target builder -t operation-deadfall-build .` |
| Native Linux build | `./scripts/install-linux-build-deps.sh && ./build.sh --preset linux64 --package` |

Default game port: **UDP 27500** (Quake-family default). Open this port on your firewall and router.

---

## Dedicated server (native)

1. Build or download a Linux engine binary (see [BUILD.md](BUILD.md)).
2. Place **`nzp/`** game data next to the repo or in the parent folder (same as `./run_game.sh`).
3. Start the server:

```bash
./scripts/run-dedicated-server.sh
```

Options:

```bash
./scripts/run-dedicated-server.sh --map ndu --maxplayers 8 --port 27500
```

Clients connect from the game console or launch line:

```text
+connect YOUR_SERVER_IP:27500
```

### Server tuning

| Setting | Suggestion |
|---------|------------|
| `od_perf_preset` | Use `0` (Low) on small VPS instances to cap zombie AI load |
| `+maxplayers` | Default 4; raise only if the host has spare CPU |
| `+sv_public 1` | Advertise on the master server list (if enabled in your build) |

---

## Dedicated server (Docker)

Docker gives a consistent runtime on any Linux host without installing build dependencies on the server.

### 1. Prepare game data

Copy or symlink NZ:P data so the repo has:

```text
Operation-Deadfall/
└── nzp/          # required — same files as for run_game.sh
```

### 2. Start the container

```bash
docker compose up --build
```

Environment variables (optional):

| Variable | Default | Purpose |
|----------|---------|---------|
| `OD_MAP` | `ndu` | Map loaded at startup |
| `OD_MAXPLAYERS` | `4` | Player cap |
| `OD_PORT_UDP` | `27500` | Host UDP port mapping |
| `OD_GAME_DIR` | `./nzp` | Host path mounted read-only at `/game/nzp` |

Example with a custom map and eight players:

```bash
OD_MAP=ndu OD_MAXPLAYERS=8 docker compose up --build
```

### 3. Firewall

Allow **UDP 27500** (and **27501** if your network stack uses a status port) from the internet to the Docker host.

---

## Reproducible builds (Docker)

The repository `Dockerfile` installs pinned Debian packages and runs `./build.sh --preset linux64 --package`, so builds do not depend on the host having SDL/OpenGL dev headers installed.

```bash
# Build inside Docker
docker build --target builder -t operation-deadfall-build .

# Copy the linux64 bundle to the host
docker create --name od-extract operation-deadfall-build
docker cp od-extract:/src/engine/dist/linux64 ./engine/dist/
docker rm od-extract
```

This is equivalent to a native `./build.sh --preset linux64 --package` on a machine with [install-linux-build-deps.sh](scripts/install-linux-build-deps.sh) applied.

---

## CI and releases

- **Every push / PR:** a fast CI job builds Linux 64-bit and compiles QuakeC to catch breakage early.
- **Full multi-platform ZIP releases:** triggered manually from GitHub Actions (**Build ALL and Publish Release** workflow) so bleeding-edge artifacts are not overwritten on every commit.

---

## Smoke-test checklist (server)

- [ ] `./scripts/run-dedicated-server.sh` starts without “Couldn't find game directory”.
- [ ] Console shows the server listening (typically port 27500).
- [ ] A client can connect with `+connect host:27500`.
- [ ] Map loads and rounds begin when a player joins.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Couldn't find game directory` | Ensure `nzp/` exists and `-basedir` points at its parent (use `run_game.sh` / compose volume layout). |
| Docker build fails on `COPY` | Run from repo root; check `.dockerignore` is not excluding required sources. |
| Clients cannot connect | Open UDP 27500 on firewall/NAT; verify the server IP and port. |
| High CPU on small VPS | Set `od_perf_preset 0` in server config or launch args. |

# Reproducible build and optional dedicated-server runtime for Operation Deadfall.
#
# Build engine only:
#   docker build --target builder -t operation-deadfall-build .
#
# Build and extract linux64 bundle to ./engine/dist/linux64 on the host:
#   docker build --target builder -t operation-deadfall-build .
#   docker create --name od-extract operation-deadfall-build
#   docker cp od-extract:/src/engine/dist/linux64 ./engine/dist/
#   docker rm od-extract
#
# Run a dedicated server (mount nzp/ game data at /game/nzp):
#   docker compose up --build deadfall-server

FROM debian:bookworm AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential gcc make ca-certificates \
    libsdl2-dev libgl1-mesa-dev libopenal-dev \
    zlib1g-dev libbz2-dev libpng-dev libjpeg-dev \
    libfreetype6-dev libvorbis-dev libogg-dev libopus-dev \
    libgnutls28-dev libx11-dev libxcursor-dev libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN ./build.sh --preset linux64 --package \
    && cp -f engine/release/nzportable-sdl2 engine/release/nzportable64-sdl

# Headless dedicated server image (requires nzp/ mounted at /game/nzp).
FROM debian:bookworm-slim AS runtime

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libsdl2-2.0-0 libopenal1 libgl1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/engine/dist/linux64/nzportable-sdl2 /usr/local/bin/nzportable64-sdl

WORKDIR /game
EXPOSE 27500/udp 27501/udp

ENV OD_MAP=nzp_asylum
ENV OD_MAXPLAYERS=4

ENTRYPOINT ["/usr/local/bin/nzportable64-sdl", "-basedir", "/game", "-nohome", "-dedicated"]
CMD ["+map", "nzp_asylum", "+maxplayers", "4"]

# Building Operation Deadfall (FTEQW Engine)

This document explains how to build the Operation Deadfall engine from source. The engine is a
fork of [FTEQW](https://fte.triptohell.info/), compiled with the `nzportable` configuration.

---

## Quick Start (Docker – Recommended)

The fastest, most reproducible way to build is using the official Docker image, which bundles
every cross-compiler and dependency.

```bash
# Pull the image (one-time)
docker pull motolegacy/fteqw:latest

# Clone the repo if you haven't already
git clone https://github.com/awest813/Operation-Deadfall.git
cd Operation-Deadfall

# Build Linux 64-bit with SDL2 (runs inside the container, writes to ./engine/release/)
docker run --rm -v "$(pwd)":/src -w /src/tools motolegacy/fteqw:latest \
    sh build-nzp-linux64.sh
```

The finished binary is placed at `engine/release/nzportable64-sdl`.

### Available Docker build scripts

| Script | Output binary | Notes |
|--------|--------------|-------|
| `build-nzp-linux32.sh` | `engine/release/nzportable32-sdl` | Linux i386 + SDL2 |
| `build-nzp-linux32-nosdl.sh` | `engine/release/nzportable32` | Linux i386, X11 direct |
| `build-nzp-linux64.sh` | `engine/release/nzportable64-sdl` | Linux x86_64 + SDL2 |
| `build-nzp-linux64-nosdl.sh` | `engine/release/nzportable64` | Linux x86_64, X11 direct |
| `build-nzp-linux_arm64.sh` | `engine/release/nzportablearm64-sdl` | Linux AArch64 + SDL2 |
| `build-nzp-linux_arm64-nosdl.sh` | `engine/release/nzportablearm64` | Linux AArch64, X11 direct |
| `build-nzp-linux_armhf.sh` | `engine/release/nzportablearmhf-sdl` | Linux ARMhf + SDL2 |
| `build-nzp-linux_armhf-nosdl.sh` | `engine/release/nzportablearmhf` | Linux ARMhf, X11 direct |
| `build-nzp-win32.sh` | `engine/release/nzportable-sdl.exe` | Windows x86 + SDL2 (cross-compiled) |
| `build-nzp-win32-nosdl.sh` | `engine/release/nzportable.exe` | Windows x86, WinAPI direct |
| `build-nzp-win64.sh` | `engine/release/nzportable-sdl64.exe` | Windows x86\_64 + SDL2 (cross-compiled) |
| `build-nzp-win64-nosdl.sh` | `engine/release/nzportable64.exe` | Windows x86\_64, WinAPI direct |
| `build-nzp-web.sh` | `engine/release/ftewebgl.{wasm,js}` | WebAssembly (Emscripten) |

---

## Native Linux Build (without Docker)

### 1. Install dependencies

#### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential gcc make \
    libsdl2-dev libgl1-mesa-dev libopenal-dev \
    zlib1g-dev libbz2-dev libpng-dev libjpeg-dev \
    libfreetype6-dev libvorbis-dev libogg-dev libopus-dev \
    libgnutls28-dev libx11-dev libxcursor-dev \
    libasound2-dev
```

#### Fedora / RHEL

```bash
sudo dnf install -y \
    gcc make SDL2-devel mesa-libGL-devel openal-soft-devel \
    zlib-devel bzip2-devel libpng-devel libjpeg-turbo-devel \
    freetype-devel libvorbis-devel libogg-devel opus-devel \
    gnutls-devel libX11-devel libXcursor-devel \
    alsa-lib-devel
```

### 2. Build

```bash
cd engine

# Pre-build vendored third-party libraries (zlib, libjpeg, libpng, etc.)
make makelibs FTE_TARGET=SDL2

# Build the main binary (-j flag sets the number of parallel jobs)
make m-rel FTE_TARGET=SDL2 FTE_CONFIG=nzportable -j$(nproc)
```

The binary is placed at `engine/release/nzportable-sdl2`.

#### Building without SDL2 (X11 direct)

```bash
cd engine
make makelibs
make m-rel FTE_CONFIG=nzportable -j$(nproc)
```

Output: `engine/release/nzportable`.

### 3. Convenience top-level script

A wrapper script is provided at the repository root:

```bash
# Auto-detects host CPU, builds SDL2 variant for the native target
./build.sh
```

Run `./build.sh --help` for available options.

---

## Cross-compiling for Windows on Linux

The Docker image already contains MinGW-w64. If you want to cross-compile on a bare Linux host:

```bash
# Debian/Ubuntu
sudo apt-get install -y mingw-w64

cd engine
make makelibs FTE_TARGET=win64_SDL2
make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j$(nproc)
# Running make a second time works around an SDL2 link-order issue:
make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j$(nproc)
```

Output: `engine/release/nzportable-sdl64.exe`

For 32-bit Windows replace `win64_SDL2` with `win32_SDL2` (or `win64` / `win32` for no-SDL builds).

---

## Native Windows Build (MSVC)

> **Note:** Cross-compiling on Linux via Docker is the officially tested path. Native MSVC
> builds are supported by FTEQW but are not regularly tested for this project.

1. Install [Visual Studio 2022](https://visualstudio.microsoft.com/) with the **Desktop
   development with C++** workload.
2. Open **x64 Native Tools Command Prompt for VS 2022**.
3. Run:

```bat
cd engine
nmake /f Makefile FTE_TARGET=vc m-rel FTE_CONFIG=nzportable
```

Refer to `engine/README.MSVC` for additional MSVC-specific notes.

---

## Build Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `FTE_TARGET` | (host) | Target architecture. See list above. |
| `FTE_CONFIG` | (none) | Config header to use. Must be `nzportable` for this project. |
| `CC` | `gcc` | C compiler. Override for cross-compilation. |
| `STRIP` | `strip` | Strip binary. Override for cross-compilation. |
| `CPUOPTIMIZATIONS` | `-Os` | CPU-level optimisation flags. |

---

## Vendored Library Versions (built by `make makelibs`)

The engine ships with vendored copies of the following libraries. `make makelibs` downloads and
compiles them automatically:

| Library | Version |
|---------|---------|
| zlib | 1.3.1 |
| libpng | 1.6.40 |
| libjpeg | 9c |
| libvorbis | 1.3.7 |
| libogg | 1.3.4 |
| libopus | 1.3.1 |
| libfreetype | 2.10.1 |
| SDL2 | 2.30.7 |
| OpenSSL | 3.0.1 |

---

## Common Failure Points

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `make: gcc: No such file or directory` | `build-essential` / `gcc` not installed | Install GCC |
| `SDL.h: No such file or directory` | SDL2 dev headers missing | `apt install libsdl2-dev` |
| `GL/gl.h: No such file or directory` | OpenGL dev headers missing | `apt install libgl1-mesa-dev` |
| `undefined reference to SDL_*` on Windows | Link-order issue with SDL2 | Run `make m-rel` a second time |
| `makelibs` fails on download | Network blocked or tarball URL changed | Check internet access; update version variables in `engine/Makefile` |
| Binary not found after build | Wrong `FTE_TARGET` selected | Check the output filename against the table above |
| `nzportable` config not recognised | `FTE_CONFIG` not set | Always pass `FTE_CONFIG=nzportable` |

---

## Smoke-Test Checklist

After a successful build, quickly verify the binary:

- [ ] `engine/release/nzportable*` (or `.exe`) exists and is non-zero in size.
- [ ] `file engine/release/nzportable64-sdl` reports the expected architecture (`ELF 64-bit`, etc.).
- [ ] Running the binary with `-nohome -dedicated +quit` exits cleanly (exit code 0).
- [ ] On Linux: `ldd engine/release/nzportable64-sdl` resolves `libSDL2` and `libGL`.
- [ ] On Windows: binary loads without a "missing DLL" dialog when SDL2.dll is present.

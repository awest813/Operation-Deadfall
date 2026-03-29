# Building Operation Deadfall (FTEQW Engine)

This document explains how to build the Operation Deadfall engine from source. The engine is a
fork of [FTEQW](https://fte.triptohell.info/), compiled with the `nzportable` configuration.

---

## Quick Start

If you want the least-friction paths for the two most common desktop targets, use the top-level
wrapper scripts.

**First-time Linux (native build):** install distro packages in one step, then build:

```bash
./scripts/install-linux-build-deps.sh
./build.sh --preset linux64 --package
```

**First-time Windows (native build, recommended):** install [MSYS2](https://www.msys2.org/), then in an MSYS2 terminal (`UCRT64` or `MINGW64`):

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-toolchain
```

Add MSYS2’s compiler `bin` folder to your user **PATH** (for example `C:\msys64\ucrt64\bin`), then from **cmd** in the repo root either double-click **`build_engine.cmd`** or run:

```bat
build.bat --preset win11 --mingw --package
```

Output: `engine\dist\win11\` with `nzportable-sdl64.exe` and `SDL2.dll`. Launch with **`run_game.cmd`** once `nzp\` is beside the clone (see [RUNNING_THE_GAME.md](RUNNING_THE_GAME.md)).

### Linux 64-bit

```bash
./build.sh --preset linux64 --package
```

This produces:

- build output in `engine/release/`
- a runnable bundle in `engine/dist/linux64/`
- a compatibility alias named `engine/release/nzportable64-sdl`

### Windows 11 / Windows 64-bit from Linux

```bash
./build.sh --preset win11 --package
```

This produces:

- `engine/release/nzportable-sdl64.exe`
- `engine/release/SDL2.dll`
- a runnable bundle in `engine/dist/win11/`

### Windows 11 / Windows 64-bit on Windows

```bat
build.bat --preset win11 --mingw --package
```

For an MSVC-native build instead:

```bat
build.bat --preset win11
```

> **Why use the wrappers?** They reduce the amount of platform-specific knowledge needed by
> auto-selecting sensible defaults, re-running the known SDL2 Windows link step, copying
> `SDL2.dll` when needed, and optionally gathering the final runnable files into `engine/dist/`.

---

## Docker Build (Recommended for Linux-hosted cross-compiles)

The most reproducible Linux and Windows cross-build path is the official Docker image, which
bundles the compilers and dependencies.

```bash
# Pull the image (one-time)
docker pull motolegacy/fteqw:latest

# Clone the repo if you haven't already
git clone https://github.com/awest813/Operation-Deadfall.git
cd Operation-Deadfall

# Build Linux 64-bit with SDL2 and gather a runnable bundle
./build.sh --preset linux64 --docker --package
```

The finished binaries are placed in `engine/release/`. If you use `--package`, the game-ready
subset also lands in `engine/dist/<preset>/`.

### Legacy Docker helper scripts

These scripts are still available under `tools/` if you want the original one-command build steps:

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
| `build-nzp-win64.sh` | `engine/release/nzportable-sdl64.exe` | Windows x86_64 + SDL2 (cross-compiled) |
| `build-nzp-win64-nosdl.sh` | `engine/release/nzportable64.exe` | Windows x86_64, WinAPI direct |
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

#### Easy path

```bash
./build.sh --preset linux64 --package
```

#### Manual path

```bash
cd engine

# Pre-build vendored third-party libraries (zlib, libjpeg, libpng, etc.)
make makelibs FTE_TARGET=SDL2

# Build the main binary (-j flag sets the number of parallel jobs)
make m-rel FTE_TARGET=SDL2 FTE_CONFIG=nzportable -j$(nproc)
```

The main SDL2 binary is placed at `engine/release/nzportable-sdl2`. The wrapper script also copies
it to the friendlier alias `engine/release/nzportable64-sdl`.

#### Building without SDL2 (X11 direct)

```bash
./build.sh --preset linux64-nosdl --package
```

Manual equivalent:

```bash
cd engine
make makelibs
make m-rel FTE_CONFIG=nzportable -j$(nproc)
```

Output: `engine/release/nzportable` (plus the wrapper alias `engine/release/nzportable64`).

---

## Cross-compiling for Windows on Linux

### Easy path

```bash
./build.sh --preset win11 --package
```

This automatically:

1. uses the 64-bit Windows SDL2 target,
2. runs the second `make m-rel` pass required by the known SDL link-order issue,
3. copies `SDL2.dll` next to the executable, and
4. collects the runnable output into `engine/dist/win11/`.

### Manual path

If you want to cross-compile on a bare Linux host instead of using the wrapper:

```bash
# Debian/Ubuntu
sudo apt-get install -y mingw-w64

cd engine
make makelibs FTE_TARGET=win64_SDL2
make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j$(nproc)
# Running make a second time works around an SDL2 link-order issue:
make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j$(nproc)
# Copy SDL2.dll next to the exe (required to run the game on Windows):
cp libs-x86_64-w64-mingw32/SDL2-2.30.7/x86_64-w64-mingw32/bin/SDL2.dll release/
```

Output: `engine/release/nzportable-sdl64.exe` + `engine/release/SDL2.dll`

For 32-bit Windows replace `win64_SDL2` with `win32_SDL2` (or `win64` / `win32` for no-SDL builds).

---

## Native Windows Build

### Fastest UX path with MinGW-w64

```bat
build.bat --preset win11 --mingw --package
```

This is the closest Windows-native equivalent to the Linux cross-build flow, including the SDL2
DLL copy and a bundled `engine\dist\win11\` output folder.

### MSVC path

> **Note:** Cross-compiling on Linux via Docker or using MinGW-w64 on Windows is the most
> convenient workflow for release-like builds. Native MSVC builds are supported by FTEQW but are
> not regularly tested for this project.

1. Install [Visual Studio 2022](https://visualstudio.microsoft.com/) with the **Desktop
   development with C++** workload.
2. Open **x64 Native Tools Command Prompt for VS 2022**.
3. Run:

```bat
build.bat --preset win11
```

Manual equivalent:

```bat
cd engine
nmake /f Makefile FTE_TARGET=vc m-rel FTE_CONFIG=nzportable
```

Refer to `engine/README.MSVC` for additional MSVC-specific notes.

---

## Wrapper Script Reference

### `build.sh`

| Option | Description |
|--------|-------------|
| `--preset linux64` | Native Linux 64-bit SDL2 build |
| `--preset linux64-nosdl` | Native Linux 64-bit no-SDL build |
| `--preset win11` | Windows 64-bit SDL2 build target |
| `--preset win11-nosdl` | Windows 64-bit no-SDL build target |
| `--target <value>` | Pass a raw `FTE_TARGET`-style target selection |
| `--nosdl` | Force a no-SDL build when using a raw Linux/Windows target |
| `--docker` | Run the build inside `motolegacy/fteqw:latest` |
| `--package` | Gather the runnable files in `engine/dist/<label>/` |
| `--jobs <N>` | Override the number of parallel jobs |

### `build.bat`

| Option | Description |
|--------|-------------|
| `--preset win11` | Windows 64-bit default preset |
| `--preset win11-nosdl` | Windows 64-bit no-SDL preset |
| `--mingw` | Use `mingw32-make` instead of `nmake` |
| `--package` | Gather the runnable files in `engine\dist\<label>\` |
| `--jobs <N>` | Override the number of parallel jobs |

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
| `mingw32-make: command not found` | MinGW-w64 tools missing on Windows | Install MinGW-w64 and ensure `mingw32-make` is on `PATH` |
| `nmake` not found | Not using a Visual Studio developer prompt | Launch an MSVC Native Tools prompt |
| `SDL.h: No such file or directory` | SDL2 dev headers missing | `apt install libsdl2-dev` |
| `GL/gl.h: No such file or directory` | OpenGL dev headers missing | `apt install libgl1-mesa-dev` |
| `undefined reference to SDL_*` on Windows | Link-order issue with SDL2 | Run `make m-rel` a second time or use the wrapper scripts |
| `makelibs` fails on download | Network blocked or tarball URL changed | Check internet access; update version variables in `engine/Makefile` |
| Binary not found after build | Wrong `FTE_TARGET` selected | Check the output filename against the table above |
| `nzportable` config not recognised | `FTE_CONFIG` not set | Always pass `FTE_CONFIG=nzportable` |

---

## Smoke-Test Checklist

After a successful build, quickly verify the binary:

- [ ] `engine/release/nzportable*` (or `.exe`) exists and is non-zero in size.
- [ ] If you used `--package`, `engine/dist/<preset>/` contains the runnable files you expect.
- [ ] `file engine/release/nzportable64-sdl` reports the expected architecture (`ELF 64-bit`, etc.).
- [ ] Running the binary with `-nohome -dedicated +quit` exits cleanly (exit code 0).
- [ ] On Linux: `ldd engine/release/nzportable64-sdl` resolves `libSDL2` and `libGL`.
- [ ] On Windows: binary loads without a "missing DLL" dialog when `SDL2.dll` is present.

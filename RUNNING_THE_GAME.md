# Running Operation Deadfall

This document explains how to set up and launch the game after building (or downloading) the
engine binary. See [BUILD.md](BUILD.md) for compilation instructions.

---

## Prerequisites

### 1. Engine binary

Either build it yourself (see [BUILD.md](BUILD.md)) or download a pre-built binary from the
[Releases](https://github.com/awest813/Operation-Deadfall/releases/tag/bleeding-edge) page.

### 2. Game assets (`nzp` folder)

The engine is **not** bundled with game assets. You need the `nzp` game-data folder, which
contains maps, textures, models, sounds, and QuakeC bytecode (`.dat` files).

Obtain the `nzp` folder from the official
[NZ:P releases](https://github.com/nzp-team/nzportable/releases) or from your existing
installation of Nazi Zombies: Portable.

---

## Directory Layout

Place the engine binary next to the `nzp` folder:

```
game-directory/
├── nzportable64-sdl          ← engine binary (Linux)
├── nzportable-sdl64.exe      ← engine binary (Windows)
└── nzp/                      ← game-data folder (required)
    ├── pak0.pak              ← base game data
    ├── progs.dat             ← server-side QuakeC bytecode
    ├── menu.dat              ← menu system QuakeC bytecode
    ├── csaddon.dat           ← client-side QuakeC bytecode
    ├── maps/
    ├── models/
    ├── sound/
    └── textures/
```

> **Note:** The engine uses `nzp` as its base game directory
> (`GAME_BASEGAMES "nzp"` in `engine/common/config_nzportable.h`). It will refuse to start if
> this folder is missing or empty.

---

## Starting the Game

### Linux

```bash
cd /path/to/game-directory
./nzportable64-sdl
```

For the X11-direct (no-SDL) build:

```bash
./nzportable64
```

### Windows

Double-click `nzportable-sdl64.exe`, or from a command prompt:

```bat
cd C:\path\to\game-directory
nzportable-sdl64.exe
```

> **SDL2.dll note:** The SDL2 build requires `SDL2.dll` in the same folder as the `.exe`. It is
> included in the release ZIP archives. If you built from source, `make makelibs` downloads the
> MinGW SDL2 package; copy `SDL2.dll` from
> `engine/libs-x86_64-w64-mingw32/SDL2-2.30.7/x86_64-w64-mingw32/bin/SDL2.dll`
> (win64) or `engine/libs-i686-w64-mingw32/SDL2-2.30.7/i686-w64-mingw32/bin/SDL2.dll` (win32)
> to the same directory as the `.exe`. The top-level `build.bat` and `build.sh` do this
> automatically.

### Dedicated server

```bash
# Linux – headless, no window
./nzportable64-sdl -dedicated +map nzp_asylum

# Windows
nzportable-sdl64.exe -dedicated +map nzp_asylum
```

---

## Useful Launch Options

| Flag / command | Effect |
|----------------|--------|
| `-window` | Force windowed mode |
| `-fullscreen` | Force fullscreen mode |
| `-width 1920 -height 1080` | Set resolution |
| `-nohome` | Ignore `~/.fte` user directory (useful for clean tests) |
| `-nosound` | Disable audio |
| `+vid_renderer gl` | Force OpenGL renderer |
| `+vid_renderer vk` | Force Vulkan renderer |
| `+vid_renderer sw` | Force software renderer (fallback) |
| `+connect <IP>` | Connect to a server on launch |
| `+map <mapname>` | Load a specific map directly |

---

## Configuration Files

The engine stores per-user settings in:

| Platform | Path |
|----------|------|
| Linux | `~/.fte/nzp/` |
| Windows | `%APPDATA%\fte\nzp\` |

The main config file is `config.cfg` inside that directory. To reset all settings, delete the
file (or the whole directory).

---

## Common Failure Points

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Couldn't find game directory` | `nzp/` folder missing or not next to the binary | Ensure the `nzp` folder is in the same directory as the binary |
| Blank/black screen on startup | Missing `progs.dat` or `pak0.pak` | Verify game-data files are present in `nzp/` |
| `SDL2.dll not found` (Windows) | DLL not next to `.exe` | Copy `SDL2.dll` from the release ZIP or MinGW/SDL2 installation |
| Crash on map load | Corrupted `.bsp` or mismatched `.dat` bytecode | Re-download game assets; rebuild QuakeC if self-compiled |
| No audio | OpenAL not installed (Linux) | `sudo apt install libopenal1` |
| `vid_renderer vk` crash | Vulkan driver missing or unsupported | Fall back with `+vid_renderer gl` |
| Game opens then immediately exits | Bad `config.cfg` value | Delete `config.cfg` and relaunch |

---

## Smoke-Test Checklist

Run through these steps to confirm a working installation:

- [ ] Engine binary launches without error messages in the console.
- [ ] Main menu appears with background music.
- [ ] Navigate to **Play** → select a map → game loads without crashing.
- [ ] Player can move, shoot, and round-counter increments.
- [ ] Dedicated server starts and prints `Listening on port 27500`.
- [ ] A second client can connect to the dedicated server.

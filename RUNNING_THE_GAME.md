# Running Operation Deadfall

This document explains how to set up and launch the game after building (or downloading) the
engine binary. See [BUILD.md](BUILD.md) for compilation instructions.

If you are working from a **git clone** of this repository, you can use **`./run_game.sh`**
from the repo root: it picks a Linux binary under `engine/release/` or `engine/dist/`, passes
`-basedir` automatically, and looks for `nzp/` either inside the repo or in the parent folder.

On Windows, use **`run_game.cmd`** from the repo root the same way: it finds `nzp\`, picks
`engine\dist\win11\nzportable-sdl64.exe` or `engine\release\nzportable-sdl64.exe` (or MSVC
`fteqw.exe` if present), and passes `-basedir` so you do not need to copy the binary next to
`nzp\`. You can still use the manual layout below if you prefer.

---

## Prerequisites

### 1. Engine binary

Either build it yourself (see [BUILD.md](BUILD.md)) or download a pre-built binary from the
[Releases](https://github.com/awest813/Operation-Deadfall/releases/tag/bleeding-edge) page.

If you built locally with the wrapper scripts, the easiest place to start is the packaged output:

- Linux 64-bit: `engine/dist/linux64/`
- Windows 11 / 64-bit: `engine/dist/win11/`

Those folders contain the runnable executable plus any supporting runtime files that had to be
copied during the build.

### 2. Game assets (`nzp` folder)

The engine is **not** bundled with game assets. You need the `nzp` game-data folder, which
contains maps, textures, models, sounds, and QuakeC bytecode (`.dat` files).

Obtain the `nzp` folder from the official
[NZ:P releases](https://github.com/nzp-team/nzportable/releases) or from your existing
installation of Nazi Zombies: Portable.

### 3. LibreQuake assets (`lq1` folder) — optional but recommended

[LibreQuake](https://github.com/lavenderdotpet/LibreQuake) is a BSD-licensed, completely free
replacement for standard Quake game data (enemy models, player gibs, environmental sounds, health
pickups, and more). When an `lq1/` folder is present next to `nzp/`, the run scripts automatically
load it as a supplementary asset layer: LibreQuake's free assets are used for standard Quake
content, while NZ:P continues to supply all custom Operation Deadfall content (weapon models,
sounds, zombie variants, etc.).

To add it:

1. Download **`mod.zip`** from the
   [LibreQuake v0.09-beta release](https://github.com/lavenderdotpet/LibreQuake/releases/tag/v0.09-beta).
2. Extract it — you should get an `lq1/` folder containing `pak0.pak` and `pak1.pak`.
3. Place `lq1/` next to `nzp/` (in the same directory as the engine binary or the parent of the
   repo, matching wherever your `nzp/` lives).

The `lq1/` folder is entirely optional. The game runs without it; NZ:P data covers everything
needed.

---

## Directory Layout

Place the engine binary next to the `nzp` folder. The optional `lq1/` folder (LibreQuake) goes in
the same location:

```text
game-directory/
├── nzportable64-sdl          ← engine binary (Linux alias created by build.sh)
├── nzportable-sdl64.exe      ← engine binary (Windows 11 / 64-bit)
├── SDL2.dll                  ← Windows SDL2 runtime (copied automatically by wrapper builds)
├── nzp/                      ← game-data folder (required)
│   ├── pak0.pak              ← base game data
│   ├── progs.dat             ← server-side QuakeC bytecode
│   ├── menu.dat              ← menu system QuakeC bytecode
│   ├── csaddon.dat           ← client-side QuakeC bytecode
│   ├── maps/
│   ├── models/
│   ├── sound/
│   └── textures/
└── lq1/                      ← LibreQuake assets (optional — see §3 above)
    ├── pak0.pak
    └── pak1.pak
```

> **Note:** The engine uses `nzp` as its base game directory
> (`GAME_BASEGAMES "nzp"` in `engine/common/config_nzportable.h`). It will refuse to start if
> this folder is missing or empty. `lq1/` is loaded on top when present.

---

## Starting the Game

### Linux

If you used the packaged wrapper output:

```bash
cd /path/to/Operation-Deadfall/engine/dist/linux64
./nzportable-sdl2
```

If you prefer the compatibility alias in `engine/release/`:

```bash
cd /path/to/Operation-Deadfall/engine/release
./nzportable64-sdl
```

For the X11-direct (no-SDL) build:

```bash
./nzportable64
```

### Windows

From a **git clone** (easiest):

```bat
cd C:\path\to\Operation-Deadfall
run_game.cmd
```

Optional: `run_game.cmd -- +map nzp_asylum`

If you prefer to run the binary directly, use the packaged wrapper output:

```bat
cd C:\path\to\Operation-Deadfall\engine\dist\win11
nzportable-sdl64.exe
```

Or run the same executable from `engine\release\`.

> **SDL2.dll note:** The SDL2 build requires `SDL2.dll` in the same folder as the `.exe`. It is
> included in the release ZIP archives. If you built from source, `make makelibs` downloads the
> MinGW SDL2 package; copy `SDL2.dll` from
> `engine/libs-x86_64-w64-mingw32/SDL2-2.30.7/x86_64-w64-mingw32/bin/SDL2.dll`
> (win64) or `engine/libs-i686-w64-mingw32/SDL2-2.30.7/i686-w64-mingw32/bin/SDL2.dll` (win32)
> to the same directory as the `.exe`. The top-level `build.bat` and `build.sh` do this
> automatically for SDL2 wrapper builds.

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
| `SDL2.dll not found` (Windows) | DLL not next to `.exe` | Copy `SDL2.dll` from the release ZIP or use the wrapper `--package` output |
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

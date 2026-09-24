# Operation Deadfall

A **COD Zombies-inspired wave-survival game** built on a fork of the
[FTEQW](https://fte.triptohell.info/about) Quake engine, set in a
sci-fi WWII world inspired by Wolfenstein.  Survive endless waves of undead,
earn points, unlock new areas, and arm yourself from wall buys and the mystery
box — all driven by a fully custom QuakeC game module.

---

## Features

### 🌊 Round System
- Wave-based state machine: **Waiting → Intro → Spawning → Active → Intermission** (repeating)
- Zombie count, health, and spawn rate all scale with round number (rounds 1–25 use a hand-tuned table; 26+ follow a formula)
- Per-round ammo drops from zombies (10mm → 5.56mm → 7.62mm depending on round)

### 💰 Economy
- Kill rewards scale with round number (base 10 pts + 2 pts/round, capped at 60)
- **Wall buys** — purchase specific weapons mounted on the wall
- **Mystery box** — random weapon for 950 pts (requires power)
- **Zone doors** — spend points to unlock new areas (default 750 pts each)
- **Perk machines** — install passive upgrades (9 perks across 4 cost tiers: 500–2000 pts)

### 🔫 Weapons
Weapons span seven classes with distinct combat feels:

| Class          | Examples                                          |
|----------------|---------------------------------------------------|
| Melee          | Fist, Knife, Axe, Vibroblade, Power Axe           |
| Pistol         | USP, Deagle, Needler                              |
| SMG            | MP9, MP7                                          |
| Shotgun        | Winchester, Mossberg, Jackhammer                  |
| Assault Rifle  | AK112, AK74, Moonlight M4, SA80                   |
| Battle Rifle   | FN FAL, Rangemaster, DKS-1                        |
| Special        | Improvised Rifle, Vril Pistol, Rocket Launcher    |

### 🧪 Perks
Nine passive perks purchasable at powered perk machines:

| Perk             | Tier | Cost  | Effect                     |
|------------------|------|-------|----------------------------|
| Bonus Movement   | 1    | 500   | Increased move speed       |
| Strong Back      | 1    | 500   | Higher carry weight        |
| Quick Pockets    | 1    | 500   | Faster reloads             |
| Awareness        | 2    | 1000  | Enemy detection range      |
| Silent Running   | 2    | 1000  | Reduced aggro radius       |
| Better Criticals | 2    | 1000  | Increased crit chance/dmg  |
| Bonus Ranged Dmg | 2    | 1000  | Ranged weapon damage boost |
| Divine Favor     | 3    | 1500  | Major defensive buff       |
| Slayer           | 4    | 2000  | Ultimate killing perk      |

### 🗺️ World Entities
All COD-Zombies-style entities are available for map authors:

| Entity               | Purpose                                          |
|----------------------|--------------------------------------------------|
| `info_wallbuy`       | Wall-mounted weapon purchase point               |
| `func_mystery_box`   | Random weapon spin (requires power)              |
| `func_perk_machine`  | Perk installation station (requires power)       |
| `func_power_switch`  | Enables mystery box and perk machines            |
| `func_door_zone`     | Point-cost passage to unlock new areas           |
| `info_zombie_spawn`  | Spawn point for round-managed zombies            |

### ⚙️ Performance Presets
The `od_perf_preset` server cvar (0 = Low / 1 = Medium / 2 = High) adjusts the
zombie AI budget for the host machine:

| Preset | Max concurrent zombies | Notes                         |
|--------|------------------------|-------------------------------|
| Low    | 12                     | Disables glow on zombie enemies|
| Medium | 24                     | Default                       |
| High   | 24                     | Full effects enabled          |

---

## Supported Platforms

| Platform        | Supported |
|-----------------|-----------|
| Linux 32-bit    | ✅        |
| Linux 64-bit    | ✅        |
| Linux ARMhf     | ✅        |
| Linux ARM64     | ✅        |
| Windows 32-bit  | ✅        |
| Windows 64-bit  | ✅        |
| macOS           | ❌        |
| Android         | ❌        |

---

## Quick Start

You always need **two things**: an **engine binary** and the **`nzp` game-data
folder** (from [Nazi Zombies: Portable](https://github.com/nzp-team/nzportable)).
The engine looks for a directory named `nzp` next to its base path (`GAME_BASEGAMES "nzp"`).

Optionally, place an **`lq1/`** folder (from [LibreQuake](https://github.com/lavenderdotpet/LibreQuake/releases) — BSD-licensed, free)
next to `nzp/`. The run scripts detect it automatically and load it as a free Quake-asset layer
alongside NZ:P data — no configuration needed.

### One-Click Setup (Fastest)

Clone the repository and run the automated setup script for your platform:

- **Windows**: Double-click **`setup_game.cmd`** (or run `setup_game.cmd` in cmd / PowerShell).
- **Linux**: Run **`./setup_game.sh`**.

This automatically downloads required game assets into `nzp/`, sets up the engine binaries and SDL2 runtime, compiles the Operation Deadfall QuakeC bytecode, and validates that everything is ready to play.

Then launch the game:
- **Windows**: Double-click **`run_game.cmd`**
- **Linux**: Run **`./run_game.sh`**

### Manual Setup & Contributing

#### Windows (from a clone)

1. Put **`nzp\`** in the repo root or parent folder (or run `setup_game.cmd` to fetch it automatically).
2. **Engine** — double-click **`build_engine.cmd`** (supports MSYS2 MinGW-w64 or Visual Studio + CMake) or download a release binary into `engine\release\`.
3. **QuakeC** — run **`build_qc.cmd`** to compile and automatically deploy Deadfall bytecode to `nzp\`.
4. **Run** — double-click **`run_game.cmd`** (e.g. `run_game.cmd -- +map ndu`).

#### Linux (from a clone)

1. Add **`nzp/`** in repo root or parent folder (or run `./setup_game.sh`).
2. Install build packages and compile engine:
   ```bash
   ./scripts/install-linux-build-deps.sh
   ./build.sh --preset linux64 --package
   ```
3. Compile QuakeC: `./build_qc.sh`
4. Run: `./run_game.sh` (e.g. `./run_game.sh -- +map ndu`)

### If you only have a ZIP or folder of binaries (no git clone)

Place the engine executable next to the `nzp` folder, then:

```bash
# Linux
./nzportable64-sdl

# Windows
nzportable-sdl64.exe
```

### QuakeC modding (optional)

To compile the game module you need **FTEQCC**. Easiest path:

```bash
make -C engine/qclib qcc    # builds engine/qclib/fteqcc.bin
./build_qc.sh               # writes artifacts under build/qc/ by default
```

On Windows, use **`build_qc.cmd`** (or `powershell -File build_qc.ps1`) after building **`engine\qclib\fteqcc.bin`** with MinGW in MSYS2.

See [BUILD.md](BUILD.md) for engine build options (Docker, Windows, cross-compile) and
[RUNNING_THE_GAME.md](RUNNING_THE_GAME.md) for directory layout, launch flags, config paths, and troubleshooting.

---

## Repository Layout

```
run_game.sh      Launch helper when nzp/ sits next to the repo (Linux)
run_game.cmd     Same idea on Windows (double-click or run from cmd)
build_engine.cmd One-step MinGW engine build (calls build.bat --mingw --package)
build_qc.cmd     Build QuakeC on Windows (runs build_qc.ps1)
build_qc.ps1     QuakeC compile script for PowerShell
scripts/
└── install-linux-build-deps.sh   One-shot apt/dnf packages for ./build.sh
engine/          FTEQW engine source (C)
quakec/
└── deadfall/    Operation Deadfall game module (QuakeC)
    ├── defs.qc            Engine globals, entity fields, compile-time constants
    ├── economy.qc         Point costs, perk IDs, kill-reward helpers
    ├── inventory.qc       IID_* constants, item name/model/weight lookups
    ├── weapons.qc         Fire functions, W_Attack dispatch, BuyMenu
    ├── mod_buy.qc         World-interaction entities (wall buy, box, perks)
    ├── round_manager.qc   Wave state machine, spawn logic, per-round tables
    ├── zombie.qc          Zombie AI, AI tuning constants
    ├── client.qc          Perk effects, PlayerPreThink / PlayerPostThink
    └── csqc/hud.qc        Client-side HUD (CSQC)
specs/
├── CONTENT_PIPELINE.md   Step-by-step guide for adding weapons, enemies, perks, maps
└── weapon_balance.md     Weapon balance notes and tuning reference
BUILD.md                  Engine build instructions
HOSTING.md                Dedicated server and Docker hosting
RUNNING_THE_GAME.md       Setup and launch instructions
```

---

## Contributing / Modding

- **Adding weapons, enemies, perks, or maps** — see
  [specs/CONTENT_PIPELINE.md](specs/CONTENT_PIPELINE.md) for detailed
  step-by-step checklists.
- **Weapon balance tuning** — all fire parameters live in `W_Attack()`
  (`weapons.qc`) and `WeaponMagQuant()` (`inventory.qc`); economy constants
  live in `economy.qc`.  See [specs/weapon_balance.md](specs/weapon_balance.md)
  for reference.
- **Building the QuakeC** — run `./build_qc.sh` from the repo root to compile
  the game module.

---

## License

See [LICENSE](LICENSE) for details.
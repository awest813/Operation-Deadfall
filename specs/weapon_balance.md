# Operation Deadfall – Weapon Balance Notes
*Phase: Combat Feel Pass – COD Zombies-inspired arcade survival shooter*

---

## Goals
- Every weapon should feel **punchy and readable** – clear audio/visual feedback on every shot and kill.
- Each weapon class should have a **distinct identity** so players can feel the difference between them.
- Tuning should remain **modular**: all values live in the fire-function call sites in `W_Attack()` (weapons.qc) and `WeaponMagQuant()` (inventory.qc).

---

## Weapon Roles

| Class          | Weapons                      | Role                                              |
|----------------|------------------------------|---------------------------------------------------|
| Melee          | Fist, Knife, Axe, Vibroblade, Power Axe | Emergency close-quarter; escalating lethality |
| Pistol         | USP, Deagle, Needler         | Starter/sidearm; three distinct feels            |
| SMG            | MP9, MP7                     | Close-range spray; differ in pace vs power        |
| Shotgun        | Winchester, Mossberg, Jackhammer | Close-range burst; differ in pellet count/speed |
| Assault Rifle  | AK112, AK74, Moonlight (M4), SA80 | Mid-range backbone; each has unique cadence  |
| Battle Rifle   | FNFAL, Rangemaster, DKS-1   | Long-range semi-auto; high damage, slow fire      |
| Special        | Improvised Rifle, Vril Pistol, Rocket Launcher | Situational/power                |

---

## Tuning Table

### Melee
| Weapon      | Old Damage | New Damage | Notes                          |
|-------------|-----------|-----------|--------------------------------|
| Fist        | 3         | 8         | Bare fists should daze a zombie |
| Toolkit     | 5         | 8         | Improvised strike              |
| Knife       | 5         | 18        | Fast stab, reliable mid-round  |
| Axe         | 10        | 30        | Heavy swing, very satisfying   |
| Vibroblade  | 25        | 50        | Tech melee, solid upgrade      |
| Power Axe   | 50        | 100       | End-game one-shotter           |

### `rec` Parameter Note
`FirePistol`, `FireSMG`, and `FireAssaultRifle` each accept a `rec` parameter (2nd argument) that is currently **reserved** — it is not referenced in the function bodies (recoil increments are hardcoded per function). The values passed in `W_Attack()` serve as design-intent annotations (e.g. Deagle `rec=3`, Needler `rec=1`, Moonlight `rec=1`) to communicate the intended recoil weight for future implementation.

### Pistols
| Weapon  | Old Dam | New Dam | Old Rate | New Rate | rec param | Recoil Cap | Notes                                        |
|---------|---------|---------|----------|----------|-----------|------------|----------------------------------------------|
| USP     | 12      | 15      | 0.25 s   | 0.22 s   | 2 (unchanged) | 12 (was 15) | Slightly faster, punchier                |
| Deagle  | 15      | 28      | 0.25 s   | 0.40 s   | 2 → **3** | 12          | High damage, deliberate pace; adds SVC_BIGKICK |
| Needler | 10      | 12      | 0.25 s   | 0.12 s   | 2 → **1** | 12          | Fast-fire poison pistol, low recoil intent   |

**Spread fix (FirePistol):** Standing base spread 50 → 30 (tighter first shot).
Moving spread 400 → 350. Recoil multiplier 40 → 38 (max spread at cap: 30+38×12=486 vs old 50+40×15=650).
Recoil per shot 4 → 3. Recoil cap 15 → 12.

### SMGs
| Weapon | Old Dam | New Dam | Old Rate | New Rate | rec param | Mag | Notes                               |
|--------|---------|---------|----------|----------|-----------|-----|-------------------------------------|
| MP9    | 12      | 14      | 0.09 s   | 0.08 s   | 2 → **1** | 30  | Fast & light; low recoil intent     |
| MP7    | 12      | 20      | 0.09 s   | 0.13 s   | 2 (unchanged) | 25 | Heavier, hits harder           |

**Spread fix (FireSMG):** Standing base 200 → 80 (was unreasonably inaccurate at close range).
Moving base kept high (250) to punish spray-and-pray while moving. Recoil cap 15 → 12.

### Shotguns
| Weapon      | Old Pellets×Dam | New Pellets×Dam | Auto | Notes                     |
|-------------|-----------------|-----------------|------|---------------------------|
| Winchester  | 5 × 6 = 30      | 5 × 10 = 50     | No   | Double-barrel punch       |
| Mossberg    | 5 × 6 = 30      | 5 × 9 = 45      | No   | Pump action, reliable     |
| Jackhammer  | 5 × 6 = 30      | 5 × 7 = 35      | Yes  | Full-auto, more shots/sec |

Mag: Jackhammer 10 → 12 (auto-shotgun needs the extra rounds).

### Assault Rifles
| Weapon       | Old Dam | New Dam | Old Rate | New Rate | Recoil/shot | Notes                   |
|--------------|---------|---------|----------|----------|-------------|-------------------------|
| AK112        | 14      | 17      | 0.09 s   | 0.10 s   | 4 (was 5)   | Balanced workhorse      |
| AK74         | 18      | 22      | 0.10 s   | 0.11 s   | 4           | High-damage full-auto   |
| Moonlight M4 | 14      | 15      | 0.09 s   | 0.08 s   | 4, rec 2→**1** | Fastest, low recoil intent  |
| SA80         | 17      | 18      | 0.08 s   | 0.09 s   | 4           | Accurate, steady cadence|

**Visual feedback fix:** `FireAssaultRifle` was only spawning blood on headshots (`critical == 3`). Now spawns blood on **all** entity hits, matching pistol/SMG behaviour.

**Screenshake:** FNFAL and DKS-1 now emit `SVC_BIGKICK` for stronger tactile feedback.

### Battle Rifles / Snipers
| Weapon      | Old Dam | New Dam | Old Rate | New Rate | Recoil/shot | Notes                       |
|-------------|---------|---------|----------|----------|-------------|-----------------------------|
| Rangemaster | 14      | 22      | 0.50 s   | 0.50 s   | 4           | Semi-auto ranger, clean     |
| FNFAL       | 12      | 32      | 0.12 s   | 0.22 s   | 4           | Battle rifle, big kick      |
| DKS-1       | 24      | 50      | 0.50 s   | 0.70 s   | 4           | Near-sniper power, big kick |

### Special
| Weapon      | Old Dam | New Dam | Old Rate | New Rate | Notes                        |
|-------------|---------|---------|----------|----------|------------------------------|
| Improvised Rifle | 18      | 22      | 0.10 s   | 0.65 s   | Single-shot; was auto-rate, now properly slow |

### Magazine Capacity
| Weapon | Old | New | Rationale                                |
|--------|-----|-----|------------------------------------------|
| USP    | 12  | 15  | Standard 15-rd pistol magazine           |
| Jackhammer | 10 | 12 | Auto-shotgun needs extra shells          |
| MP7    | 30  | 25  | Differentiate from MP9's 30-rd mag       |

### Reload Timing
| Class         | Perk 3 | Standard | Notes                     |
|---------------|--------|----------|---------------------------|
| Pistols / SMGs | 0.8 s  | 1.5 s    | Magazine swap, fast       |
| Rifles         | 1.0 s  | 2.0 s    | Unchanged                 |
| Single-shot    | 1.0 s  | 1.0 s    | Shell/rocket insert (unchanged) |

---

## Files Changed
| File                              | What Changed                                               |
|-----------------------------------|------------------------------------------------------------|
| `quakec/deadfall/weapons.qc`      | Melee dmg, W_Attack fire calls, FirePistol spread/recoil, FireSMG spread, FireAssaultRifle blood+recoil+screenshake, ReloadWeapon fast-reload tier, Deagle screenshake; **milestone**: Vril Pistol damage+speed, Vibroblade/PowerAxe energy hit sound, per-shot hit-confirm ric cue |
| `quakec/deadfall/inventory.qc`    | WeaponMagQuant: USP 12→15, Jackhammer 10→12, MP7 30→25    |
| `quakec/deadfall/zombie.qc`       | **milestone**: tiered ammo drop on zombie death (10mm r1-7, 5.56mm r8-14, 7.62mm r15+) |

---

## Follow-up Recommendations

1. **Per-weapon reload animations** – The current system plays a single generic reload animation for all weapons. Adding weapon-specific reload sounds/animations would make each gun feel more distinct.
2. **Muzzle flash / tracer effects** – No visual muzzle flash is spawned for hitscan weapons. A simple temporary light entity at the muzzle on each shot would greatly improve readability.
3. ~~**Hit markers**~~ – **Implemented**: `weapons/ric1.wav` is played as a quiet per-shot sound cue to the shooter on confirmed entity hits in `FirePistol`, `FireSMG`, and `FireAssaultRifle`.
4. ~~**Ammo pick-up economy**~~ – **Implemented**: `zombie_die` drops tiered ammo (60 % chance) based on `current_round`: 18×10mm (rounds 1-7), 15×5.56mm (rounds 8-14), 12×7.62mm (rounds 15+).
5. ~~**Improvised Rifle single-shot reload**~~ – **Already done**: `IID_WP_PIPERIFLE` uses the shell-insert (`weapons/shell.wav`, 1 s lock) path in `ReloadWeapon` alongside Winchester/Mossberg.
6. ~~**Vril Pistol tuning**~~ – **Implemented**: `PlasmaBolt` base damage raised 30 → 50 (range 50–80); `FireAlienBlaster` projectile speed raised 1700 → 2200.
7. ~~**Power Axe / Vibroblade hit sound**~~ – **Implemented**: `FireMelee` accepts an optional `entsnd` string; `W_FireMelee` passes `"enforcer/enfstop.wav"` for both energy melee weapons.

# Operation Deadfall — Content Pipeline

This document describes how gameplay content flows through the codebase and
provides step-by-step checklists for safely adding new weapons, enemies,
perks, maps, and interactable entities.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Adding a Ranged Weapon](#adding-a-ranged-weapon)
3. [Adding a Melee Weapon](#adding-a-melee-weapon)
4. [Adding an Enemy Type](#adding-an-enemy-type)
5. [Adding a Perk](#adding-a-perk)
6. [Adding a Map Zone / Area](#adding-a-map-zone--area)
7. [Adding an Interactable Entity](#adding-an-interactable-entity)
8. [Economy and Balance Constants](#economy-and-balance-constants)
9. [Known Limitations](#known-limitations)

---

## Architecture Overview

```
defs.qc          — engine globals, entity fields, compile-time constants
economy.qc       — point costs, perk IDs (PERK_ID_*), kill reward helpers
inventory.qc     — IID_* constants, item name/model/weight lookup functions
weapons.qc       — W_Precache, W_Attack (fire dispatch), FirePistol/SMG/AR/…
mod_buy.qc       — world-interaction entities (wallbuy, mystery box, perk machine)
round_manager.qc — wave state machine, spawn logic, per-round tuning tables
zombie.qc        — zombie AI, AI tuning constants, spawn_zombie
client.qc        — perk effects, PlayerPreThink / PlayerPostThink
```

### Item Identity (IID)

Every item has a numeric **Item ID** (`IID_*`) declared in `inventory.qc`.
IIDs are packed with a status/ammo count in a slot value:

```
slot_value = IID * 512 | status_or_ammo_count
ToIID(sv)    = floor(sv / 512)
ToStatus(sv) = sv & 511
SlotVal(iid, st) = (iid * 512) | (st & 511)
```

**IID ranges** (must be respected for `IsRanged` / `IsMelee` macros):

| Range     | Category          |
|-----------|-------------------|
| 0         | IID_NONE (fists)  |
| 101–104   | Grenades          |
| 201–208   | Armor             |
| 301–306   | Chems / Stims     |
| 350–357   | Buildables        |
| 375–378   | Equipment         |
| 400–404   | Melee weapons     |
| 405–430   | Ranged weapons    |
| 507–517   | Ammo              |

---

## Adding a Ranged Weapon

A **ranged weapon** uses ammo (tracked in its slot status field) and needs a
view model, world model, ammo type, magazine size, and a fire function.

### Step 1 — `inventory.qc`

**a) Declare the IID constant** in the ranged weapon block (405–430):

```qc
float IID_WP_YOURGUN = 424;   // pick an unused number inside 405-430
```

> ⚠ If you exceed 430 you must also update the `IsRanged` macro upper bound.

**b) `GetItemName()`** — add a display name:

```qc
if (iid == IID_WP_YOURGUN)
    return "your gun name (ammo type)";
```

**c) `GetItemVModel()`** — view model (first-person):

```qc
if (iid == IID_WP_YOURGUN)
    return "progs/v_yourgun.mdl";
```

**d) `GetItemWModel()`** — world model (dropped / holstered):

```qc
if (iid == IID_WP_YOURGUN)
    return "progs/w_yourgun.mdl";
```

**e) `WeaponAmmoType()`** — which ammo IID this weapon consumes:

```qc
if (iid == IID_WP_YOURGUN)
    return IID_AM_556MM;   // or whatever ammo type applies
```

**f) `WeaponMagQuant()`** — magazine capacity (rounds per reload):

```qc
if (iid == IID_WP_YOURGUN)
    return 30;
```

**g) `GetItemWeight()`** — carry weight (affects encumbrance):

```qc
if (iid == IID_WP_YOURGUN)
    return 5;
```

**h) `GetItemDesc()`** *(optional)* — flavour-text for the character sheet.

---

### Step 2 — `weapons.qc`

**a) `W_Precache()`** — pre-load the fire sound:

```qc
precache_sound ("weapons/yourgun.wav");
```

**b) `W_Attack()`** — add a fire dispatch branch.
Choose the fire function that matches the weapon type:

| Function              | Suitable for                    |
|-----------------------|---------------------------------|
| `FirePistol`          | Semi-auto pistols / bolt-action |
| `FireSMG`             | Full-auto SMGs                  |
| `FireAssaultRifle`    | Full-auto rifles                |
| `W_FireShotgun`       | Pump / semi / auto shotguns     |
| `W_FireRocket`        | Rocket launcher                 |
| `FireAlienBlaster`    | Plasma bolt (energy)            |

Signature for `FirePistol` / `FireSMG` / `FireAssaultRifle`:

```
FireXxx(float dam, float rec, string snd, float rng, float rate)
  dam  — damage per hit
  rec  — recoil strength
  snd  — fire sound path
  rng  — effective range (units)
  rate — seconds between shots (sets attack_finished)
```

```qc
else if (weap == IID_WP_YOURGUN)
    FireAssaultRifle(22, 2, "weapons/yourgun.wav", 4000, 0.11);
```

---

### Step 3 — `mod_buy.qc` *(mystery box — optional)*

If the weapon should appear in the mystery box:

1. Add a branch in `DoMysteryBox`:

```qc
else if (r == 14) iid = IID_WP_YOURGUN;
```

2. Increment `BOX_POOL_SIZE` at the top of that block:

```qc
#define BOX_POOL_SIZE 15   // was 14
```

> `BOX_POOL_SIZE` is a `#define` — there is exactly one place to update.
> Forgetting to update it is the most common mystery-box bug.

---

### Step 4 — Map / Trenchbroom

Place an `info_wallbuy` brush entity:

```
"classname"  "info_wallbuy"
"buy_item"   "424"          ← IID number as a string
"buy_cost"   "1500"
```

---

## Adding a Melee Weapon

Melee weapons live in the 400–404 IID range.

| File           | What to add                                              |
|----------------|----------------------------------------------------------|
| `inventory.qc` | `IID_WP_YOURWEAPON = NNN` (must stay ≤ 404 or update `IsMelee` upper bound) |
| `inventory.qc` | `GetItemName`, `GetItemVModel`, `GetItemWModel`, `GetItemWeight` |
| `weapons.qc`   | `W_FireMelee` — add `else if (iid == IID_WP_YOURWEAPON) FireMelee(dam, dist, rate, snd);` |

`FireMelee` signature:

```
FireMelee(float damage, float dist, float rate, string entsnd)
  damage  — base damage (random bonus ×1 applied in code)
  dist    — reach in units (typical: 32–96)
  rate    — seconds between strikes
  entsnd  — hit sound override; "" uses target's armornoise
```

---

## Adding an Enemy Type

All round-managed enemies follow the **zombie** pattern:

### 1. Create `quakec/deadfall/your_enemy.qc`

Copy the structure from `zombie.qc` as a starting point:

```
$cd id1/models/your_enemy

// ── AI tuning constants ────────────────────────────────────────────────────
float YOUR_ENEMY_MELEE_RANGE   = 80;
float YOUR_ENEMY_MELEE_DAMAGE_MIN = 15;
float YOUR_ENEMY_MELEE_DAMAGE_MAX = 30;
float YOUR_ENEMY_MELEE_COOLDOWN   = 0.7;
float YOUR_ENEMY_PAIN_IGNORE      = 12;
float YOUR_ENEMY_PAIN_KNOCKDOWN   = 30;

// Walk / run / attack / pain / death animation chains …

void() your_enemy_die = { … };
void() your_enemy_pain = { … };
void() spawn_your_enemy = { … };   ← round manager calls this
```

### 2. Register in `progs.src`

Add the new file **after** `zombie.qc`:

```
zombie.qc
your_enemy.qc
```

### 3. Wire into `round_manager.qc`

Forward-declare the spawn function near the top of `round_manager.qc`:

```qc
void(entity stuff) spawn_your_enemy;   // defined in your_enemy.qc
```

Call it in `RM_TrySpawnOne()` alongside `spawn_zombie` if you want the new
enemy type to spawn during normal rounds.

### 4. Register attack routing in `ai.qc`

`CheckAnyAttack()` in `ai.qc` routes to the correct attack function by
classname.  Add a branch for your new monster:

```qc
if (self.classname == "monster_yourenemy")
    return YourEnemyCheckAttack();
```

### Key globals set by `round_manager.qc` for spawned enemies

| Global                | Set by RM?  | Meaning                    |
|-----------------------|-------------|----------------------------|
| `round_zombie_health` | Yes         | Kill threshold for the wave |
| `zombies_alive`       | Incremented by `spawn_zombie` | Count for victory check |

When your enemy dies it must call `zombies_alive = zombies_alive - 1;`
(see `zombie_die` in `zombie.qc` for the pattern).

---

## Adding a Perk

Perks are identified by a numeric ID.  Named constants live in `economy.qc`.

### 1. Add a PERK_ID constant — `economy.qc`

```qc
#define PERK_ID_YOURPERK  10   // next unused ID
```

### 2. Register name and cost — `economy.qc`

In `EC_PerkName()`:

```qc
if (id == PERK_ID_YOURPERK) return "your perk name";
```

In `EC_PerkCost()`, assign a tier or a custom cost:

```qc
if (id == PERK_ID_YOURPERK) return 1500;   // custom, or EC_PERK_T3
```

### 3. Implement the perk effect — `client.qc`

Perk checks live in `PlayerPreThink` and `PlayerPostThink`.  The player has
a `perks` bitfield; check and set the appropriate bit using your perk ID.

```qc
// Example: bonus movement speed
if (self.perks & (1 << PERK_ID_YOURPERK))
    self.maxspeed = self.maxspeed * 1.15;
```

### 4. Place a `func_perk_machine` entity in the map

```
"classname"  "func_perk_machine"
"buy_item"   "10"     ← PERK_ID_YOURPERK value
"buy_cost"   "1500"   ← optional override; defaults to EC_PerkCost()
```

---

## Adding a Map Zone / Area

Zones are unlocked by players spending points at a `func_door_zone`.

```
"classname"  "func_door_zone"
"buy_cost"   "750"       ← door unlock price (defaults to EC_DOOR_COST)
"targetname" "zone_b"    ← used to link trigger_once / info_zombie_spawn
```

Spawn point for zombies in that zone:

```
"classname"  "info_zombie_spawn"
"target"     "zone_b"    ← (optional) restricts spawns to this zone
```

If no `info_zombie_spawn` entities are present the round manager falls back
to `info_player_deathmatch`, then `info_player_start`.

---

## Adding an Interactable Entity

All COD-Zombies-style buy entities share two map keys:

| Key        | Type   | Meaning                              |
|------------|--------|--------------------------------------|
| `buy_item` | float  | IID (weapon) or perk ID              |
| `buy_cost` | float  | Point cost (overrides EC_* defaults) |

### `info_wallbuy` — wall-mounted weapon purchase

Defined in `mod_buy.qc` (`DoWallBuy`).
Requires both `buy_item` and `buy_cost`; warns at runtime if either is 0.

### `func_mystery_box` — random weapon spin

Defined in `mod_buy.qc` (`DoMysteryBox`).
Requires **power to be on**.  Optionally overrides spin cost with `buy_cost`.

### `func_perk_machine` — perk installation

Defined in `mod_buy.qc` (`DoInstallPerk`).
Requires power.  `buy_item` is a perk ID (`PERK_ID_*`).

### `func_power_switch` — enables box and perk machines

Defined in `mod_buy.qc` (`power_switch_activate`).
Toggle; sets global `power_on`.

### `func_door_zone` — point-cost passage

Defined in `doors.qc`.  Buy cost deducted from the activating player.

---

## Economy and Balance Constants

All constants are in `economy.qc` or at the top of `round_manager.qc`.
Edit **only those files** to rebalance without touching game logic.

### `economy.qc`

| Constant        | Default | Meaning                        |
|-----------------|---------|--------------------------------|
| `EC_KILL_BASE`  | 10      | Base kill reward (pts)         |
| `EC_KILL_PER_RND`| 2      | Bonus pts per round            |
| `EC_KILL_MAX`   | 60      | Kill reward cap                |
| `EC_DOOR_COST`  | 750     | Default zone door price        |
| `EC_BOX_COST`   | 950     | Mystery box spin price         |
| `EC_PERK_T1–T4` | 500–2000| Perk tier prices               |
| `EC_REPAIR_COST`| 25      | Barricade repair cost          |

### `round_manager.qc`

| Constant                      | Default | Meaning                      |
|-------------------------------|---------|------------------------------|
| `ROUND_INTRO_DURATION`        | 5 s     | Pre-wave countdown duration  |
| `ROUND_INTERMISSION`          | 10 s    | Rest between rounds          |
| `ROUND_MAX_CONCURRENT`        | 24      | Max zombies alive at once    |
| `ROUND_STUCK_TIMEOUT`         | 300 s   | Auto-end hung active phase   |
| `ROUND_TABLE_MAX`             | 25      | Explicit table size          |

Scaling formulas (`RT_ZombieCount`, `RT_ZombieHealth`, `RT_SpawnInterval`)
are plain QuakeC functions at the top of `round_manager.qc` — edit them to
change difficulty progression beyond round 25.

---

## Known Limitations

1. **`IsRanged` / `IsMelee` are range macros** (`inventory.qc`).  Adding a
   weapon IID outside the current numeric range (405–430 for ranged, 400–404
   for melee) will silently break inventory slot routing.  Update both bounds
   if you ever need to extend the ranges.

2. **Mystery box pool is an explicit if/else chain** (`mod_buy.qc`).  The
   pool size is now a `#define BOX_POOL_SIZE` constant but the entries are
   still manual.  Future work: replace with a compact array declaration if
   FTEQCC array support is added to the project.

3. **Only `monster_zombie` and `izombie` are round-managed** (`round_manager.qc`).
   A second enemy type requires explicit changes to `RM_TrySpawnOne` and
   careful coordination of the `zombies_alive` counter.

4. **Perk effects are scattered** inside `client.qc` `PlayerPreThink` /
   `PlayerPostThink`.  There is no single "perk dispatch table"; adding a
   perk that has a persistent per-frame effect means editing both check
   functions individually.

5. **`GetItemName`, `GetItemVModel`, `GetItemWModel`, `WeaponAmmoType`,
   `WeaponMagQuant`, and `GetItemWeight`** are separate if/else chains in
   `inventory.qc`.  Every new weapon must be registered in all six
   (plus `W_Attack` and `W_Precache`).  A future refactor could consolidate
   them into a single per-weapon descriptor block once FTEQCC struct support
   is stable.

6. **Ammo drop tiers in `zombie_die`** (`zombie.qc`) are hardcoded to
   `IID_AM_10MM`, `IID_AM_556MM`, and `IID_AM_762MM` at fixed round
   thresholds (r1–7, r8–14, r15+).  New ammo types require editing that
   function directly.

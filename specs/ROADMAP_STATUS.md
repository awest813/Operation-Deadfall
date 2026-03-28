# Operation Deadfall - Roadmap Status

Last updated: 2026-03-27

This file tracks roadmap-facing work as three states:

- `Surfaced`: visible to normal players in menus, UI, or standard gameplay flow.
- `Playable`: can be used end-to-end in gameplay right now.
- `Planned`: intentionally tracked but not fully implemented yet.

---

## Player-Facing Gameplay Items

### Buildables (IID 350-357)

| Item | Surfaced | Playable | Planned | Notes |
|---|---|---|---|---|
| Field Forge (`IID_BUILD_MRAMMO`) | Yes | Yes | No | In `shop_other` and deploys via `spawn_station`. |
| Shield Generator (`IID_BUILD_SHIELDGEN`) | Yes | Yes | No | In `shop_other` and deploys via `spawn_station`. |
| Auto-Doc (`IID_BUILD_AUTODOC`) | Yes | Yes | No | In `shop_other` and deploys via `spawn_station`. |
| Tesla Turret (`IID_BUILD_TTURRET`) | Yes | Yes | No | In `shop_other`; turret finish path active in `FinishTurret`. |
| Rocket Turret (`IID_BUILD_RTURRET`) | Yes | Yes | No | Surfaced in misc shop and deploys via `spawn_station`. |
| Machine-gun Turret (`IID_BUILD_GTURRET`) | Yes | Yes | No | Surfaced in misc shop and deploys via `spawn_station`. |
| Robo-Fang (`IID_BUILD_ROBOFANG`) | Yes | Yes | No | Now sold in `shop_other`; completed construction hands off to `spawn_dog` and activates the companion unit. |
| Telepad (`IID_BUILD_TELEPAD`) | Yes | No | Yes | Explicitly shown as planned in misc shop; selection/use prints a roadmap message instead of spawning gameplay logic. |

---

## Combat Feel Pass Follow-ups

Source of truth for this list: `specs/weapon_balance.md` ("Follow-up Recommendations").

| Item | Surfaced | Playable | Planned | Notes |
|---|---|---|---|---|
| Per-weapon reload animations | No | No | Yes | Still listed as future work. |
| Muzzle flash/tracer effects for hitscan weapons | Yes | Yes | No | Added lightweight in-air shot trails for pistol/SMG/assault rifle fire paths in `weapons.qc`. |
| Hit-confirm cue (`weapons/ric1.wav`) | Yes | Yes | No | Implemented in pistol/SMG/AR hit paths. |
| Tiered ammo drop economy | Yes | Yes | No | Implemented in `zombie_die` by round tier. |
| Improvised rifle single-shot pacing | Yes | Yes | No | Implemented via shell-insert reload path. |
| Vril pistol tuning | Yes | Yes | No | Implemented in plasma projectile stats. |
| Vibroblade/Power Axe hit sound | Yes | Yes | No | Implemented via energy melee hit sound path. |
| Runtime usage of `rec` weapon parameter | No | No | Yes | Parameter is still design intent metadata, not applied in recoil logic yet. |

---

## Engineering Backlog (Non Player-Facing)

Source of truth for these items: `specs/CONTENT_PIPELINE.md` ("Known Limitations").

| Item | Surfaced | Playable | Planned | Notes |
|---|---|---|---|---|
| Data-driven mystery box pool | No | No | Yes | Currently a manual if/else chain with `BOX_POOL_SIZE`. |
| Multi-enemy round manager support | No | No | Yes | Round manager still assumes zombie-centric spawn/accounting flow. |
| Central perk effect dispatch | No | No | Yes | Perk logic remains distributed in `PlayerPreThink`/`PlayerPostThink`. |
| Unified weapon descriptor registry | No | No | Yes | Weapon metadata still split across multiple `inventory.qc` chains. |

---

## Update Rule

When an item changes status:

1. Update this file first.
2. Update the implementation note in the relevant spec (`weapon_balance.md` or `CONTENT_PIPELINE.md`) if needed.
3. Keep status labels literal (`Yes`/`No`) so diffs stay clean.

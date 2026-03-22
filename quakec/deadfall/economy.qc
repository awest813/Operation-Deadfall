/*
==============================================================================

ECONOMY — Operation Deadfall                    quakec/deadfall/economy.qc

Centralized kill-reward and purchase-cost constants for the COD Zombies-style
progression loop.  Edit this file to rebalance the game without touching any
game-logic code.

PERK IDs (used as buy_item on func_perk_machine entities and in EC_PerkCost /
EC_PerkName).  Use these named constants everywhere instead of raw numbers.
───────────────────────────────────────────────────
  PERK_ID_MOVE    1  bonus movement (Tier 1 — 500 pts)
  PERK_ID_BACK    2  strong back     (Tier 1 — 500 pts)
  PERK_ID_POCKET  3  quick pockets   (Tier 1 — 500 pts)
  PERK_ID_AWARE   4  awareness       (Tier 2 — 1000 pts)
  PERK_ID_SILENT  5  silent running  (Tier 2 — 1000 pts)
  PERK_ID_CRITS   6  better criticals (Tier 2 — 1000 pts)
  PERK_ID_RANGED  7  bonus ranged damage (Tier 2 — 1000 pts)
  PERK_ID_DIVINE  8  divine favor    (Tier 3 — 1500 pts)
  PERK_ID_SLAYER  9  slayer          (Tier 4 — 2000 pts)

KILL REWARDS  (ammo_shells awarded per zombie kill)
───────────────────────────────────────────────────
  Base reward : EC_KILL_BASE (10 pts)
  Per-round   : +EC_KILL_PER_RND (2 pts/round) up to EC_KILL_MAX (60 pts)
  Examples    :  Round 1 → 12,  Round 5 → 20,  Round 10 → 30, Round 25 → 60

ZONE DOOR UNLOCK COST (EC_DOOR_COST)
───────────────────────────────────────────────────
  Default 750 pts, overrideable per door via the 'buy_cost' map key.

WALL-BUY WEAPON COSTS
───────────────────────────────────────────────────
  Set via 'buy_cost' key on info_wallbuy.  No global default because each
  wall buy should be explicitly priced by the map author.

MYSTERY BOX  (EC_BOX_COST)
───────────────────────────────────────────────────
  950 pts per spin.  Requires power to be on.

PERK MACHINE TIER COSTS
───────────────────────────────────────────────────
  EC_PERK_T1   500   perks 1–3  (minor utility)
  EC_PERK_T2  1000   perks 4–7  (moderate)
  EC_PERK_T3  1500   perk 8     (major)
  EC_PERK_T4  2000   perk 9     (ultimate)

REPAIR COST  (EC_REPAIR_COST)
───────────────────────────────────────────────────
  Flat cost to repair a barricade: 25 pts.

==============================================================================
*/

// ---------------------------------------------------------------------------
// Perk ID constants — use these everywhere instead of raw integers 1-9.
// Set buy_item to one of these on each func_perk_machine entity in the map.
// To add a new perk: add a PERK_ID_* constant here, add a case to
// EC_PerkName and EC_PerkCost below, and implement the perk effect in
// client.qc (PlayerPreThink / PlayerPostThink).
// ---------------------------------------------------------------------------
#define PERK_ID_MOVE    1   // bonus movement speed
#define PERK_ID_BACK    2   // strong back (carry weight)
#define PERK_ID_POCKET  3   // quick pockets (item switch speed)
#define PERK_ID_AWARE   4   // awareness (enemy outlines)
#define PERK_ID_SILENT  5   // silent running (reduced footstep noise)
#define PERK_ID_CRITS   6   // better criticals (critical hit chance)
#define PERK_ID_RANGED  7   // bonus ranged damage
#define PERK_ID_DIVINE  8   // divine favor (self-revive chance)
#define PERK_ID_SLAYER  9   // slayer (execute threshold)

// ---------------------------------------------------------------------------
// Kill reward tuning
// ---------------------------------------------------------------------------
float EC_KILL_BASE    =  10;   // base points for any zombie kill
float EC_KILL_PER_RND =   2;   // bonus points per round number
float EC_KILL_MAX     =  60;   // upper cap on per-kill reward

// ---------------------------------------------------------------------------
// Zone-door unlock (default; overrideable per entity via map key 'buy_cost')
// ---------------------------------------------------------------------------
float EC_DOOR_COST    = 750;

// ---------------------------------------------------------------------------
// Mystery box spin cost
// ---------------------------------------------------------------------------
float EC_BOX_COST     = 950;

// ---------------------------------------------------------------------------
// Perk machine tier costs
// ---------------------------------------------------------------------------
float EC_PERK_T1      =  500;   // perks 1-3
float EC_PERK_T2      = 1000;   // perks 4-7
float EC_PERK_T3      = 1500;   // perk 8
float EC_PERK_T4      = 2000;   // perk 9

// ---------------------------------------------------------------------------
// Repair cost (barricades / boards)
// ---------------------------------------------------------------------------
float EC_REPAIR_COST  =  25;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Compute the kill reward for the current round, capped at EC_KILL_MAX.
float() EC_KillReward =
{
    local float pts;
    pts = EC_KILL_BASE + current_round * EC_KILL_PER_RND;
    if (pts > EC_KILL_MAX)
        pts = EC_KILL_MAX;
    return pts;
};

// Return the point cost for a perk by its ID (use PERK_ID_* constants).
float(float id) EC_PerkCost =
{
    if (id <= PERK_ID_POCKET) return EC_PERK_T1;   // IDs 1-3
    if (id <= PERK_ID_RANGED) return EC_PERK_T2;   // IDs 4-7
    if (id == PERK_ID_DIVINE) return EC_PERK_T3;   // ID  8
    return EC_PERK_T4;                              // ID  9 (PERK_ID_SLAYER)
};

// Return a human-readable name for a perk ID (use PERK_ID_* constants).
string(float id) EC_PerkName =
{
    if (id == PERK_ID_MOVE)   return "bonus movement";
    if (id == PERK_ID_BACK)   return "strong back";
    if (id == PERK_ID_POCKET) return "quick pockets";
    if (id == PERK_ID_AWARE)  return "awareness";
    if (id == PERK_ID_SILENT) return "silent running";
    if (id == PERK_ID_CRITS)  return "better criticals";
    if (id == PERK_ID_RANGED) return "bonus ranged damage";
    if (id == PERK_ID_DIVINE) return "divine favor";
    if (id == PERK_ID_SLAYER) return "slayer";
    return "unknown perk";
};

// Award points to a player.
void(entity player, float pts) EC_GivePoints =
{
    if (player.classname != "player")
        return;
    player.ammo_shells = player.ammo_shells + pts;
};

// Attempt to spend points.  Returns TRUE on success, FALSE if too poor.
float(entity player, float cost) EC_SpendPoints =
{
    if (player.ammo_shells < cost)
        return FALSE;
    player.ammo_shells = player.ammo_shells - cost;
    return TRUE;
};

// Check affordability without spending.
float(entity player, float cost) EC_CanAfford =
{
    return (player.ammo_shells >= cost);
};

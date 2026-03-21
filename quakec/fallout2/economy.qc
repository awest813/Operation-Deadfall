/*
==============================================================================

ECONOMY — Operation Deadfall                    quakec/fallout2/economy.qc

Centralized kill-reward and purchase-cost constants for the COD Zombies-style
progression loop.  Edit this file to rebalance the game without touching any
game-logic code.

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

// Return the point cost for a perk by its ID (1-9).
float(float id) EC_PerkCost =
{
    if (id <= 3) return EC_PERK_T1;
    if (id <= 7) return EC_PERK_T2;
    if (id == 8) return EC_PERK_T3;
    return EC_PERK_T4;
};

// Return a human-readable name for a perk ID without touching entity state.
string(float id) EC_PerkName =
{
    if (id == 1) return "bonus movement";
    if (id == 2) return "strong back";
    if (id == 3) return "quick pockets";
    if (id == 4) return "awareness";
    if (id == 5) return "silent running";
    if (id == 6) return "better criticals";
    if (id == 7) return "bonus ranged damage";
    if (id == 8) return "divine favor";
    if (id == 9) return "slayer";
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

/*
==============================================================================

ROUND MANAGER  —  quakec/fallout2/round_manager.qc

COD Nazi Zombies-inspired wave-survival round loop.

STATE MACHINE OVERVIEW
───────────────────────────────────────────────────────────────────────────
  RSTATE_WAITING      (0)  No active round; idle until ≥1 live player.
  RSTATE_INTRO        (1)  Pre-round countdown fanfare.
  RSTATE_SPAWNING     (2)  Zombies trickle into play at per-round pace.
  RSTATE_ACTIVE       (3)  All queued zombies are out; waiting for kills.
  RSTATE_INTERMISSION (4)  Rest period; countdown to next round.
  RSTATE_GAMEOVER     (5)  All players dead — GameControl handles restart.

Transitions:
  WAITING      → INTRO        first live player detected
  INTRO        → SPAWNING     ROUND_INTRO_DURATION seconds elapsed
  SPAWNING     → ACTIVE       zombies_queued drains to 0
  ACTIVE       → INTERMISSION zombies_alive + zombies_queued == 0
  ACTIVE       → GAMEOVER     all players die mid-wave
  INTERMISSION → INTRO        ROUND_INTERMISSION seconds elapsed
  any state    → GAMEOVER     all players die

BALANCE TABLE (rounds 1-25)
───────────────────────────────────────────────────────────────────────────
 Round  Zombies   HP    Spawn interval   Max alive
   1       6      60        3.0 s           24
   2       8      80        2.8 s           24
   3      10     100        2.6 s           24
   4      12     120        2.4 s           24
   5      14     140        2.2 s           24
   6      16     162        2.0 s           24
   7      18     184        1.9 s           24
   8      20     206        1.7 s           24
   9      22     228        1.6 s           24
  10      24     250        1.4 s           24
  11      26     300        1.3 s           24
  12      28     350        1.2 s           24
  13      30     400        1.1 s           24
  14      32     450        1.0 s           24
  15      34     500        0.9 s           24
  16      36     600        0.85 s          24
  17      38     700        0.8 s           24
  18      40     800        0.75 s          24
  19      42     900        0.7 s           24
  20      44    1000        0.65 s          24
  21      46    1200        0.6 s           24
  22      48    1400        0.6 s           24
  23      50    1600        0.6 s           24
  24      52    1800        0.6 s           24
  25      54    2000        0.6 s           24
  26+  54+2*(r-25)  2000+200*(r-25)  0.6 s  24

KNOWN ISSUES
───────────────────────────────────────────────────────────────────────────
• If ALL map info_zombie_spawn / info_player_deathmatch spawn points are
  permanently blocked (solid geometry overlap), the spawn attempt silently
  skips that slot; fewer-than-expected zombies will appear that round.
• Mid-round player-disconnects are not tracked; if the last player drops
  and reconnects before GameControl restarts, round_state stays GAMEOVER
  until a map restart clears it.

PERFORMANCE PRESETS  (od_perf_preset cvar — see defs.qc)
───────────────────────────────────────────────────────────────────────────
The server cvar od_perf_preset (0/1/2) is read in worldspawn and stored in
the global perf_preset (PERF_LOW=0 / PERF_MEDIUM=1 / PERF_HIGH=2).

  Low  (0) — ROUND_MAX_CONCURRENT = 12  (halved zombie AI budget),
              no per-ghoul dynamic lights, reduced blood particles.
             Best for older hardware or high player-count servers.
  Med  (1) — ROUND_MAX_CONCURRENT = 24  (default, unchanged behaviour).
  High (2) — ROUND_MAX_CONCURRENT = 24  with full glow effects and
             maximum particle density.  Use on high-end machines.

==============================================================================
*/

// ---------------------------------------------------------------------------
// Forward declarations (definitions appear later in progs.src)
// ---------------------------------------------------------------------------
void(entity stuff) spawn_zombie;   // defined in zombie.qc

// ---------------------------------------------------------------------------
// Helper — broadcast a centerprint to every live player.
// ---------------------------------------------------------------------------
void(string msg) RM_CenterprintAll =
{
    local entity p;
    p = find(world, classname, "player");
    while (p)
    {
        centerprint(p, msg);
        p = find(p, classname, "player");
    }
};

// ---------------------------------------------------------------------------
// Helper — play a sound to every live player (ATTN_NONE = heard everywhere).
// ---------------------------------------------------------------------------
void(string snd, float vol) RM_SoundAll =
{
    local entity p;
    p = find(world, classname, "player");
    while (p)
    {
        if (p.health > 0)
            sound(p, CHAN_AUTO, snd, vol, ATTN_NONE);
        p = find(p, classname, "player");
    }
};

// ---------------------------------------------------------------------------
// Tuning constants — edit here to rebalance without touching game logic.
// ---------------------------------------------------------------------------
float ROUND_INTRO_DURATION  =  5;   // seconds of fanfare before first spawn
float ROUND_INTERMISSION    = 10;   // seconds of rest between rounds
float ROUND_MAX_CONCURRENT  = 24;   // hard cap on zombies alive at once (set by preset)
float ROUND_STUCK_TIMEOUT   = 300;  // auto-end a hung active phase (seconds)
float ROUND_TABLE_MAX       = 25;   // highest round in explicit tuning table

// Per-preset concurrent-zombie caps (used in RM_Init to configure ROUND_MAX_CONCURRENT).
float ROUND_MAX_CONCURRENT_LOW     = 12;  // Low preset: halved AI budget
float ROUND_MAX_CONCURRENT_DEFAULT = 24;  // Medium / High preset: full quota

// ---------------------------------------------------------------------------
// State identifiers  (also stored in the global  round_state)
// ---------------------------------------------------------------------------
float RSTATE_WAITING        = 0;
float RSTATE_INTRO          = 1;
float RSTATE_SPAWNING       = 2;
float RSTATE_ACTIVE         = 3;
float RSTATE_INTERMISSION   = 4;
float RSTATE_GAMEOVER       = 5;

// ---------------------------------------------------------------------------
// Tuning table — zombie count for round r
//   Grows by +2 every round from a base of 6.
// ---------------------------------------------------------------------------
float(float r) RT_ZombieCount =
{
    if (r <=  5) return  6 + (r - 1) * 2;   //  6,  8, 10, 12, 14
    if (r <= 10) return 14 + (r - 5) * 2;   // 16, 18, 20, 22, 24
    if (r <= 15) return 24 + (r - 10) * 2;  // 26, 28, 30, 32, 34
    if (r <= 20) return 34 + (r - 15) * 2;  // 36, 38, 40, 42, 44
    if (r <= 25) return 44 + (r - 20) * 2;  // 46, 48, 50, 52, 54
    return 54 + (r - 25) * 2;               // continues beyond 25
};

// ---------------------------------------------------------------------------
// Tuning table — zombie kill-threshold (HP) for round r
//   Single T_Damage hit must exceed this value to kill the zombie.
// ---------------------------------------------------------------------------
float(float r) RT_ZombieHealth =
{
    if (r <=  1) return 60;
    if (r <=  5) return  60 + (r -  1) *  20;  //  60 →  140
    if (r <= 10) return 140 + (r -  5) *  22;  // 140 →  250 (≈ +22/round)
    if (r <= 15) return 250 + (r - 10) *  50;  // 250 →  500
    if (r <= 20) return 500 + (r - 15) * 100;  // 500 → 1000
    if (r <= 25) return 1000 + (r - 20) * 200; // 1000 → 2000
    return 2000 + (r - 25) * 200;              // continues beyond 25
};

// ---------------------------------------------------------------------------
// Tuning table — seconds between individual zombie spawns for round r
//   Decreases toward a 0.6 s performance-safe floor.
// ---------------------------------------------------------------------------
float(float r) RT_SpawnInterval =
{
    if (r <=  1) return 3.0;
    if (r <=  5) return 3.0  - (r -  1) * 0.20;  // 3.0 → 2.2
    if (r <= 10) return 2.2  - (r -  5) * 0.16;  // 2.2 → 1.4
    if (r <= 15) return 1.4  - (r - 10) * 0.10;  // 1.4 → 0.9
    if (r <= 20) return 0.9  - (r - 15) * 0.05;  // 0.9 → 0.65
    return 0.6;                                    // performance floor
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Return the number of currently alive players.
float() RM_LivePlayerCount =
{
    local entity te;
    local float  count;

    count = 0;
    te = find(world, classname, "player");
    while (te)
    {
        if (te.health > 0)
            count = count + 1;
        te = find(te, classname, "player");
    }
    return count;
};

// Pick a random zombie spawn point using reservoir sampling.
// Priority: info_zombie_spawn > info_player_deathmatch > info_player_start.
// count is deliberately not reset between fallback tiers: the early-return
// after each tier means the fallback is only reached when count == 0,
// so the sampling is always correct.
entity() RM_PickSpawnPoint =
{
    local entity spot, chosen;
    local float  count;

    count  = 0;
    chosen = world;

    spot = find(world, classname, "info_zombie_spawn");
    while (spot)
    {
        count = count + 1;
        if (random() < (1.0 / count))
            chosen = spot;
        spot = find(spot, classname, "info_zombie_spawn");
    }
    if (chosen != world)
        return chosen;  // found ≥1 info_zombie_spawn; count == 0 never reached below

    // Fallback: deathmatch spawn points.
    // count is still 0 here (the tier above returned early if any found).
    spot = find(world, classname, "info_player_deathmatch");
    while (spot)
    {
        count = count + 1;
        if (random() < (1.0 / count))
            chosen = spot;
        spot = find(spot, classname, "info_player_deathmatch");
    }
    if (chosen != world)
        return chosen;

    // Last resort: any player start.
    return find(world, classname, "info_player_start");
};

// Attempt to spawn one zombie.
// Returns TRUE if the spawn was attempted (queued slot consumed).
// Increments zombies_alive only if spawn_zombie actually placed a ghoul.
float() RM_TrySpawnOne =
{
    local entity spot, saved_self;

    if (zombies_queued <= 0)
        return FALSE;

    // Hard cap: wait until an existing zombie dies before spawning more.
    if (zombies_alive >= ROUND_MAX_CONCURRENT)
    {
        dprint("RM: concurrent cap hit, deferring\n");
        return FALSE;
    }

    spot = RM_PickSpawnPoint();
    if (spot == world)
    {
        dprint("RM: no spawn point available\n");
        zombies_queued = zombies_queued - 1; // consume slot, try elsewhere next tick
        return TRUE;
    }

    // spawn_zombie reassigns the global `self` — save and restore it.
    // On success spawn_zombie increments zombies_alive (see zombie.qc).
    // If the spawn point is blocked it returns early and the count is
    // silently forfeit to avoid stalling the queue indefinitely.
    saved_self = self;
    spawn_zombie(spot);
    self = saved_self;

    zombies_queued = zombies_queued - 1;
    return TRUE;
};

// ---------------------------------------------------------------------------
// State-machine think — runs on the round_manager entity every frame.
// ---------------------------------------------------------------------------
void() RoundManager_Think =
{
    local float interval;

    // ---- GAMEOVER: idle until GameControl issues a map restart ----
    if (round_state == RSTATE_GAMEOVER)
    {
        self.nextthink = time + 1;
        return;
    }

    // ---- WAITING: hold until at least one player is alive ----
    if (round_state == RSTATE_WAITING)
    {
        if (RM_LivePlayerCount() > 0)
        {
            current_round = 1;
            round_state   = RSTATE_INTRO;
            round_timer   = time + ROUND_INTRO_DURATION;
            dprint("RM: player detected — starting Round 1 in 5 s\n");
            bprint(2, "^4** ^bROUND 1 BEGINS IN 5 SECONDS^b **\n");
            RM_CenterprintAll("ROUND 1\nBegins in 5 seconds...");
            RM_SoundAll("misc/power.wav", 0.5);
        }
        self.nextthink = time + 1;
        return;
    }

    // ---- INTRO: fanfare countdown before first spawn ----
    if (round_state == RSTATE_INTRO)
    {
        if (RM_LivePlayerCount() == 0)
        {
            round_state = RSTATE_GAMEOVER;
            self.nextthink = time + 1;
            return;
        }

        if (time >= round_timer)
        {
            // Transition → SPAWNING: prime the queue from the tuning table.
            zombies_queued      = RT_ZombieCount(current_round);
            zombies_alive       = 0;
            round_zombie_health = RT_ZombieHealth(current_round);
            round_state         = RSTATE_SPAWNING;
            round_timer         = time; // spawn on very next tick

            dprint("RM: INTRO→SPAWNING  round=");
            dprint(ftos(current_round));
            dprint("  count=");
            dprint(ftos(zombies_queued));
            dprint("  hp=");
            dprint(ftos(round_zombie_health));
            dprint("\n");
        }
        self.nextthink = time + 1;
        return;
    }

    // ---- SPAWNING: trickle zombies in at the configured rate ----
    if (round_state == RSTATE_SPAWNING)
    {
        if (RM_LivePlayerCount() == 0)
        {
            round_state = RSTATE_GAMEOVER;
            self.nextthink = time + 1;
            return;
        }

        if (time >= round_timer)
        {
            if (zombies_queued > 0)
            {
                if (RM_TrySpawnOne())
                {
                    interval    = RT_SpawnInterval(current_round);
                    round_timer = time + interval;
                }
                else
                {
                    // Concurrent cap hit — retry in 1 s.
                    round_timer = time + 1;
                }
            }

            if (zombies_queued <= 0)
            {
                round_state = RSTATE_ACTIVE;
                round_timer = time + ROUND_STUCK_TIMEOUT;
                dprint("RM: SPAWNING→ACTIVE\n");
            }
        }

        // Wake up at half the spawn interval for timing accuracy.
        interval = RT_SpawnInterval(current_round) * 0.5;
        if (interval < 0.1)
            interval = 0.1;
        self.nextthink = time + interval;
        return;
    }

    // ---- ACTIVE: wait for all zombies to die ----
    if (round_state == RSTATE_ACTIVE)
    {
        if (RM_LivePlayerCount() == 0)
        {
            round_state = RSTATE_GAMEOVER;
            self.nextthink = time + 1;
            return;
        }

        // Stuck-round safeguard: force round end after timeout.
        if (time >= round_timer)
        {
            dprint("RM: ACTIVE timeout — forcing round clear\n");
            bprint(2, "^4** ^bROUND CLEAR (TIMEOUT)^b **\n");
            zombies_alive  = 0;
            zombies_queued = 0;
        }

        if (zombies_alive <= 0 && zombies_queued <= 0)
        {
            round_state = RSTATE_INTERMISSION;
            round_timer = time + ROUND_INTERMISSION;
            self.cnt    = 0;    // intermission tick counter (used for countdown)
            bprint(2, "^4** ^bROUND ");
            bprint(2, ftos(current_round));
            bprint(2, " COMPLETE!^b **\n");
            RM_CenterprintAll(strcat("ROUND ", ftos(current_round), " COMPLETE!\nNext round in 10 seconds..."));
            RM_SoundAll("items/protect2.wav", 0.8);
            dprint("RM: ACTIVE→INTERMISSION\n");
        }
        self.nextthink = time + 1;
        return;
    }

    // ---- INTERMISSION: count down before next round ----
    if (round_state == RSTATE_INTERMISSION)
    {
        if (RM_LivePlayerCount() == 0)
        {
            round_state = RSTATE_GAMEOVER;
            self.nextthink = time + 1;
            return;
        }

        // Integer tick counter (incremented once per second) drives the
        // 3-2-1 countdown.  This mirrors the endgame_timer pattern in
        // GameControl and guarantees each message prints exactly once
        // regardless of slight timing variations.
        self.cnt = self.cnt + 1;
        if (self.cnt == ROUND_INTERMISSION - 3)
            bprint(2, "^4** 3 **\n");
        if (self.cnt == ROUND_INTERMISSION - 2)
            bprint(2, "^4** 2 **\n");
        if (self.cnt == ROUND_INTERMISSION - 1)
            bprint(2, "^4** 1 **\n");

        if (time >= round_timer)
        {
            current_round = current_round + 1;
            round_state   = RSTATE_INTRO;
            round_timer   = time + ROUND_INTRO_DURATION;
            bprint(2, "^4** ^bROUND ");
            bprint(2, ftos(current_round));
            bprint(2, " BEGINS!^b **\n");
            RM_CenterprintAll(strcat("ROUND ", ftos(current_round), "\nBegins now!"));
            RM_SoundAll("misc/power.wav", 0.5);
            dprint("RM: INTERMISSION→INTRO  round=");
            dprint(ftos(current_round));
            dprint("\n");
        }
        self.nextthink = time + 1;
        return;
    }

    // Fallback — should not reach here.
    self.nextthink = time + 1;
};

// ---------------------------------------------------------------------------
// Called by zombie_die (zombie.qc) when a round-manager ghoul is killed.
// ---------------------------------------------------------------------------
void() RM_ZombieDied =
{
    if (zombies_alive > 0)
        zombies_alive = zombies_alive - 1;

    dprint("RM: ghoul killed  alive=");
    dprint(ftos(zombies_alive));
    dprint("  queued=");
    dprint(ftos(zombies_queued));
    dprint("\n");
};

// ---------------------------------------------------------------------------
// Initialise the round manager — call once from create_referees().
// ---------------------------------------------------------------------------
void() RM_Init =
{
    local entity rm;

    // Initialise all round globals to safe defaults.
    current_round       = 0;
    zombies_queued      = 0;
    zombies_alive       = 0;
    round_zombie_health = 60;  // classic kill-threshold; overwritten each round
    round_state         = RSTATE_WAITING;
    round_timer         = 0;
    power_on            = 0;   // power starts off; activate func_power_switch to enable perks/box

    // Apply the performance preset to the concurrent-zombie hard cap.
    // Low preset halves the AI budget to keep frame times stable at high rounds.
    if (perf_preset == PERF_LOW)
        ROUND_MAX_CONCURRENT = ROUND_MAX_CONCURRENT_LOW;
    else
        ROUND_MAX_CONCURRENT = ROUND_MAX_CONCURRENT_DEFAULT;  // Medium and High both use the full cap

    rm             = spawn();
    rm.classname   = "round_manager";
    rm.movetype    = MOVETYPE_NONE;
    rm.solid       = SOLID_NOT;
    setorigin(rm, '0 0 -300');
    rm.think       = RoundManager_Think;
    rm.nextthink   = time + 2;  // short startup delay

    dprint("RM: Round Manager initialized  max_concurrent=");
    dprint(ftos(ROUND_MAX_CONCURRENT));
    dprint("\n");
};

// ---------------------------------------------------------------------------
// info_zombie_spawn — map entity.
//   Place instances in the map to define where ghouls can enter the level.
//   Optionally set 'target' to a path_corner for patrol-path following.
//   If no instances are placed the manager falls back to
//   info_player_deathmatch and then info_player_start entities.
// ---------------------------------------------------------------------------
/*QUAKED info_zombie_spawn (1 0.5 0) (-16 -16 -24) (16 16 24)
Zombie wave spawn point.  The round manager selects among all placed
instances (uniform random) when deciding where to enter each ghoul.
Set 'target' to a path_corner to give spawned ghouls a patrol route.
*/
void() info_zombie_spawn =
{
    // No run-time behaviour — this entity is a location marker only.
};

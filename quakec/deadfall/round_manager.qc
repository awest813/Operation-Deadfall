/*
==============================================================================

ROUND MANAGER  —  quakec/deadfall/round_manager.qc

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
  permanently blocked (solid geometry overlap), the manager now retries a
  blocked slot several times before forfeiting it. This avoids transient
  blockage causing accidental zombie loss, but a truly broken map can still
  lose a slot after the retry limit rather than stalling forever.

PERFORMANCE PRESETS  (od_perf_preset cvar — see defs.qc)
───────────────────────────────────────────────────────────────────────────
The server cvar od_perf_preset (0/1/2) is read in worldspawn and stored in
the global perf_preset (PERF_LOW=0 / PERF_MEDIUM=1 / PERF_HIGH=2).

  Low  (0) — ROUND_MAX_CONCURRENT = 12  (halved zombie AI budget),
              no per-zombie dynamic lights,
              1 gib per kill (instead of 3), gib/head lifetime 5 s.
             Best for older hardware or high player-count servers.
  Med  (1) — ROUND_MAX_CONCURRENT = 24  (default, unchanged behaviour),
              no per-zombie dynamic lights,
              3 gibs per kill, head lifetime 10 s, gib lifetime 8 s.
  High (2) — ROUND_MAX_CONCURRENT = 24  with full glow effects:
             EF_DIMLIGHT active when enemy is within attack range (RANGE_NEAR/MID);
             automatically suppressed at RANGE_FAR to cap GPU cost.
             3 gibs per kill, head lifetime 15 s, gib lifetime 10-20 s.
             Use on high-end machines.

TOP PERFORMANCE BOTTLENECKS & FIXES
───────────────────────────────────────────────────────────────────────────
1. [FIXED] ThrowHead entity leak — zombie head entities had nextthink=-1
   (never expired), permanently consuming entity slots every round.
   Fix: schedule SUB_Remove after 5/10/15 s based on preset (zombie.qc).

2. [FIXED] Gib entity accumulation — 3 bounce-physics entities × 24 kills
   per round × 10-20 s lifetime = hundreds of live gib entities at high rounds.
   Fix: Low preset spawns 1 gib per kill instead of 3 (zombie.qc);
        all presets use shorter lifetimes: Low=5s, Med=8s, High=10-20s
        (ThrowGib/ThrowGib2 in player.qc; head entity in zombie.qc).

3. [FIXED] ai_run() traceline waste — visible() fires a full traceline every
   monster think frame regardless of distance.  At RANGE_FAR (>1000 units)
   the result is never used for attack decisions.
   Fix: range() checked first; visible() skipped for RANGE_FAR enemies (ai.qc).

4. [FIXED] Attack-sound pile-up — ZombieFireGrenade fired z_shot1.wav with no
   throttle; 24 simultaneous grenade throws = 24 sounds in one frame.
   Fix: zombie_attack_sound_time global caps at ~10 attack sounds/sec
   (zombie.qc; mirrors zombie_idle_sound_time / zombie_pain_sound_time).

5. [FIXED] Redundant cvar() reads — CSQC_UpdateView read vid_conwidth/height
   then HUD_Draw re-read the same cvars every single frame.
   Fix: dimensions passed as HUD_Draw(sw, sh) parameters (main.qc / hud.qc).

6. [FIXED] High-preset dynamic-light waste — EF_DIMLIGHT was set once at spawn
   and never revisited; all 24 zombies emitted lights even when far away.
   Fix: zombie_run1 checks enemy_range each run cycle and clears EF_DIMLIGHT
   when the enemy is at RANGE_FAR on PERF_HIGH preset (zombie.qc).

7. [EXISTING] Concurrent cap — ROUND_MAX_CONCURRENT limits active AI count
   (12 on Low, 24 on Med/High).

8. [EXISTING] Dynamic lights — EF_DIMLIGHT suppressed on Low/Medium presets;
   distance-culled on High preset (see item 6 above).

9. [EXISTING] Audio throttle — zombie idle/pain sounds server-rate-limited
   (zombie_idle_sound_time / zombie_pain_sound_time / zombie_attack_sound_time
   globals, zombie.qc).

POLISH IMPROVEMENTS  (see also hud.qc, player.qc, zombie.qc, client.qc)
───────────────────────────────────────────────────────────────────────────
1. [NEW] 3-2-1 countdown during INTRO phase — fires misc/menu1.wav ticks and
   bprint messages at 3/2/1 s before the first zombie spawn.  Builds tension
   and mirrors the intermission countdown already present before this change.
   The INTRO state now tracks self.cnt (same pattern as intermission).

2. [NEW] Intro countdown in HUD — STAT_INTRO_SECS (stat 72) is synced by
   client.qc during RSTATE_INTRO, allowing the CSQC HUD to show
   "INCOMING!  3s" rather than a static label.

3. [NEW] Best-streak tracking — player.best_streak updated live in zombie_die
   and on death in player.qc.  Shown on the game-over screen (hud.qc) and
   synced via STAT_BEST_STREAK (stat 71).

4. [NEW] Power-on indicator — STAT_POWER (stat 73) mirrors the power_on global
   so the CSQC HUD can show "PWR: OFF" (red) / "PWR: ON" (green) in the
   top-left corner without polling the server every frame.

5. [NEW] Zombie count alive/queued split — HUD now shows "ZOMBIES: 5 + 10"
   (alive + still-spawning) instead of a single total, giving tactical info
   about how many are already on the map.

6. [NEW] Milestone round flash colour — HUD_CheckTransitions detects rounds
   divisible by 5 and fires a gold "ROUND X  MILESTONE!" flash instead of the
   standard orange, making milestone rounds feel special.

7. [NEW] Reserve ammo colour warnings — SH/NL/RK/CE reserve rows in the HUD
   ammo display turn red when critically low, giving at-a-glance warnings.

REMAINING HOTSPOTS (not yet addressed)
───────────────────────────────────────────────────────────────────────────
• findradius() in spawn_zombie — small per-spawn cost (0.6 s+ interval).
• RM_LivePlayerCount() find() loop — runs at 1 s intervals, acceptable.
• walkmove / movetogoal C-side path cost scales with entity count at very
  high rounds (25+) on maps with complex geometry.

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
float ROUND_MAX_CONCURRENT;         // hard cap on zombies alive at once (initialized in RM_Init by preset)
float ROUND_SPAWN_RETRY     = 0.25; // blocked spawn-point retry interval
float ROUND_SPAWN_FAIL_MAX  = 8;    // retries before a permanently blocked slot is skipped
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
// Only counts players who have selected a class (class > 0); spectators
// waiting at the class-selection menu are excluded so the round does not
// start or end prematurely while testers are still choosing their loadout.
float() RM_LivePlayerCount =
{
    local entity te;
    local float  count;

    count = 0;
    te = find(world, classname, "player");
    while (te)
    {
        if (te.health > 0 && te.class > 0)
            count = count + 1;
        te = find(te, classname, "player");
    }
    return count;
};

// Return the number of connected players, alive or dead.
float() RM_PlayerCount =
{
    local entity te;
    local float  count;

    count = 0;
    te = find(world, classname, "player");
    while (te)
    {
        count = count + 1;
        te = find(te, classname, "player");
    }
    return count;
};

// Reset the round loop to its idle pre-game state.
// Used when everyone disconnects so the next join starts cleanly from round 1
// instead of being stranded in GAMEOVER or a half-finished wave.
void() RM_ResetToWaiting =
{
    current_round        = 0;
    zombies_queued       = 0;
    zombies_alive        = 0;
    zombies_round_total  = 0;
    round_spawn_failures = 0;
    round_state          = RSTATE_WAITING;
    round_timer          = 0;
    self.cnt             = 0;
    dprint("RM: reset to WAITING (no connected players)\n");
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
// Increments zombies_alive only if spawn_zombie actually placed a zombie.
float() RM_TrySpawnOne =
{
    local entity spot, saved_self;
    local float  alive_before;

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
    // If the chosen point is blocked by a player/zombie, retry a few times
    // before forfeiting the slot so transient congestion does not shrink the
    // wave, while permanently broken maps still fail safe instead of stalling.
    saved_self = self;
    alive_before = zombies_alive;
    spawn_zombie(spot);
    self = saved_self;

    if (zombies_alive > alive_before)
    {
        round_spawn_failures = 0;
        zombies_queued = zombies_queued - 1;
        return TRUE;
    }

    round_spawn_failures = round_spawn_failures + 1;
    if (round_spawn_failures >= ROUND_SPAWN_FAIL_MAX)
    {
        dprint("RM: spawn point stayed blocked, forfeiting queued slot\n");
        round_spawn_failures = 0;
        zombies_queued = zombies_queued - 1;
        return TRUE;
    }

    dprint("RM: spawn blocked, retrying shortly\n");
    return FALSE;
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
        if (RM_PlayerCount() <= 0)
            RM_ResetToWaiting();
        self.nextthink = time + 1;
        return;
    }

    // ---- WAITING: hold until at least one player is alive ----
    if (round_state == RSTATE_WAITING)
    {
        if (RM_LivePlayerCount() > 0)
        {
            local float rnd1_count;
            current_round = 1;
            round_state   = RSTATE_INTRO;
            round_timer   = time + ROUND_INTRO_DURATION;
            self.cnt      = 0;   // reset intro countdown tick counter
            rnd1_count    = RT_ZombieCount(1);
            dprint("RM: player detected — starting Round 1 in 5 s\n");
            bprint(2, strcat("^4** ^bROUND 1 BEGINS IN 5 SECONDS  [",
                             ftos(rnd1_count), " zombies]^b **\n"));
            RM_CenterprintAll(strcat("ROUND 1\nBegins in 5 seconds...\n(",
                                     ftos(rnd1_count), " zombies)"));
            RM_SoundAll("misc/power.wav", 0.5);
        }
        self.nextthink = time + 1;
        return;
    }

    // ---- INTRO: fanfare countdown before first spawn ----
    if (round_state == RSTATE_INTRO)
    {
        if (RM_PlayerCount() <= 0)
        {
            RM_ResetToWaiting();
            self.nextthink = time + 1;
            return;
        }

        if (RM_LivePlayerCount() == 0)
        {
            round_state = RSTATE_GAMEOVER;
            self.nextthink = time + 1;
            return;
        }

        // Integer tick counter drives the 3-2-1 countdown (same pattern as
        // intermission).  self.cnt is reset to 0 when entering INTRO state.
        self.cnt = self.cnt + 1;
        if (self.cnt == ROUND_INTRO_DURATION - 3)
        {
            bprint(2, "^4** 3 **\n");
            RM_SoundAll("misc/menu1.wav", 0.8);
        }
        if (self.cnt == ROUND_INTRO_DURATION - 2)
        {
            bprint(2, "^4** 2 **\n");
            RM_SoundAll("misc/menu1.wav", 0.8);
        }
        if (self.cnt == ROUND_INTRO_DURATION - 1)
        {
            bprint(2, "^4** 1 **\n");
            RM_SoundAll("misc/menu1.wav", 1.0);
        }

        if (time >= round_timer)
        {
            // Transition → SPAWNING: prime the queue from the tuning table.
            zombies_queued      = RT_ZombieCount(current_round);
            zombies_round_total = zombies_queued;   // snapshot for HUD spawn-progress display
            zombies_alive       = 0;
            round_spawn_failures = 0;
            round_zombie_health = RT_ZombieHealth(current_round);
            round_state         = RSTATE_SPAWNING;
            round_timer         = time; // spawn on very next tick
            self.cnt            = 0;    // reset for next intro use

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
        if (RM_PlayerCount() <= 0)
        {
            RM_ResetToWaiting();
            self.nextthink = time + 1;
            return;
        }

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
                    // Concurrent cap or blocked spawn — retry soon.
                    round_timer = time + ROUND_SPAWN_RETRY;
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
        if (RM_PlayerCount() <= 0)
        {
            RM_ResetToWaiting();
            self.nextthink = time + 1;
            return;
        }

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
            local entity rp;
            local float  clear_bonus;

            round_state = RSTATE_INTERMISSION;
            round_timer = time + ROUND_INTERMISSION;
            self.cnt    = 0;    // intermission tick counter (used for countdown)

            // Round-clear bonus: reward all live players for surviving the wave.
            // Scales with round number so late-game rounds feel more rewarding.
            clear_bonus = 200 + current_round * 50;
            rp = find(world, classname, "player");
            while (rp)
            {
                if (rp.health > 0 && rp.class > 0)
                {
                    EC_GivePoints(rp, clear_bonus);
                    sprint(rp, PRINT_HIGH, strcat("^3ROUND CLEAR BONUS: ^2+", ftos(clear_bonus), " pts\n"));
                }
                rp = find(rp, classname, "player");
            }

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
        if (RM_PlayerCount() <= 0)
        {
            RM_ResetToWaiting();
            self.nextthink = time + 1;
            return;
        }

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
        {
            bprint(2, "^4** 3 **\n");
            RM_SoundAll("misc/menu1.wav", 0.8);   // audible countdown tick
        }
        if (self.cnt == ROUND_INTERMISSION - 2)
        {
            bprint(2, "^4** 2 **\n");
            RM_SoundAll("misc/menu1.wav", 0.8);
        }
        if (self.cnt == ROUND_INTERMISSION - 1)
        {
            bprint(2, "^4** 1 **\n");
            RM_SoundAll("misc/menu1.wav", 1.0);   // louder on the final tick
        }

        if (time >= round_timer)
        {
            local float next_count;
            current_round = current_round + 1;
            round_state   = RSTATE_INTRO;
            round_timer   = time + ROUND_INTRO_DURATION;
            self.cnt      = 0;   // reset intro countdown tick counter
            next_count    = RT_ZombieCount(current_round);

            // Milestone rounds (every 5th) get a special fanfare.
            if (current_round > 1 && (current_round % 5) == 0)
            {
                bprint(2, strcat("^3** ^bMILESTONE — ROUND ", ftos(current_round),
                                 "!  [", ftos(next_count), " zombies]^b **\n"));
                RM_SoundAll("misc/menu3.wav", 1.0);
            }
            else
            {
                bprint(2, strcat("^4** ^bROUND ", ftos(current_round),
                                 " BEGINS!  [", ftos(next_count), " zombies]^b **\n"));
                RM_SoundAll("misc/power.wav", 0.5);
            }
            RM_CenterprintAll(strcat("ROUND ", ftos(current_round),
                                     "\nBegins now!\n(", ftos(next_count), " zombies)"));
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
// Called by zombie_die (zombie.qc) when a round-manager zombie is killed.
// ---------------------------------------------------------------------------
void() RM_ZombieDied =
{
    if (zombies_alive > 0)
        zombies_alive = zombies_alive - 1;

    dprint("RM: zombie killed  alive=");
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
    current_round        = 0;
    zombies_queued       = 0;
    zombies_alive        = 0;
    zombies_round_total  = 0;
    round_spawn_failures = 0;
    round_zombie_health  = 60;  // classic kill-threshold; overwritten each round
    round_state          = RSTATE_WAITING;
    round_timer          = 0;
    power_on             = 0;   // power starts off; activate func_power_switch to enable perks/box

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
//   Place instances in the map to define where zombies can enter the level.
//   Optionally set 'target' to a path_corner for patrol-path following.
//   If no instances are placed the manager falls back to
//   info_player_deathmatch and then info_player_start entities.
// ---------------------------------------------------------------------------
/*QUAKED info_zombie_spawn (1 0.5 0) (-16 -16 -24) (16 16 24)
Zombie wave spawn point.  The round manager selects among all placed
instances (uniform random) when deciding where to enter each zombie.
Set 'target' to a path_corner to give spawned zombies a patrol route.
*/
void() info_zombie_spawn =
{
    // No run-time behaviour — this entity is a location marker only.
};

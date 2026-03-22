/*
==============================================================================

HUD  —  quakec/fallout2/csqc/hud.qc

Client-side HUD for Operation Deadfall.

LAYOUT (at default 640×480 resolution)
───────────────────────────────────────────────────────────────────────────
  Top-centre    │ ROUND <n> label + state banner
  Top-right     │ Zombies remaining (alive + queued)
  Bottom-left   │ Health  │  Armor
  Bottom-right  │ Ammo count + ammo-type name
  Bottom-centre │ Kill count
  Full-screen   │ Game-over overlay (RSTATE_GAMEOVER)
  Full-screen   │ Semi-transparent round-transition message

COLOUR CONVENTIONS
  ^4 / '0.3 0.7 1'   blue   – neutral info
  ^2 / '0.3 1 0.3'   green  – good / healthy
  ^1 / '1 0.3 0.3'   red    – danger / low resources
  ^3 / '1 0.85 0.3'  yellow – caution / kills
  white              standard text

==============================================================================
*/

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------
#define HUD_CHAR_W  8   // default character width
#define HUD_CHAR_H  8   // default character height
#define HUD_PADDING 8   // padding from screen edges

// Colours used throughout the HUD.
vector HUD_COL_NORMAL  = '1 1 1';
vector HUD_COL_GREEN   = '0.3 1 0.3';
vector HUD_COL_RED     = '1 0.3 0.3';
vector HUD_COL_YELLOW  = '1 0.85 0.3';
vector HUD_COL_BLUE    = '0.3 0.7 1';
vector HUD_COL_ORANGE  = '1 0.55 0.1';

// Font scale vectors (width × height as a 3D vector, z unused).
vector HUD_FONT_SMALL  = '6 6 0';
vector HUD_FONT_NORMAL = '8 8 0';
vector HUD_FONT_LARGE  = '12 12 0';
vector HUD_FONT_HUGE   = '20 20 0';

// Tracks the last round state seen; used to detect transitions.
float hud_last_round_state;
float hud_last_round;

// Transition overlay: displayed for a short duration on state changes.
float  hud_flash_endtime;
string hud_flash_msg;
vector hud_flash_col;

// --------------------------------------------------------------------------
// Helper: draw a filled backdrop behind HUD text for legibility.
// --------------------------------------------------------------------------
void(vector pos, vector sz) HUD_DrawBack =
{
    drawfill(pos - '2 2 0', sz + '4 4 0', '0 0 0', 0.45);
};

// --------------------------------------------------------------------------
// Bottom-left: Health and Armor
// --------------------------------------------------------------------------
void(float sw, float sh) HUD_DrawHealthArmor =
{
    float hp, armor;
    vector col_hp, col_armor;
    string s_hp, s_armor;
    vector base;

    hp    = getstati(STAT_HEALTH);
    armor = getstati(STAT_ARMOR);

    // Colour thresholds.
    if (hp > 60)  col_hp = HUD_COL_GREEN;
    else if (hp > 25) col_hp = HUD_COL_YELLOW;
    else              col_hp = HUD_COL_RED;

    col_armor = HUD_COL_GREEN;
    if (armor <= 30)
        col_armor = HUD_COL_YELLOW;

    s_hp    = ftos(hp);
    s_armor = ftos(armor);

    base = HUD_PADDING * '1 0 0' + (sh - HUD_PADDING - 24) * '0 1 0';

    // Backdrop.
    HUD_DrawBack(base, '120 22 0');

    // Health icon + value.
    drawstring(base,              "HP  ",  HUD_FONT_SMALL,  HUD_COL_BLUE, 1);
    drawstring(base + '24 0 0',   s_hp,   HUD_FONT_LARGE,  col_hp,       1);

    // Armor icon + value.
    base_x = base_x + 72;
    drawstring(base,              "AR  ",  HUD_FONT_SMALL,  HUD_COL_BLUE, 1);
    drawstring(base + '24 0 0',   s_armor, HUD_FONT_LARGE, col_armor,    1);
};

// --------------------------------------------------------------------------
// Bottom-right: Ammo
// --------------------------------------------------------------------------
void(float sw, float sh) HUD_DrawAmmo =
{
    float ammo, shells, nails, rockets, cells;
    vector base;
    vector ammo_col;
    string s;

    ammo    = getstati(STAT_AMMO);
    shells  = getstati(STAT_SHELLS);
    nails   = getstati(STAT_NAILS);
    rockets = getstati(STAT_ROCKETS);
    cells   = getstati(STAT_CELLS);

    // Current-weapon ammo — big display.
    s = ftos(ammo);
    base = (sw - HUD_PADDING - 80) * '1 0 0' + (sh - HUD_PADDING - 24) * '0 1 0';
    HUD_DrawBack(base, '80 22 0');
    drawstring(base, "AMMO  ", HUD_FONT_SMALL,  HUD_COL_BLUE,   1);
    ammo_col = HUD_COL_NORMAL;
    if (ammo <= 10)
        ammo_col = HUD_COL_RED;
    drawstring(base + '36 0 0', s, HUD_FONT_LARGE, ammo_col, 1);

    // Reserve ammo — smaller row.
    base_y = base_y + 24;
    base_x = sw - HUD_PADDING - 160;
    HUD_DrawBack(base, '160 12 0');
    drawstring(base,              strcat("SH:", ftos(shells)),  HUD_FONT_SMALL, HUD_COL_NORMAL, 1);
    drawstring(base + '40 0 0',   strcat("NL:", ftos(nails)),   HUD_FONT_SMALL, HUD_COL_NORMAL, 1);
    drawstring(base + '80 0 0',   strcat("RK:", ftos(rockets)), HUD_FONT_SMALL, HUD_COL_NORMAL, 1);
    drawstring(base + '120 0 0',  strcat("CE:", ftos(cells)),   HUD_FONT_SMALL, HUD_COL_NORMAL, 1);
};

// --------------------------------------------------------------------------
// Bottom-centre: Kill count
// --------------------------------------------------------------------------
void(float sw, float sh) HUD_DrawKills =
{
    float kills;
    string s;
    vector base;

    kills = getstati(STAT_KILLS);
    s     = strcat("KILLS: ", ftos(kills));
    base  = (sw * 0.5 - strlen(s) * 0.5 * HUD_FONT_NORMAL_x) * '1 0 0'
            + (sh - HUD_PADDING - 12) * '0 1 0';
    HUD_DrawBack(base, (strlen(s) * HUD_FONT_NORMAL_x + 4) * '1 0 0' + '0 10 0');
    drawstring(base, s, HUD_FONT_NORMAL, HUD_COL_YELLOW, 1);
};

// --------------------------------------------------------------------------
// Top-centre: Round number + state label
// --------------------------------------------------------------------------
void(float sw) HUD_DrawRoundInfo =
{
    float  rnd, rstate;
    string label, state_str;
    vector col;
    float  lw;
    vector base;

    rnd    = getstati(STAT_ROUND);
    rstate = getstati(STAT_ROUND_STATE);

    // Round state label and colour.
    if (rstate == RSTATE_WAITING)
    {
        state_str = "WAITING";
        col = HUD_COL_BLUE;
    }
    else if (rstate == RSTATE_INTRO)
    {
        state_str = "INCOMING!";
        col = HUD_COL_ORANGE;
    }
    else if (rstate == RSTATE_SPAWNING)
    {
        state_str = "SPAWNING";
        col = HUD_COL_ORANGE;
    }
    else if (rstate == RSTATE_ACTIVE)
    {
        state_str = "ACTIVE";
        col = HUD_COL_RED;
    }
    else if (rstate == RSTATE_INTERMISSION)
    {
        float secs_left;
        secs_left = getstati(STAT_INTERMISSION_SECS);
        if (secs_left > 0)
            state_str = strcat("ROUND CLEAR  ", ftos(rint(secs_left)), "s");
        else
            state_str = "ROUND CLEAR";
        col = HUD_COL_GREEN;
    }
    else  // GAMEOVER
    {
        state_str = "GAME OVER";
        col = HUD_COL_RED;
    }

    label = strcat("ROUND  ", ftos(rnd));
    lw    = strlen(label) * HUD_FONT_LARGE_x;
    base  = (sw * 0.5 - lw * 0.5) * '1 0 0' + HUD_PADDING * '0 1 0';

    HUD_DrawBack(base, lw * '1 0 0' + '0 14 0');
    drawstring(base, label, HUD_FONT_LARGE, HUD_COL_NORMAL, 1);

    // State below the round number.
    base_y = base_y + 16;
    lw = strlen(state_str) * HUD_FONT_SMALL_x;
    base_x = sw * 0.5 - lw * 0.5;
    HUD_DrawBack(base, lw * '1 0 0' + '0 10 0');
    drawstring(base, state_str, HUD_FONT_SMALL, col, 1);
};

// --------------------------------------------------------------------------
// Top-right: Zombies remaining (alive + queued)
// --------------------------------------------------------------------------
void(float sw) HUD_DrawZombies =
{
    float alive, queued, total;
    string s;
    float  lw;
    vector base, col;

    alive  = getstati(STAT_ZOMBIES_ALIVE);
    queued = getstati(STAT_ZOMBIES_QUEUED);
    total  = alive + queued;

    s   = strcat("ZOMBIES: ", ftos(total));
    col = HUD_COL_RED;
    if (total == 0)
        col = HUD_COL_GREEN;
    lw  = strlen(s) * HUD_FONT_NORMAL_x;
    base = (sw - HUD_PADDING - lw) * '1 0 0' + HUD_PADDING * '0 1 0';
    HUD_DrawBack(base, lw * '1 0 0' + '0 10 0');
    drawstring(base, s, HUD_FONT_NORMAL, col, 1);
};

// --------------------------------------------------------------------------
// Full-screen Game-Over overlay
// --------------------------------------------------------------------------
void(float sw, float sh) HUD_DrawGameOver =
{
    float cx, cy;
    string title, sub, reached;
    float rnd;

    // Dark semi-transparent vignette.
    drawfill('0 0 0', sw * '1 0 0' + sh * '0 1 0', '0 0 0', 0.55);

    title = "GAME  OVER";
    sub   = "All operators are down.  Press any key to restart.";

    cx = sw * 0.5;
    cy = sh * 0.5;

    // Title.
    drawstring((cx - strlen(title) * HUD_FONT_HUGE_x * 0.5) * '1 0 0'
               + (cy - 30) * '0 1 0',
               title, HUD_FONT_HUGE, HUD_COL_RED, 1);

    // Round reached — only shown when the round system was active.
    rnd = getstati(STAT_ROUND);
    if (rnd > 0)
    {
        reached = strcat("Reached Round  ", ftos(rnd));
        drawstring((cx - strlen(reached) * HUD_FONT_NORMAL_x * 0.5) * '1 0 0'
                   + (cy - 4) * '0 1 0',
                   reached, HUD_FONT_NORMAL, HUD_COL_YELLOW, 0.9);
    }

    // Sub-line.
    drawstring((cx - strlen(sub) * HUD_FONT_SMALL_x * 0.5) * '1 0 0'
               + (cy + 14) * '0 1 0',
               sub, HUD_FONT_SMALL, HUD_COL_NORMAL, 0.85);
};

// --------------------------------------------------------------------------
// Transition flash overlay (round start / round clear)
// --------------------------------------------------------------------------
void(float sw, float sh) HUD_DrawFlash =
{
    float remain, alpha;
    float lw;
    vector base;

    if (time >= hud_flash_endtime)
        return;

    remain = hud_flash_endtime - time;
    // Fade in during first 0.4 s, hold, fade out during last 0.6 s.
    if (remain > 2.0)
        alpha = (3.0 - remain) / 1.0;  // fade in
    else
        alpha = remain / 2.0;          // fade out
    if (alpha > 1) alpha = 1;
    if (alpha < 0) alpha = 0;

    lw   = strlen(hud_flash_msg) * HUD_FONT_HUGE_x;
    base = (sw * 0.5 - lw * 0.5) * '1 0 0'
           + (sh * 0.4) * '0 1 0';

    drawfill(base - '8 8 0', lw * '1 0 0' + '16 36 0', '0 0 0', alpha * 0.5);
    drawstring(base, hud_flash_msg, HUD_FONT_HUGE, hud_flash_col, alpha);
};

// --------------------------------------------------------------------------
// Full-screen danger vignette — pulsing red border strips when HP ≤ 25.
// Uses sin(time) for a smooth breathing pulse at ~2 Hz.
// Drawn before the round-flash overlay so transitions always show on top.
// --------------------------------------------------------------------------
void(float sw, float sh) HUD_DrawDangerVignette =
{
    float hp, base_alpha, pulse_alpha;
    float vw;   // vignette strip width
    vector red;

    hp = getstati(STAT_HEALTH);
    if (hp <= 0 || hp > 25)  // threshold matches low_health_pulse in client.qc
        return;

    red = HUD_COL_RED;

    // Strip width: ~6.5% of screen width feels proportional at all resolutions.
    vw = sw * 0.065;

    // Brighter pulsing the closer to death.
    if (hp <= 10)
        base_alpha = 0.38;
    else
        base_alpha = 0.22;

    // Smooth 2 Hz breathing: oscillates between ~0 and base_alpha.
    // 12.56 ≈ 4π, giving one full sin cycle per 0.5 s (2 Hz).
    pulse_alpha = base_alpha * (0.5 + 0.5 * sin(time * 12.56));

    // Left strip
    drawfill('0 0 0',
             vw * '1 0 0' + sh * '0 1 0',
             red, pulse_alpha);
    // Right strip
    drawfill((sw - vw) * '1 0 0',
             vw * '1 0 0' + sh * '0 1 0',
             red, pulse_alpha);
    // Top strip
    drawfill('0 0 0',
             sw * '1 0 0' + vw * '0 1 0',
             red, pulse_alpha);
    // Bottom strip
    drawfill((sh - vw) * '0 1 0',
             sw * '1 0 0' + vw * '0 1 0',
             red, pulse_alpha);
};

// --------------------------------------------------------------------------
// Trigger a flash message.
// --------------------------------------------------------------------------
void(string msg, vector col) HUD_Flash =
{
    hud_flash_msg     = msg;
    hud_flash_col     = col;
    hud_flash_endtime = time + 3.0;
};

// --------------------------------------------------------------------------
// Detect round-state transitions and emit flash messages.
// --------------------------------------------------------------------------
void() HUD_CheckTransitions =
{
    float rstate, rnd;
    rstate = getstati(STAT_ROUND_STATE);
    rnd    = getstati(STAT_ROUND);

    if (rstate != hud_last_round_state)
    {
        if (rstate == RSTATE_INTRO)
        {
            if (hud_last_round_state == RSTATE_WAITING
                || hud_last_round_state == RSTATE_INTERMISSION)
            {
                HUD_Flash(strcat("ROUND  ", ftos(rnd)), HUD_COL_ORANGE);
            }
        }
        else if (rstate == RSTATE_INTERMISSION)
        {
            HUD_Flash(strcat("ROUND ", ftos(rnd), "  CLEAR!"), HUD_COL_GREEN);
        }
        hud_last_round_state = rstate;
        hud_last_round       = rnd;
    }
    else if (rnd != hud_last_round && rstate == RSTATE_INTRO)
    {
        // Round number changed while already in INTRO (e.g. fast restart).
        HUD_Flash(strcat("ROUND  ", ftos(rnd)), HUD_COL_ORANGE);
        hud_last_round = rnd;
    }
};

// --------------------------------------------------------------------------
// Main draw entry-point — called from CSQC_UpdateView.
// --------------------------------------------------------------------------
void() HUD_Draw =
{
    float sw, sh, rstate;

    sw = cvar("vid_conwidth");
    sh = cvar("vid_conheight");

    rstate = getstati(STAT_ROUND_STATE);

    // Detect transitions first so flash messages fire even on game-over.
    HUD_CheckTransitions();

    // ---------- Top HUD ----------
    HUD_DrawRoundInfo(sw);
    HUD_DrawZombies(sw);

    // ---------- Bottom HUD ----------
    HUD_DrawHealthArmor(sw, sh);
    HUD_DrawAmmo(sw, sh);
    HUD_DrawKills(sw, sh);

    // ---------- Full-screen overlays (drawn last, on top) ----------
    if (rstate == RSTATE_GAMEOVER)
        HUD_DrawGameOver(sw, sh);

    HUD_DrawDangerVignette(sw, sh);
    HUD_DrawFlash(sw, sh);
};

/*
First-launch welcome: short orientation and clear primary actions for new players.
Controlled by cvar menu_welcome_seen (set with seta when available so it persists).
*/

#ifndef ISMENUQC
#ifdef CSQC
	#define ISMENUQC	FALSE
#else
	#define ISMENUQC	TRUE
#endif
#endif

var float autocvar_menu_welcome_seen = 0;
var float autocvar_menu_welcome_auto = 1;

nonstatic void(mitem_desktop desktop) M_Welcome_Mark =
{
	if (checkcommand2("seta", FALSE))
		localcmd("\nseta menu_welcome_seen 1\n");
	else
		cvar_set("menu_welcome_seen", "1");
};

nonstatic void(mitem_desktop desktop, float tour) M_Welcome_Show =
{
	mitem_exmenu m;
	float pos;
	string act;

	act = tour ? "m_pop;m_main" : "m_pop;m_welcome_mark;m_main";
	m = spawn(mitem_exmenu, item_text:_("Welcome"), item_flags:IF_SELECTABLE, item_command:act);
	desktop.add(m, RS_X_MIN_PARENT_MIN|RS_Y_MIN_PARENT_MIN | RS_X_MAX_PARENT_MAX|RS_Y_MAX_PARENT_MAX, '0 0', '0 0');
	desktop.item_focuschange(m, IF_KFOCUSED);
	m.totop();

	pos = -120;
	{
		mitem_pic banner = spawn(mitem_pic, item_text:"gfx/ttl_main.lmp", item_size_y:24, item_flags:IF_CENTERALIGN);
		m.addm(banner, [(160-banner.item_size_x)*0.5, pos-32], [(160+banner.item_size_x)*0.5, pos-8]);
	}
	pos += 8;

	m.addm(spawn(mitem_text, item_text:_("Quick start — pick one path below."), item_scale:16, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+16]);
	pos += 24;

	act = tour ? "m_pop;m_newgame sp" : "m_pop;m_welcome_mark;m_newgame sp";
	m.addm(spawn(mitem_text, item_text:_("Single player — start the campaign on the default skill menu."), item_scale:8, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+8]);
	pos += 8;
	if (checkcommand2("map", TRUE))
	{
		m.addm(spawn(mitem_text, item_text:_("Start single player"), item_command:act, item_scale:16, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+16]);
		pos += 20;
	}

	act = tour ? "m_pop;m_servers" : "m_pop;m_welcome_mark;m_servers";
	m.addm(spawn(mitem_text, item_text:_("Multiplayer — browse public servers or host a local game from New Game."), item_scale:8, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+8]);
	pos += 8;
	if (isserver() != 1 && checkbuiltin2(gethostcacheindexforkey, ISMENUQC))
	{
		m.addm(spawn(mitem_text, item_text:_("Join a server"), item_command:act, item_scale:16, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+16]);
		pos += 20;
	}
	act = tour ? "m_pop;m_newgame" : "m_pop;m_welcome_mark;m_newgame";
	if (checkcommand2("map", TRUE))
	{
		m.addm(spawn(mitem_text, item_text:_("Host / local multiplayer"), item_command:act, item_scale:16, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+16]);
		pos += 20;
	}

	act = tour ? "m_pop;m_options" : "m_pop;m_welcome_mark;m_options";
	m.addm(spawn(mitem_text, item_text:_("Name, keys, video, and audio live under Options."), item_scale:8, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+8]);
	pos += 8;
	m.addm(spawn(mitem_text, item_text:_("Open options"), item_command:act, item_scale:16, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+16]);
	pos += 24;

	act = tour ? "m_pop;m_main" : "m_pop;m_welcome_mark;m_main";
	m.addm(spawn(mitem_text, item_text:_("Continue to main menu"), item_command:act, item_scale:16, item_flags:IF_CENTERALIGN), [0, pos], [160, pos+16]);
	pos += 16;

	m.add(spawn(mitem_spinnymodel, item_text:"progs/player.mdl", firstframe:0, framecount:6, shootframe:119, shootframes:6), RS_X_MIN_PARENT_MID|RS_Y_MIN_PARENT_MID | RS_X_MAX_PARENT_MID|RS_Y_MAX_PARENT_MID, [-160, 12*-16/2], [0, 12*16/2]);
	addmenuback(m);
};

nonstatic void(mitem_desktop desktop) M_Welcome =
{
	M_Welcome_Show(desktop, FALSE);
};

nonstatic void(mitem_desktop desktop) M_Welcome_Tour =
{
	M_Welcome_Show(desktop, TRUE);
};

nonstatic void(mitem_desktop desktop) M_Welcome_Maybe =
{
	if (!autocvar_menu_welcome_auto)
		return;
	if (autocvar_menu_welcome_seen)
		return;
	M_Welcome(desktop);
};

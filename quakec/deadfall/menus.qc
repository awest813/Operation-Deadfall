/*

	return ("
weaponry\n\n
ê1ë melee          \n
ê2ë thrown         \n
ê3ë pistols&smgs   \n
ê4ë shotguns       \n
ê5ë rifles         \n
ê6ë heavy guns     \n
êeë leave          
*/

/*
ê1ë 1911a1     .45   01       5$\n
ê2ë d. eagle   .44   02       7$\n
ê3ë mk23 socom .45   02       9$\n
ê4ë h&k mp7    4mm   03      14$\n
ê5ë h&k mp5    9mm   03      17$\n
ê6ë alien blaster    02      21$\n

ê1ë pipe rifle .44   02       4$\n
ê2ë winchester 12g   03       8$\n
ê3ë mossberg   12g   04      14$\n
ê4ë citykiller 12g   05      35$\n

ê1ë rangemaster 7mm  03      11$\n
ê2ë ak-112      5mm  04      21$\n
ê3ë remington  .308  05      24$\n
ê4ë ak-74       5mm  04      27$\n
ê5ë moonlight  .223  05      36$\n
ê6ë sa-80       5mm  05      23$\n
ê7ë plasma rifle     07      41$\n
ê8ë gauss rifle 2mm  08      51$\n
*/

string () ShopString =
{
	return ("--- S H O P -------\n"
		"\n"
		"ê1ë traits         \n"
		"ê2ë perks          \n"
		"ê3ë body armour    \n"
		"ê4ë protection     \n"
		"ê5ë weapons        \n"
		"ê6ë equipment      \n"
		"ê7ë chems          \n"
		"ê8ë special        \n"
		"êeë leave          \n");
};

string () WeaponString =
{
	return ("weaponry\n"
		"\n"
		"ê1ë melee          \n"
		"ê2ë thrown         \n"
		"ê3ë pistols&smgs   \n"
		"ê4ë shotguns       \n"
		"ê5ë rifles         \n"
		"ê6ë heavy guns     \n"
		"êeë leave          \n");
};

string () TraitString =
{
	return ("traits\n"
		"\n"
		"ê1ë one handed     \n"
		"ê2ë small frame    \n"
		"ê3ë bruiser        \n"
		"ê4ë heavy handed   \n"
		"ê5ë bloody mess    \n"
		"ê6ë bad luck       \n"
		"êeë leave          \n");
};

string () ThrownString =
{
	return ("grenades\n"
		"	GRENADE | COST		  \n"
		"\n"
		"ê1ë smoke grenade             3$\n"
		"ê2ë frag grenade              4$\n"
		"ê3ë emp grenade               5$\n"
		"ê4ë flashbang                 7$\n"
		"êeë exit                        \n");
};

string () BuildString =
{
	return ("BUILD A STRUCTURE\n"
		"      NAME | UPGRADE |   SCRAPS\n"
		"\n"
		"ê1ë Mr. Ammo                  4\n"
		"ê2ë Barricade                 6\n"
		"ê3ë AutoDoc(tm)              10\n"
		"ê4ë Robo-Fang                11\n"
		"êeë exit                       \n");
};

string () HelmetString =
{
	return ("helmets\n"
		"protect you from headshots so\n"
		"make sure you use a decent one\n"
		"\n"
		"                  ABS% WT DEFLECT PRC\n"
		"ê1ë combat helm   -10% 01    5%    05\n"
		"ê2ë combat helm 2  +0% 02    5%    20\n"
		"ê3ë heavy-duty    +20% 03    5%    20\n"
		"ê4ë ceramic helm  -20% ...");
};

string () ArmorString =
{
	return ("body armour           wt  abs  prc\n"
		"\n"
		"ê1ë light kevlar      03 1/20% 03$\n"
		"ê2ë leather armor     05 2/30% 08$\n"
		"ê3ë kevlar armor      09 3/35% 10$\n"
		"ê4ë metal armor       15 5/35% 12$\n"
		"ê5ë combat armor      12 4/40% 25$\n"
		"ê6ë brotherhood armor 17 5/45% 35$\n"
		"ê7ë force armor       06 7/10% 45$\n"
		"ê8ë metal armor mkii  20 8/50% 55$\n");
};

// Costs must match EC_PERK_T1/T2/T3/T4 constants in economy.qc.
string () PerkString =
{
	return ("perks\n"
		"  ABILITY          | COST \n"
		"\n"
		"ê1ë bonus movement      500\n"
		"ê2ë strong back          500\n"
		"ê3ë quick pockets        500\n"
		"ê4ë awareness           1000\n"
		"ê5ë silent running      1000\n"
		"ê6ë better criticals    1000\n"
		"ê7ë bonus ranged dmg    1000\n"
		"ê8ë divine favor        1500\n"
		"ê9ë slayer              2000\n");
};

string () ProtectString =
{
	return ("++ high-tech protective devices ++ \n"
		"\n"
		"  HARDWARE | SHIELDS VS |  PRICE   \n"
		"ê1ë energy amulet  |damage: 7% ê15ë\n"
		"ê2ë force field    |front: 15% ê20ë\n"
		"ê3ë safety ring    |absorb: 3  ê35ë\n"
		"ê4ë smokescreen    |obscures   ê40ë\n"
		"ê5ë sentient cube  |regenerate ê45ë\n");
};


/*return ("++ high-tech protective devices ++ \n\n
  HARDWARE | SHIELDS VS |  PRICE   \n
ê1ë energy amulet  |damage: 7% ê15ë\n
ê2ë force field    |front: 15% ê20ë\n
ê3ë safety ring    |absorb: 3  ê35ë\n
ê4ë smokescreen    |obscures   ê40ë\n
ê5ë sentient cube  |regenerate ê45ë\n");*/


string () OtherString =
{
	return
		"++ miscellaneous items ++\n"
		"  ITEM   |   CLASS   |   PRICE     \n"
		"\n"
		"\n"
		"ê1ë (25) bandages for medic      2$\n"
		"ê2ë (20) robofang               20$\n"
		"ê3ë (20) mr.ammo                20$\n"
		"ê4ë (20) auto-doc               20$\n"
		"ê5ë (20) shield-gen             20$\n"
		"ê6ë (20) tesla-turret           20$\n"
		"ê7ë (20) rocket-turret          20$\n"
		"ê8ë (20) machinegun-turret      20$\n"
		"ê9ë telepad (planned)         --\n"
		;
};


string () MeleeString =
{
	return ("MELEE WEAPONS\n"
		"WEAPON | TYPE | WT | PRICE   \n"
		"\n"
		"ê1ë knife        melee 01 01$\n"
		"ê2ë hand axe     melee 08 03$\n"
		"ê3ë vibroblade   melee 04 10$\n"
		"ê4ë power axe    melee 07 15$\n"
		"êeë exit                     \n");
};

/*
ê6ë h&k mp5   9mmP   03      17$\n
ê7ë h&k mp7  4.60mm  03      14$\n
ê8ë fn p90   5.57mm  03      22$\n
ê9ë h&k mp10  10mm   03      24$\n
ê0ë thompson  .45    03      20$\n


ê6ë h&k mp5   9mmP   03      17$\nê7ë h&k mp7  4.60mm  03      14$\nê8ë fn p90   5.57mm  03      22$\nê9ë h&k mp10  10mm   03      24$\nê0ë thompson  .45    03      20$\n
*/

string () PistolString =
{
	return ("Pistols and Submachineguns\n"
		"    WEAPON | CAL | WEIGHT | PRICE \n"
		"\n"
		"ê1ë mk23 socom .45   01       5$\n"
		"ê2ë d. eagle   .44   02       7$\n"
		"ê3ë needler pistol   02       9$\n"
		"ê4ë h&k mp7    4mm   03      14$\n"
		"ê5ë grease gun 9mm   03      17$\n"
		"ê6ë alien blaster    02      21$\n");
};

string () ShotgunString =
{
	return ("shotguns\n"
		"    WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"ê1ë pipe rifle .44   02       4$\n"
		"ê2ë winchester 12g   03       8$\n"
		"ê3ë mossberg   12g   04      14$\n"
		"ê4ë citykiller 12g   05      35$\n");
};

/*
ê6ë dks-1      .338   bolt 08 32$\n
ê7ë moonlight  .223   auto 06 54$\n
ê8ë xl70e3      5mm   auto 08 27$\n
ê9ë fn-fal     .308   auto 04 51$\n
ê0ë sa-80      .223   auto 07 45$\n

*/
string () RifleString =
{
	return ("rifles\n"
		"   RIFLE | TYPE | WEIGHT | PRICE \n"
		"\n"
		"ê1ë rangemaster 7mm  03      11$\n"
		"ê2ë ak-112      5mm  04      21$\n"
		"ê3ë remington  .308  05      24$\n"
		"ê4ë ak-74       5mm  04      27$\n"
		"ê5ë moonlight  .223  05      36$\n"
		"ê6ë sa-80       5mm  05      32$\n"
		"ê7ë fn-fal     .308  09      25$\n");
};

string () HeavyString =
{
	return ("other weaponry\n"
		"  WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"ê1ë rocket launcher  10      30$\n"
		"ê2ë gauss rifle      07      32$\n"
		"ê3ë laser carbine    12      45$\n");
};

string () ChemString =
{
	return ("drugs\n     DRUG  |   EFFECTS   |  PRICE\n"
		"\n"
		"ê1ë stimpack   heals 05+20     3$\n"
		"ê2ë medkit+    heals 10+50     5$\n"
		"ê3ë superstim* heals 20+60    12$\n"
		"ê4ë adrenaline*+speed/jump    10$\n"
		"ê5ë jet*       aim better     18$\n"
		"êeë exit                         \n"
		"\n"
		"+ requires medic                 \n"
		"* requires advanced medic        \n");
};

string () ChemString2 =
{
	return ("chems\n     DRUG  |   EFFECTS   |  PRICE\n"
		"\n"
		"ê1ë adrenaline +60 speed/jump  3$\n"
		"ê2ë stimpack   heals 40        5$\n"
		"ê3ë psycho+    +60 hp/no pain 11$\n"
		"ê4ë medkit*    heals 20+50    12$\n"
		"ê5ë berserk*   adren+psycho   12$\n"
		"ê6ë jet*       aim better     15$\n"
		"êeë exit                         \n"
		"\n"
		"+ requires shaman                \n"
		"* requires advanced shaman       \n");
};

string () EnergyWeaponsString =
{
	return ("high-tech weaponry\n"
		"  WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"ê1ë [*] flash gun         semi 03 21$\n"
		"ê2ë [&] plasma rifle      semi 08 34$\n"
		"ê3ë [*] laser rifle       semi 11 40$\n"
		"ê4ë [*] laser carbine     auto 06 57$\n"
		"ê5ë [?] alien blaster     semi 02 72$\n");
};

//ê6ë bozar                    14 81$\nê7ë firestorm                12 97$

string () HeavyGunsString =
{
	return ("heavy guns\n"
		"    WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"ê1ë light support weapon     15 55$\n"
		"ê2ë rocket launcher          11 75$\n"
		"ê3ë 50oc flamethrower        16 35$\n"
		"ê4ë steyr amr .50 flechette  17 72$\n"
		"ê5ë m72 gauss rifle 2mm      12 81$\n"
		"ê6ë bozar                    14 81$\n"
		"ê7ë firestorm                12 97$");
};

string () de_dust =
{
	return ("             DE_DUST          \n"
		"        (BOMB/DEFUSE MAP)     \n"
		"\n"
		"rangers have obtained two ufos\n"
		"that have crash landed in the \n"
		"desert. raiders must blow them\n"
		"up with c4 before its too late\n"
		"\n"
		"(activate electronic tools and\n"
		"c4 by pressing 4)         ...");
};

/*
ê4ë motion sensor                 ê20cë\n
ê5ë extra magazines               ê20cë\n
ê6ë electronic tools mark ii      ê30cë\n
ê7ë climbing gear                 ê30cë\n
ê8ë remote camera                 ê40cë\n
ê9ë cooling module                ê50cë\n
ê0ë laser defense field           ê50cë\n
*/



string () EquipmentString =
{
	return ("+ special equipment +\n"
		"press your c key to activate!\n"
		"\n"
		"ê1ë medic's bag                   ê15cë\n"
		"ê2ë security alarm                ê15cë\n"
		"ê3ë remote camera                 ê15cë\n"
		"ê4ë belt pouch                    ê15cë\n"
		"ê5ë backpack                      ê15cë\n"
		"ê6ë toolkit mark ii               ê15cë\n"
		"ê7ë climbing gear                 ê15cë\n"
		"ê8ë enhanced battery              ê15cë\n"
		"ê9ë stealth boy                   ê45cë\n"
		"\n");
};

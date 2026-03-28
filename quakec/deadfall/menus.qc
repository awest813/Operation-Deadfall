/*

	return ("
weaponry\n\n
�1� melee          \n
�2� thrown         \n
�3� pistols&smgs   \n
�4� shotguns       \n
�5� rifles         \n
�6� heavy guns     \n
�e� leave          
*/

/*
�1� 1911a1     .45   01       5$\n
�2� d. eagle   .44   02       7$\n
�3� mk23 socom .45   02       9$\n
�4� h&k mp7    4mm   03      14$\n
�5� h&k mp5    9mm   03      17$\n
�6� alien blaster    02      21$\n

�1� pipe rifle .44   02       4$\n
�2� winchester 12g   03       8$\n
�3� mossberg   12g   04      14$\n
�4� citykiller 12g   05      35$\n

�1� rangemaster 7mm  03      11$\n
�2� ak-112      5mm  04      21$\n
�3� remington  .308  05      24$\n
�4� ak-74       5mm  04      27$\n
�5� moonlight  .223  05      36$\n
�6� sa-80       5mm  05      23$\n
�7� plasma rifle     07      41$\n
�8� gauss rifle 2mm  08      51$\n
*/

string () ShopString =
{
	return ("--- S H O P -------\n"
		"\n"
		"�1� traits         \n"
		"�2� perks          \n"
		"�3� body armour    \n"
		"�4� protection     \n"
		"�5� weapons        \n"
		"�6� equipment      \n"
		"�7� chems          \n"
		"�8� misc           \n"
		"�e� leave          \n");
};

string () WeaponString =
{
	return ("weaponry\n"
		"\n"
		"�1� melee          \n"
		"�2� thrown         \n"
		"�3� pistols&smgs   \n"
		"�4� shotguns       \n"
		"�5� rifles         \n"
		"�6� heavy guns     \n"
		"�e� leave          \n");
};

string () TraitString =
{
	return ("traits (free, choose one)\n"
		"  TRAIT       | EFFECT          \n"
		"\n"
		"�1� one handed   1-hand accuracy\n"
		"�2� small frame  agility/light  \n"
		"�3� bruiser      melee damage   \n"
		"�4� heavy handed strength focus \n"
		"�5� bloody mess  gory kills     \n"
		"�6� bad luck     risk/reward    \n"
		"�e� exit                        \n");
};

string () ThrownString =
{
	return ("grenades\n"
		"	GRENADE | COST		  \n"
		"\n"
		"�1� smoke grenade             3$\n"
		"�2� frag grenade              4$\n"
		"�3� emp grenade               5$\n"
		"�4� flashbang                 7$\n"
		"�e� exit                        \n");
};

string () BuildString =
{
	return ("BUILD A STRUCTURE\n"
		"      NAME | UPGRADE |   SCRAPS\n"
		"\n"
		"�1� Mr. Ammo                  4\n"
		"�2� Barricade                 6\n"
		"�3� AutoDoc(tm)              10\n"
		"�4� Robo-Fang                11\n"
		"�e� exit                       \n");
};

string () HelmetString =
{
	return ("helmets\n"
		"protect you from headshots so\n"
		"make sure you use a decent one\n"
		"\n"
		"                  ABS% WT DEFLECT PRC\n"
		"�1� combat helm   -10% 01    5%    05\n"
		"�2� combat helm 2  +0% 02    5%    20\n"
		"�3� heavy-duty    +20% 03    5%    20\n"
		"�4� ceramic helm  -20% ...");
};

string () ArmorString =
{
	return ("body armour           wt  abs  prc\n"
		"\n"
		"�1� light kevlar      03 1/20% 03$\n"
		"�2� leather armor     05 2/30% 08$\n"
		"�3� kevlar armor      09 3/35% 10$\n"
		"�4� metal armor       15 5/35% 12$\n"
		"�5� combat armor      12 4/40% 25$\n"
		"�6� brotherhood armor 17 5/45% 35$\n"
		"�7� force armor       06 7/10% 45$\n"
		"�8� metal armor mkii  20 8/50% 55$\n");
};

// Costs must match EC_PERK_T1/T2/T3/T4 constants in economy.qc.
string () PerkString =
{
	return ("perks\n"
		"  ABILITY          | COST \n"
		"\n"
		"�1� bonus movement      500\n"
		"�2� strong back          500\n"
		"�3� quick pockets        500\n"
		"�4� awareness           1000\n"
		"�5� silent running      1000\n"
		"�6� better criticals    1000\n"
		"�7� bonus ranged dmg    1000\n"
		"�8� divine favor        1500\n"
		"�9� slayer              2000\n");
};

string () ProtectString =
{
	return ("++ high-tech protective devices ++ \n"
		"\n"
		"  HARDWARE | SHIELDS VS |  PRICE   \n"
		"�1� energy amulet  |damage: 7% �15�\n"
		"�2� force field    |front: 15% �20�\n"
		"�3� safety ring    |absorb: 3  �35�\n"
		"�4� smokescreen    |obscures   �40�\n"
		"�5� sentient cube  |regenerate �45�\n");
};


/*return ("++ high-tech protective devices ++ \n\n
  HARDWARE | SHIELDS VS |  PRICE   \n
�1� energy amulet  |damage: 7% �15�\n
�2� force field    |front: 15% �20�\n
�3� safety ring    |absorb: 3  �35�\n
�4� smokescreen    |obscures   �40�\n
�5� sentient cube  |regenerate �45�\n");*/


string () OtherString =
{
	return
		"++ miscellaneous items ++\n"
		"  ITEM   |   CLASS   |   PRICE     \n"
		"\n"
		"\n"
		"�1� (25) bandages for medic      2$\n"
		"�2� (20) robofang               20$\n"
		"�3� (20) mr.ammo                20$\n"
		"�4� (20) auto-doc               20$\n"
		"�5� (20) shield-gen             20$\n"
		"�6� (20) tesla-turret           20$\n"
		"�7� (20) rocket-turret          20$\n"
		"�8� (20) machinegun-turret      20$\n"
		"�9� telepad (planned)         --\n"
		;
};


string () MeleeString =
{
	return ("MELEE WEAPONS\n"
		"WEAPON | TYPE | WT | PRICE   \n"
		"\n"
		"�1� knife        melee 01 01$\n"
		"�2� hand axe     melee 08 03$\n"
		"�3� vibroblade   melee 04 10$\n"
		"�4� power axe    melee 07 15$\n"
		"�e� exit                     \n");
};

/*
�6� h&k mp5   9mmP   03      17$\n
�7� h&k mp7  4.60mm  03      14$\n
�8� fn p90   5.57mm  03      22$\n
�9� h&k mp10  10mm   03      24$\n
�0� thompson  .45    03      20$\n


�6� h&k mp5   9mmP   03      17$\n�7� h&k mp7  4.60mm  03      14$\n�8� fn p90   5.57mm  03      22$\n�9� h&k mp10  10mm   03      24$\n�0� thompson  .45    03      20$\n
*/

string () PistolString =
{
	return ("Pistols and Submachineguns\n"
		"    WEAPON | CAL | WEIGHT | PRICE \n"
		"\n"
		"�1� mk23 socom .45   01       5$\n"
		"�2� d. eagle   .44   02       7$\n"
		"�3� needler pistol   02       9$\n"
		"�4� h&k mp7    4mm   03      14$\n"
		"�5� grease gun 9mm   03      17$\n"
		"�6� alien blaster    02      21$\n");
};

string () ShotgunString =
{
	return ("shotguns\n"
		"    WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"�1� pipe rifle .44   02       4$\n"
		"�2� winchester 12g   03       8$\n"
		"�3� mossberg   12g   04      14$\n"
		"�4� citykiller 12g   05      35$\n");
};

/*
�6� dks-1      .338   bolt 08 32$\n
�7� moonlight  .223   auto 06 54$\n
�8� xl70e3      5mm   auto 08 27$\n
�9� fn-fal     .308   auto 04 51$\n
�0� sa-80      .223   auto 07 45$\n

*/
string () RifleString =
{
	return ("rifles\n"
		"   RIFLE | TYPE | WEIGHT | PRICE \n"
		"\n"
		"�1� rangemaster 7mm  03      11$\n"
		"�2� ak-112      5mm  04      21$\n"
		"�3� remington  .308  05      24$\n"
		"�4� ak-74       5mm  04      27$\n"
		"�5� moonlight  .223  05      36$\n"
		"�6� sa-80       5mm  05      32$\n"
		"�7� fn-fal     .308  09      25$\n");
};

string () HeavyString =
{
	return ("other weaponry\n"
		"  WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"�1� rocket launcher  10      30$\n"
		"�2� gauss rifle      07      32$\n"
		"�3� laser carbine    12      45$\n");
};

string () ChemString =
{
	return ("drugs\n     DRUG  |   EFFECTS   |  PRICE\n"
		"\n"
		"�1� stimpack   heals 40        3$\n"
		"�2� medkit+    heals 20+50     5$\n"
		"�3� superstim* heals 40+60    10$\n"
		"�4� adrenaline*+speed/jump    12$\n"
		"�5� psycho*    +60 hp/no pain 18$\n"
		"�6� berserk*   adren+psycho   21$\n"
		"�e� exit                         \n"
		"\n"
		"+ requires medic                 \n"
		"* requires advanced medic        \n");
};

string () ChemString2 =
{
	return ("chems\n     DRUG  |   EFFECTS   |  PRICE\n"
		"\n"
		"�1� adrenaline +60 speed/jump  3$\n"
		"�2� stimpack   heals 40        5$\n"
		"�3� psycho+    +60 hp/no pain 11$\n"
		"�4� medkit*    heals 20+50    12$\n"
		"�5� berserk*   adren+psycho   12$\n"
		"�6� jet*       aim better     15$\n"
		"�e� exit                         \n"
		"\n"
		"+ requires shaman                \n"
		"* requires advanced shaman       \n");
};

string () EnergyWeaponsString =
{
	return ("high-tech weaponry\n"
		"  WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"�1� [*] flash gun         semi 03 21$\n"
		"�2� [&] plasma rifle      semi 08 34$\n"
		"�3� [*] laser rifle       semi 11 40$\n"
		"�4� [*] laser carbine     auto 06 57$\n"
		"�5� [?] alien blaster     semi 02 72$\n");
};

//�6� bozar                    14 81$\n�7� firestorm                12 97$

string () HeavyGunsString =
{
	return ("heavy guns\n"
		"    WEAPON | TYPE | WEIGHT | PRICE \n"
		"\n"
		"�1� light support weapon     15 55$\n"
		"�2� rocket launcher          11 75$\n"
		"�3� 50oc flamethrower        16 35$\n"
		"�4� steyr amr .50 flechette  17 72$\n"
		"�5� m72 gauss rifle 2mm      12 81$\n"
		"�6� bozar                    14 81$\n"
		"�7� firestorm                12 97$");
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
�4� motion sensor                 �20c�\n
�5� extra magazines               �20c�\n
�6� electronic tools mark ii      �30c�\n
�7� climbing gear                 �30c�\n
�8� remote camera                 �40c�\n
�9� cooling module                �50c�\n
�0� laser defense field           �50c�\n
*/



string () EquipmentString =
{
	return ("+ special equipment +\n"
		"press your c key to activate!\n"
		"\n"
		"�1� medic's bag                   �15c�\n"
		"�2� security alarm                �15c�\n"
		"�3� remote camera                 �15c�\n"
		"�4� belt pouch                    �15c�\n"
		"�5� backpack                      �15c�\n"
		"�6� toolkit mark ii               �15c�\n"
		"�7� climbing gear                 �15c�\n"
		"�8� enhanced battery              �15c�\n"
		"�9� stealth boy                   �45c�\n"
		"\n");
};

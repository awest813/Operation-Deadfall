
void(entity to, float iid, float amount) AddNonStackable =
{
	local float slot;

	slot = SlotOfItem(to, iid);
	if (!slot)
		slot = FindSuitableEmptySlot(to, iid);
	if (slot)
		SetItemSlot(to, slot, SlotVal(iid, amount));
};

void(entity to, float iid, float amount) AddStackable =
{
	local float slot;

	slot = FindSuitableEmptySlot(to, iid);
	if (slot)
		SetItemSlot(to, slot, SlotVal(iid, amount + ToStatus(ItemInSlot(to, slot))));
}

void(float cost, float iid) BuyStackable =
{
	local string z;

	if (self.ammo_shells < cost)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "not enough money.\n");
		return;
	}

	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	self.ammo_shells = self.ammo_shells - cost;

	sprint(self, PRINT_HIGH, "you bought a ");

	z = GetItemName(iid);
	sprint(self, PRINT_HIGH, z);
	sprint(self, PRINT_HIGH, "\n");

	//put grenade in inventory
	//finds existing grenades, otherwise, empty slot

	TryGiveStackable(self, iid, 1);
};

void() BuyBandages =
{
	local string y;

	if (self.ammo_shells < 2)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "not enough money.\n");
		return;
	}
	if (self.class != 2)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "not a medic.\n");
		return;
	}
	if (self.bandages >= 50)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "too many bandages.\n");
		return;
	}

	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	self.bandages = self.bandages + 25;
	self.ammo_shells = self.ammo_shells - 2;
	if (self.bandages > 50)
		self.bandages = 50;
	y = ftos(self.bandages);
	sprint(self, PRINT_HIGH, "you now have ");
	sprint(self, PRINT_HIGH, y);
	sprint(self, PRINT_HIGH, "/50 bandages.\n");	
};

void(float cost, float type) BuyChem =
{
	local string chemname;
	local float max;
	local float alreadygot;

	if (self.ammo_shells < cost)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "not enough money.\n");
		return;
	}
	if (type != IID_CHEM_STIMPACK && self.class != 1)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "not a medic.\n");
		return;
	}
	if (self.equipment == 1)
		max = 4;
	else
		max = 2;

	if (type == IID_CHEM_MEDICALBAG)
		max = 50;

	alreadygot = TotalQuantity(self, type);
	if (alreadygot >= max)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "you can't hold any more chems.\n");
		return;
	}

	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	self.ammo_shells = self.ammo_shells - cost;
	chemname = GetItemName(type);
	sprint(self, PRINT_HIGH, chemname);
	sprint(self, PRINT_HIGH, " purchased.\n");
	TryGiveStackable(self, type, 1);
};

void(string type) ChangeAmmo =
{

	if (self.ammo_shells < 1)
	{
		self.currentmenu = "none";
		sprint(self, PRINT_HIGH, "not enough money.\n");
		return;
	}

	
	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);

	if (self.current_slot == 1)
		self.ammotype1 = type;
	if (self.current_slot == 2)
		self.ammotype2 = type;
};

void() SetWeaponModel;

void (float wt, float cost, float wid) BuyWeapon =
{
	local string itname;
	local float ammotype, ammocount;
	local float slotnum;
	local float curweap;

	if (self.ammo_shells < cost)
	{
		self.currentmenu = "none";
		sound (self, CHAN_BODY, "misc/menu3.wav", 1, ATTN_IDLE);
		sprint(self, PRINT_HIGH, "not enough money.\n");
		return;
	}

	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	self.ammo_shells = self.ammo_shells - cost;

	sprint(self, PRINT_HIGH, "you bought ");

	itname = GetItemName(wid);
	sprint(self, PRINT_HIGH, itname);
	sprint(self, PRINT_HIGH, ".\n");

	//put new weapon in current slot
	//put old weapon in empty slot (but not armor slot!)
      //otherwise, drop it.

	curweap = ItemInSlot(self, self.current_slot);
	slotnum = FindSuitableEmptySlot(self, ToIID(curweap));

	if (slotnum == 0)//no more room
		DropFromSlot (self.current_slot, 1, 0);
	else       //found a place to stick old weapon
		SetItemSlot(self, slotnum, curweap);

	ammocount = WeaponMagQuant(wid);//load weapon with full ammo (may be changed)
	SetItemSlot(self, self.current_slot, SlotVal(wid, ammocount));


	ammotype = WeaponAmmoType(wid);//load weapon with full ammo (may be changed)
	TryGiveStackable(self, ammotype, ammocount*3);

	SetWeaponModel();
};


void (float cost, float item) BuyPerk =
{
	if (self.ammo_shells < cost)
	{
		sprint (self, PRINT_HIGH, "not enough money\n");
		self.currentmenu = "none";
		return;
	}
	if (self.perk == item)
	{
		sprint (self, PRINT_HIGH, "you already have that perk.\n");
		self.currentmenu = "none";
		return;
	}
	self.ammo_shells = self.ammo_shells - cost;
	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	sprint (self, PRINT_HIGH, "perk installed: ");
	sprint (self, PRINT_HIGH, EC_PerkName(item));
	sprint (self, PRINT_HIGH, ".\n");
	self.perk = item;
	self.currentmenu = "none";
	return;
};

// Return a human-readable name for a trait ID (1-6).
string (float id) TraitName =
{
	if (id == 1) return "one handed";
	if (id == 2) return "small frame";
	if (id == 3) return "bruiser";
	if (id == 4) return "heavy handed";
	if (id == 5) return "bloody mess";
	if (id == 6) return "bad luck";
	return "unknown";
};

// Select a trait (free, once per life).  Traits have no point cost but can
// only be chosen once.  Pass the trait ID (1-6 matching TraitString).
void (float id) SelectTrait =
{
	if (self.trait > 0)
	{
		sprint (self, PRINT_HIGH, "you already have a trait: ");
		sprint (self, PRINT_HIGH, TraitName(self.trait));
		sprint (self, PRINT_HIGH, ".\n");
		self.currentmenu = "none";
		return;
	}
	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	self.trait = id;
	sprint (self, PRINT_HIGH, "trait selected: ");
	sprint (self, PRINT_HIGH, TraitName(id));
	sprint (self, PRINT_HIGH, ".\n");
	self.currentmenu = "none";
};

/*
void (float wt, float cost, float item) BuyArmor =
{

	local float curr;
	local float lbs;
	local string x;

	lbs = weightx ();
	if (((item >= TE_LIGHTNING2) && (self.protect >= SPAWNFLAG_SUPERSPIKE)))
	{
		sprint (self, PRINT_HIGH, "remove your hardware before buying\nany kind of advanced armor!\ntoo much interference otherwise.");
		self.currentmenu = "none";
		return;
	}
	if ((cost > self.ammo_shells))
	{
		sprint (self, PRINT_HIGH, "not enough money.\n");
		self.currentmenu = "none";
		return;
	}
	if ((((lbs + wt) - GetItemsWeight(self.islot3)) > self.max_weight))
	{
		sprint (self, PRINT_HIGH, "you can't carry that much.\n");
		self.currentmenu = "none";
		return;
	}
	sound (self, CHAN_BODY, "misc/item2.wav", 1, ATTN_NORM);
	self.ammo_shells = (self.ammo_shells - cost);
//	self.armor_weight = wt;
	self.armor = item;
	x = GetArmorName();
	sprint (self, PRINT_HIGH, x);
	sprint (self, PRINT_HIGH, " purchased.\n");

	return;

};*/

void (float wt, float cost, float item) BuyArmor =
{
	local string z;
	local float x;

	if (self.ammo_shells < cost)
	{
		self.currentmenu = "none";
		sound (self, CHAN_BODY, "misc/menu3.wav", 1, ATTN_IDLE);
		sprint(self, PRINT_HIGH, "not enough money.\n");
		return;
	}

	sound (self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
	self.ammo_shells = self.ammo_shells - cost;

	sprint(self, PRINT_HIGH, "you bought ");

	z = GetItemName(item);
	sprint(self, PRINT_HIGH, z);
	sprint(self, PRINT_HIGH, ".\n");

	//put new armor in armor slot
	//put old armor in inventory

	x = FindEmptySlot(self);

	if (x == 0)
		sprint(self, 2, "no more room. giving armor to merchant.\n");

	if (x != 0) //found a place to stick old armor
		SetItemSlot(self, x, SlotVal(self.islot3, 1));

		SetItemSlot(self, 3, SlotVal(item, 1));
};

void (float cost, float item) BuyEquipment =
{
	local float lbs;
	local string x;

	lbs = weightx ();
	if ((cost > self.ammo_shells))
	{
		sprint (self, PRINT_HIGH, "not enough money.\n");
		self.currentmenu = "none";
		return;
	}
	sound (self, CHAN_BODY, "items/item1.wav", 1, ATTN_NORM);
	self.equipment = item;
	x = GetEquipmentName();
	sprint (self, PRINT_HIGH, x);
	sprint (self, PRINT_HIGH, " purchased.\n");
	self.ammo_shells = (self.ammo_shells - cost);
	return;
};

void (float cost, float item) BuyProtect =
{
	local string x;

/*
	if ((self.armor >= TE_LIGHTNING2))
	{
		sprint (self, PRINT_HIGH, "too many electronics in\nyour currently worn armor!");
		self.currentmenu = "none";
		return;
	}
*/
	if ((cost > self.ammo_shells))
	{
		sprint (self, PRINT_HIGH, "not enough money.\n");
		self.currentmenu = "none";
		return;
	}
	sound (self, CHAN_BODY, "items/item1.wav", 1, ATTN_NORM);
	self.ammo_shells = (self.ammo_shells - cost);
	self.protect = item;
	x = GetProtectName();
	sprint (self, PRINT_HIGH, x);
	sprint (self, PRINT_HIGH, " purchased.\n");

	return;
};


float (float input) overweight =
{
	local float tmp;
	local float max;

	tmp = input + self.weight;
	max = self.max_weight;
	if (self.class == TE_LIGHTNING2)
	{
		max = max + SPAWNFLAG_LASER;
	}
	if (self.perk == TE_LAVASPLASH)
	{
		return (FALSE);
	}
	if (tmp > max)
	{
		return (TRUE);
	}
	else
	{
		return (FALSE);
	}
};

void () W_GetClass =
{
	if ((self.currentmenu == "select_skill"))
	{
		sound (self, CHAN_WEAPON, "buttons/switch02.wav", TRUE, ATTN_NORM);
		if (self.impulse == 1)
		{
			self.currentmenu = "none";
			self.max_health = 80;
			self.class = 1;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nMedic - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
		if ((self.impulse == 2))
		{
			self.currentmenu = "none";
			self.max_health = 70;
			self.class = 2;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nAssassin - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
		if (self.impulse == 3)
		{
			self.currentmenu = "none";
			self.max_health = 100;
			self.class = 3;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nSoldier - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
		if (self.impulse == 4)
		{
			self.max_health = 80;
			self.currentmenu = "none";
			self.class = 4;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nScientist - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
	}
	if (self.impulse > 4)
		return;

};


void() W_PlayerMenu =
{
	if (self.currentmenu == "none")
		return;

	if (self.currentmenu == "shop_list")
	{
		if (self.impulse == 1)
			self.currentmenu = "shop_trait";
		if (self.impulse == 2)
			self.currentmenu = "shop_perk";
		if (self.impulse == 3)
			self.currentmenu = "shop_armor";
		if (self.impulse == 4)
			self.currentmenu = "shop_protect";
		if (self.impulse == 5)
			self.currentmenu = "shop_weapons";
		if (self.impulse == 6)
			self.currentmenu = "shop_equipment";
		if (self.impulse == 7)
			self.currentmenu = "shop_chems";
		if (self.impulse == 8)
			self.currentmenu = "shop_other";

		DisplayMenu();
		return;
	}

	if (self.currentmenu == "shop_trait")
	{
		if (self.impulse == 1) { SelectTrait(1); return; }
		if (self.impulse == 2) { SelectTrait(2); return; }
		if (self.impulse == 3) { SelectTrait(3); return; }
		if (self.impulse == 4) { SelectTrait(4); return; }
		if (self.impulse == 5) { SelectTrait(5); return; }
		if (self.impulse == 6) { SelectTrait(6); return; }
		return;
	}
	if (self.currentmenu == "shop_perk")
	{
		if (self.impulse == 1)
                  BuyPerk(EC_PERK_T1, 1);
		if (self.impulse == 2)
                  BuyPerk(EC_PERK_T1, 2);
		if (self.impulse == 3)
                  BuyPerk(EC_PERK_T1, 3);
		if (self.impulse == 4)
                  BuyPerk(EC_PERK_T2, 4);
		if (self.impulse == 5)
                  BuyPerk(EC_PERK_T2, 5);
		if (self.impulse == 6)
                  BuyPerk(EC_PERK_T2, 6);
		if (self.impulse == 7)
                  BuyPerk(EC_PERK_T2, 7);
		if (self.impulse == 8)
                  BuyPerk(EC_PERK_T3, 8);
		if (self.impulse == 9)
                  BuyPerk(EC_PERK_T4, 9);

			return;
	}
	if (self.currentmenu == "shop_armor")
	{
		if (self.impulse == 1)
                  BuyArmor(3, 3, IID_ARM_SHIRT);          //weight, cost, item
		if (self.impulse == 2)
                  BuyArmor(7, 5, IID_ARM_LEATHER);          //weight, cost, item
		if (self.impulse == 3)
                  BuyArmor(9, 10, IID_ARM_KEVLAR);         //weight, cost, item
		if (self.impulse == 4)
                  BuyArmor(15, 12, IID_ARM_METAL);         //weight, cost, item
		if (self.impulse == 5)
                  BuyArmor(12, 25, IID_ARM_COMBAT);         //weight, cost, item
		if (self.impulse == 6)
                  BuyArmor(17, 35, IID_ARM_BROTHERHOOD);   //weight, cost, item
		if (self.impulse == 7)
                  BuyArmor(5, 45, IID_ARM_FORCE);         //weight, cost, item
		if (self.impulse == 8)
                  BuyArmor(20, 55, IID_ARM_LPOWER);         //weight, cost, item

			return;
	}
	if (self.currentmenu == "shop_protect")
	{
		if (self.impulse == 1)
                  BuyProtect(20, 1);
		if (self.impulse == 2)
                  BuyProtect(20, 2);
		if (self.impulse == 3)
                  BuyProtect(30, 3);
		if (self.impulse == 4)
                  BuyProtect(30, 4);
		if (self.impulse == 5)
                  BuyProtect(40, 5);

			return;
	}
	if (self.currentmenu == "shop_weapons")
	{
		if (self.impulse == 1)
			self.currentmenu = "shop_melee";
		if (self.impulse == 2)
			self.currentmenu = "shop_thrown";
		if (self.impulse == 3)
			self.currentmenu = "shop_pistols";
		if (self.impulse == 4)
			self.currentmenu = "shop_shotguns";
		if (self.impulse == 5)
			self.currentmenu = "shop_rifles";
		if (self.impulse == 6)
			self.currentmenu = "shop_heavy";

		DisplayMenu();
		return;
	}
	if (self.currentmenu == "shop_melee")
	{
		if (self.impulse == 1)
                  BuyWeapon(1, 1, IID_WP_KNIFE);         //weight, cost, item
		if (self.impulse == 2)
                  BuyWeapon(6, 3, IID_WP_AXE);         //weight, cost, item
		if (self.impulse == 3)
                  BuyWeapon(3, 10, IID_WP_VIBROBLADE);         //weight, cost, item
		if (self.impulse == 4)
                  BuyWeapon(10, 15, IID_WP_POWERAXE);         //weight, cost, item

			return;
	}
	if (self.currentmenu == "shop_thrown")
	{
		if (self.impulse == 1)
                  BuyStackable(3, IID_GREN_SMOKE);         //weight, cost, item
		if (self.impulse == 2)
                  BuyStackable(4, IID_GREN_FRAG);         //weight, cost, item
		if (self.impulse == 3)
                  BuyStackable(5, IID_GREN_EMP);         //weight, cost, item
		if (self.impulse == 4)
                  BuyStackable(6, IID_GREN_FLASH);         //weight, cost, item

			return;
	}
	if (self.currentmenu == "shop_pistols")
	{
		if (self.impulse == 1)
                  BuyWeapon(1, 5, IID_WP_USP);         //weight, cost, item
		if (self.impulse == 2)
                  BuyWeapon(2, 7, IID_WP_DEAGLE);         //weight, cost, item
		if (self.impulse == 3)
                  BuyWeapon(2, 9, IID_WP_NEEDLER);         //weight, cost, item
		if (self.impulse == 4)
                  BuyWeapon(3, 14, IID_WP_MP9);         //weight, cost, item
		if (self.impulse == 5)
                  BuyWeapon(3, 17, IID_WP_MP7);         //weight, cost, item
		if (self.impulse == 6)
                  BuyWeapon(2, 21, IID_WP_ALIENBLASTER);         //weight, cost, item

			return;
	}
	if (self.currentmenu == "shop_shotguns")
	{
		if (self.impulse == 1)
                  BuyWeapon(3, 4, IID_WP_PIPERIFLE);         //weight, cost, item
		if (self.impulse == 2)
                  BuyWeapon(4, 8, IID_WP_WINCHESTER);         //weight, cost, item
		if (self.impulse == 3)
                  BuyWeapon(5, 12, IID_WP_MOSSBERG);         //weight, cost, item
		if (self.impulse == 4)
                  BuyWeapon(7, 34, IID_WP_JACKHAMMER);         //weight, cost, item

			return;
	}
	if (self.currentmenu == "shop_rifles")
	{
		if (self.impulse == 1)
                  BuyWeapon(3, 11, IID_WP_RANGEMASTER);    //weight, cost, item
		if (self.impulse == 2)
                  BuyWeapon(4, 21, IID_WP_AK112);          //weight, cost, item
		if (self.impulse == 3)
                  BuyWeapon(5, 25, IID_WP_AK74);           //weight, cost, item
		if (self.impulse == 4)
                  BuyWeapon(6, 28, IID_WP_DKS1);           //weight, cost, item
		if (self.impulse == 5)
                  BuyWeapon(5, 30, IID_WP_MOONLIGHT);      //weight, cost, item
		if (self.impulse == 6)
                  BuyWeapon(4, 32, IID_WP_SA80);           //weight, cost, item
		if (self.impulse == 7)
                  BuyWeapon(9, 25, IID_WP_FNFAL);          //weight, cost, item

			return;
	}
	if (self.currentmenu == "shop_heavy")
	{
		if (self.impulse == 1)
                  BuyWeapon(10, 30, IID_WP_ROCKETLAUNCHER);//weight, cost, item
		if (self.impulse == 2)
                  BuyWeapon(7, 32, IID_WP_GAUSERIFLE);     //weight, cost, item
		if (self.impulse == 3)
                  BuyWeapon(12, 45, IID_WP_PULSERIFLE);    //weight, cost, item
	}

	if (self.currentmenu == "shop_equipment")
	{
		if (self.impulse == 1)
                  BuyEquipment(20, 1);         //cost, item
		if (self.impulse == 2)
                  BuyEquipment(20, 2);         //cost, item
		if (self.impulse == 3)
                  BuyEquipment(20, 3);         //cost, item
		if (self.impulse == 4)
                  BuyEquipment(20, 4);         //cost, item
		if (self.impulse == 5)
                  BuyEquipment(20, 5);         //cost, item
		if (self.impulse == 6)
                  BuyEquipment(20, 6);         //cost, item
		if (self.impulse == 7)
                  BuyEquipment(20, 7);         //cost, item
		if (self.impulse == 8)
                  BuyEquipment(20, 8);         //cost, item
		if (self.impulse == 9)
                  BuyEquipment(20, 9);         //cost, item
		if (self.impulse == 10)
                  BuyEquipment(20, 10);         //cost, item

			return;
	}

	if (self.currentmenu == "shop_chems")
	{
		if (self.impulse == 1)
                  BuyChem(3, IID_CHEM_STIMPACK);         //cost, item
		if (self.impulse == 2)
                  BuyChem(5, IID_CHEM_MEDICALBAG);         //cost, item
		if (self.impulse == 3)
                  BuyChem(10, IID_CHEM_SUPERSTIM);         //cost, item
		if (self.impulse == 4)
                  BuyChem(12, IID_CHEM_ADRENALINE);         //cost, item
		if (self.impulse == 5)
                  BuyChem(18, IID_CHEM_PSYCHO);         //cost, item
		if (self.impulse == 6)
                  BuyChem(21, IID_CHEM_BESERK);         //cost, item
		return;
	}

	if (self.currentmenu == "shop_other")
	{
		if (self.impulse == 1)
			BuyChem(5, IID_CHEM_MEDICALBAG);
		if (self.impulse == 2)
			BuyStackable(20, IID_BUILD_ROBOFANG);
		if (self.impulse == 3)
			BuyStackable(20, IID_BUILD_MRAMMO);
		if (self.impulse == 4)
			BuyStackable(20, IID_BUILD_AUTODOC);
		if (self.impulse == 5)
			BuyStackable(20, IID_BUILD_SHIELDGEN);
		if (self.impulse == 6)
			BuyStackable(20, IID_BUILD_TTURRET);
		if (self.impulse == 7)
			BuyStackable(20, IID_BUILD_RTURRET);
		if (self.impulse == 8)
			BuyStackable(20, IID_BUILD_GTURRET);
		if (self.impulse == 9)
			sprint(self, PRINT_HIGH, "Telepad deployment is planned, but the buildable is not implemented yet.\n");
		return;
	}


	if (self.currentmenu == "select_team")
	{
		if (self.impulse == 1)
		{
			bprint(2, self.netname);
			bprint(2, " has joined the rangers.\n");
			self.currentmenu = "confirm_team";
			DisplayMenu();
			self.team = 1;
			return;
		}
		if (self.impulse == 2)
		{
			bprint(2, self.netname);
			bprint(2, " has joined the raiders.\n");
			self.currentmenu = "confirm_team";
			DisplayMenu();
			self.team = 2;
			return;
		}
		if (self.impulse == 3)
		{
			// Auto-assign: join the smaller team; break ties toward Rangers.
			local entity te;
			local float  r_count, ra_count;
			r_count  = 0;
			ra_count = 0;
			te = find(world, classname, "player");
			while (te)
			{
				if (te.team == 1) r_count  = r_count  + 1;
				if (te.team == 2) ra_count = ra_count + 1;
				te = find(te, classname, "player");
			}
			if (ra_count < r_count)
				self.team = 2;
			else
				self.team = 1;
			bprint(2, self.netname);
			if (self.team == 1)
				bprint(2, " has joined the rangers.\n");
			else
				bprint(2, " has joined the raiders.\n");
			self.currentmenu = "confirm_team";
			DisplayMenu();
			return;
		}

	}

	if (self.currentmenu == "select_skill")
	{
		sound (self, CHAN_WEAPON, "buttons/switch02.wav", TRUE, ATTN_NORM);

		if (self.impulse == 1)
		{
			self.currentmenu = "none";
			self.max_health = 80;
			self.class = 1;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nMedic - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
		if ((self.impulse == 2))
		{
			self.currentmenu = "none";
			self.max_health = 70;
			self.class = 2;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nAssassin - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
		if (self.impulse == 3)
		{
			self.currentmenu = "none";
			self.max_health = 100;
			self.class = 3;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nSoldier - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
		if (self.impulse == 4)
		{
			self.max_health = 80;
			self.currentmenu = "none";
			self.class = 4;
			self.currentmenu = "confirm_skill";
			centerprint (self, "�your class will be�\n\nScientist - OK?\n�1� Yes     \n�2� No      \n");
			self.ghost = 0;
			return;
		}
	}


		if (self.currentmenu == "confirm_team")
		{
			if (self.impulse == 1)
			{
				sound (self, CHAN_WEAPON, "buttons/switch02.wav", TRUE, ATTN_NORM);
				self.currentmenu = "select_skill";
				DisplayMenu();
				self.impulse = 0;
				return;
			}
			if (self.impulse == 2)
			{
				sound (self, CHAN_WEAPON, "buttons/switch02.wav", TRUE, ATTN_NORM);
				self.currentmenu = "select_team";
				DisplayMenu();
				self.impulse = 0;
				self.team = 0;
				return;
			}
		}
		if (self.currentmenu == "confirm_skill")
		{
			if (self.impulse == 1)
			{
				sound (self, CHAN_WEAPON, "buttons/switch02.wav", TRUE, ATTN_NORM);
				self.currentmenu = "none";
				centerprint(self, "");
				PutClientInServer();
				self.impulse = 0;
				return;
			}
			if (self.impulse == 2)
			{
				sound (self, CHAN_WEAPON, "buttons/switch02.wav", TRUE, ATTN_NORM);
				self.currentmenu = "select_skill";
				DisplayMenu();
				self.impulse = 0;
				self.class = 0;
				return;
			}
		}

};
// ============================================================================
// WORLD INTERACTION ENTITIES
// COD Zombies-style buy / interaction entities placed directly in maps.
// ============================================================================

// ---------------------------------------------------------------------------
// Shared helper: give an item (weapon/equipment) to the current player.
// Returns TRUE when the item was successfully placed in inventory.
// ---------------------------------------------------------------------------
float(float iid) EC_GiveItem =
{
local float slot;
slot = FindSuitableEmptySlot(self, iid);
if (!slot)
{
sprint(self, PRINT_HIGH, "no room in inventory.\n");
return FALSE;
}
SetItemSlot(self, slot, SlotVal(iid, 1));
if (slot == self.current_slot)
W_SetCurrentAmmo();
return TRUE;
};

// ---------------------------------------------------------------------------
// DoWallBuy — called from BuyMenu when the player is near an info_wallbuy.
//   Purchases the weapon/item this entity sells (ent.buy_item, ent.buy_cost).
// ---------------------------------------------------------------------------
void(entity ent) DoWallBuy =
{
local float cost;
local float iid;
local string name;

if (self.spamdelay > time)
return;
self.spamdelay = time + 1.5;

cost = ent.buy_cost;
iid  = ent.buy_item;

if (!iid)
{
sprint(self, PRINT_HIGH, "wall buy not configured (missing buy_item).\n");
return;
}
if (!cost)
{
sprint(self, PRINT_HIGH, "wall buy not configured (missing buy_cost).\n");
return;
}

if (!EC_CanAfford(self, cost))
{
sprint(self, PRINT_HIGH, "not enough money (");
sprint(self, PRINT_HIGH, ftos(cost));
sprint(self, PRINT_HIGH, " pts needed).\n");
return;
}

name = GetItemName(iid);
if (!EC_GiveItem(iid))
return;

EC_SpendPoints(self, cost);
sound(self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
sprint(self, PRINT_HIGH, "bought ");
sprint(self, PRINT_HIGH, name);
sprint(self, PRINT_HIGH, ".\n");
};

// ---------------------------------------------------------------------------
// DoMysteryBox — called from BuyMenu when near a func_mystery_box.
//   Costs EC_BOX_COST, gives a random ranged weapon.  Requires power on.
// ---------------------------------------------------------------------------
// BOX_POOL_SIZE must equal the number of entries in the if/else chain below.
// When adding or removing a weapon from the pool:
//   1. Add/remove its branch in DoMysteryBox.
//   2. Update BOX_POOL_SIZE to match.
// Using a #define instead of a mutable global prevents the count from
// drifting out of sync during refactors.
#define BOX_POOL_SIZE 14

void(entity ent) DoMysteryBox =
{
local float r;
local float iid;
local float cost;

if (self.spamdelay > time)
return;
self.spamdelay = time + 2.0;

if (!power_on)
{
centerprint(self, "^1Power is off.\nActivate the power switch first.");
return;
}

cost = ent.buy_cost;
if (!cost)
cost = EC_BOX_COST;

if (!EC_CanAfford(self, cost))
{
sprint(self, PRINT_HIGH, "not enough money (");
sprint(self, PRINT_HIGH, ftos(cost));
sprint(self, PRINT_HIGH, " pts needed).\n");
return;
}

EC_SpendPoints(self, cost);

// Random weapon pool — BOX_POOL_SIZE entries (indices 0 .. BOX_POOL_SIZE-1).
// To add a weapon: append an "else if" branch, then increment BOX_POOL_SIZE.
r = floor(random() * BOX_POOL_SIZE);
if      (r ==  0) iid = IID_WP_USP;
else if (r ==  1) iid = IID_WP_DEAGLE;
else if (r ==  2) iid = IID_WP_NEEDLER;
else if (r ==  3) iid = IID_WP_MP9;
else if (r ==  4) iid = IID_WP_MP7;
else if (r ==  5) iid = IID_WP_PIPERIFLE;
else if (r ==  6) iid = IID_WP_WINCHESTER;
else if (r ==  7) iid = IID_WP_MOSSBERG;
else if (r ==  8) iid = IID_WP_JACKHAMMER;
else if (r ==  9) iid = IID_WP_RANGEMASTER;
else if (r == 10) iid = IID_WP_AK112;
else if (r == 11) iid = IID_WP_AK74;
else if (r == 12) iid = IID_WP_ALIENBLASTER;
else              iid = IID_WP_ROCKETLAUNCHER;  // index 13 = BOX_POOL_SIZE-1

sound(self, CHAN_BODY, "misc/item2.wav", 1, ATTN_NORM);
EC_GiveItem(iid);
sprint(self, PRINT_HIGH, "mystery box: ");
sprint(self, PRINT_HIGH, GetItemName(iid));
sprint(self, PRINT_HIGH, "!\n");
};

// ---------------------------------------------------------------------------
// DoInstallPerk — called from BuyMenu when near a func_perk_machine.
//   Installs the perk specified by ent.buy_item.  Requires power on.
// ---------------------------------------------------------------------------
void(entity ent) DoInstallPerk =
{
local float cost;
local float perk_id;

if (self.spamdelay > time)
return;
self.spamdelay = time + 1.5;

if (!power_on)
{
centerprint(self, "^1Power is off.\nActivate the power switch first.");
return;
}

perk_id = ent.buy_item;
if (!perk_id)
{
sprint(self, PRINT_HIGH, "perk machine not configured (missing buy_item).\n");
return;
}

if (self.perk == perk_id)
{
sprint(self, PRINT_HIGH, "you already have that perk.\n");
return;
}

cost = ent.buy_cost;
if (!cost)
cost = EC_PerkCost(perk_id);

if (!EC_CanAfford(self, cost))
{
sprint(self, PRINT_HIGH, "not enough money (");
sprint(self, PRINT_HIGH, ftos(cost));
sprint(self, PRINT_HIGH, " pts needed).\n");
return;
}

EC_SpendPoints(self, cost);
self.perk = perk_id;
sound(self, CHAN_BODY, "misc/item1.wav", 1, ATTN_NORM);
sprint(self, PRINT_HIGH, "perk installed: ");
sprint(self, PRINT_HIGH, EC_PerkName(perk_id));
sprint(self, PRINT_HIGH, ".\n");
};

// ---------------------------------------------------------------------------
// info_wallbuy — point entity placed on a wall.
//
// Required map keys:
//   buy_item  : IID of the weapon / item to sell (see inventory.qc for IIDs)
//   buy_cost  : point cost
//
// Optional map keys:
//   message   : short label shown in the touch prompt (default: item name)
//
/*QUAKED info_wallbuy (1 0.5 0) (-8 -8 -8) (8 8 8)
Wall-mounted weapon purchase point.
Player walks up and presses [BUY] to purchase the item.

Required keys:
  buy_item  IID of the weapon/item to sell (see inventory.qc IID_ constants)
  buy_cost  point cost
Optional keys:
  message   label shown in the HUD prompt (defaults to item name)
*/
// ---------------------------------------------------------------------------
void() wallbuy_touch =
{
local string name;
local string msg;

if (!triggercantouch(self, other))
	return;
if (other.classname != "player")
	return;
if (self.attack_finished > time)
	return;
self.attack_finished = time + 1.5;

if (self.message != "")
	name = self.message;
else
	name = GetItemName(self.buy_item);
msg = strcat(name, "\n^2[", ftos(self.buy_cost), " pts - press BUY]");
centerprint(other, msg);
};

void() info_wallbuy =
{
self.movetype = MOVETYPE_NONE;
self.solid    = SOLID_TRIGGER;
setsize(self, '-48 -48 -24', '48 48 48');
self.classname = "info_wallbuy";
self.touch     = wallbuy_touch;
};

// ---------------------------------------------------------------------------
// func_mystery_box — brush entity that dispenses a random weapon.
//
// Optional map keys:
//   buy_cost  : override spin cost (default EC_BOX_COST = 950)
//
/*QUAKED func_mystery_box (0 0.5 1) ?
Mystery box.  Player approaches and presses [BUY] to spend EC_BOX_COST pts
for a random weapon.  Requires the map power switch to be activated first.

Optional keys:
  buy_cost  override spin price (default 950)
*/
// ---------------------------------------------------------------------------
void() mysterybox_touch =
{
local string msg;
local float cost;

if (!triggercantouch(self, other))
return;
if (other.classname != "player")
return;
if (self.attack_finished > time)
return;
self.attack_finished = time + 1.5;

cost = self.buy_cost;
if (!cost)
cost = EC_BOX_COST;

if (power_on)
msg = strcat("MYSTERY BOX\n^2[", ftos(cost), " pts - press BUY]");
else
msg = "MYSTERY BOX\n^1[Power required - find the power switch]";
centerprint(other, msg);
};

void() func_mystery_box =
{
self.movetype  = MOVETYPE_NONE;
self.solid     = SOLID_BSP;
self.classname = "func_mystery_box";
setmodel(self, self.model);
setorigin(self, self.origin);
self.touch = mysterybox_touch;
};

// ---------------------------------------------------------------------------
// func_perk_machine — brush entity that installs a single perk.
//
// Required map keys:
//   buy_item  : perk ID (1-9)
//
// Optional map keys:
//   buy_cost  : override cost (default derived from perk tier via EC_PerkCost)
//
/*QUAKED func_perk_machine (0.5 0 1) ?
Perk vending machine.  Player approaches and presses [BUY] to install the
perk specified by buy_item.  Requires power to be on.

Required keys:
  buy_item  perk ID (1-9)
Optional keys:
  buy_cost  override price (default from perk tier table in economy.qc)
*/
// ---------------------------------------------------------------------------
void() perkmachine_touch =
{
local float cost;
local float perk_id;
local string msg;

if (!triggercantouch(self, other))
return;
if (other.classname != "player")
return;
if (self.attack_finished > time)
return;
self.attack_finished = time + 1.5;

perk_id = self.buy_item;
cost    = self.buy_cost;
if (!cost)
cost = EC_PerkCost(perk_id);

if (power_on)
msg = strcat(EC_PerkName(perk_id), "\n^2[", ftos(cost), " pts - press BUY]");
else
msg = strcat(EC_PerkName(perk_id), "\n^1[Power required - find the power switch]");
centerprint(other, msg);
};

void() func_perk_machine =
{
self.movetype  = MOVETYPE_NONE;
self.solid     = SOLID_BSP;
self.classname = "func_perk_machine";
setmodel(self, self.model);
setorigin(self, self.origin);
self.touch = perkmachine_touch;
};

// ---------------------------------------------------------------------------
// func_power_switch — brush or point entity that activates the map's power.
//
// Touching (or triggering) this entity turns on the power globally, enabling
// perk machines and the mystery box.
//
/*QUAKED func_power_switch (1 1 0) ?
Power switch.  Walk up and press [BUY] (or trigger via target/targetname) to
turn on the map power, enabling perk machines and mystery box.
Once activated the switch cannot be toggled off.
*/
// ---------------------------------------------------------------------------
// power_switch_activate is called two ways:
//   1. Via self.use trigger — self is the power switch entity
//   2. Directly from BuyMenu — self is the player standing near the switch
// In both cases we broadcast the power-on to all players.
void() power_switch_activate =
{
	local entity p;

	if (power_on)
	{
		// Give feedback to whoever called this.
		if (self.classname == "player")
			centerprint(self, "^3Power is already on.");
		return;
	}

	power_on = 1;
	bprint(2, "^3** POWER ON! Perk machines and mystery box are now active. **\n");

	// Notify every live player.
	p = find(world, classname, "player");
	while (p)
	{
		centerprint(p, "^3POWER ON!\nPerk machines and mystery box are now active!");
		sound(p, CHAN_BODY, "misc/basekey.wav", 1, ATTN_NORM);
		p = find(p, classname, "player");
	}

	// If called as a triggered entity (self = the switch), fire its targets.
	if (self.classname == "func_power_switch")
		SUB_UseTargets();
};

void() powerswitch_touch =
{
local string msg;

if (!triggercantouch(self, other))
return;
if (other.classname != "player")
return;
if (self.attack_finished > time)
return;
self.attack_finished = time + 1.5;

if (power_on)
msg = "POWER SWITCH\n^3[Power is ON]";
else
msg = "POWER SWITCH\n^2[Press BUY to activate]";
centerprint(other, msg);
};

void() func_power_switch =
{
self.movetype  = MOVETYPE_NONE;
self.solid     = SOLID_BSP;
self.classname = "func_power_switch";
setmodel(self, self.model);
setorigin(self, self.origin);
self.touch = powerswitch_touch;
self.use   = power_switch_activate;
};

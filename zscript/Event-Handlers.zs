// Struct for itemspawn information. 
class WaresSpawnItem play
{
	// ID by string for spawner
	string spawnName;
	
	// ID by string for spawnees
	Array<WaresSpawnItemEntry> spawnReplaces;
	
	// Whether or not to persistently spawn.
	bool isPersistent;
	
	// Whether or not to replace the original item.
	bool replaceItem;

	string toString()
	{
		let replacements = "[";
		if (spawnReplaces.size())
		{
			replacements = replacements..spawnReplaces[0].toString();

			for (let i = 1; i < spawnReplaces.size(); i++)
			{
				replacements = replacements..", "..spawnReplaces[i].toString();
			}
		}
		replacements = replacements.."]";


		return String.format("{ spawnName=%s, spawnReplaces=%s, isPersistent=%b, replaceItem=%b }", spawnName, replacements, isPersistent, replaceItem);
	}
}

class WaresSpawnItemEntry play
{
	string name;
	int    chance;

	string toString()
	{
		return String.format("{ name=%s, chance=%s }", name, chance >= 0 ? "1/"..(chance + 1) : "never");
	}
}

// Struct for passing useinformation to ammunition. 
class WaresSpawnAmmo play
{
	// ID by string for the header ammo.
	string ammoName;
	
	// ID by string for weapons using that ammo.
	Array<string> weaponNames;
	
	string toString()
	{

		let weapons = "[";
		if (weaponNames.size())
		{
			weapons = weapons..weaponNames[0];

			for (let i = 1; i < weaponNames.size(); i++)
			{
				weapons = weapons..", "..weaponNames[i];
			}
		}
		weapons = weapons.."]";

		return String.format("{ ammoName=%s, weaponNames=%s }", ammoName, weapons);
	}
}



// One handler to rule them all. 
class OffworldWaresHandler : EventHandler
{
	// List of persistent classes to completely ignore. 
	// This -should- mean this mod has no performance impact. 
	static const class<actor> blacklist[] =
	{
		"HDSmoke",
		"BloodTrail",
		"CheckPuff",
		"WallChunk",
		"HDBulletPuff",
		"HDFireballTail",
		"ReverseImpBallTail",
		"HDSmokeChunk",
		"ShieldSpark",
		"HDFlameRed",
		"HDMasterBlood",
		"PlantBit",
		"HDBulletActor",
		"HDLadderSection"
	};

	// List of weapon-ammo associations.
	// Used for ammo-use association on ammo spawn (happens very often). 
	array<WaresSpawnAmmo> ammoSpawnList;
	
	// List of item-spawn associations.
	// used for item-replacement on mapload. 
	array<WaresSpawnItem> itemSpawnList;

	bool cvarsAvailable;
	
	// appends an entry to itemSpawnList;
	void addItem(string name, Array<WaresSpawnItemEntry> replacees, bool persists, bool rep=true)
	{
		// Creates a new struct;
		WaresSpawnItem spawnee = WaresSpawnItem(new('WaresSpawnItem'));
		
		// Populates the struct with relevant information,
		spawnee.spawnName = name;
		spawnee.isPersistent = persists;
		spawnee.replaceItem = rep;
		for (int i = 0; i < replacees.size(); i++)
		{
			spawnee.spawnReplaces.push(replacees[i]);
		}
		
		// Pushes the finished struct to the array. 
		itemSpawnList.push(spawnee);
	}


	WaresSpawnItemEntry addItemEntry(string name, int chance)
	{
		// Creates a new struct;
		WaresSpawnItemEntry spawnee = WaresSpawnItemEntry(new('WaresSpawnItemEntry'));
		spawnee.name = name.makelower();
		spawnee.chance = chance;
		return spawnee;
	}

	// appends an entry to ammoSpawnList;
	void addammo(string name, Array<string> weapons)
	{
	
		// Creates a new struct;
		WaresSpawnAmmo spawnee = WaresSpawnAmmo(new('WaresSpawnAmmo'));
		spawnee.ammoName = name.makelower();
		
		// Populates the struct with relevant information,
		for (int i = 0; i < weapons.size(); i++)
		{
			spawnee.weaponNames.push(weapons[i].makelower());
		}
		
		// Pushes the finished struct to the array. 
		ammoSpawnList.push(spawnee);
	}
	

	// Populates the replacement and association arrays. 
	void init()
	{	
		cvarsAvailable = true;

		//------------
		// Ammunition
		//------------

		// Flintlock
		Array<string> wep_flint;
		wep_flint.push("HD_FlintlockPistol");
		addAmmo("HDBallAmmo", wep_flint);

		// Musket
		Array<string> wep_musket;
		wep_musket.push("HD_Musket");
		addAmmo("HDBallAmmo", wep_musket);


		//------------
		// Weaponry
		//------------

		// Flintlock
		Array<WaresSpawnItemEntry> spawns_flint;
		spawns_flint.push(addItemEntry("WildBackpack", flint_saw_spawn_bias));
		// This is true yet it acts like false.
		// I don't know why.
		// I'll fix it some other time, I've been staring at this for literal hours.
		// If you're reading this and know a fix, please let me know. - [Ted]
		addItem("HD_FlintlockPistol", spawns_flint, flint_persistent_spawning);

		// Musket
		Array<WaresSpawnItemEntry> spawns_musket;
		spawns_musket.push(addItemEntry("SquadSummoner", musket_blur_spawn_bias));
		addItem("HD_MusketDropper", spawns_musket, musket_persistent_spawning);


		// --------------------
		// Items
		// --------------------

		/*
		// Rum
		Array<WaresSpawnItemEntry> spawns_rum;
		spawns_rum.push(addItemEntry('PortableStimpack', rum_pmi_spawn_bias));
		addItem('UaS_Alcohol_OleRum', spawns_rum, rum_persistent_spawning, false);

		// Radsuit Packages
		Array<WaresSpawnItemEntry> spawns_radpack;
		spawns_radpack.push(addItemEntry('Radsuit', suit_replacement_spawn_bias));
		addItem('HD_RadsuitPack', spawns_radpack, rum_persistent_spawning, false);

		// Armor Patch Kit
      	Array<WaresSpawnItemEntry> spawns_apk;
		spawns_apk.push(addItemEntry('HDArmour', apk_replacement_spawn_bias));
		spawns_apk.push(addItemEntry('DeadRifleman', apk_replacement_spawn_bias));
		spawns_apk.push(addItemEntry('ReallyDeadRifleman', apk_replacement_spawn_bias));
		spawns_apk.push(addItemEntry('Lumberjack', apk_replacement_spawn_bias));
		addItem('HDAPKSpawner', spawns_apk, apk_persistent_spawning, false);
	
		// Universal Reloader
		Array<WaresSpawnItemEntry> spawns_url;
		spawns_url.push(addItemEntry('HDAmBox', url_replacement_spawn_bias));
		spawns_url.push(addItemEntry('HDAmBoxUnarmed', url_replacement_spawn_bias));
		spawns_url.push(addItemEntry('DeadRifleman', url_replacement_spawn_bias));
		spawns_url.push(addItemEntry('ReallyDeadRifleman', url_replacement_spawn_bias));
		addItem('HDUniversalReloader', spawns_url, url_persistent_spawning, false);
	
		// Logistics Bag
		Array<WaresSpawnItemEntry> spawns_logibag;
		spawns_logibag.push(addItemEntry('HDAmBox', lgb_replacement_spawn_bias));
		spawns_logibag.push(addItemEntry('HDAmBoxUnarmed', lgb_replacement_spawn_bias));
		spawns_logibag.push(addItemEntry('DeadRifleman', lgb_replacement_spawn_bias));
		spawns_logibag.push(addItemEntry('ReallyDeadRifleman', lgb_replacement_spawn_bias));
		addItem('HD_WildLogiBag', spawns_logibag, lgb_persistent_spawning, false);

		// Medical Backpack
		Array<WaresSpawnItemEntry> spawns_medibag;
		spawns_medibag.push(addItemEntry('PortableMedikit', mdb_replacement_spawn_bias));
		spawns_medibag.push(addItemEntry('DeadRifleman', mdb_replacement_spawn_bias));
		spawns_medibag.push(addItemEntry('ReallyDeadRifleman', mdb_replacement_spawn_bias));
		addItem('HD_WildMediBag', spawns_medibag, lgb_persistent_spawning, false);

		// Defib
		Array<WaresSpawnItemEntry> spawns_defib;
		spawns_defib.push(addItemEntry('PortableMedikit', dfb_replacement_spawn_bias));
		spawns_defib.push(addItemEntry('DeadRifleman', dfb_replacement_spawn_bias));
		spawns_defib.push(addItemEntry('ReallyDeadRifleman', dfb_replacement_spawn_bias));
		addItem('HDefib', spawns_defib, dfb_persistent_spawning, false);
		*/
	}
	
	// Fill above with entries for each weapon
	// Random stuff, stores it and forces negative values just to be 0.
	bool giveRandom(int chance)
	{
		if (chance > -1)
		{
			let result = random(0, chance);

			if (hd_debug) console.printf("Rolled a "..result.." out of "..(chance + 1));

			return result == 0;
		}

		return false;
	}

	// Tries to create the item via random spawning.
	bool tryCreateItem(Inventory item, WaresSpawnItem f, int g, bool rep)
	{
		if (giveRandom(f.spawnReplaces[g].chance))
		{
			if (Actor.Spawn(f.spawnName, item.pos) && rep)
			{
				if (hd_debug) console.printf(item.GetClassName().." -> "..f.spawnName);

				item.destroy();

				return true;
			}
		}

		return false;
	}

	override void worldthingspawned(worldevent e)
	{
		// Populates the main arrays if they haven't been already. 
		if (!cvarsAvailable) init();
		
		// If thing spawned doesn't exist, quit
		if (!e.Thing) return;

		// If thing spawned is blacklisted, quit
		for (let i = 0; i < blacklist.size(); i++) if (e.thing is blacklist[i]) return;

		string candidateName = e.Thing.GetClassName();
		candidateName = candidateName.makelower();

		// Pointers for specific classes.
		let ammo = HDAmmo(e.Thing);
		let item = Inventory(e.Thing);
		
		// If the thing spawned is an ammunition, add any and all items that can use this.
		if (ammo) handleAmmoUses(ammo, candidateName);

		// Return if range before replacing things.
		if (level.MapName ~== "RANGE") return;

		if (item) handleWeaponReplacements(item, ammo, candidateName);
	}

	private void handleAmmoUses(HDAmmo ammo, string candidateName)
	{
		// Goes through the entire ammospawn array.
		for (let i = 0; i < ammoSpawnList.size(); i++)
		{
			if (candidateName == ammoSpawnList[i].ammoName)
			{
				// Appends each entry in that ammo's subarray.
				for (let j = 0; j < ammoSpawnList[i].weaponNames.size(); j++)
				{
					// Actual pushing to itemsthatusethis().
					ammo.ItemsThatUseThis.Push(ammoSpawnList[i].weaponNames[j]);
				}
			}
		}
	}

	private void handleWeaponReplacements(Inventory item, HDAmmo ammo, string candidateName)
	{
		// Checks if the level has been loaded more than 1 tic.
		bool prespawn = !(level.maptime > 1);

		// Iterates through the list of item candidates for e.thing.
		for (let i = 0; i < itemSpawnList.size(); i++)
		{
			
			// if an item is owned or is an ammo (doesn't retain owner ptr), 
			// do not replace it. 
			if ((prespawn || itemSpawnList[i].isPersistent) && (!item.owner && (!ammo || prespawn)))
			{
				for (let j = 0; j < itemSpawnList[i].spawnReplaces.size(); j++)
				{
					if (itemSpawnList[i].spawnReplaces[j].name == candidateName)
					{
						if (hd_debug) console.printf("Attempting to replace "..candidateName.." with "..itemSpawnList[i].spawnName.."...");

						if (tryCreateItem(item, itemSpawnList[i], j, itemSpawnList[i].replaceItem)) return;
					}
				}
			}
		}
	}
}

//-------------------------------------------------
// MONSTERS
//-------------------------------------------------

// Trite controller
class TriteHandler : EventHandler
{    
    private int current_trites;
	private int max_trites;
	private int maxtospawn;

    void init()
    {
        current_trites = current_tritescvar;
		max_trites = max_tritescvar;
    }

	override void WorldLoaded(WorldEvent e)
	{
		// always calls init.
		init();
		super.WorldLoaded(e);
	}

    override void WorldThingSpawned(WorldEvent e)
    {
		if (e.thing && e.thing is "Trite")current_trites++; // this line of code wouldn't propegate properly to all of the spawners. You'd need to give each spawner a maximum number they can spawn. 
        let sss=TriteBarrel(e.thing);
        //if (sss)sss.maxtospawn = current_trites;
    }
} 

// Trite Barrels
class SpiderBarrelEventHandler : EventHandler
{
	private bool cvarsAvailable;

	private int spawnBiasActual;
	private bool isPersistent;
	
	// Shoves cvar values into their non-cvar shaped holes.
	// I have no idea why names for cvars become reserved here.
	// But, this works. So no complaints. 
	void init()
	{
		cvarsAvailable = true;
		spawnBiasActual = sbrl_regulars_spawn_bias;
		isPersistent = sbrl_persistent_spawning;
	}

	bool giveRandom(int chance)
	{
		if (chance > -1)
		{
			let result = random(0, chance);

			if (hd_debug) console.printf("Rolled a "..result.." out of "..(chance + 1));

			return result == 0;
		}

		return false;
	}

	bool tryCreateBarrel(worldevent e, int chance)
	{
		if (giveRandom(chance))
		{
			if (Actor.Spawn("TriteBarrel", e.thing.pos, SXF_TRANSFERSPECIAL | SXF_NOCHECKPOSITION))
			{
				if (hd_debug) console.printf(e.thing.GetClassName().." -> TriteBarrel");

				e.thing.destroy();

				return true;
			}
		}

		return false;
	}

	override void worldthingspawned(worldevent e)
	{
		// Makes sure the values are always loaded before
		// taking in events.
		if (!cvarsAvailable) init();
			
		// in case it's not real. 
		if (!e.Thing) return;
		
		// Checks if the level has been loaded more than 1 tic.
		bool prespawn = !(level.maptime > 1);
		
		// Don't spawn anything if the level has been loaded more than a tic. 
		if (prespawn || isPersistent)
		{

			switch(e.Thing.GetClassName())
			{
				case 'HDBarrel':
					if (hd_debug) console.printf("Attempting to replace "..e.Thing.GetClassName().." with TriteBarrel...");
					tryCreateBarrel(e, spawnBiasActual);
					break;
			}
		}
	}
}
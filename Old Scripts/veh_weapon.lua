--	Weapon/projectile replacement script by aLTis (altis94@gmail.com)
--	The script is currently set up to change a weapon of a vehicle
--	Another functionality of this script is to replace grenades
--	Note that this will remove the reticle from vehicles and projectiles will have no sounds and some effects
--	Also note that the script will not work the first match it was loaded unless the vehicles have spawned AFTER loading it
--	Reloading the script will NOT break anything though

--CONFIG

--	GRENADES
		replace_grenades = true
		
		--Which grenade tag do you want to replace?
		grenade_source_type_frag = "weapons\\frag grenade\\frag grenade"
		grenade_source_type_plasma = "weapons\\plasma grenade\\plasma grenade"
		
		--Grenade type will be random
		use_random_grenades = false
		
		--Which projectile do you want to use instead of grenade
		grenade_type_frag = 1
		grenade_type_plasma = 6
		
--	VEHICLES

		replace_vehicle_projectiles = true
		
		--	Which vehicle projectiles do you want to replace
		--	id = <directory>, <projectile id>, <projectile id>...
		--	Add more than 1 projectile ids if you want random projectiles
		VEHICLES = {
			[1] = {"vehicles\\ghost\\ghost_mp", 3},
			[2] = {"vehicles\\warthog\\mp_warthog", 7},
			[3] = {"vehicles\\c gun turret\\c gun turret_mp", 3, 5},
			[4] = {"vehicles\\banshee\\banshee_mp", 6},
			[5] = {"vehicles\\rwarthog\\rwarthog", 8},
			[6] = {"vehicles\\scorpion\\scorpion_mp", 4	},
		}
		
	--WEAPON MODS
		fire_rate = 10	-- Projectiles per second
		projectiles_per_shot = 1 -- How many projectiles to fire in one shot
		error_from = 0.00	-- accuracy when started firing (0-1; 0-pi rad)
		error_to = 0.03	-- accuracy when firing (0-1; 0-pi rad)
		
--IDS
		--Projectile type IDs:
		PROJECTILES = {
			[1]= "weapons\\rocket launcher\\rocket";
			[2]= "weapons\\needler\\needle";
			[3]= "weapons\\plasma rifle\\bolt";
			[4]= "weapons\\plasma_cannon\\plasma_cannon";
			[5]= "weapons\\plasma pistol\\bolt";
			[6]= "weapons\\plasma rifle\\charged bolt";
			[7]= "weapons\\sniper rifle\\sniper bullet";
			[8]= "vehicles\\c gun turret\\mp gun turret";
			[9]= "weapons\\plasma grenade\\plasma grenade";
			[10]= "weapons\\frag grenade\\frag grenade";
			[11]= "vehicles\\scorpion\\tank shell";
		}
	
--END OF CONFIG

api_version = "1.9.0.0"

PROJECTILE_IDS = {}
WEAPON_IDS = {}

function OnScriptLoad()
	GetMetaIDs()
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
end

function OnScriptUnload()
end

function OnGameStart()
	GetMetaIDs()
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentObjectID, ObjectID)
	if(WEAPON_IDS[1] == nil) then return true end
	if(replace_grenades and MetaID == grenade_source_frag) then
		local projectile = rand(1,7)
		if(use_random_grenades == false) then
			projectile = grenade_type_frag
		end
		return true, PROJECTILE_IDS[projectile]
	end
	if(replace_grenades and MetaID == grenade_source_plasma) then
		local projectile = rand(1,7)
		if(use_random_grenades == false) then
			projectile = grenade_type_plasma
		end
		return true, PROJECTILE_IDS[projectile]
	end
	
	if(replace_vehicle_projectiles == false) then return false end
	
	for i = 1,#WEAPON_IDS do
		if(MetaID == WEAPON_IDS[i]) then
			ModWeaponTag()
			return true, weapon_target
		end
	end
	
	if(MetaID == projectile_source) then
		--Don't change flamethrower's projectiles
		player_object = get_dynamic_player(PlayerIndex)
		if(player_object ~= 0) then
			local weapon_ID = read_dword(player_object + 0x118)
			local weapon_object = get_object_memory(weapon_ID)
			if(weapon_object ~= 0) then
				name = read_string(read_dword(read_word(weapon_object) * 32 + 0x40440038))
				if(name == "weapons\\flamethrower\\flamethrower") then
					return true
				end
			end
			local vehicle_objectid = read_dword(player_object + 0x11C)
			local vehicle_object = get_object_memory(vehicle_objectid)
			if(vehicle_object ~= 0) then
				local vehicle_name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
				for i = 1,#VEHICLES do
					if(VEHICLES[i][1] == vehicle_name) then
						local projectiles = {}
						for j =2,20 do
							if(VEHICLES[i][j] ~= nil) then
								projectiles[j-1] = VEHICLES[i][j]
							else
								break
							end
						end
						return true, PROJECTILE_IDS[projectiles[rand(1,#projectiles+1)]]
					end
				end
			end
		end
	end
end

function ModWeaponTag()
	local old_weapon = lookup_tag("weap", "weapons\\gravity rifle\\gravity rifle")
	local old_data = read_dword(old_weapon + 0x14)
	for i = 1,#VEHICLES do
		local vehicle = lookup_tag("vehi", VEHICLES[i][1])
		local vehicle_data = read_dword(vehicle + 0x14)
		local animation_id = read_dword(vehicle_data + 0x38 + 0xC)
		local animation = lookup_tag(animation_id)
		local animation_data = read_dword(animation + 0x14)
		local units = read_dword(animation_data + 0x0C + 4)
		local weapons = read_dword(units + 0x58 + 4)
		local weapon_types = read_dword(weapons + 0xB0 + 4)
		write_string(weapon_types, "ar")
	end
	
	local trigger_data = read_dword(old_data + 0x4FC + 4)
	
	write_bit(trigger_data, 3, 1)--	Does not repeat automatically
	write_bit(trigger_data, 5, 1)--	Uses weapon origin
	write_short(trigger_data + 0x22, 0)--			Rounds per shot; leave at 0 for infinite ammo
	write_float(trigger_data + 0x4, fire_rate)--	Rounds per second from
	write_float(trigger_data + 0x8, fire_rate)--	Rounds per second to
	write_short(trigger_data + 0x6E, projectiles_per_shot)--	Projectiles per shot
	write_float(trigger_data + 0x7C, error_from)--	Error from
	write_float(trigger_data + 0x80, error_to)--	Error to
	
	--Remove weapon model
	write_dword(old_data + 0x28, 0xffffffff)
	write_dword(old_data + 0x28 + 0xC, 0xffffffff)
end

function GetMetaIDs()
	cprint("	Getting IDs...")
	for i = 1,#VEHICLES do
		local tag_data = lookup_tag("vehi", VEHICLES[i][1])
		if(tag_data == 0) then
			cprint("	Something is wrong")
			cprint("	Could not read tag data of "..VEHICLES[i][1]..".vehi")
			return false
		end
			
		local vehicle_tag = read_dword(tag_data + 0x14)
		local first_weapon = read_dword(vehicle_tag + 0x2DC)
		local primary_weapon = read_string(read_dword(first_weapon + 4))
		WEAPON_IDS[i] = GetMetaID("weap", primary_weapon)
	end
	
	grenade_source_frag = GetMetaID("proj", grenade_source_type_frag)
	grenade_source_plasma = GetMetaID("proj", grenade_source_type_plasma)
	weapon_target = GetMetaID("weap", "weapons\\gravity rifle\\gravity rifle")
	projectile_source = GetMetaID("proj", "weapons\\flamethrower\\flame")
	
	for i = 1,#PROJECTILES do
		PROJECTILE_IDS[i] = GetMetaID("proj", PROJECTILES[i])
	end
	
	ModWeaponTag()
	return false
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= 0) then
		--cprint(object_dir..": "..address.."     "..read_dword(address + 0xC))
		return read_dword(address + 0xC)
	end
	return nil
end
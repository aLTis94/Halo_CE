--	Weapon/projectile replacement script by aLTis (altis94@gmail.com)
--	The script is currently set up to change a weapon of a vehicle
--	Another functionality of this script is to replace grenades
--	Note that this will remove the reticle from vehicles and projectiles will have no sounds and some effects

--CONFIG

--	GRENADES
		replace_grenades = true
		
		--Which grenade tag do you want to replace?
		grenade_source_type = "weapons\\frag grenade\\frag grenade"
		
		--Grenade type will be random
		use_random_grenades = false
		
		--Which projectile do you want to use instead of grenade
		grenade_type = 1
		
--	VEHICLES
		replace_vehicle_projectiles = true
		
		--Weapon tag you want to replace
		weapon_source_tag = "vehicles\\ghost\\mp_ghost gun"

		--Weapon will fire a random projectile type
		use_random_projectiles = false

		--Which projectile do you want to use if random projectiles are disabled
		projectile_type = 6
		
	--WEAPON MODS
		fire_rate = 5
		error_from = 0
		error_to = 0.01
		
	--IDS
		--Projectile type IDs:
		ID1= "weapons\\rocket launcher\\rocket"
		ID2= "weapons\\needler\\needle"
		ID3= "weapons\\plasma rifle\\bolt"
		ID4= "weapons\\plasma_cannon\\plasma_cannon"
		ID5= "weapons\\plasma pistol\\bolt"
		ID6= "weapons\\plasma rifle\\charged bolt"
		ID7= "weapons\\sniper rifle\\sniper bullet"
		ID8= "vehicles\\c gun turret\\mp gun turret"
		ID9= "weapons\\plasma grenade\\plasma grenade"
	
--END OF CONFIG

api_version = "1.9.0.0"

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
	if(weapon_source == nil) then return true end
	if(replace_grenades and MetaID == grenade_source) then
		local projectile = rand(1,7)
		--Specific projectile
		if(use_random_grenades == false) then
			projectile = grenade_type
		end
		return ChooseProjectile(projectile)
	end
	
	if(replace_vehicle_projectiles == false) then return false end
	
	if(MetaID == weapon_source) then
		ModWeaponTag()
		return true, weapon_target
	end
	
	--Choose random projectile
	if(MetaID == object_source2) then
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
		end
		local projectile = rand(1,7)
		--Specific projectile
		if(use_random_projectiles == false) then
			projectile = projectile_type
		end
		return ChooseProjectile(projectile)
	end
end

function ModWeaponTag()
	replacement_weapon = lookup_tag("weap", weapon_source_tag)
	tag_data = read_dword(replacement_weapon + 0x14)
	old_weapon = lookup_tag("weap", "weapons\\gravity rifle\\gravity rifle")
	old_data = read_dword(old_weapon + 0x14)
	
	--	Replace weapon tag label so the vehicle could hold it
	replacement_label = read_string(tag_data + 0x30C)
	write_string(old_data + 0x30C, replacement_label)
	
	trigger_data = read_dword(old_data + 0x4FC + 4)
	
	write_bit(trigger_data, 5, 1)
	write_short(trigger_data + 0x22, 0)--	Rounds per shot
	write_float(trigger_data + 0x4, fire_rate)--	Rounds per second from
	write_float(trigger_data + 0x8, fire_rate)--	Rounds per second to
	write_float(trigger_data + 0x7C, error_from)--	Error from
	write_float(trigger_data + 0x80, error_to)--	Error to
	
	weapon_model = lookup_tag("mod2", "weapons\\gravity rifle\\gravity rifle")
	model_data = read_dword(weapon_model + 0x14)
	
	marker_count = read_dword(model_data + 0xAC + 0)
	markers_address = read_dword(model_data + 0xAC + 4)
	
	for i=0,marker_count-1 do
		local struct = markers_address + i * 64
		if(read_string(struct) == "primary trigger") then
			write_string(struct, "rip")
		end
	end
	
end

function ChooseProjectile(projectile)
	if(projectile == 1) then
		return true, object_target1
	elseif(projectile == 2) then
		return true, object_target2
	elseif(projectile == 3) then
		return true, object_target3
	elseif(projectile == 4) then
		return true, object_target4
	elseif(projectile == 5) then
		return true, object_target5
	elseif(projectile == 6) then
		return true, object_target6
	elseif(projectile == 7) then
		return true, object_target7
	elseif(projectile == 8) then
		return true, object_target8
	elseif(projectile == 9) then
		return true, object_target9
	end
end

function GetMetaIDs()
	weapon_source = GetMetaID("weap", weapon_source_tag)
	if(weapon_source) == nil then
		return false
	end
	weapon_target = GetMetaID("weap", "weapons\\gravity rifle\\gravity rifle")
	
	grenade_source = GetMetaID("proj", grenade_source_type)
	object_source2 = GetMetaID("proj", "weapons\\flamethrower\\flame")
	
	object_target1 = GetMetaID("proj", ID1)
	object_target2 = GetMetaID("proj", ID2)
	object_target3 = GetMetaID("proj", ID3)
	object_target4 = GetMetaID("proj", ID4)
	object_target5 = GetMetaID("proj", ID5)
	object_target6 = GetMetaID("proj", ID6)
	object_target7 = GetMetaID("proj", ID7)
	object_target8 = GetMetaID("proj", ID8)
	object_target9 = GetMetaID("proj", ID9)
	
	ModWeaponTag()
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= 0) then
		--cprint(object_dir..": "..address.."     "..read_dword(address + 0xC))
		return read_dword(address + 0xC)
	end
	return nil
end
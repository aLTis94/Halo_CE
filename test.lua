--	Test

api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	
	weapon_source = GetMetaID("weap", "vehicles\\ghost\\mp_ghost gun")
	weapon_target = GetMetaID("weap", "weapons\\gravity rifle\\gravity rifle")
	
	object_source = GetMetaID("proj", "weapons\\frag grenade\\frag grenade")
	object_target = GetMetaID("proj", "weapons\\rocket launcher\\rocket")
	object_source2 = GetMetaID("proj", "weapons\\flamethrower\\flame")
	object_target2 = GetMetaID("proj", "weapons\\needler\\needle")
	object_target3 = GetMetaID("proj", "weapons\\plasma rifle\\bolt")
	object_target4 = GetMetaID("proj", "weapons\\plasma_cannon\\plasma_cannon")
	object_target5 = GetMetaID("proj", "weapons\\plasma pistol\\bolt")
	object_target6 = GetMetaID("proj", "weapons\\plasma rifle\\charged bolt")
	object_target7 = GetMetaID("proj", "weapons\\sniper rifle\\sniper bullet")
	object_target8 = GetMetaID("proj", "weapons\\plasma grenade\\plasma grenade")
end

function OnScriptUnload()
end

function OnGameStart()
	weapon_source = GetMetaID("weap", "vehicles\\ghost\\mp_ghost gun")
	weapon_target = GetMetaID("weap", "weapons\\gravity rifle\\gravity rifle")
	
	object_source = GetMetaID("proj", "weapons\\frag grenade\\frag grenade")
	object_target = GetMetaID("proj", "weapons\\rocket launcher\\rocket")
	object_source2 = GetMetaID("proj", "weapons\\flamethrower\\flame")
	object_target2 = GetMetaID("proj", "weapons\\needler\\needle")
	object_target3 = GetMetaID("proj", "weapons\\plasma rifle\\bolt")
	object_target4 = GetMetaID("proj", "weapons\\plasma_cannon\\plasma_cannon")
	object_target5 = GetMetaID("proj", "weapons\\plasma pistol\\bolt")
	object_target6 = GetMetaID("proj", "weapons\\plasma rifle\\charged bolt")
	object_target7 = GetMetaID("proj", "weapons\\sniper rifle\\sniper bullet")
	object_target8 = GetMetaID("proj", "weapons\\plasma grenade\\plasma grenade")
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentObjectID, ObjectID)
	if(MetaID == object_source) then
		return true, object_target
	end
	
	if(MetaID == weapon_source) then
		replacement_weapon = lookup_tag("weap", "vehicles\\ghost\\mp_ghost gun")
		replacement_label = read_string(read_dword(replacement_weapon + 0x14) + 0x30C)
		old_weapon = lookup_tag("weap", "weapons\\gravity rifle\\gravity rifle")
		write_string(read_dword(old_weapon + 0x14) + 0x30C, replacement_label)
		return true, weapon_target
	end
	
	if(MetaID == object_source2) then
		projectile = rand(1,7)
		projectile = 4
		if(projectile == 1) then
			return true, object_target
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
		end
	end
end

function OnPlayerSpawn(PlayerIndex)
	Weapon = spawn_object("weap", "weapons\\gravity rifle\\gravity rifle", 0, 0, 0)
	timer(100, "assign_weapon", Weapon, PlayerIndex)
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= nil) then
		return read_dword(address + 0xC)
	end
	return nil
end
--	Oddball respawn script by aLTis. Thanks to 002 for helping me read globals tag
--	This script will respawn oddball if it goes below a given z coordinate

--	CONFIG

debug_mode = false

--	Use global z value for all maps unless listed in the MAPS table

use_global_z = true
global_z = -25

--	Map name and z coordinate below which oddball is removed
MAPS = {
	["gephyrophobia"] = -25,
	["damnation"] = -1,
	["boardingaction"] = -10,
}

--	When object spawns, its coordinates will be checked after this delay (33 seems to work fine)
spawned_object_check = 33

--	How often to check object's z coordinate
check_z_delay = 100

--	END OF CONFIG

api_version = "1.9.0.0"

x = nil
y = nil
z = nil
map_z = nil
game_ended = false
ball_id = nil

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	GetOdballID()
end

function OnGameEnd()
	game_ended = true
	map_z = nil
end

function OnGameStart()
	timer(5000, "GetOdballID")
end

function GetOdballID()
	game_ended = false
	ball_id = read_dword(read_dword(read_dword(lookup_tag("matg","globals\\globals") + 0x14) + 0x164 + 4) + 0x4C + 0xC)
	local map = get_var(1,"$map")
	map_z = MAPS[map]
	if(use_global_z and map_z == nil) then
		map_z = global_z
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ObjectID)
	if(debug_mode) then rprint(1, "Object has spawned") end
	timer(spawned_object_check, "ObjectCheck", ObjectID)
end

function ObjectCheck(ObjectID)
	if(map_z == nil) then return false end
	if(ObjectID == nil) then return true end
	local WeaponObj = get_object_memory(tonumber(ObjectID))
	
	if(WeaponObj ~= 0) then
		local MetaID = read_dword(WeaponObj)
		if(MetaID == ball_id) then
			if(debug_mode) then rprint(1, "Oddball has spawned") end
			x, y, z = read_vector3d(WeaponObj + 0x5C)
			timer(check_z_delay, "CheckZ", ObjectID)
		end
	end
end

function CheckZ(ObjectID)
	if(game_ended) then return false end
	
	WeaponObj = get_object_memory(tonumber(ObjectID))
	if(WeaponObj == 0) then
		return false
	end
	
	if(read_float(WeaponObj + 0x64) < map_z) then
		if(debug_mode) then rprint(1, "Oddball has respawned") end
		write_vector3d(WeaponObj + 0x5C, x, y, z)
		write_vector3d(WeaponObj + 0x68, 0, 0, 0)
	end
	
	return true
end

function OnScriptUnload() end
--	Oddball respawn script V2.0 by aLTis. Thanks to 002 for helping me read globals tag
--	This script will respawn oddball if it goes below a given z coordinate

--	CONFIG

debug_mode = false

--	Use global z value for all maps unless listed in the MAPS table

use_global_z = false
global_z = -25

--	Map name and z coordinate below which oddball is removed
MAPS = {
	["gephyrophobia"] = -25,
	["damnation"] = -1,
	["snowdrop"] = -10,
}

--	When object spawns, its coordinates will be checked after this delay (33 seems to work fine)
spawned_object_check = 33

--	How often to check object's z coordinate
check_z_delay = 100

--	END OF CONFIG

api_version = "1.9.0.0"

game_ended = false
ODDBALLS = {}
ODDBALL_SPAWNPOINTS = {}

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	register_callback(cb["EVENT_TICK"],"OnTick")
	timer(30, "GetOdballID")
end

function OnGameEnd()
	ODDBALLS = {}
	game_ended = true
	map_z = nil
end

function OnGameStart()
	ball_id = nil
	ODDBALLS = {}
	timer(5000, "GetOdballID")
	ODDBALL_SPAWNPOINTS = {}
end

function OnTick()
	if get_var(0, "$gt") ~= "oddball" then return false end
	for ID, value in pairs (ODDBALLS) do
		local object = get_object_memory(ID)
		if object ~= 0 then
			if read_dword(object + 0x11C) == 0xFFFFFFFF then
				local x,y,z = read_vector3d(object + 0x5C)
				if(read_float(object + 0x64) < map_z) then
					if #ODDBALL_SPAWNPOINTS > 0 then
						local loc = ODDBALL_SPAWNPOINTS[math.random(#ODDBALL_SPAWNPOINTS)]
						if(debug_mode) then rprint(1, "Oddball has respawned to "..loc[1].."  "..loc[2].."  "..loc[3]) end
						write_vector3d(object + 0x5C, loc[1], loc[2], loc[3]+0.1)
						write_vector3d(object + 0x68, 0, 0, 0)
					end
				end
			end
		else
			ODDBALLS[ID] = nil
		end
	end
end

function GetOdballID()
	game_ended = false
	local globals = GetGlobals()
	if globals == nil then return false end
	ball_id = read_dword(read_dword(globals + 0x164 + 4) + 0x4C + 0xC)
	
	FindOddballObjects()
	CheckScenario()
	
	local map = get_var(0,"$map")
	map_z = MAPS[map]
	if map_z == nil then
		if use_global_z then
			map_z = global_z
		else
			map_z = lowest_map_z
		end
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	if get_var(0, "$gt") == "oddball" then
		if MetaID == ball_id then
			if(debug_mode) then rprint(1, "Oddball has spawned") end
			ODDBALLS[ID] = true
		end
	end
end

function CheckScenario()
	lowest_map_z = 10000
	
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_data = read_dword(scenario_tag + 0x14)
	netgame_flag_count = read_dword(scenario_data + 0x378)
	netgame_flags = read_dword(scenario_data + 0x378 + 4)
	for i=0,netgame_flag_count-1 do
		local current_flag = netgame_flags + i*148
		local flag_type = read_word(current_flag + 0x10)
		local x,y,z = read_vector3d(current_flag)
		if z < lowest_map_z then
			lowest_map_z = z
		end
		if flag_type == 2 then
			table.insert(ODDBALL_SPAWNPOINTS, {x, y, z})
		end
	end
	
	local starting_location_reflexive = scenario_data + 0x354
    starting_location_count = read_dword(starting_location_reflexive)
    local starting_location_address = read_dword(starting_location_reflexive + 0x4)
	for i=0,starting_location_count-1 do
        local starting_location = starting_location_address + 52 * i
		local x,y,z = read_vector3d(starting_location)
		if z < lowest_map_z then
			lowest_map_z = z
		end
	end
	lowest_map_z = lowest_map_z - 5
end

function OnScriptUnload() end

function FindOddballObjects()
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 and object ~= 0xFFFFFFFF then
			if read_dword(object) == ball_id then
				if(debug_mode) then rprint(1, "Oddball was found!") end
				ODDBALLS[ID] = true
			end
		end
	end
end

function GetGlobals() -- taken from 002's headshots script
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6D617467 then
            return read_dword(tag + 0x14)
		end
	end
	return nil
end
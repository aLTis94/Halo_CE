-- Force Vehicle Respawn script by aLTis (took some stuff from giraffe's script)
-- This script should respawn vehicles that get stuck
-- It will NOT respawn vehicles that spawned AFTER the game has starter (for example Falcon after it was destroyed)

-- Configuration
 
-- Vehicle respawn time (should be 60)
RESPAWN_TIME = 60

-- Vehicles that you want to force spawn
VEHICLES = {
    --{ "bourrin\\halo reach\\vehicles\\warthog\\h2 mp_warthog"},
	--{ "bourrin\\halo reach\\vehicles\\warthog\\reach gauss hog"},
	--{ "bourrin\\halo reach\\vehicles\\warthog\\rocket warthog"},
    --{ "altis\\vehicles\\mongoose\\mongoose"},
	--{ "altis\\vehicles\\mortargoose\\mortargoose"},
	{"vehicles\\banshee\\banshee_mp"},
	{"vehicles\\ghost\\ghost_mp"},
	{"vehicles\\rwarthog\\rwarthog"},
	{"vehicles\\scorpion\\scorpion_mp"},
	{"vehicles\\warthog\\mp_warthog"},
}
 
-- End of configuration
 
GAME_STARTED = true
GAME_ENDED = false

api_version = "1.9.0.0"
 
function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'], "OnGameStart")
    register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
    register_callback(cb['EVENT_OBJECT_SPAWN'], "OnObjectSpawn")
end

function SpawnTheActualVehicle(vehicle_name, x, y, z, a, b, c, d)
	respawnedVehicleID = spawn_object("vehi", vehicle_name, x, y, (z-0.45), 0)
    respawnedVehicle = get_object_memory(respawnedVehicleID)
    if(respawnedVehicle ~= nil) then
		write_float(respawnedVehicle + 0x76, a)
        write_float(respawnedVehicle + 0x7A, b)
        write_float(respawnedVehicle + 0x7E, c)
        write_float(respawnedVehicle + 0x82, d)
		despawn_vehicle(respawnedVehicleID, RESPAWN_TIME, x, y, z, a, b, c, d)
    end
end

function RespawnVehicle(ObjectID, x, y, z, a, b, c, d)
	local vehicle_object = get_object_memory(ObjectID)
	if(vehicle_object == nil) then return true end
	local name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
	vehicle_name = string.format("%s", name)
	timer(33, "SpawnTheActualVehicle", vehicle_name, x, y, z, a, b, c, d)
	destroy_object(ObjectID)
    return false
end

function FindVehicleTag(TagName)
    local tag_array = read_dword(0x40440000)
    for i=0,read_word(0x4044000C)-1 do
        local tag = tag_array + i * 0x20
        if(read_dword(tag) == 1986357353 and read_string(read_dword(tag + 0x10)) == TagName) then
            return tag + 0x14
        end
    end
end

function OnGameStart()
	timer(4000, "reset_game")
end

function OnGameEnd()
	GAME_ENDED = true
	timer(16000, "end_game")
end

function end_game()
	GAME_ENDED = false
	GAME_STARTED = true
	--say_all("GAME STARTED")
end

function reset_game()
    GAME_STARTED = false
	--say_all("GAME RESET")
end

function SpawnedVehicleCheck(ObjectID, vehicle_name)
        local object = get_object_memory(ObjectID)
        if(object ~= 0) then
            if(read_byte(object + 0xB4) == 0x01) then
                local tagDataAddress = read_dword(0x40440000) + read_word(object) * 0x20 + 0x14  
                    if(tagDataAddress == FindVehicleTag(vehicle_name)) then
                        local x, y, z = read_vector3d(object + 0x5c)
                        local a = read_float(object + 0x76)
                        local b = read_float(object + 0x7A)
                        local c = read_float(object + 0x7E)
                        local d = read_float(object + 0x82)
                        despawn_vehicle(ObjectID, RESPAWN_TIME, x, y, z, a, b, c, d)
                    end
            end
        end
end

function despawn_vehicle(ObjectID, wait, x, y, z, a, b, c, d)
	if(GAME_ENDED) then 
	return false end
	for i=1,16 do
		if(player_alive(i) == true) then 
			if(tonumber(ObjectID) ~= 0xFFFFFFFF) then
				local newVehicle = get_object_memory(ObjectID)
				local player_object = get_dynamic_player(i)
				local vehicle_objectid = read_dword(player_object + 0x11C)
				if(tonumber(vehicle_objectid) ~= 0xFFFFFFFF) then
					local vehicle_object = get_object_memory(vehicle_objectid)
					--execute_command("rprint 1 player_is_in_a_vehicle")
					if(vehicle_object == newVehicle) then
						--execute_command("rprint 1 player_is_in_a_SPAWNED_vehicle!")
						wait = RESPAWN_TIME
					end
				end
			end
		end
	end
	--execute_command("rprint 1 \""..wait.."\"")
	if(tonumber(wait) > 0) then
		wait = (wait - 1)
		--say_all("x,y,z = "..x.." "..y.." "..z)
		timer(1000, "despawn_vehicle", ObjectID, wait, x, y, z, a, b, c, d)
	else
		RespawnVehicle(ObjectID, x, y, z, a, b, c, d)
		return false
	end
end

function ObjectCheck(ObjectID)
	if(ObjectID == nil) then return true end
	local vehicle_object = get_object_memory(ObjectID)
	if(vehicle_object == nil or vehicle_object == 0) then return true end
	local name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
	if(name == nil) then return true end
	vehicle_name = string.format("%s", name)
	--say_all(vehicle_name)
	for k, v in pairs(VEHICLES) do
		if(vehicle_name == v[1]) then
			SpawnedVehicleCheck(ObjectID, vehicle_name)
		end
	end
end

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)
	if(GAME_STARTED) then
		timer(0, "ObjectCheck", ObjectID)
	end
    return true
end

function OnScriptUnload() end
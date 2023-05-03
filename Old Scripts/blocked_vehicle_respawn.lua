-- Force Vehicle Respawn script by aLTis (took some stuff from giraffe's script)
-- This script should respawn vehicles that get stuck
-- It will NOT respawn vehicles that spawned AFTER the game has starter (for example Falcon after it was destroyed)

--	THIS SCRIPT IS FUCKING GARBAGE


-- Configuration
 
-- Vehicle respawn time
RESPAWN_TIME = 61*10

-- Vehicles that you want to force spawn
VEHICLES = {
    --{ "bourrin\\halo reach\\vehicles\\warthog\\h2 mp_warthog"},
	--{ "bourrin\\halo reach\\vehicles\\warthog\\reach gauss hog"},
	--{ "bourrin\\halo reach\\vehicles\\warthog\\rocket warthog"},
    --{ "altis\\vehicles\\mongoose\\mongoose"},
	--{ "altis\\vehicles\\mortargoose\\mortargoose"},
	--{ "altis\\vehicles\\spade\\spade"},
	--{ "vehicles\\newhog\\newhog mp_warthog"},
	--{ "vehicles\\falcon_destroyed\\falcon_destroyed"},
	--{ "altis\\vehicles\\truck_destroyed\\truck_destroyed"},
	--{ "altis\\vehicles\\truck_katyusha\\truck_katyusha"},
	{"vehicles\\banshee\\banshee_mp"},
	{"vehicles\\ghost\\ghost_mp"},
	{"vehicles\\rwarthog\\rwarthog"},
	{"vehicles\\scorpion\\scorpion_mp"},
	{"vehicles\\warthog\\mp_warthog"},
}
 
 --	If the vehicle is further than this distance from spawn then it will be respawned
max_distance = 0.3

-- End of configuration
 
 api_version = "1.9.0.0"
 
GAME_STARTED = true
GAME_ENDED = false
VEHICLE_LOCATIONS = {}

 
function OnScriptLoad()
    register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
    register_callback(cb['EVENT_OBJECT_SPAWN'], "OnObjectSpawn")
	
end

function RespawnVehicle(ObjectID, RespawnID)
	local vehicle_object = get_object_memory(ObjectID)
	if(vehicle_object == 0) then return true end
	local name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
	destroy_object(ObjectID)
	local id = VEHICLE_LOCATIONS[tonumber(RespawnID)]
	ObjectID = spawn_object("vehi", name, id[3], id[4], id[5], 0)
    respawnedVehicle = get_object_memory(ObjectID)
	
	if(respawnedVehicle ~= nil) then
        --timer(33, "RotateVehicle", ObjectID, id[6], id[7], id[8])
		write_float(respawnedVehicle + 0x76, id[6])
        write_float(respawnedVehicle + 0x7A, id[7])
        write_float(respawnedVehicle + 0x7E, id[8])
        write_float(respawnedVehicle + 0x82, id[9])
        id[2] = ObjectID
		despawn_vehicle(ObjectID, RESPAWN_TIME, RespawnID)
    end
    return false
end

function RotateVehicle(ObjectID, a, b, c)
	local vehicle_object = get_object_memory(ObjectID)
	if(vehicle_object == 0) then return true end
	--write_vector3d(vehicle_object + 0x550, a, b, c)
	write_float(vehicle_object + 0x550, a)
	cprint(b)
end

function despawn_vehicle(ObjectID, wait, RespawnID)
	if(GAME_ENDED) then return false end
	local newVehicle
	
	for i=1,16 do
		if(player_alive(i) == true) then 
			if(tonumber(ObjectID) ~= 0xFFFFFFFF) then
				newVehicle = get_object_memory(ObjectID)
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
		timer(100, "despawn_vehicle", ObjectID, wait, RespawnID)
	else
		if(FindDistance(newVehicle, RespawnID) > max_distance) then
			say_all("A vehicle has been forced to respawn! respawned")
			RespawnVehicle(ObjectID, RespawnID)
			return false
		else
			despawn_vehicle(ObjectID, RESPAWN_TIME, RespawnID)
			return false
		end
	end
end

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)
	timer(33, "ObjectCheck", ObjectID)
    return true
end

function ObjectCheck(ObjectID)
	if(ObjectID == nil) then return true end
	local vehicle_object = get_object_memory(ObjectID)
	if(vehicle_object == nil or vehicle_object == 0) then return true end
	local name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
	if(name == nil) then return true end
	vehicle_name = string.format("%s", name)
	
	for k, v in pairs(VEHICLES) do
		if(vehicle_name == v[1]) then
			SpawnedVehicleCheck(ObjectID)
			return false
		end
	end
end

function SpawnedVehicleCheck(ObjectID)
    local object = get_object_memory(ObjectID)
		
    if(object ~= 0) then--	Object exists
        if(read_byte(object + 0xB4) == 0x01) then--	Object is a vehicle
			--	Check if object is already in the list already
			for i = 1, #VEHICLE_LOCATIONS do
				local id = VEHICLE_LOCATIONS[i]
				if(tonumber(id[2]) == tonumber(ObjectID)) then
					return false
				end
			end
			
			local RespawnID = #VEHICLE_LOCATIONS + 1
            --local x, y, z = read_vector3d(object + 0x52C)
			local x, y, z = read_vector3d(object + 0x5c)
            --local a, b, c = read_vector3d(object + 0x550)
			local a = read_float(object + 0x76)
            local b = read_float(object + 0x7A)
            local c = read_float(object + 0x7E)
            local d = read_float(object + 0x82)
			table.insert(VEHICLE_LOCATIONS, {RespawnID, ObjectID, x, y, z, a, b, c, d})
            despawn_vehicle(ObjectID, RESPAWN_TIME - 2, RespawnID)
        end
    end
end

function FindDistance(newVehicle, RespawnID)
	local a = VEHICLE_LOCATIONS[tonumber(RespawnID)]
	local x,y,z = read_vector3d(newVehicle + 0x5c)
	return math.sqrt(math.pow(x - a[3],2) + math.pow(y - a[4],2) + math.pow(z - a[5],2))
end

function OnGameEnd()
	GAME_ENDED = true
	timer(16000, "end_game")
end

function end_game()
	GAME_ENDED = false
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

function OnScriptUnload() end
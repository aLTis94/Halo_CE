-- Vehicle destruction script by giraffe, edited by aLTis (altis94@gmail.com)

--	This script will make a few vehicles such as warthog and mongoose explode when driver dies.
--	Vehicle only explodes if driver was killed by specific damage effects (explosions)
--	The script should ONLY be used on BigassV3!



--	WARNING! Only works after a new game has started
-- WARNING!!!!!!!!! passenger may not respawn after vehicle exploded
--	a vehicle may not explode but it respawns creating a duplicate

-- Config
 
 debug_mode = false
 
-- Assuming driver is first seat in vehicle tag then leave at 0
SEAT_INDEX = 0

-- In seconds, the amount of time to keep a destroyed vehicle spawned
DESTROY_TIME = 60

-- True or false, whether you want SAPP to respawn starting vehicles after DESTROY_TIME has elapsed
RESPAWN_STARTING_VEHICLES = true

-- Respawn timer
RESPAWN_TIME = 60
 
-- First vehicle is the destroyable vehicle, second vehicle is the destroyed variant
VEHICLES = {
    { "bourrin\\halo reach\\vehicles\\warthog\\h2 mp_warthog", "bourrin\\halo reach\\vehicles\\warthog\\warthog_destroyed" },
	{ "bourrin\\halo reach\\vehicles\\warthog\\reach gauss hog", "bourrin\\halo reach\\vehicles\\warthog\\warthog_destroyed" },
	{ "bourrin\\halo reach\\vehicles\\warthog\\rocket warthog", "bourrin\\halo reach\\vehicles\\warthog\\warthog_destroyed" },
    { "altis\\vehicles\\mongoose\\mongoose", "altis\\vehicles\\mongoose\\mongoose destroyed" },
	{ "altis\\vehicles\\mortargoose\\mortargoose", "altis\\vehicles\\mongoose\\mongoose destroyed" },
	{ "halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\military truck mp", "altis\\vehicles\\truck_destroyed\\truck_destroyed"},
}

--	Will vehicle get destroyed from any type of damage
use_any_damage = true

--	paths of damage effects that will destroy the vehicles
DAMAGES = {
	[0] = "h2\\weapons\\grenade\\fragmentation_grenade\\explosion",--		frag grenade
	[1] = "weapons\\rocket launcher\\mine",-- 		trip mine
	[2] = "bourrin\\effects\\explosions\\medium\\gauss explosion", --		gauss
	[3] = "zteam\\objects\\weapons\\single\\spartan_laser\\h3\\laser", --	spartan laser
	[4] = "altis\\scenery\\capsule2\\bam", -- 		binoculars
	[5] = "bourrin\\effects\\explosions\\medium\\small exp rl metal metal xd", -- rocket launcher
	[6] = "vehicles\\scorpion\\bomb explosion", --	tank shell
	[7] = "bourrin\\effects\\explosions\\medium\\small exp", --	rocket hog
	[8] = "bourrin\\effects\\explosions\\medium\\warthog gauss explosion", -- gauss hog
}
--	How long "LAST_DAMAGE" lasts in ms
damage_time = 200

--	If the vehicle is further than this distance from spawn then it will be respawned
max_distance = 0.2
 
-- End of config
 
LAST_DAMAGE = {}
TAG_DATA = {}
STARTING_VEHICLES = {}
STARTING_OBJECT_IDS = {}
GAME_STARTED = false
GAME_COUNT = 1

api_version = "1.9.0.0"
 
function OnScriptLoad()
    register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
    register_callback(cb['EVENT_GAME_START'], "OnGameStart")
    register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
    register_callback(cb['EVENT_OBJECT_SPAWN'], "OnObjectSpawn")
	register_callback(cb['EVENT_DAMAGE_APPLICATION'], "OnDamage")
end

function ResetDamage(PlayerIndex)
	LAST_DAMAGE[tonumber(PlayerIndex)] = nil
end

function DirOfTag(MetaID)
    local tag = lookup_tag(MetaID)
    if tag ~= 0 then
        local path = read_string(read_dword(tag + 0x10))
        return path
    end
end

function OnDamage(PlayerIndex, Causer, MetaID)
	local name = DirOfTag(MetaID)
	for i=0,8 do
		if(name == DAMAGES[i]) then
			LAST_DAMAGE[PlayerIndex] = 1
			timer(damage_time, "ResetDamage", PlayerIndex)
		end
	end
end

function OnPlayerDeath(PlayerIndex)
	if(use_any_damage == false) then
		if(LAST_DAMAGE[PlayerIndex] == nil) then return false end
	end
    local player = get_dynamic_player(PlayerIndex)
    local vehicle = read_dword(player + 0x11C)
    local seatIndex = read_byte(player + 0x2F0)
    local vehicleObject = get_object_memory(vehicle)
			
			
    if(vehicleObject ~= 0 and seatIndex == SEAT_INDEX) then
 
        local destroyedVehicle = nil
        local vehicleName = nil
        local tagDataAddress = read_dword(0x40440000) + read_word(vehicleObject) * 0x20 + 0x14  
 
		--	Check if the destroyed vehicle is one of starting vehicles
        local count = 0
        for _,v in pairs(TAG_DATA) do
            count = count + 1
            if(tagDataAddress == v[2]) then
                vehicleName = v[1]
                destroyedVehicle = count
            end
        end

        local startingVehicleIndex = nil
        count = 0
        for _,v in pairs(STARTING_VEHICLES) do
            count = count + 1
            if(vehicle == v[1]) then startingVehicleIndex = count end
        end
 
		--	Kill all riders
        if(destroyedVehicle ~= nil) then
		for i=1,16 do
			if(i ~= PlayerIndex and player_alive(i)) then
				local tempVehicleID = read_dword(get_dynamic_player(i) + 0x11C)
				if(tonumber(tempVehicleID) == tonumber(vehicle)) then 
					kill(i)
				end
				tempVehicle = nil
			end
		end
            timer(33, "get_destroyed_vehicle_info", vehicle, destroyedVehicle)
            if(startingVehicleIndex ~= nil) then
                timer(67 + (1000 * RESPAWN_TIME), "respawn_vehicle", startingVehicleIndex, vehicleName, GAME_COUNT)
            end
        end
    end
end

function get_destroyed_vehicle_info(vehicle, destroyedVehicle)
    local vehicleObject = get_object_memory(vehicle)
    if(vehicleObject == 0) then return false end

    local x, y, z = read_vector3d(vehicleObject + 0x5c)
 
    local a = read_float(vehicleObject + 0x76)
    local b = read_float(vehicleObject + 0x7A)
    local c = read_float(vehicleObject + 0x7E)
    local d = read_float(vehicleObject + 0x82)
 
	for i=1,16 do
		if(player_alive(i)) then
			local tempVehicleID = read_dword(get_dynamic_player(i) + 0x11C)
			if(tonumber(tempVehicleID) == tonumber(vehicle)) then 
				say_all("One of vehicle's riders didn't die. This would have caused a glitch before :o")
				kill(i)
				return true
			end
			tempVehicle = nil
		end
	end
	
    destroy_object(vehicle)
	timer(33, "create_destroyed_vehicle", vehicle, destroyedVehicle, a, b, c, d, x, y, z)
    return false
end

function create_destroyed_vehicle(vehicle, destroyedVehicle, a, b, c, d, x, y, z)
	if(get_object_memory(vehicle) ~= 0) then 
		if(debug_mode) then say_all("A vehicle took a bit too long to explode.") end
		return true
	end
	if(debug_mode) then say_all("A vehicle was destroyed") end
    newVehicleID = spawn_object("vehi", VEHICLES[tonumber(destroyedVehicle)][2], x, y, z, 0)
    newVehicle = get_object_memory(newVehicleID)
    if(newVehicle ~= nil) then
        write_float(newVehicle + 0x76, a)
        write_float(newVehicle + 0x7A, b)
        write_float(newVehicle + 0x7E, c)
        write_float(newVehicle + 0x82, d)
    end

    timer(1000 * DESTROY_TIME, "destroy_vehicle", newVehicleID, GAME_COUNT)

	return false
end

function destroy_vehicle(ObjectID, gameCount)
    if(tonumber(gameCount) ~= GAME_COUNT) then return false end
    destroy_object(ObjectID)
    return false
end

function despawn_vehicle(startingVehicleIndex, vehicleName, gameCount, ObjectID, wait)
	local newVehicle = get_object_memory(ObjectID)
	if(debug_mode) then rprint(1, newVehicle) end
	if(newVehicle == 0) then 
		if(debug_mode) then say_all("a vehicle was removed...") end
		return false
	end
	for i=1,16 do
		if(player_alive(i) == true) then 
			if(tonumber(ObjectID) ~= 0xFFFFFFFF) then
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
		timer(1000, "despawn_vehicle", startingVehicleIndex, vehicleName, gameCount, ObjectID, wait)
		return false
	else
		if(FindDistance(newVehicle, startingVehicleIndex) > max_distance) then
			destroy_object(ObjectID)
			if(debug_mode) then say_all("A new vehicle is respawning...") end
			timer(33, "respawn_vehicle", startingVehicleIndex, vehicleName, gameCount)
			return false
		else
			if(debug_mode) then say_all("A vehicle is in the spawn") end
			despawn_vehicle(startingVehicleIndex, vehicleName, gameCount, ObjectID, RESPAWN_TIME)
			return false
		end
	end
end

function respawn_vehicle(startingVehicleIndex, vehicleName, gameCount)
	if(debug_mode) then say_all("A vehicle respawned") end
    if(not RESPAWN_STARTING_VEHICLES or tonumber(gameCount) ~= GAME_COUNT) then return false end
    local a = STARTING_VEHICLES[tonumber(startingVehicleIndex)]
    respawnedVehicleID = spawn_object("vehi", vehicleName, a[2], a[3], a[4], 0)
    respawnedVehicle = get_object_memory(respawnedVehicleID)
    if(respawnedVehicle ~= nil) then
        write_float(respawnedVehicle + 0x76, a[5])
        write_float(respawnedVehicle + 0x7A, a[6])
        write_float(respawnedVehicle + 0x7E, a[7])
        write_float(respawnedVehicle + 0x82, a[8])
        STARTING_VEHICLES[tonumber(startingVehicleIndex)][1] = respawnedVehicleID
		despawn_vehicle(startingVehicleIndex, vehicleName, gameCount, respawnedVehicleID, RESPAWN_TIME)
    end
    return false
end

function FindDistance(vehicle, startingVehicleIndex)
	local a = STARTING_VEHICLES[tonumber(startingVehicleIndex)]
	local x,y,z = read_vector3d(vehicle + 0x5c)
	return math.sqrt(math.pow(x - a[2],2) + math.pow(y - a[3],2) + math.pow(z - a[4],2))
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
    local count = 0
    for _,v in pairs(VEHICLES) do
        count = count + 1
        TAG_DATA[count] = { VEHICLES[count][1], FindVehicleTag(VEHICLES[count][1]) }
    end
    start_vehicle_check()
end

function OnGameEnd()
    TAG_DATA = {}
    STARTING_VEHICLES = {}
    STARTING_OBJECT_IDS = {}
    GAME_COUNT = GAME_COUNT + 1
    timer(15000, "reset_game")
end

function reset_game()
    GAME_STARTED = false
    return false
end

function start_vehicle_check()
    for _,id in pairs(STARTING_OBJECT_IDS) do
        local object = get_object_memory(id)
        if(object ~= 0) then
            if(read_byte(object + 0xB4) == 0x01) then
                local tagDataAddress = read_dword(0x40440000) + read_word(object) * 0x20 + 0x14  
                local count = 0
                for _,v in pairs(TAG_DATA) do
                    count = count + 1
                    if(tagDataAddress == v[2]) then
                        local x, y, z = read_vector3d(object + 0x5c)
                        local a = read_float(object + 0x76)
                        local b = read_float(object + 0x7A)
                        local c = read_float(object + 0x7E)
                        local d = read_float(object + 0x82)
                        table.insert(STARTING_VEHICLES, {id, x, y, z, a, b, c, d})
                    end
                end
            end
        end
    end
    STARTING_OBJECT_IDS = {}
end

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)
    if(RESPAWN_STARTING_VEHICLES and not GAME_STARTED) then
        table.insert(STARTING_OBJECT_IDS, ObjectID)
    end
    return true
end

function OnScriptUnload() end
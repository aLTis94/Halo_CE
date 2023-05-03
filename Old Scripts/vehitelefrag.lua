-- Vehicle telefragger script by 002 v1.0.0
-- Configuration

-- Action to take if a vehicle is clogging the teleporter.
-- 1 = Launch vehicle into the air
-- 2 = Respawn vehicle (requires that vehicular respawning is enabled)
ACTION_TO_TAKE = 2

-- Time until action is taken in seconds
ACTION_TIME = 0.5

-- Telefrag all passengers in the vehicle. Otherwise, they're ejected.
TELEFRAG_PASSENGERS = false

-- Warning given
-- Variables: $SECONDS = ACTION_TIME
WARNING_MESSAGE = "Your vehicle is blocking the teleporter. You have $SECONDS to move your vehicle."

-- End of configuration



api_version = "1.9.0.0"

-- {x, y, z}
teleporter_channels = {}
teleporter_entrances = {}
teleporter_exits = {}
X = {}
Y = {}
Z = {}

-- {objectid, timeblocked}
blocking_vehicles = {}


function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
    register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
    register_callback(cb['EVENT_TICK'],"OnTick")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
end

function OnScriptUnload()

end

function DistanceFormula(x1,y1,z1,x2,y2,z2)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ObjectID)
	timer(33, "ObjectCheck", ObjectID)
end

function ObjectCheck(ObjectID)
	if(ObjectID == nil) then return true end
	local object_memory = get_object_memory(ObjectID)
	if(object_memory ~= 0) then
		if(read_word(object_memory + 0xB4) == 1) then
			X[ObjectID], Y[ObjectID], Z[ObjectID] = read_vector3d(object_memory + 0x5c)
		end
	end
end

function OnTick()
    local time = os.clock()
    local blocking_right_now = {}
    for i=1,16 do
        local player_dyn = get_dynamic_player(i)

        -- Check if player is valid
        if(player_dyn ~= 0) then
            local vehicle_objectid = read_dword(player_dyn + 0x11C)
            local vehicle_object = get_object_memory(vehicle_objectid)
            -- Check if player is not inside vehicle
            if(vehicle_object == 0) then
                local x,y,z = read_vector3d(player_dyn + 0x5C)
                for channel=1,#(teleporter_channels) do
                    for entrance=1,#(teleporter_entrances[teleporter_channels[channel]]) do
                        local entrance_table = teleporter_entrances[teleporter_channels[channel]][entrance]

                        -- Check if player is within teleporting distance (0.5 world units)
                        if(DistanceFormula(x,y,z,entrance_table[1],entrance_table[2],entrance_table[3]) <= 1) then
                            -- Search for vehicles
                            for key,value in pairs(X) do
                                local object_memory = get_object_memory(key)

                                -- Check if object is valid
                                if(object_memory ~= 0) then

                                    -- Check if object is a vehicle
                                    if(read_word(object_memory + 0xB4) == 1) then
                                        local x,y,z = read_vector3d(object_memory + 0x5C)
                                        for exit=1,#(teleporter_exits[teleporter_channels[channel]]) do
                                            local exit_table = teleporter_exits[teleporter_channels[channel]][exit]

                                            -- Check if object is within blocking distance
                                            if(DistanceFormula(x,y,z,exit_table[1],exit_table[2],exit_table[3]) <= 2) then
                                                blocking_right_now[#(blocking_right_now) + 1] = key
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Remove vehicles that are not blocking right now
    for i=#blocking_vehicles,1,-1 do
        local vehicle_still_blocking = false
        for j=1,#blocking_right_now do
            if(blocking_right_now[j] == blocking_vehicles[i][1]) then 
                vehicle_still_blocking = true 
                break 
            end
        end
        if(vehicle_still_blocking == false) then
            table.remove(blocking_vehicles, i)
			say_all("removed")
        end
    end

    -- Add vehicles that are blocking
    for i=1,#blocking_right_now do
        local vehicle_is_new = true
        for j=1,#blocking_vehicles do
            if(blocking_vehicles[j][1] == blocking_right_now[i]) then
                vehicle_is_new = false
                break
            end
        end
        if(vehicle_is_new) then
            blocking_vehicles[#blocking_vehicles + 1] = {blocking_right_now[i],time}
            for p=1,16 do
                local player_dyn = get_dynamic_player(p)
                if(player_dyn ~= 0) then
                    if(read_word(player_dyn + 0x11C) == blocking_right_now[i]) then
                        say(p,string.gsub(WARNING_MESSAGE,"$SECONDS",ACTION_TIME))
                    end
                end
            end
        end
    end

    for i=1,#blocking_vehicles do
        if(time > blocking_vehicles[i][2] + ACTION_TIME) then
            local memory = get_object_memory(blocking_vehicles[i][1])
            if(ACTION_TO_TAKE == 1) then
                local is_moving = read_dword(memory + 0x10)
                if(bit.band(is_moving, math.pow(2,5)) > 0) then
                    write_dword(memory + 0x10, is_moving - math.pow(2,5))
                end
                --local x,y,z = read_vector3d(memory + 0x5C)
                --write_vector3d(memory + 0x5C,x,y,z + 3)
                write_vector3d(memory + 0x68,0.25 * (rand(1,10) - 5) / 5,0.25 * (rand(1,10) - 5) / 5,0.5 * (rand(3,5) / 5))
                write_float(memory + 0x278, 1.0)
            elseif(ACTION_TO_TAKE == 2) then
				--say_all("teleporting vehicle")
				--write_float(memory + 0x540, 0.1)
				--write_vector3d(memory + 0x68,0,0,-0.5 * (rand(1,2) / 5))
				--write_vector3d(memory + 0x5C,X[blocking_vehicles[i][1]],Y[blocking_vehicles[i][1]],Z[blocking_vehicles[i][1]] + 1)
				--write_float(memory + 0x278, 1.0)
				--write_bit(memory + 0x528, 0, 0)
                write_dword(memory + 0x5AC, read_dword(memory + 0x5AC) - 0x100000)
				rprint(1, read_dword(memory + 0x5AC))
            end
            for p=1,16 do
                local player_dyn = get_dynamic_player(p)
                if(player_dyn ~= 0) then
                    if(read_word(player_dyn + 0x11C) == blocking_right_now[i]) then
                        if(TELEFRAG_PASSENGERS) then
                            local player = get_player(p)
                            write_dword(player + 0xCC, 0x10000)
                            write_byte(player + 0xD4, 1)
                        else
                            exit_vehicle(p)
                        end
                    end
                end
            end
        end
    end
end

function OnGameStart()
    teleporter_channels = {}
    teleporter_entrances = {}
    teleporter_exits = {}
    blocking_vehicles = {}
    local tag_array = read_dword( 0x40440000 )
    local scenario_tag_index = read_word( 0x40440004 )
    local scenario_tag_entry = tag_array + scenario_tag_index * 0x20
    local scenario_tag_data = read_dword(scenario_tag_entry + 0x14)
    local netgame_flag_count = read_dword(scenario_tag_data + 0x378)
    local netgame_flag_address = read_dword(scenario_tag_data + 0x378 + 0x4)
    for i=0,netgame_flag_count-1 do
        local netgame_flag = netgame_flag_address + i * 148
        local write_table = nil
        local flag_type = read_word(netgame_flag + 0x10)
        if(flag_type == 0x6 or flag_type == 0x7) then
            if(flag_type == 0x6) then
                write_table = teleporter_entrances
            elseif(flag_type == 0x7) then
                write_table = teleporter_exits
            else
                return
            end
    
            local flag_team = read_word(netgame_flag + 0x12)
    
            local channel_found = false
            for i=1,#(teleporter_channels) do
                if(teleporter_channels[i] == flag_team) then
                    channel_found = true
                    break
                end
            end
            if(channel_found == false) then
                teleporter_channels[#(teleporter_channels) + 1] = flag_team
            end
    
            local x,y,z = read_vector3d(netgame_flag)
    
            if(write_table[flag_table] == nil) then write_table[flag_team] = {} end
            write_table[flag_team][#(write_table[flag_team]) + 1] = {x,y,z}
        end
    end
end

function OnGameEnd()
	x = {}
	y = {}
	z = {}
    teleporter_channels = {}
    teleporter_entrances = {}
    teleporter_exits = {}
    blocking_vehicles = {}
end
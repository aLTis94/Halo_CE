
--CONFIG
	command_name = "unblock"
	minimum_range = 3
--END OF CONFIG

api_version = "1.9.0.0"

vehicle_thing = nil

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
end

function OnCommand(PlayerIndex,Command,Environment,Password)
	Command = string.lower(Command)
	if command_name == Command then
		local nearest_distance = minimum_range
		local nearest_object = nil
		local hit, x, y, z = GetPlayerAimLocation(PlayerIndex)
		if hit == true then
			say(PlayerIndex, "You are aiming at the wrong place.")
			return false
		end
		local object_table = read_dword(read_dword(object_table_ptr + 2))
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		for i=0,object_count-1 do
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= 0 and object ~= 0xFFFFFFFF then
				if read_word(object + 0xB4) == 1 then
					x1, y1, z1 = read_vector3d(object + 0x5C)
					local distance = DistanceFormula(x1,y1,z1,x,y,z)
					if distance < nearest_distance then
						nearest_distance = distance
						nearest_object = object
					end
				end
			end
		end
		if nearest_object ~= nil then
			say(PlayerIndex, "The vehicle has been respawned.")
			local x2, y2, z2 = read_vector3d(nearest_object + 0x5B4)
			write_bit(nearest_object + 0x10, 5, 0)
			write_vector3d(nearest_object + 0x68, 0, 0, 0.001)
			write_vector3d(nearest_object + 0x5C, x2, y2, z2)
			--write_vector3d(nearest_object + 0x590, 0, 0, 0)
			--rprint(1, read_float(nearest_object + 0x52C))
			--rprint(1, read_float(nearest_object + 0x5C))
		else
			say(PlayerIndex, "There's no vehicle where you're aiming")
		end
		return false
	end
	return true
end

function GetPlayerAimLocation(PlayerIndex)--	Finds location where player is looking, from giraffe's script
	local player = get_dynamic_player(PlayerIndex)
	local px, py, pz = read_vector3d(player + 0x5c)
    local vx, vy, vz = read_vector3d(player + 0x230)
    local cs = read_float(player + 0x50C)
    local h = 0.62 - (cs * (0.62 - 0.35))
    pz = pz + h
	local hit, x, y , z = intersect(px, py, pz, 10000*vx, 10000*vy, 10000*vz, read_dword(get_player(PlayerIndex) + 0x34))
	local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - 0.1
	return intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(PlayerIndex) + 0x34))
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function OnScriptUnload() 
	destroy_object(vehicle_thing)
end
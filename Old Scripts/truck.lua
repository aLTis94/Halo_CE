
api_version = "1.9.0.0"

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	execute_command("object_create truck_bed")
end

trailer = nil
truck = nil
timer = 10

function OnScriptUnload()
	if trailer ~= nil then
		local trailer_object = get_object_memory(trailer)
		if trailer_object ~= 0 then
			destroy_object(trailer)
		end
	end
end

function OnGameStart()
	truck = nil
end

function Findtruck()
	timer = timer - 1
	if timer < 1 then
		timer = 100
	else
		return true
	end
	
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = get_object_memory(ID)
		if object ~= 0 and read_word(object + 0xB4) == 1 then
			local name = GetName(object)
			if name == "altis\\vehicles\\truck_bed\\truck_bed" then
				if truck == nil then
					truck = ID
				end
			end
		end
	end
	return true
end

function OnTick()
	if (truck == nil or get_object_memory(truck) == 0) and Findtruck() then
		return false
	end
	
	local truck_object = get_object_memory(truck)
	if read_dword(truck_object + 0x324) ~= 0xFFFFFFFF then
		local truck_x = read_float(truck_object + 0x5C)
		local truck_y = read_float(truck_object + 0x60)
		local truck_z = read_float(truck_object + 0x64)
		local truck_plug_x = read_float(truck_object + 0x5C0 + 0x34*2 + 0x28)
		local truck_plug_y = read_float(truck_object + 0x5C0 + 0x34*2 + 0x2C)
		local truck_plug_z = read_float(truck_object + 0x5C0 + 0x34*2 + 0x30)
		
		if driver == nil then
			driver = 1
			for i = 1,16 do
				local player = get_dynamic_player(i)
				if player ~= 0 then
					local vehicle = read_dword(player + 0x11C)
					if truck_object == get_object_memory(vehicle) then
						driver = i
					end
				end
			end
		end
		if trailer ~= nil and get_object_memory(trailer) ~= 0 then
			local trailer_object = get_object_memory(trailer)
			local player_id = read_dword(stats_globals + to_real_index(driver)*48 + 0x4)
			write_dword(trailer_object + 0xC0, player_id)
			write_dword(trailer_object + 0xC4, read_dword(get_player(driver) + 0x34))
			write_bit(trailer_object + 0x10, 5, 0)
			
			local trailer_plug_x = read_float(trailer_object + 0x5C0 + 0x34 + 0x28)
			local trailer_plug_y = read_float(trailer_object + 0x5C0 + 0x34 + 0x2C)
			local trailer_plug_z = read_float(trailer_object + 0x5C0 + 0x34 + 0x30)
			local x = read_float(trailer_object + 0x5C)
			local y = read_float(trailer_object + 0x60)
			local z = read_float(trailer_object + 0x64)
			local x_dist = (truck_plug_x - x)
			local y_dist = (truck_plug_y - y)
			local z_dist = (truck_plug_z - z)
			local distance = math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
			
			local rot_x = x_dist / distance
			local rot_y = y_dist / distance
			local rot_z = z_dist / distance
			
			x_dist = (truck_plug_x - trailer_plug_x)
			y_dist = (truck_plug_y - trailer_plug_y)
			z_dist = (truck_plug_z - trailer_plug_z)
			distance = math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
			
			if distance > 0.1 then
				--write_float(trailer_object + 0x74, rot_x)
				--write_float(trailer_object + 0x78, rot_y)
				--write_float(trailer_object + 0x7C, 0)
				
				--write_float(trailer_object + 0x7C, rot_z)
				--write_float(trailer_object + 0x80, 0)
				--write_float(trailer_object + 0x84, 0)
				--write_float(trailer_object + 0x88, 1)
			end
			
			local current_rot_x = read_float(trailer_object + 0x74)
			local current_rot_y = read_float(trailer_object + 0x78)
			local current_rot_z = read_float(trailer_object + 0x7C)
			
			local x_rot_vel = 0.05*(rot_x - current_rot_x)
			local y_rot_vel = 1*(rot_y - current_rot_y)
			local z_rot_vel = 0.05*(rot_z - current_rot_z)
			--rprint(1, y_rot_vel)
			
			write_float(trailer_object + 0x8C, 0)
			write_float(trailer_object + 0x90, 0)
			write_float(trailer_object + 0x94, y_rot_vel)
			
			local velocity = 1
			
			write_float(trailer_object + 0x68, velocity*(truck_plug_x - trailer_plug_x))
			write_float(trailer_object + 0x6C, velocity*(truck_plug_y - trailer_plug_y))
			write_float(trailer_object + 0x70, velocity*(truck_plug_z - trailer_plug_z))
		else
			trailer = spawn_object("vehi", "altis\\vehicles\\truck_bed_long\\truck_bed_long", truck_x, truck_y+4, truck_z)
			--rprint(1, "spawned")
		end
	else
		driver = nil
		if trailer ~= nil then
			--rprint(1, "destroyed")
			destroy_object(trailer)
			trailer = nil
		end
	end
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end
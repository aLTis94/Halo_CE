
api_version = "1.9.0.0"
	
	vehicle_tag = "altis\\vehicles\\boat\\boat"

function OnScriptLoad()
	if(lookup_tag("vehi", vehicle_tag) ~= 0) then
		register_callback(cb["EVENT_TICK"],"OnTick")
	end
end

function OnTick()
	for i = 1,16 do
		if(player_alive(i)) then
			local player_object = get_dynamic_player(i)
			local vehicle = read_dword(player_object + 0x11C)
			local vehicle_object = get_object_memory(vehicle)
			if(vehicle_object ~= 0 and read_word(player_object + 0x2F0) == 0 and GetName(vehicle_object) == vehicle_tag) then
				local rot1 = read_float(vehicle_object + 0x5C)
				local rot2 = read_float(vehicle_object + 0x60)
				local rot3 = read_float(vehicle_object + 0x64)
				local rot4 = read_float(vehicle_object + 0x68)
				local rot5 = read_float(vehicle_object + 0x6C)
				local rot6 = read_float(vehicle_object + 0x70)
				local rot7 = read_float(vehicle_object + 0x74)
                local rot8 = read_float(vehicle_object + 0x78)
                local rot9 = read_float(vehicle_object + 0x7C)
                local rot10 = read_float(vehicle_object + 0x80)
                local rot11 = read_float(vehicle_object + 0x84)
                local rot12 = read_float(vehicle_object + 0x88)
				rprint(1, "rot~1~"..rot1)
				rprint(1, "rot~2~"..rot2)
				rprint(1, "rot~3~"..rot3)
				rprint(1, "rot~4~"..rot4)
				rprint(1, "rot~5~"..rot5)
				rprint(1, "rot~6~"..rot6)
				rprint(1, "rot~7~"..rot7)
				rprint(1, "rot~8~"..rot8)
				rprint(1, "rot~9~"..rot9)
				rprint(1, "rot~10~"..rot10)
				rprint(1, "rot~11~"..rot11)
				rprint(1, "rot~12~"..rot12)
			end
		end
	end
end

function OnScriptUnload()
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
end

function OnScriptUnload()
end

abs = math.abs

function OnTick()
	if get_var(0, "$map") == "boardingaction_grav" then
		
		--local object_table = read_dword(read_dword(object_table_ptr + 2))
		--local object_count = read_word(object_table + 0x2E)
		--local first_object = read_dword(object_table + 0x34)
		--for i=0,object_count-1 do
		for i=1,16 do
			object = get_dynamic_player(i)
			--local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= 0 and object ~= 0xFFFFFFFF then
				local x_coord = read_float(object + 0xA0)
				local velocity = read_float(object + 0x70)
				ClearConsole(i)
				if x_coord > 0 and x_coord < 20 and read_float(object + 0xA8) > -20.0 and abs(velocity) > 0.001 then
					rprint(i, "your gravity is changed, coordinate "..x_coord)
					local difference = abs(10 - x_coord)
					local scale = (1 - (difference / 8)) * 0.65 + 0.25
					write_float(object + 0x70, velocity + 0.003665 * scale)
				end
			end
		end
	end
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end
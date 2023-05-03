
-- Need to add all types of objects pls

api_version = "1.9.0.0"
debug_person = 0

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_TICK'],"OnTick")
end

function OnTick()--	Most of this is taken from 002
	local vehicle_count = 0
	local biped_count = 0
	local weapon_count = 0
	local scenery_count = 0
	local equipment_count = 0
	local garbage_count = 0
	local projectile_count = 0
	local sound_scenery_count = 0
	local total_objects = 0
	local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if(object ~= 0 and object ~= 0xFFFFFFFF) then
			total_objects = total_objects + 1
			local object_type = read_word(object + 0xB4)
            if(object_type == 0) then
				biped_count = biped_count + 1
			elseif(object_type == 1) then
				vehicle_count = vehicle_count + 1
			elseif(object_type == 2) then
				weapon_count = weapon_count + 1
			elseif(object_type == 3) then
				equipment_count = equipment_count + 1
			elseif(object_type == 4) then
				garbage_count = garbage_count + 1
			elseif(object_type == 5) then
				projectile_count = projectile_count + 1
			elseif(object_type == 6) then
				scenery_count = scenery_count + 1
			elseif(object_type == 11) then
				sound_scenery_count = sound_scenery_count + 1
			end
		end
	end
	if(debug_mode == true) then
		ClearConsole(debug_person)
		rprint(debug_person, "|rBipeds "..biped_count)
		rprint(debug_person, "|rVehicles "..vehicle_count)
		rprint(debug_person, "|rWeapons "..weapon_count)
		rprint(debug_person, "|rEquipment "..equipment_count)
		rprint(debug_person, "|rProjectiles "..projectile_count)
		rprint(debug_person, "|rSynced objects "..biped_count + vehicle_count + weapon_count + equipment_count + projectile_count)
		rprint(debug_person, "|rGarbage "..garbage_count)
		rprint(debug_person, "|rScenery "..scenery_count)
		rprint(debug_person, "|rSound Scenery "..sound_scenery_count)
		rprint(debug_person, "|rObject count "..total_objects.."/"..object_count)
	end
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	commandargs = {}
	for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end

	if(commandargs[1] == "debug") then
		local value_wanted = tonumber(commandargs[2])
		if(value_wanted == 0) then
			debug_mode = false
			say_all("Debug mode disabled.")
			return false
		else
			if(value_wanted == 1) then
				debug_mode = true
				debug_person = PlayerIndex
				say_all("Debug mode enabled.")
				return false
			else
				say(PlayerIndex, "Incorrect arguments! Command usage: debug <1/0>")
				return false
			end
		end
	end
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end
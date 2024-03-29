
api_version = "1.9.0.0"

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D") -- used for FindAllObjects()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	Initialize()
end

function OnScriptUnload()
end

function Initialize()
	if string.find(get_var(0, "$map"), "bigass_mod") then
		OBJECTS = {}
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
		register_callback(cb['EVENT_VEHICLE_ENTER'], "OnVehicleEnter")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		
		if file_name == nil then
			file_name = "Game "..os.date("%d.%m.%Y at %H.%M")
		end
		savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
		if savefile ~= nil then
			savefile:write("Script loaded.\n")
			savefile:write("\n")
			savefile:close()
		else
			say_all("error")
		end
	else
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_LEAVE'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_VEHICLE_EXIT'])
		unregister_callback(cb['EVENT_VEHICLE_ENTER'])
		unregister_callback(cb['EVENT_SPAWN'])
	end
	
	--local tag = lookup_tag(3813016018)
	--if tag ~= nil and tag ~= 0 then
	--	rprint(1, read_string(read_dword(tag + 0x10)))
	--end
end

function OnPlayerJoin(i)
	savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
	savefile:write("---Player joined "..get_var(i, "$name").."...\n")
	savefile:close()
end

function OnPlayerLeave(i)
	savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
	savefile:write("---Player quit "..get_var(i, "$name").."...\n")
	savefile:close()
end

function OnPlayerDeath(i)
	savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
	savefile:write("---Player died "..get_var(i, "$name").."...\n")
	savefile:close()
end

function OnVehicleExit(i)
	savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
	savefile:write("---Player left a vehicle "..get_var(i, "$name").."...\n")
	savefile:close()
end

function OnVehicleEnter(i)
	savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
	savefile:write("---Player entered a vehicle "..get_var(i, "$name").."...\n")
	savefile:close()
end

function OnPlayerSpawn(i)
	savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
	savefile:write("---Player spawned "..get_var(i, "$name").."...\n")
	savefile:close()
end

function OnTick()
	local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
        local object = read_dword(first_object + i * 0xC + 0x8)
        if object ~= 0 and object ~= 0xFFFFFFFF then
			local object_type = read_word(object + 0xB4)
			if object_type == 1 then
				OBJECTS[ID] = GetName(object)
			end
		end
	end
	
	for ID,name in pairs (OBJECTS) do
		local object = get_object_memory(ID)
		if object == 0 then
			savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
			savefile:write(os.date("%d.%m.%Y at %H.%M.%S").."  Successfully removed a vehicle "..name.."...\n")
			savefile:close()
			OBJECTS[ID] = nil
		end
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	local tag = lookup_tag(MetaID)
	if tag ~= nil and tag ~= 0 then
		savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
		savefile:write(os.date("%d.%m.%Y at %H.%M.%S").." Spawning a new object "..read_string(read_dword(tag + 0x10)).."...\n")
		savefile:close()
	end
	timer(0, "ObjectInfo", ID, MetaID)
end

function ObjectInfo(ID, MetaID)
	ID = tonumber(ID)
	MetaID = tonumber(MetaID)
	if get_object_memory(ID) ~= 0 then
		local name = GetName(get_object_memory(ID))
		local object_type = read_word(get_object_memory(ID) + 0xB4)
			if object_type == 1 then
			savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
			savefile:write(os.date("%d.%m.%Y at %H.%M.%S").." Spawned a new vehicle successfully! Name: "..name.."\n")
			savefile:close()
		end
	else
		local tag = lookup_tag(MetaID)
		savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
		savefile:write(os.date("%d.%m.%Y at %H.%M.%S").." Failed to spawn an object "..read_string(read_dword(tag + 0x10)).."\n")
		savefile:close()
	end
end

function GetName(DynamicObject)--	Gets directory of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function OnGameStart()
	Initialize()
	
	if string.find(get_var(0, "$map"), "bigass_mod") then
		savefile = io.open("sapp\\bigass_reports\\"..file_name..".txt", "a")
		savefile:write("\n")
		savefile:write("\n")
		savefile:write(" New game "..os.date("%d.%m.%Y at %H.%M").."\n")
		savefile:write("\n")
		savefile:write("\n")
		savefile:close()
	end
end

--	configuration
	remove_mines_on_leave = false -- not working right now, not sure if I will bother fixing this
	
	maximum_mine_count = 50
	
	mine_name = "my_weapons\\trip-mine\\mine_springs"
	mine_red = "my_weapons\\trip-mine\\mine_springs red"
	mine_blue = "my_weapons\\trip-mine\\mine_springs blue"
	
	mine_projectile = "my_weapons\\trip-mine\\trip-mine"
	mine_projectile_red = "my_weapons\\trip-mine\\trip-mine red"
	mine_projectile_blue = "my_weapons\\trip-mine\\trip-mine blue"
--	end of configuration

api_version = "1.12.0.0"

mine_counter_delay = 30
total_mine_count = 0
MINES = {}
WANTS_MINES = {}
bigassv3 = false
mine_projectile_id = nil
mine_projectile_red_id = nil
mine_projectile_blue_id = nil
mine_scenery_id = nil
mine_scenery_red_id = nil
mine_scenery_blue_id = nil

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
    register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
	register_callback(cb["EVENT_TICK"],"OnTick")
	if remove_mines_on_leave then
		register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
		for i = 1,16 do
			MINES[i] = {}
		end
	end
	safe_read = true
	if(lookup_tag("proj", mine_projectile_red) ~= 0) then
		bigassv3 = true
		GetWeaponIDs()
	end
	safe_read = false
end

function OnScriptUnload()
end

function OnGameStart()
	total_mine_count = 0
	if lookup_tag("proj", mine_projectile_red) ~= 0 then
		bigassv3 = true
		GetWeaponIDs()
	else
		bigassv3 = false
	end
	MINES = {}
	WANTS_MINES = {}
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ObjectID)
	if bigassv3 and get_var(PlayerIndex, "$ffa") == "0" and MetaID == mine_projectile_id then
		if total_mine_count >= maximum_mine_count then
			say(PlayerIndex, "Maximum tripmine count reached!")
			execute_command("nades "..PlayerIndex.." +1 1")
			return false
		end
		if get_var(PlayerIndex, "$team") == "red" then
			if(mine_projectile_red_id ~= nil) then
				return true, mine_projectile_red_id
			end
		elseif get_var(PlayerIndex, "$team") == "blue" then
			if mine_projectile_blue_id ~= nil then
				return true, mine_projectile_blue_id
			end
		end
	end
	if remove_mines_on_leave then
		timer(33, "ObjectCheck", ObjectID, PlayerIndex)
	end
end

function ObjectCheck(ObjectID, PlayerIndex)
	if ObjectID == nil then return true end
	ObjectID = tonumber(ObjectID)
	PlayerIndex = tonumber(PlayerIndex)
	local weapon = get_object_memory(ObjectID)
	
	if MINES[PlayerIndex] == nil then
		MINES[PlayerIndex] = {}
	end
	
	if weapon ~= 0 then
		
		local name = GetName(weapon)
		if(bigassv3 == false) then
			if(name == mine_name) then
				for i = 1, 200 do
					if(MINES[PlayerIndex][i] == nil) then
						MINES[PlayerIndex][i] = ObjectID
						break
					end
				end
			end
		elseif(name == mine_name or name == mine_red or name == mine_blue) then
			for i = 1, 200 do
				if(MINES[PlayerIndex][i] == nil) then
					MINES[PlayerIndex][i] = ObjectID
					break
				end
			end
		end
	end
end

function OnPlayerJoin(PlayerIndex)
	if bigassv3 then
		timer(5000, "CheckPlayer", PlayerIndex)
	end
end

function CheckPlayer(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	if player_present(PlayerIndex) and get_var(PlayerIndex, "$has_chimera") == "1" then
		FindAllMines(PlayerIndex)
		WANTS_MINES[PlayerIndex] = 0
	end
end

function OnTick()
	if bigassv3 == false then return end
	
	for i = 1,16 do
		if player_present(i) and WANTS_MINES[i] ~= nil and MINES[i][WANTS_MINES[i]] ~= nil then
			local object = get_object_memory(MINES[i][WANTS_MINES[i]])
			if object ~= 0 then
				local x = read_float(object + 0x5C)
				local y = read_float(object + 0x60)
				local z = read_float(object + 0x64)
				local MetaID = read_dword(object)
				if MetaID == mine_scenery_id then
					rprint(i, "mine~def~"..x.."~"..y.."~"..z)
				elseif MetaID == mine_scenery_red_id then
					rprint(i, "mine~red~"..x.."~"..y.."~"..z)
				elseif MetaID == mine_scenery_blue_id then
					rprint(i, "mine~blue~"..x.."~"..y.."~"..z)
				end
				WANTS_MINES[i] = WANTS_MINES[i] + 1
			else
				WANTS_MINES[i] = nil
				MINES[i] = nil
			end
		else
			WANTS_MINES[i] = nil
			MINES[i] = nil
		end
	end
	
	mine_counter_delay = mine_counter_delay - 1
	
	if mine_counter_delay < 0 then
		total_mine_count = 0
		mine_counter_delay = 30
		local object_table = read_dword(read_dword(object_table_ptr + 2))
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		
		for i=0,object_count-1 do
			local ID = read_word(first_object + i*12)*0x10000 + i
			local object = get_object_memory(ID)
			if object ~= 0 and read_word(object + 0xB4) == 6 then
				local MetaID = read_dword(object)
				if MetaID == mine_scenery_id or MetaID == mine_scenery_red_id or MetaID == mine_scenery_blue_id then
					total_mine_count = total_mine_count + 1
				end
			end
		end
	end
end

function FindAllMines(PlayerIndex)
	MINES[PlayerIndex] = {}
	local mine_count = 0
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		if mine_count > maximum_mine_count then
			return false
		end
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = get_object_memory(ID)
		if object ~= 0 and read_word(object + 0xB4) == 6 then
			local MetaID = read_dword(object)
			if MetaID == mine_scenery_id or MetaID == mine_scenery_red_id or MetaID == mine_scenery_blue_id then
				MINES[PlayerIndex][mine_count] = ID
				mine_count = mine_count + 1
			end
		end
	end
end

function OnPlayerLeave(PlayerIndex)
	if MINES[PlayerIndex] ~= nil then
		cprint("removing mines")
		for i = 1, 200 do
			if MINES[PlayerIndex][i] ~= nil then
				local object = get_object_memory(MINES[PlayerIndex][i])
				if object ~= 0 and string.find(GetName(object), "my_weapons") ~= nil then
					destroy_object(MINES[PlayerIndex][i])
					cprint("removed mine")
				end
			else
				break
			end
		end
		MINES[PlayerIndex] = {}
	end
end

function GetWeaponIDs()
	safe_read = true
	mine_projectile_id = GetMetaID("proj", mine_projectile)
	mine_projectile_red_id = GetMetaID("proj", mine_projectile_red)
	mine_projectile_blue_id = GetMetaID("proj", mine_projectile_blue)
	mine_scenery_id = GetMetaID("scen", mine_name)
	mine_scenery_red_id = GetMetaID("scen", mine_red)
	mine_scenery_blue_id = GetMetaID("scen", mine_blue)
	
	safe_read = false
end

function OnError(Message)
	say_all("Error!"..Message)
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= nil) then
		return read_dword(address + 0xC)
	end
	return nil
end

function GetName(DynamicObject)--	Gets directory + name of the object
	if DynamicObject ~= nil and DynamicObject ~= 0 then
		return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
	else
		return ""
	end
end
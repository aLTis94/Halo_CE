--	Mine removal and mine colour change by aLTis (altis94@gmail.com)

--	To be used on bigass (any version), coloured mines only work on bigass v3!
--	All mines that a player dropped will be removed when they leave the server. It only removes them on host side so they will still be visible for
--	Players who are still on the server but they will not deal any damage

--	configuration
	mine_name = "grenades\\mine_springs\\mine_springs"
	mine_red = "grenades\\mine_springs\\mine_springs red"
	mine_blue = "grenades\\mine_springs\\mine_springs blue"
	
	banana = "my_weapons\\trip-mine\\banana"
	mine_projectile = "my_weapons\\trip-mine\\trip-mine"
	mine_projectile_red = "my_weapons\\trip-mine\\trip-mine red"
	mine_projectile_blue = "my_weapons\\trip-mine\\trip-mine blue"
--	end of configuration

api_version = "1.9.0.0"

MINES = {}
bigassv3 = false
banana_id = nil
mine_projectile_id = nil
mine_projectile_red_id = nil
mine_projectile_blue_id = nil

function OnScriptLoad()
    register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
	safe_read = true
	if(lookup_tag("proj", mine_projectile_red) ~= 0) then
		bigassv3 = true
		GetWeaponIDs()
	end
	safe_read = false
	for i = 1,16 do
		MINES[i] = {}
	end
end

function OnScriptUnload()
end

function OnGameStart()
	if(lookup_tag("proj", mine_projectile_red) ~= 0) then
		bigassv3 = true
		GetWeaponIDs()
	else
		bigassv3 = false
	end
	MINES = {}
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ObjectID)
	if(bigassv3 and MetaID == mine_projectile_id) then
		if(get_var(PlayerIndex, "$lvl") == "5") then
			return true, banana_id
		elseif(get_var(PlayerIndex, "$team") == "red") then
			if(mine_projectile_red_id ~= nil) then
				return true, mine_projectile_red_id
			end
		elseif(get_var(PlayerIndex, "$team") == "blue") then
			if(mine_projectile_blue_id ~= nil) then
				return true, mine_projectile_blue_id
			end
		end
	end
	timer(33, "ObjectCheck", ObjectID, PlayerIndex)
end

function ObjectCheck(ObjectID, PlayerIndex)
	ObjectID = tonumber(ObjectID)
	PlayerIndex = tonumber(PlayerIndex)
	if(ObjectID == nil) then return true end
	local weapon = get_object_memory(ObjectID)
	
	if(MINES[PlayerIndex] == nil) then
		MINES[PlayerIndex] = {}
	end
	
	if(weapon ~= 0) then
		
		local name = GetName(weapon)
		if(bigassv3 == false) then
			if(name == mine_name) then
				for i = 1, 2000 do
					if(MINES[PlayerIndex][i] == nil) then
						MINES[PlayerIndex][i] = ObjectID
						break
					end
				end
			end
		elseif(name == mine_name or name == mine_red or name == mine_blue) then
			for i = 1, 2000 do
				if(MINES[PlayerIndex][i] == nil) then
					MINES[PlayerIndex][i] = ObjectID
					break
				end
			end
		end
	end
end

function OnPlayerLeave(PlayerIndex)
	if(MINES[PlayerIndex] ~= nil) then
		for i = 1, 2000 do
			if(MINES[PlayerIndex][i] ~= nil) then
				if(GetName(get_object_memory(MINES[PlayerIndex][i])) == mine_name) then
					destroy_object(MINES[PlayerIndex][i])
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
	banana_id = GetMetaID("proj", banana)
	safe_read = false
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= nil) then
		return read_dword(address + 0xC)
	end
	return nil
end

function GetName(DynamicObject)--	Gets directory + name of the object
	if(DynamicObject ~= nil and DynamicObject ~= 0) then
		return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
	else
		return ""
	end
end
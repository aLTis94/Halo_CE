-- Sprinting v2.0.2 by 002, edited by aLTis (altis94@gmail.com)

--																README!
-- Sprinting gives player a specified weapon and changes its ammo depending on energy to sync energy meter on the hud
-- Player cannot sprint while holding the flag or on race and oddball gametypes
-- This script will ONLY work on maps that have sprinting weapons (bigassv3 and TSCE_Multiplayer)


--	 Configuration --

	sprint_weap = "altis\\weapons\\sprint\\sprint"
	female_weap = "altis\\weapons\\sprint\\sprint_female"
	
	newspaper = "altis\\weapons\\newspaper\\newspaper"

	-- Bipeds that are in the maps. 2 is male and 1 is female
	BIPEDS = 
	{
		["bourrin\\halo reach\\spartan\\male\\haunted"] = 2,
		["bourrin\\halo reach\\spartan\\male\\117"] = 2,
		["bourrin\\halo reach\\marine-to-spartan\\mp test"] = 2,
		["bourrin\\halo reach\\spartan\\male\\odst"] = 2,
		["bourrin\\halo reach\\spartan\\male\\mp masterchief"] = 2,
		["bourrin\\halo reach\\spartan\\male\\spec_ops"] = 2,
		["bourrin\\halo reach\\spartan\\female\\female"] = 1,
		["bourrin\\halo reach\\marine-to-spartan\\mp female"] = 1,
		["cmt\\characters\\evolved_h1-spirit\\cyborg\\bipeds\\cyborg_mp"] = 2,
		["bourrin\\halo reach\\spartan\\male\\koslovik"] = 2,
		["bourrin\\halo reach\\spartan\\male\\linda"] = 2,
	}
	
	flood_biped = "characters\\floodcombat_human\\player\\flood player"
	
	flood_speed = 1.9 -- Set speed for flood biped
	normal_speed = 1.0 -- Set the base walking speed
	sprint_increase = 0.5 -- Set the sprinting speed increase
	minimum_energy = 20 -- Player cannot start sprinting if less than this percentage of energy
	sprint_time = 13 -- This is how long you can sprint before running out of energy

	-- This controls how players can regain energy
	--      0 = Players will regain energy over time if they aren't sprinting.
	--      1 = Player must not move forward/backward/sideways.
	--      2 = Energy will not increase over time. It is only restored to 100% upon respawn.
	energy_renew = 0
	energy_renew_time = 7-- This controls how much time it takes for energy to renew to 100% in seconds

	--	Delays (don't touch these unless you know what you're doing and I know that you don't so don't touch these)
	double_tap_delay = 		0.2	--	(in seconds)How quickly you need to double tap W in order to sprint. 0.2-0.5 works the best
	dropped_weapon_check = 	100	--	(in ms) 	How often to check if player is picking up weapons in third slot
	sprint_remove_check = 	1000	--	(in ms) 	How often to check if sprint weapon needs to be removed
	spawned_object_check =	1	--	(in ms) 	After an object was spawned, how often to check if the object is sprint weapon
	sprint_delay =			30	--	(in ticks)	How often to check if player is sprinting (lower means more often)


-- End of configuration

api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	OnGameStart()
end

function OnScriptUnload()--			Removes sprint weapons and sets speed to default
	for i=1,16 do
		if SPRINT_WEAPS ~= nil then
			DestroySprintWeapon(i)
			
			local player = get_dynamic_player(i)
			if player ~= 0 then
				if read_float(get_player(i) + 0x6C) ~= 0 then
					write_float(get_player(i) + 0x6C, 1.0)
				end
			end
		end
	end
end

function OnTick()--	Main part of the script
	if sprinting_disabled then return false end
	
    for i = 1,16 do
		local player = get_dynamic_player(i)
        if player ~= 0 then
			current_biped[i] = BIPEDS[GetName(player)]
			
			CheckSprint(i)
			RestPlayer(i)
			
			local boost = 0.0
			if sprinting[i] then
				blocked_objects[i] = 1
				execute_command("block_all_objects "..i.." 1")
				
				if player_energy[i] > 0 then
					boost = sprint_increase
					player_energy[i] = player_energy[i] - (1.0/sprint_time)/30
					
					OnSprint(i)
				else
					DestroySprintWeapon(i)
					player_energy[i] = 0
				end
			end
			local speed = normal_speed + boost
			if read_dword(player) == flood_metaid then 
				if tonumber(get_var(0, "$ticks"))%90 == 1 then -- reset speed sometimes to prevent desync
					speed = 1
				else
					speed = flood_speed
				end
			end
			SetSpeedOfPlayer(i,speed)
		else
			DestroySprintWeapon(i)
			current_biped[i] = 0
        end
    end
end

function PlayerSpawn(i)--	Resets all values
	if blocked_objects[i] == 1 then
		execute_command("block_all_objects "..i.." 0")
	end
    player_energy[i] = 1.0
    stopped_moving[i] = 0
    started_moving[i] = 0
	blocked_objects[i] = 0
    sprinting[i] = false
    moving[i] = false
end

function SetSpeedOfPlayer(i,Speed)
    Speed = math.floor(Speed * 40 + 0.5) / 40
    local player = get_player(i)
    local player_speed = (read_float(get_player(i)) * 40 + 0.5) / 40
    if player_speed ~= Speed then
		if read_float(get_player(i) + 0x6C) ~= 0 then
			--rprint(1, "changing speed "..Speed)
			write_float(get_player(i) + 0x6C, Speed)
		end
    end
end

function CheckSprint(i, custom_key)
	if sprinting_disabled then return false end
	
	i = tonumber(i)
    local player = get_dynamic_player(i)
	if player == 0 then return false end
	local crouch = read_byte(player + 0x2A0) == 3
    local runningforward = read_float(player + 0x278) > 0.7 -- maybe if this was changed to 0.8 it would work better on controllers?
    local invehicle = read_dword(player + 0x11C) ~= 0xFFFFFFFF
	local trigger = 0
    local stopped_moving_time = os.clock() - stopped_moving[i] -- Time since stopped moving (sec)
    local started_moving_time = os.clock() - started_moving[i] -- Time since started moving (sec)
	
	local held_weapon = get_object_memory(read_dword(player + 0x118))
	if held_weapon ~= 0 and read_word(held_weapon + 0xB4) == 2 then
		MetaID = read_dword(held_weapon)
		trigger = read_bit(held_weapon + 0x230, 1)
	end
	
	if custom_key and custom_key == "stop" then
		--say(1, "custom stop")
		DestroySprintWeapon(i)
		return
	end
	
	if CUSTOM_KEYS[i] ~= nil then
		stopped_moving_time = 9000000
	end
	
    if(runningforward and (moving[i]==false or (custom_key and custom_key=="start")) and invehicle==false and MetaID~=flag and current_biped[i]~=0 and crouch==false and trigger == 0) then -- Player just started moving
		moving[i] = true
        local last_moving_duration = started_moving_time - stopped_moving_time

        if(last_moving_duration < double_tap_delay and stopped_moving_time < double_tap_delay) or (custom_key and custom_key=="start") then -- Player wants to sprint
            if player_energy[i] >= minimum_energy/100 then
				SpawnSprintWeap(i)
				if custom_key then
					--say(1, "custom start")
					rprint(i, "started_sprinting")
				end
			end
        end

		if custom_key == nil then
			started_moving[i] = os.clock()
		end

    elseif((runningforward==false and moving[i]) or invehicle or MetaID==flag or crouch==1) then -- Player stopped moving
		moving[i] = false
        stopped_moving[i] = os.clock()
		DestroySprintWeapon(i)
    end
end

function SpawnSprintWeap(i)
	DestroySprintWeapon(i)
	sprinting[i] = true
	
	if current_biped[i] == 2 then
		SPRINT_WEAPS[i] = spawn_object("weap", sprint_weap)
		assign_weapon(SPRINT_WEAPS[i], i)
		--say_all("spawning")
	elseif current_biped[i] == 1 then
		SPRINT_WEAPS[i] = spawn_object("weap", female_weap)
		assign_weapon(SPRINT_WEAPS[i], i)
	end
end

function RestPlayer(i)
    if sprinting[i] then  return end
	
	if blocked_objects[i] == 1 then
		execute_command("block_all_objects "..i.." 0")
		blocked_objects[i] = 0
	end
	
	DestroySprintWeapon(i)
	
    local increase_energy = false
    if energy_renew == 0 then
        increase_energy = true
    elseif energy_renew == 1 then
        local player = get_dynamic_player(i)
		if player ~= 0 then
			local moving = read_float(player + 0x278) ~= 0.0 or read_float(player + 0x27C) ~= 0.0
			if moving == false then increase_energy = true end
		end
    end
    if increase_energy then
        player_energy[i] = player_energy[i] + (1.0/energy_renew_time)/30
        if player_energy[i] > 1.0 then
            player_energy[i] = 1.0
        end
    end
end

function DestroySprintWeapon(i)
	sprinting[i] = false
	if SPRINT_WEAPS[i] and get_object_memory(SPRINT_WEAPS[i]) ~= 0 then
		destroy_object(SPRINT_WEAPS[i])
		--say_all("destroying")
	end
	SPRINT_WEAPS[i] = nil
end

function OnSprint(i)
	if SPRINT_WEAPS[i] ~= nil then
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local held_obj_id = read_dword(player + 0x118)
			local sprint_obj = get_object_memory(SPRINT_WEAPS[i])
			if sprint_obj ~= 0 and read_word(sprint_obj + 0xB4) == 2 then
				local parent = read_dword(sprint_obj + 0x11C)
				if parent == 0xFFFFFFFF then
					if held_obj_id ~= SPRINT_WEAPS[i] and read_bit(sprint_obj + 0x18, 0) == 1 then
						--rprint(1, GetName(get_object_memory(held_obj_id)))
						DestroySprintWeapon(i)
					end
				else
					write_bit(sprint_obj + 0x18, 0, 1)
				end
			end
		end
	end
		
	SyncEnergyBar(i)
end

function SyncEnergyBar(i)
	local player = get_dynamic_player(i)
	if player ~= 0 and sprinting[i] and SPRINT_WEAPS[i] then
		for j=1,4 do
			if read_dword(player + 0x2F8 + (j - 1) * 4) == SPRINT_WEAPS[i] then
				local ammo = math.floor(player_energy[i] * 85 + 0.5)--	Sync hud meter using ammo
				execute_command("ammo \""..i.."\" \""..ammo.."\" \""..j.."\"")
				break
			end
		end
	end
end

function AddCustomKey(i, key)
	i = tonumber(i)
	if CUSTOM_KEYS ~= nil and get_var(i, "$has_chimera") == "1" then
		CUSTOM_KEYS[i] = key
	end
end

function OnPlayerJoin(i)
	CUSTOM_KEYS[i] = nil
end

function CheckMap()
	if(lookup_tag("weap", sprint_weap) ~= 0) then
		return true
	else
		return false
	end
end

function GetGametype()-- returns 0 if race or oddball, 1 otherwise. Sprint doesn't work on race and oddball because player speed cannot be changed
	if(get_var(0, "$gt") == "oddball" or get_var(0, "$gt") == "race") then
		return false
	else
		return true
	end
end

function OnGameStart()--	Checks if gametype and map supports sprinting
	sprinting_disabled = false
	if GetGametype() and CheckMap() then
	
		GetTags()
		
		stopped_moving = {}
		started_moving = {}
		sprinting = {}
		moving = {}
		current_biped = {}
		previous_slot = {}
		blocked_objects = {}
		player_energy = {}
		SPRINT_WEAPS = {}
		CUSTOM_KEYS = {}
		
		register_callback(cb["EVENT_SPAWN"],"PlayerSpawn")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		
		for i=1,16 do
			PlayerSpawn(i)
		end
	else
		sprinting_disabled = true
		unregister_callback(cb["EVENT_SPAWN"])
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb["EVENT_JOIN"])
	end
end

function DisableSprinting()
	sprinting_disabled = true
	for i=1,16 do
		execute_command("block_all_objects "..i.." 0")
	end
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetTags()--	Gets flag's MetaID
	flag = read_dword(read_dword(read_dword(lookup_tag("matg","globals\\globals") + 0x14) + 0x164 + 4) + 0x0 + 0xC)
	sprint_weap_metaid_male = lookup_tag("weap", sprint_weap)
	sprint_weap_metaid_female = lookup_tag("weap", female_weap)
	newspaper_tag_metaid = lookup_tag("weap", newspaper)
	flood_metaid = read_dword(lookup_tag("bipd", flood_biped) + 0xC)
end

function OnError(Message)
	say_all("Error!"..Message)
end
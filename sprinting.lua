-- Sprinting v2.0.2 by 002, edited by aLTis (altis94@gmail.com)

--																README!
-- Sprinting gives player a specified weapon and changes its ammo depending on energy to sync energy meter on the hud
-- Player cannot sprint while holding the flag or on race and oddball gametypes
-- This script will ONLY work on maps that have sprinting weapons (bigassv3 and TSCE_Multiplayer)


-- Change log:
-- 2016-07-06:
--	Flag is now checked based on MetaID from globals rather than using a string which lets this script to be used on different maps
--	The script is now automatically disabled on race and oddball gametypes because player speed cannot be changed on those
-- 2016-07-09:
--	The script now checks if the sprinting weapon exists and disables sprint if it doesn't.
--	Adjusted some delay values which should hopefully fix a rare glitch that makes player constantly pick up the sprinting weapon.
-- 2016-07-11:
--	Fixed crash which happened if the script was loaded when no map was running.
-- 2016-07-13:
--	Fixed a glitch that constantly gave sprint weapon when sprinting for players with high ping.
--	Players can no longer sprint while crouched

--	 Configuration --

-- Sprinting weapons
sprint_weap = "altis\\weapons\\sprint\\sprint"
female_weap = "altis\\weapons\\sprint\\sprint_female"

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
	["cmt\\characters\\evolved_h1-spirit\\cyborg\\bipeds\\cyborg_mp"] = 2,
	["characters\\smoke\\smoke"] = 2,
	["impzone\\characters\\alice\\alice_mp"] = 1,
}

-- Set the base walking speed
normal_speed = 1.0

-- Set the sprinting speed increase
sprint_increase = 0.7

-- Set the minimum speed when out of energy. Set to normal_speed to prevent tiredness
tired_speed = 1.0

-- Player cannot start sprinting if less than this percentage of energy
minimum_energy = 20

-- This is how long you can sprint before running out of energy
sprint_time = 10

-- This controls how players can regain energy
--      0 = Players will regain energy over time if they aren't sprinting.
--      1 = Player must not move forward/backward/sideways.
--      2 = Energy will not increase over time. It is only restored to 100% upon respawn.
energy_renew = 0

-- This controls how much time it takes for energy to renew to 100% in seconds
energy_renew_time = 5

-- This controls how much damage the player takes when sprinting (percentage).
damage_health_increase = 100
damage_shield_increase = 150

-- The plugin will only affect players with this admin level (or higher). Set to -1 to affect everyone
admin_level = -1

--	Delays (don't touch these unless you know what you're doing and I know that you don't so don't touch these)
double_tap_delay = 		0.2	--	(in seconds)How quickly you need to double tap W in order to sprint. 0.2-0.5 works the best
dropped_weapon_check = 	100	--	(in ms) 	How often to check if player is picking up weapons in third slot
sprint_remove_check = 	1000	--	(in ms) 	How often to check if sprint weapon needs to be removed
spawned_object_check =	1	--	(in ms) 	After an object was spawned, how often to check if the object is sprint weapon
sprint_delay =			30	--	(in ticks)	How often to check if player is sprinting (lower means more often)


-- End of configuration

api_version = "1.9.0.0"
player_energy = {}
flag = nil

-- Iterations per second. Halo does not do ticks faster than 30 per second, so do not set it higher than 30.
n_per_second = 30



function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	safe_read(true)
	if(GetGametype() and CheckMap()) then
		GetFlag()
		register_callback(cb["EVENT_SPAWN"],"PlayerSpawn")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_WEAPON_PICKUP'], "OnWeaponPickup")
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	end
	safe_read(false)
end

function OnScriptUnload()--			Removes sprint weapons and sets speed to default
	for i=1,16 do
		if(player_alive(i)) then
			local player = get_dynamic_player(i)
			local currentWeapon = read_dword(player + 0x118)
			local WeaponObj = get_object_memory(currentWeapon)
			
			if(WeaponObj ~= nil and WeaponObj ~= 0) then
				local name = read_string(read_dword(read_word(WeaponObj) * 32 + 0x40440038))
				if(name == sprint_weap or name == female_weap) then
					execute_command("wdel \""..i.."\" \"".. 3 .."\"")
					execute_command("wdel \""..i.."\" \"".. 4 .."\"")
					if(read_float(get_player(i) + 0x6C) ~= 0) then
						write_float(get_player(i) + 0x6C, 1.0)
					end
				end
			end
		end
	end
end

stopped_moving = {}
started_moving = {}
sprinting = {}
moving = {}
current_biped = {}
previous_slot = {}
delay = 0--	Don't touch this

function OnTick()--	Main part of the script
	local ammo = {}
	local biped = 0
	local biped_name
	local name
	
    for PlayerIndex = 1,16 do
        if(player_alive(PlayerIndex) == true) then
			biped = get_dynamic_player(PlayerIndex)
			if(biped ~= 0) then
				name = GetName(biped)
				biped_name = string.format("%s", name)
				current_biped[PlayerIndex] = BIPEDS[biped_name]
				biped = 0
			else
				current_biped[PlayerIndex] = 0
			end
			
            if(player_energy[PlayerIndex] == nil) then -- prevent error if plugin is loaded during a game
                player_energy[PlayerIndex] = 1.0
            end
			if(tonumber(get_var(PlayerIndex,"$lvl")) >= admin_level) then
                CheckSprint(PlayerIndex)
                RestPlayer(PlayerIndex)
                local boost = 0.0
                if(sprinting[PlayerIndex] == true) then
                    if(player_energy[PlayerIndex] > 0) then
                        boost = sprint_increase
						
						player_energy[PlayerIndex] = player_energy[PlayerIndex] - (1.0/sprint_time)/n_per_second
						ammo = math.floor(player_energy[PlayerIndex] * 85 + 0.5)--	Sync hud meter using ammo
						
						OnSprint(PlayerIndex, ammo)
						
                       -- say(PlayerIndex,"[DEBUG] " .. get_var(PlayerIndex,"$name") .. "'s energy: " .. math.floor(player_energy[PlayerIndex] * 100 + 0.5) .. "%")
                    else
                        sprinting[PlayerIndex] = false
                        player_energy[PlayerIndex] = 0
                    end
                end
                local speed = tired_speed + (normal_speed - tired_speed) * player_energy[PlayerIndex] + boost
                SetSpeedOfPlayer(PlayerIndex,speed)
			end
        end
    end
end

function PlayerSpawn(PlayerIndex)--	Resets all values
    player_energy[PlayerIndex] = 1.0
    stopped_moving[PlayerIndex] = 0
    started_moving[PlayerIndex] = 0
    sprinting[PlayerIndex] = false
    moving[PlayerIndex] = false
end

function SprintObjectRemove(ObjectID)--	Check if players aren't holding the sprint weapon any more. If they are, call this function again until it is dropped
	ObjectID = tonumber(ObjectID)
	local player
	local current_weapon
	
	for i=1,16 do
		if(player_alive(i)) then
			player = get_dynamic_player(i)
			currentWeapon = read_dword(player + 0x118)
			 if(currentWeapon == ObjectID) then
				timer(sprint_remove_check, "SprintObjectRemove", ObjectID)
				return false
			end
		end
	end
	destroy_object(ObjectID)
end

function SprintObjectCheck(ObjectID)--	Check if an object that just spawned is sprint weapon
	if(ObjectID == nil) then return true end
	local weapon = get_object_memory(ObjectID)
	
	if(weapon ~= 0) then
		local name = GetName(weapon)
		if(name == sprint_weap or name == female_weap) then
			timer(sprint_remove_check, "SprintObjectRemove", ObjectID)--	Removes sprint weapon when it's no longer used
		end
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ObjectID)
	timer(spawned_object_check, "SprintObjectCheck", ObjectID)
end

function GetDefaultHealthShieldOfPlayer(PlayerIndex)
    local stats = {}
    if(player_alive(PlayerIndex) == false) then return stats end
    local player_data = get_dynamic_player(PlayerIndex)
    local unit_tag_index = read_word(player_data)
    local tag_array = read_dword(0x40440000)
    local unit_data = read_dword(tag_array + 0x20 * unit_tag_index + 0x14)
    local coll_tag_index = read_word(unit_data + 0x70 + 0xC)
    if(coll_tag_index == 0xFFFF) then return stats end -- No shirt? No collision model? No service!
    local coll_tag_data = read_dword(tag_array + 0x20 * coll_tag_index + 0x14)
    stats["health"] = read_float(coll_tag_data + 0x8)
    stats["shield"] = read_float(coll_tag_data + 0xCC)
    return stats
end

function SetSpeedOfPlayer(PlayerIndex,Speed)
    Speed = math.floor(Speed * 40 + 0.5) / 40
    local player = get_player(PlayerIndex)
    local player_speed = (read_float(get_player(PlayerIndex)) * 40 + 0.5) / 40
    if(player_speed ~= Speed) then
		if(read_float(get_player(PlayerIndex) + 0x6C) ~= 0) then
			write_float(get_player(PlayerIndex) + 0x6C, Speed)
		end
    end
end

function CheckSprint(PlayerIndex)
    if(stopped_moving[PlayerIndex] == nil) then PlayerSpawn(PlayerIndex) end -- In case the host added the script late
	local held_weapon
	local MetaID
    local player_address = get_dynamic_player(PlayerIndex)
	local crouch = read_bit(player_address + 0x208,0)
    local runningforward = read_float(player_address + 0x278) > 0.0
    local invehicle = read_dword(player_address + 0x11C) ~= 0xFFFFFFFF
	local held_obj_id = read_dword(player_address + 0x118)
	
    local stopped_moving_time = os.clock() - stopped_moving[PlayerIndex] -- Time since stopped moving (sec)
    local started_moving_time = os.clock() - started_moving[PlayerIndex] -- Time since started moving (sec)
	
	--	Get player's weapon MetaID
    if(tonumber(held_obj_id) ~= 4294967295) then
		held_weapon = get_object_memory(held_obj_id)
		MetaID = read_dword(held_weapon)
	else
		MetaID = nil
	end
	
    if(runningforward and moving[PlayerIndex] == false and invehicle == false and MetaID ~=flag and current_biped[PlayerIndex] ~= 0 and crouch == 0) then -- Player just started moving
		moving[PlayerIndex] = true
        local last_moving_duration = started_moving_time - stopped_moving_time

        if(last_moving_duration < double_tap_delay and stopped_moving_time < double_tap_delay and player_energy[PlayerIndex] >= (minimum_energy/100)) then -- Player wants to sprint
            sprinting[PlayerIndex] = true
			execute_command("block_all_objects "..PlayerIndex.." 1")
            local healthshield = GetDefaultHealthShieldOfPlayer(PlayerIndex)

            if(healthshield["shield"] ~= nil) then
                local newshield = healthshield["shield"] / (damage_shield_increase / 100.0)
                local newhealth = healthshield["health"] / (damage_health_increase / 100.0)

                write_float(player_address + 0xD8,newhealth)
                write_float(player_address + 0xDC,newshield)
            end
        end

        started_moving[PlayerIndex] = os.clock()

    elseif((runningforward == false and moving[PlayerIndex] == true) or invehicle == true or MetaID == flag or crouch == 1) then -- Player stopped moving
		moving[PlayerIndex] = false
        stopped_moving[PlayerIndex] = os.clock()
        if(sprinting[PlayerIndex]) then
            sprinting[PlayerIndex] = false
            local healthshield = GetDefaultHealthShieldOfPlayer(PlayerIndex)
            if(healthshield["shield"] ~= nil) then
                write_float(player_address + 0xD8,healthshield["health"])
                write_float(player_address + 0xDC,healthshield["shield"])
            end
        end
    end
end

function RestPlayer(PlayerIndex)
    if(sprinting[PlayerIndex]) then  return end
	execute_command("block_all_objects "..PlayerIndex.." 0")
	OnRest(PlayerIndex)
    local increase_energy = false
    if(energy_renew == 0) then
        increase_energy = true
    elseif(energy_renew == 1) then
        local player_address = get_dynamic_player(PlayerIndex)
        local moving = read_float(player_address + 0x278) ~= 0.0 or read_float(player_address + 0x27C) ~= 0.0
        if(moving == false) then increase_energy = true end
    end
    if(increase_energy) then
        player_energy[PlayerIndex] = player_energy[PlayerIndex] + (1.0/energy_renew_time)/n_per_second
        if(player_energy[PlayerIndex] > 1.0) then
            player_energy[PlayerIndex] = 1.0
        end
    end
end

function DropWeapon(PlayerIndex)--	This is used to prevent players from picking up a third weapon while sprinting
	local PlayerObj = get_dynamic_player(PlayerIndex)
	local WeaponObj = get_object_memory(read_dword(PlayerObj + 0x2F8 + (2) * 4))
	
	if(WeaponObj == nil or WeaponObj == 0) then return false end
	local name = GetName(WeaponObj)
	local MetaID = read_dword(WeaponObj)
	
	if(name ~= sprint_weap and name ~=female_weap and MetaID ~= flag) then
		timer(dropped_weapon_check, "DropWeapon", PlayerIndex)
		drop_weapon(PlayerIndex)
	end
end

function OnWeaponPickup(PlayerIndex, WeaponIndex)--	This is also used to prevent players from picking up a third weapon while sprinting
		local PlayerObj = get_dynamic_player(PlayerIndex)
		local WeaponObj = get_object_memory(read_dword(PlayerObj + 0x2F8 + (tonumber(WeaponIndex) - 1) * 4))
		local name = GetName(WeaponObj)
		local MetaID = read_dword(WeaponObj)
		
		if((tonumber(WeaponIndex)) == 3 or (tonumber(WeaponIndex)) == 4) then
			if(name ~= sprint_weap and name ~=female_weap and MetaID ~= flag) then
				timer(dropped_weapon_check, "DropWeapon", PlayerIndex)
			end
		end
end

function OnRest(PlayerIndex)
	
    local player = get_dynamic_player(PlayerIndex)
    local held_obj_id = read_dword(player + 0x118)
	local weapon_name
	local slot_name
	local slot_weapon_name
	local WeaponObj
	local metaid
	
	if(tonumber(held_obj_id) ~= 4294967295) then--	Get the weapon that player is holding
		local held_weapon = get_object_memory(held_obj_id)
		local name = GetName(held_weapon)
		weapon_name = string.format("%s", name)
	else
		weapon_name = nil
	end
	
	if(weapon_name == sprint_weap or weapon_name == female_weap) then
		for j=1,4 do
			metaid = (read_dword(player + 0x2F8 + (j - 1) * 4))
			if(metaid ~= 0xFFFFFFFF) then
				WeaponObj = get_object_memory(metaid)
				slot_name = GetName(WeaponObj)
				slot_weapon_name = string.format("%s", slot_name)
				if(sprint_weap == slot_weapon_name or female_weap == slot_weapon_name) then
					execute_command("wdel \""..PlayerIndex.."\" \""..j.."\"")
				end
			end
		end
	end
end

function OnSprint(PlayerIndex, ammo)
    local player = get_dynamic_player(PlayerIndex)
    local held_obj_id = read_dword(player + 0x118)
	local weapon_name
	local slot_name
	local slot_weapon_name
	local WeaponObj
	local metaid
	local SprintObj
	
	if(tonumber(held_obj_id) ~= 4294967295) then--	Get the weapon that player is holding
		local held_weapon = get_object_memory(held_obj_id)
		local name = GetName(held_weapon)
		weapon_name = string.format("%s", name)
		local metaid = read_dword(held_weapon)
	else
		weapon_name = string.format("test")
		metaid = nil
	end	

	--	If player's current weapon is not sprint then remove sprint weapons and give them a sprint weapon
	if(weapon_name ~= sprint_weap and weapon_name ~= female_weap and metaid ~= flag and delay == 0) then
		delay = sprint_delay
		for j=1,4 do
			metaid = (read_dword(player + 0x2F8 + (j - 1) * 4))
			if(metaid ~= 0xFFFFFFFF) then
				WeaponObj = get_object_memory(metaid)
				slot_name = GetName(WeaponObj)
				slot_weapon_name = string.format("%s", slot_name)
				if(sprint_weap == slot_weapon_name or female_weap == slot_weapon_name) then
					execute_command("wdel \""..PlayerIndex.."\" \""..j.."\"")
				end
			end
		end
		
		if(current_biped[PlayerIndex] == 2) then--	Assign a weapon based on gender
			SprintObj = spawn_object("weap", sprint_weap)
			assign_weapon(SprintObj, PlayerIndex)
		else
			if(current_biped[PlayerIndex] == 1) then
				SprintObj = spawn_object("weap", female_weap)
				assign_weapon(SprintObj, PlayerIndex)
			end
		end
	end
		
	--	Change ammo to sync energy
	for j=1,4 do
		metaid = (read_dword(player + 0x2F8 + (j - 1) * 4))
		if(metaid ~= 0xFFFFFFFF) then
			WeaponObj = get_object_memory(metaid)
			slot_name = GetName(WeaponObj)
			slot_weapon_name = string.format("%s", slot_name)
			if(sprint_weap == slot_weapon_name or female_weap == slot_weapon_name) then
				execute_command("ammo \""..PlayerIndex.."\" \""..ammo.."\" \""..j.."\"")
			end
		end
	end
	
	if(delay > 0) then
		delay = (delay - 1)
	end
end

function CheckMap()--	Checks if sprinting weapon exists, returns true if it does, 0 if does not
	if(lookup_tag("weap", sprint_weap) ~= 0) then
		return true
	else
		return false
	end
end

function GetGametype()-- returns 0 if race or oddball, 1 otherwise. Sprint doesn't work on race and oddball
	if(get_var(1, "$gt") == "oddball" or get_var(1, "$gt") == "race") then
		return false
	else
		return true
	end
end

function OnGameStart()--	Checks if gametype and map supports sprinting
	if(GetGametype() and CheckMap()) then
		GetFlag()
		register_callback(cb["EVENT_SPAWN"],"PlayerSpawn")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_WEAPON_PICKUP'], "OnWeaponPickup")
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	else
		unregister_callback(cb["EVENT_SPAWN"])
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_WEAPON_PICKUP'])
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
	end
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetFlag()--	Gets flag's MetaID
	flag = read_dword(read_dword(read_dword(lookup_tag("matg","globals\\globals") + 0x14) + 0x164 + 4) + 0x0 + 0xC)
end
-- Vehicle spawn script by giraffe
-- Edited by aLTis

-- This script spawns vehicles where the player is looking when he fires a specified weapon
-- Used for calling in a Pelican that drops a warthog (or other vehicles)

--	I added AI spawning functions. Right now it will only work with a single biped, could use a table to store AI values
--	The AI table would increase in size with every spawned biped and would be cleaned when bipeds are teleported
--	This requires an encounter with a wanted number of AI (respawn disabled)
--	Could spawn different encounter depending on player's team

-- Configuration

debug_mode = false

infinite_ammo = true

WEAPON_TAG = "altis\\weapons\\binoculars\\binoculars"
CONFIRM_TAG = "altis\\weapons\\binoculars\\warthog_confirm"
DENY_TAG = "altis\\weapons\\binoculars\\warthog_error"
PELICAN_TAG = "altis\\vehicles\\pelican_drop\\pelican"
PELICAN_CARRY_TAG = "altis\\vehicles\\pelican_drop\\warthog\\warthog"
VEHICLE_TAG = "bourrin\\halo reach\\vehicles\\warthog\\h2 mp_warthog"
BIPED = "characters\\floodcombat_human\\floodcombat_human"

-- vehicle respawn time in seconds (should be 60 seconds)
respawn_time = 60

-- the magazine to check for decrease in ammo; primary = 0, secondary = 1
MAGAZINE = 1

-- in world units, how far away to spawn vehicle from collision surface (to prevent vehicle from clipping through geometry)
DISTANCE_FROM_COLLISION = 1

-- values can be found in player's biped tag under 'camera, collision, and autoaim'.
STANDING_CAMERA_HEIGHT = 0.62
CROUCHING_CAMERA_HEIGHT = 0.35

-- End of config

DISTANCE = 10000
WEAPON_AMMO = {}
VEHICLE_NAME = {}
AI = nil

api_version = "1.9.0.0"

function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
    register_callback(cb['EVENT_TICK'],"OnTick")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
end

function OnGameStart()
    WEAPON_AMMO = {}
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ObjectID)
	timer(33, "ObjectCheck", ObjectID)
end

function ObjectCheck(ObjectID)
	if(ObjectID == nil) then return true end
	local weapon = get_object_memory(tonumber(ObjectID))
	
	if(weapon ~= 0) then
		local name = read_string(read_dword(read_word(weapon) * 32 + 0x40440038))
		if(name == WEAPON_TAG) then
			if(debug_mode) then rprint(1, "Binoculars spawned") end
			write_word(weapon + 0x2B8 + (0xC * MAGAZINE), 1)
		elseif(name == BIPED) then
			if(debug_mode) then rprint(1, "AI spawned!") end
			AI = weapon
			if(debug_mode) then rprint(1, AI) end
		end
	end
end

function destroy_vehicle(ObjectID)
    destroy_object(ObjectID)
end

function spawnhog(x, y, z)
	newVehiID = spawn_object("vehi", VEHICLE_TAG, x, (y-2), (z+5.3), 1.5708)
	despawn_hog(newVehiID, respawn_time)
end

function despawn_hog(ObjectID, wait)
	for i=1,16 do
		if(player_alive(i) == true) then 
			if(tonumber(ObjectID) ~= 0xFFFFFFFF) then
				local newVehicle = get_object_memory(ObjectID)
				local player_object = get_dynamic_player(i)
				local vehicle_objectid = read_dword(player_object + 0x11C)
				
				if(tonumber(vehicle_objectid) ~= 0xFFFFFFFF) then
					local vehicle_object = get_object_memory(vehicle_objectid)
					if(vehicle_object == newVehicle) then
						if(debug_mode) then rprint(1, "|rPlayer is driving a spawned vehicle") end
						wait = respawn_time
					end
				end
			end
		end
	end
	if(debug_mode) then rprint(1, wait) end
	if(tonumber(wait) > 0) then
		wait = (wait - 1)
		timer(1000, "despawn_hog", ObjectID, wait)
	else
		destroy_vehicle(ObjectID)
	end
end

function GiveAmmo(player)--		Gives player 1 ammo
	for j=1,4 do
		metaid = (read_dword(player + 0x2F8 + (j - 1) * 4))
		if(metaid ~= 0xFFFFFFFF) then
			WeaponObj = get_object_memory(metaid)
			slot_name = read_string(read_dword(read_word(WeaponObj) * 32 + 0x40440038))
			slot_weapon_name = string.format("%s", slot_name)
			if(WEAPON_TAG == slot_weapon_name) then
				write_word(WeaponObj + 0x2B8 + (0xC * MAGAZINE), 1)
			end
		end
	end
end

function check_location(x, y, z, PlayerIndex)--		Checks if the location where player is aiming is not the sky
	local player = get_dynamic_player(PlayerIndex)
	
	if(z>16 or x>202 or x<(-195) or y>105 or y<(-100)) then
		if(debug_mode) then rprint(1, "Request denied!") end
		execute_command("spawn weap \""..DENY_TAG.."\" \""..PlayerIndex.."\"")
		GiveAmmo(player)
		return false
	end
	
	execute_command("spawn weap \""..CONFIRM_TAG.."\" \""..PlayerIndex.."\"")
	if(debug_mode) then rprint(1, "Request confirmed!") end
	if(infinite_ammo) then GiveAmmo(player) end
	return true
end

function spawn_ai()--	Only used for AI testing
	execute_command("ai_place flood_base")
end

function teleport_ai(x, y, z)--	Only used for AI testing
	if(debug_mode) then rprint(1, AI) end
	if(AI == nil) then return false end
	if(debug_mode) then rprint(1, "Teleporting AI...") end
	
	write_float(AI + 0x5C, x)
	write_float(AI + 0x60, y)
	write_float(AI + 0x64, z)
	AI = nil
end

function OnTick()
    for i=1,16 do
        if(player_present(i) and player_alive(i)) then
            local player = get_dynamic_player(i)
            local player_weapon_id = read_dword(player + 0x118)
            local player_weapon = get_object_memory(player_weapon_id)
			
            if(player_weapon ~= 0) then
				local name = read_string(read_dword(read_word(player_weapon) * 32 + 0x40440038))
                if(WEAPON_TAG == name) then
                    local current_ammo = read_word(player_weapon + 0x2B8 + (0xC * MAGAZINE))
                    local last_ammo = WEAPON_AMMO[player_weapon_id]
                    if(last_ammo ~= nil) then
                        if(last_ammo > current_ammo) then
                            local px, py, pz = read_vector3d(player + 0x5c)
                            local vx, vy, vz = read_vector3d(player + 0x230)
                            local cs = read_float(player + 0x50C)
                            local h = STANDING_CAMERA_HEIGHT - (cs * (STANDING_CAMERA_HEIGHT - CROUCHING_CAMERA_HEIGHT))
                            pz = pz + h
                            local hit, x, y , z = intersect(px, py, pz, DISTANCE*vx, DISTANCE*vy, DISTANCE*vz, read_dword(get_player(i) + 0x34))
                            local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - DISTANCE_FROM_COLLISION
                            hit, x, y , z = intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(i) + 0x34))
							
							if(check_location(x, y, z, i)) then
								newPeliID = spawn_object("weap", PELICAN_TAG, x, y, z, 0)
								newCarryID = spawn_object("weap", PELICAN_CARRY_TAG, x, y, z, 0)
								timer(18333, "spawnhog", x, y, z)
								timer(18333, "destroy_vehicle", newCarryID)
								--timer(18000, "spawn_ai")
								--timer(18333, "teleport_ai", x, y, z)
								timer(29500, "destroy_vehicle", newPeliID)
							end
                        end
                    end
                    WEAPON_AMMO[player_weapon_id] = current_ammo
                end
            end
        end
    end
end

function OnScriptUnload() end
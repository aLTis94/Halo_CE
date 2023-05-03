--	Armor Ability script by aLTis (altis94@gmail.com)
--	Will only work in maps like BigassV3
--	You should only edit the spawn locations unless you know what you're doing
--	Auto turret will only work with ai sync script


--CONFIG	
	debug_mode = false -- prints debug info

	map_name = "bigass_" -- this script only works on this map (can just be a part of the map name)
	
	use_battery_hud = true 	-- set to false if you have weapons with batteries in your map
							-- requires modifying some HUD tags to use secondary loaded ammo instead of age
							-- setting to false also messes up weapon skins so don't use in bigass
	
	SPAWN_LOCATIONS = {		-- type, x, y, z
		{"Regen", -130.622, -62.7805, -0.2},
		{"Regen", 149.08, 32.8956, -0.75},
		{"Hologram", -142.047, 4.13594, 2.79},
		{"Hologram", 178.821, 95.7612, 6.95},
		{"EMP", 11.3799, -45.071, 1.58},
		{"EMP", -40.6592, 60.4578, 9.3},
		{"Bubble Shield", -33.4583, 8.15652, 3.39},
		{"Bubble Shield", 35.4629, 5.40593, 0.51},
		{"Drone", -126.827, -75.0669, 1.72572},
		{"Drone", 150.238, 45.6678, 1.07183},
	}
	
	COOLDOWNS = {	--	How long you need to wait after activating an ability
		["Bubble Shield"] = 30 * 30,
		["Hologram"] = 		15 * 30,
		["Regen"] = 		30 * 30,
		["EMP"] = 			15 * 30,
		["Drone"] =	31 * 30,
	}
	
	HUD_ID = {	--	Don't touch this, you won't understand it anyway
				--	For nerds that want to understand, these are ammo/age values at which HUD meters make only specific one visible
		["Bubble Shield"] = 47,
		["Hologram"] = 		75,
		["Regen"] = 		16,
		["EMP"] = 			30,
		["Drone"] =	60,
	}
	
	respawn_time = 15*1000	-- how often abilities respawn
	x_delay = 10 			-- how much frames to wait after E was pressed until X gets pressed again to activate ability
	vehicle_leave_timer = 3-- how many frames to wait until player can activate AA after he left a vehicle
	pick_up_range = 1.0 	-- distance from where you can pick up armor abilities
	
	health_regen_rate = 0.01
	health_regen_range = 1.5
	hologram_lifetime = 10 * 30
	auto_turret_lifetime = 30 * 1000	-- should be lower than cooldown
	auto_turret_altitude = 0.9		-- how far above player's location it spawns. it still flies up a bit higher after spawn
	emp_range = 4
	
	--tag locations
	--you must have all of the tags for each armor ability you want to use in your map
	bubble_shield_pickup = "armor_abilities\\pickups\\bubble shield"
	bubble_shield_deployed = "armor_abilities\\bubble_shield\\deployed\\bubble_shield"
	hologram_pickup = "armor_abilities\\pickups\\hologram"
	hologram_deployed = "armor_abilities\\hologram\\hologram_" -- red and blue
	hologram_deployed_idle = "armor_abilities\\hologram\\hologram_idle_" -- red and blue
	hologram_destruction_effect = "armor_abilities\\hologram\\hologram_destruction"
	health_regen_pickup = "armor_abilities\\pickups\\regen"
	health_regen_deployed = "armor_abilities\\health_regen\\health_regen"
	emp_pickup = "armor_abilities\\pickups\\emp"
	emp_deployed = "armor_abilities\\emp\\emp"
	auto_turret_pickup = "armor_abilities\\pickups\\drone"
	auto_turret_deployed = "ai\\turret\\biped"
	auto_turret_projectile = "ai\\turret\\weapons\\turret\\bullet"
--END OF CONFIG


api_version = "1.9.0.0"

PLAYERS = {}
PICKUPS = {}
REGENS = {}
HOLO = {}
WANTS_TURRET = {}
TURRETS = {}
stats_globals = nil
the_bsp = ""
game_count = 0

function OnScriptLoad()
    stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
	network_struct = read_dword(sig_scan("F3ABA1????????BA????????C740??????????E8????????668B0D") + 3)
	
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	
	Initialize()
end

function OnGameStart()
	game_count = game_count + 1
	Initialize()
end

function Initialize()
	if string.find(get_var(0, "$map"), map_name) then
		cprint("  AA script disabled")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		register_callback(cb['EVENT_WEAPON_PICKUP'],"OnWeaponPickup")
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		for i=1,16 do
			PLAYERS[i] = {}
			PLAYERS[i]["X_KEY"] = 0
			PLAYERS[i]["STATE"] = 0
			PLAYERS[i]["ABILITY"] = "Regen" -- FOR TESTING
			PLAYERS[i]["COOLDOWN"] = 0
			PLAYERS[i]["PREVIOUS_ACTION"] = 0
			PLAYERS[i]["DELAY"] = 0
			PLAYERS[i]["HOLD_X"] = 0
			PLAYERS[i]["HINT"] = 0
			PLAYERS[i]["VEHICLE_TIMER"] = 0
			WANTS_TURRET[i] = 0
			
			timer(100, "SyncAmmo", i)
		end
		
		GetTagData()
		
		timer(3000, "RespawnArmorAbilities", game_count)
	else
		cprint("  AA script enabled")
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
		unregister_callback(cb['EVENT_WEAPON_PICKUP'])
		unregister_callback(cb['EVENT_JOIN'])
	end
end

function GetTagData()
	bubble_tag = GetMetaID("weap", bubble_shield_pickup)
	emp_tag = GetMetaID("weap", emp_pickup)
	health_regen_tag = GetMetaID("weap", health_regen_pickup)
	hologram_tag = GetMetaID("weap", hologram_pickup)
	auto_turret_tag = GetMetaID("weap", auto_turret_pickup)
	auto_turret_deployed_tag = GetMetaID("bipd", auto_turret_deployed)
	auto_turret_projectile_tag = GetMetaID("proj", auto_turret_projectile)
	
	-- these must be disabled so player couldn't pick them up
	-- the script just fakes picking them up
	execute_command("disable_object \""..bubble_shield_pickup.."\"")
	execute_command("disable_object "..emp_pickup)
	execute_command("disable_object "..health_regen_pickup)
	execute_command("disable_object "..hologram_pickup)
	execute_command("disable_object \""..auto_turret_pickup.."\"")
end

function RespawnArmorAbilities(this_count)
	if game_count == tonumber(this_count) then
		for k,v in pairs (SPAWN_LOCATIONS) do
			pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..string.lower(v[1]), v[2], v[3], v[4])
			PICKUPS[pickup_id] = v[1]
			timer(respawn_time, "remove_object", pickup_id)
		end
		timer(respawn_time, "RespawnArmorAbilities", this_count)
	end
end

function OnPlayerJoin(i)
	PLAYERS[i]["HINT"] = 1
end

function OnPlayerSpawn(PlayerIndex)
	PLAYERS[PlayerIndex]["ABILITY"] = nil
	PLAYERS[PlayerIndex]["COOLDOWN"] = 0
end

function OnPlayerDeath(i)
	if PLAYERS[i]["ABILITY"] ~= nil then
		PICKUPS[spawn_object("weap", "armor_abilities\\pickups\\"..PLAYERS[i]["ABILITY"], PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.1)] = PLAYERS[i]["ABILITY"]
	end
end

function OnTick()
	--	Remove despawned pickups
	for ID,TYPE in pairs (PICKUPS) do
		if get_object_memory(ID) == 0 then
			PICKUPS[ID] = nil
		end
	end
	--	Remove turret IDs from the list if they don't exist anymore
	for ID,ALIVE in pairs (TURRETS) do
		if get_object_memory(ID) == 0 then
			TURRETS[ID] = nil
		end
	end
	
	
	execute_command("ai_migrate turret_red turret_red"..the_bsp)
	execute_command("ai_migrate turret_red1 turret_red"..the_bsp)
	execute_command("ai_migrate turret_red2 turret_red"..the_bsp)
	execute_command("ai_migrate turret_blue turret_blue"..the_bsp)
	execute_command("ai_migrate turret_blue1 turret_blue"..the_bsp)
	execute_command("ai_migrate turret_blue2 turret_blue"..the_bsp)
	
	SyncCooldowns()
	
	for i=1,16 do
		if WANTS_TURRET[i] > 0 then
			rprint(i, "You couldn't spawn a drone, yell at altis NOW!")
			WANTS_TURRET[i] = WANTS_TURRET[i] - 1
		end
		
		if player_alive(i) then
			if debug_mode == true then ClearConsole(i) end
			local player = get_dynamic_player(i)
			
			if read_dword(player + 0x11C) == 4294967295 then -- if player is not in a vehicle
				if PLAYERS[i]["VEHICLE_TIMER"] > 0 then
					if debug_mode == true then rprint(i, "vehicle timer: "..PLAYERS[i]["VEHICLE_TIMER"]) end
					PLAYERS[i]["VEHICLE_TIMER"] = PLAYERS[i]["VEHICLE_TIMER"] - 1
				end
			
				GetPlayerInput(i, player)
				CheckIfPickingUp(i)
				
				--	Check if player is activating an AA
				if PLAYERS[i]["X_KEY"] == 1 and PLAYERS[i]["VEHICLE_TIMER"] == 0 then
					--	AA happens here
					if PLAYERS[i]["COOLDOWN"] == 0 then
					--BUBBLE
						if PLAYERS[i]["ABILITY"] == "Bubble Shield" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Bubble Shield"]
							local ID = spawn_object("eqip", bubble_shield_deployed, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.01)
							timer(15000, "destroy_object", ID)
					--HOLOGRAM
						elseif PLAYERS[i]["ABILITY"] == "Hologram" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Hologram"]
							local team = get_var(i, "$team")
							local hologram_object = spawn_object("vehi", hologram_deployed..team, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.03, PLAYERS[i]["YAW"])
							local object = get_object_memory(hologram_object)
							if object ~= 0 then
								local pitch, yaw, roll = read_vector3d(object + 0x550)
								pitch = pitch/13
								yaw = yaw/13
								write_bit(object + 0x10, 5, 0)
								write_vector3d(object + 0x68, pitch, yaw, 0)
								HOLO[hologram_object] = {}
								HOLO[hologram_object].timer = hologram_lifetime
								HOLO[hologram_object].player_yaw = PLAYERS[i]["YAW"]
								HOLO[hologram_object].yaw = yaw
								HOLO[hologram_object].pitch = pitch
								HOLO[hologram_object].team = team
								HOLO[hologram_object].x, HOLO[hologram_object].y, HOLO[hologram_object].z = read_vector3d(object + 0x5C)
							end
					--REGEN
						elseif PLAYERS[i]["ABILITY"] == "Regen" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Regen"]
							local ID = spawn_object("eqip", health_regen_deployed, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.01)
							REGENS[ID] = 1
							timer(15000, "destroy_object", ID)
					--EMP
						elseif PLAYERS[i]["ABILITY"] == "EMP" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["EMP"]
							local emp = spawn_object("proj", emp_deployed, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.05)
							local player_team = get_var(i, "$team")
							local ffa = get_var(i, "$ffa")
							for j=1,16 do
								if player_alive(j) and (get_var(j, "$team") ~= player_team or ffa == 1) and j ~= i then
									local enemy = get_dynamic_player(j)
									local x1, y1, z1 = read_vector3d(enemy + 0x5C)
									local vehicle = get_object_memory(read_dword(enemy + 0x11C))
									if vehicle ~= 0 then
										x1, y1, z1 = read_vector3d(vehicle + 0x5C)
									end
									if DistanceFormula(x1,y1,z1,PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"]) < emp_range then
										write_float(enemy + 0xE4, 0)
									end
								end
							end
							for ID,ALIVE in pairs (TURRETS) do
							local turret_object = get_object_memory(ID)
								if turret_object ~= 0 then
									local x1, y1, z1 = read_vector3d(turret_object + 0x5C)
									local distance = DistanceFormula(x1, y1, z1, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"])
									if distance < emp_range then
										write_float(turret_object + 0xE0, 0)
										TURRETS[ID] = nil
									end
								end
							end
						elseif PLAYERS[i]["ABILITY"] == "Drone" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Drone"]
							local player_team = get_var(i, "$team")
							local ffa = get_var(i, "$ffa")
							WANTS_TURRET[i] = 1
							BSP()
							if the_bsp == 0 then
								the_bsp = ""
							end
							local encounter = "turret_"..player_team
							execute_command("ai_place "..encounter)
							--execute_command("ai_place turret_blue")
						end
					else
						--rprint(i, "|c"..math.floor(PLAYERS[i]["COOLDOWN"]/30).."s left")
					end
				end
			else
				PLAYERS[i]["VEHICLE_TIMER"] = vehicle_leave_timer
			end
			
			RegenerateHealth(i, player)
			
			--	Cooldown
			if PLAYERS[i]["COOLDOWN"] > 0 then
				PLAYERS[i]["COOLDOWN"] = PLAYERS[i]["COOLDOWN"] - 1
				if PLAYERS[i]["COOLDOWN"] == 0 then
					--rprint(i, "|cAbility ready!")
				end
			end
			
		end
	end
	
	--	Remove hologram or replace it with idle hologram
	for ID, value in pairs (HOLO) do
		if value.timer > 0 then
			value.timer = value.timer - 1
			if value.idle == nil then
				local object = get_object_memory(ID)
				if object ~= 0 then
					local x, y, z = read_vector3d(object + 0x5C)
					local distance = DistanceFormula(x, y, z, value.x, value.y, value.z)
					if distance > 0.06 or distance == 0 then
						value.x = x
						value.y = y
						value.z = z
						write_bit(object + 0x10, 5, 0)
						local x_vel, y_vel, z_vel = read_vector3d(object + 0x68)
						write_vector3d(object + 0x68, value.pitch, value.yaw, z_vel)
					else
						--add idle vehicle
						new_ID = spawn_object("vehi", hologram_deployed_idle..value.team, value.x, value.y, value.z - 0.19, value.player_yaw)
						local x_temp = value.x
						local y_temp = value.y
						local z_temp = value.z
						HOLO[new_ID] = {}
						HOLO[new_ID].x = x_temp
						HOLO[new_ID].y = y_temp
						HOLO[new_ID].z = z_temp
						HOLO[new_ID].timer = value.timer
						HOLO[new_ID].idle = 1
						destroy_object(ID)
						HOLO[ID] = nil
					end
				else
					HOLO[ID] = nil
				end
			end
		else
			local destruction_effect = spawn_object("weap", hologram_destruction_effect, value.x, value.y, value.z)
			timer(100, "destroy_object", destruction_effect)
			destroy_object(ID)
			HOLO[ID] = nil
		end
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	local found = false
	if MetaID == auto_turret_deployed_tag then
		for i=1,16 do
			if found == false and WANTS_TURRET[i] > 0 then
				WANTS_TURRET[i] = 0
				timer(33, "PlaceTurret", i, ID)
				found = true
				TURRETS[ID] = 1
			end
		end
	end
end

function PlaceTurret(i, ID)
	i = tonumber(i)
	ID = tonumber(ID)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local x, y, z = read_vector3d(player + 0x5C)
		local turret_object = get_object_memory(ID)
		if turret_object ~= 0 then
			timer(auto_turret_lifetime, "remove_object", ID)
			
			write_vector3d(turret_object + 0x5C, x, y, z+auto_turret_altitude)  -- move biped to player's location
			write_float(turret_object + 0x70, 0.08)								-- give it a bit of velocity to fly up
			
			-- change the parent of the turret to the player who spawned it
			-- this way kills will count correctly instead of getting killed by guardians
			local player_id = read_dword(stats_globals + to_real_index(i)*48 + 0x4)
			write_dword(turret_object + 0xC0, player_id)
			write_dword(turret_object + 0xC4, read_dword(get_player(i) + 0x34))
		else
			destroy_object(ID)
		end
	else
		destroy_object(ID)
	end
end

function SyncCooldowns()--	Get players positions and set weapon ammo to sync cooldown meter
	for i=1,16 do
		if player_alive(i) then
			local player = get_dynamic_player(i)
			PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] = read_vector3d(player + 0x5C)
			for j = 0,2 do
				local currentWeapon = read_dword(player + 0x2F8 + j*0x4)
				local WeaponObj = get_object_memory(currentWeapon)
				if WeaponObj ~= 0 then
					local ammo = 0	-- this is used for the cooldown meter
					local age = 1	--	this is used for armor ability type
					if PLAYERS[i]["ABILITY"] ~= nil then
						ammo = math.floor( (COOLDOWNS[PLAYERS[i]["ABILITY"]] - PLAYERS[i]["COOLDOWN"])/ COOLDOWNS[PLAYERS[i]["ABILITY"]] * 88)
						age = HUD_ID[PLAYERS[i]["ABILITY"]]
					end
					if ammo < 0 then
						ammo = 0
					end
					write_word(WeaponObj + 0x2C2, ammo)
					if use_battery_hud then
						execute_command("battery "..i.." "..age) -- There should be a better way of doing this
					else
						write_word(WeaponObj + 0x2C4, age)
					end
				end
			end
		end
	end
end

function OnWeaponPickup(i)
	timer(66, "SyncAmmo", i)
end

function SyncAmmo(i) -- sync ammo for all weapons for this player
	i = tonumber(i)
	if player_alive(i) then
		local player = get_dynamic_player(i)
		for j = 0,2 do
			local currentWeapon = read_dword(player + 0x2F8 + j*0x4)
			if get_object_memory(currentWeapon) ~= 0 then
				sync_ammo(currentWeapon, 1)
			end
		end
	end
end

function CheckIfPickingUp(i) --	Check if player is picking up an AA
	if PLAYERS[i]["PREVIOUS_ACTION"] == 1 and PLAYERS[i]["HOLD_X"] == 0 then
		if PLAYERS[i]["STATE"] == 1 then
			PLAYERS[i]["STATE"] = 0
			local picked = false
			for ID,TYPE in pairs (PICKUPS) do
				if picked == false then
					local x1, y1, z1 = read_vector3d(get_object_memory(ID) + 0x5C)
					if DistanceFormula(x1,y1,z1,PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"]) < pick_up_range then
						if PLAYERS[i]["ABILITY"] ~= TYPE then
							if PLAYERS[i]["ABILITY"] ~= nil then
								pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..string.lower(PLAYERS[i]["ABILITY"]), PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.1)
								PICKUPS[pickup_id] = PLAYERS[i]["ABILITY"]
								timer(respawn_time, "remove_object", pickup_id)
							end
							PLAYERS[i]["ABILITY"] = TYPE
							if get_var(i, "$has_chimera") == "1" then
								rprint(i, "hud_msg~".."Picked up "..TYPE.." armor ability")
							else
								rprint(i, "Picked up "..TYPE.." armor ability|ncA9CCE3") -- tells player that he picked up an ability
								for g = 1,15 do
									rprint(i, " ")
								end
							end
							destroy_object(ID)
							PICKUPS[ID] = nil
							picked = true
							timer(66, "SyncAmmo", i)
							if PLAYERS[i]["HINT"] == 1 then
								say(i, "Press X to activate armor ability!")
								PLAYERS[i]["HINT"] = 0
							end
						end
					end
				end
			end
		end
	else
		PLAYERS[i]["STATE"] = 1
	end
end

function GetPlayerInput(i, player) -- checks if player is pressing X key
	local client_machineinfo_struct = network_struct + 0x3B8+0x40 + to_real_index(i) * 0xEC
	local action_key_all = read_bit(player + 0x209, 6)
	local action_key_only = read_bit(client_machineinfo_struct + 0x24, 6)
	local e_key = read_bit(player + 0x47A, 6)
	PLAYERS[i]["YAW"] = read_float(client_machineinfo_struct + 0x28)
	
	PLAYERS[i]["X_KEY"] = 0
	
	if action_key_all == 1 then
		if debug_mode == true then rprint(1, "action_key_all") end
		if PLAYERS[i]["DELAY"] == 0 and PLAYERS[i]["PREVIOUS_ACTION"] == 0 and e_key == 0 then
			--say(i, "X")
			PLAYERS[i]["X_KEY"] = 1
			if debug_mode == true then say_all("X_KEY") end
		end
		PLAYERS[i]["PREVIOUS_ACTION"] = 1
	else
		PLAYERS[i]["PREVIOUS_ACTION"] = 0
		PLAYERS[i]["HOLD_X"] = 0
	end
	
	if PLAYERS[i]["DELAY"] > 0 then
		if debug_mode == true then rprint(1, "DELAY") end
		PLAYERS[i]["DELAY"] = PLAYERS[i]["DELAY"] - 1
	end
	
	if e_key == 1 then
		if debug_mode == true then say_all("e_key") end
		PLAYERS[i]["DELAY"] = x_delay
	end
	
	if PLAYERS[i]["X_KEY"] == 1 then
		PLAYERS[i]["HOLD_X"] = 1
		execute_command("block_all_objects "..i.." 1")
	end
	
	if PLAYERS[i]["HOLD_X"] == 1 then
		if debug_mode == true then rprint(1, "holding X") end
	else
		execute_command("block_all_objects "..i.." 0")
	end
end

function RegenerateHealth(i, player)
	for ID,TYPE in pairs (REGENS) do 
		if get_object_memory(ID) == 0 then
			PICKUPS[ID] = nil
		else
			local x1, y1, z1 = read_vector3d(get_object_memory(ID) + 0x5C)
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 then
				PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] = read_vector3d(vehicle + 0x5C)
			end
			local player_health = read_float(player + 0xE0)
			local player_shields = read_float(player + 0xE4)
			if DistanceFormula(x1,y1,z1,PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"]) < health_regen_range then
				if player_health < 1.0 then
					write_float(player + 0xE0, player_health + health_regen_rate)
				end
				if player_shields < 0.999 and player_health > 0.95 then
					write_float(player + 0xE4, player_shields + health_regen_rate)
					write_bit(player + 0x122, 0, 1)
				end
			end
		end
	end
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= 0) then
		--cprint(object_dir..": "..address.."     "..read_dword(address + 0xC))
		return read_dword(address + 0xC)
	end
	return nil
end

function BSP()
    register_callback(cb['EVENT_ECHO'],"GetBSPIndex")
    execute_command("structure_bsp_index",0,true)
    unregister_callback(cb['EVENT_ECHO'])
    return the_bsp
end

function GetBSPIndex(Useless,BSPIndex)
    the_bsp = tonumber(BSPIndex)
end

function remove_object(object_id)
	destroy_object(tonumber(object_id))
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function OnScriptUnload() 
	for ID,TYPE in pairs (PICKUPS) do
		destroy_object(ID)
	end
	for ID, value in pairs (HOLO) do
		destroy_object(ID)
	end
	-- need to remove turrets on unload somehow
end
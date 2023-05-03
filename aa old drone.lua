--	Armor Ability script by aLTis (altis94@gmail.com)
--	Will only work in maps like BigassV3
--	You should only edit the spawn locations unless you know what you're doing


--CONFIG	
	debug_mode = false -- prints debug info

	map_name = "bigass_" -- this script only works on this map (can just be a part of the map name)
	
	spawn_on_death = true	-- players drop their armor abilities when they die
	
	use_battery_hud = true 	-- set to false if you have weapons with batteries in your map
							-- requires modifying some HUD tags to use secondary loaded ammo instead of age
							-- setting to false also messes up weapon skins so don't use in bigass
	
	default_ability = "Drone" --players spawn with this ability. set to nil if you don't want them to spawn with any
	
	SPAWN_LOCATIONS = {		-- type, x, y, z
		{"Regen", -132.334, -63.0751, 0.141824},
		{"Regen", 149.08, 32.8956, -0.75},
		{"Hologram", -142.047, 4.13594, 2.79},
		{"Hologram", 178.821, 95.7612, 6.95},
		{"EMP", 11.3799, -45.071, 1.58},
		{"EMP", -40.6592, 60.4578, 9.3},
		{"Bubble Shield", -33.4583, 8.15652, 3.39},
		{"Bubble Shield", 34.6, 9.88, 1.04389},
		{"Bubble Shield", -126.827, -75.0669, 1.72572},
		{"Bubble Shield", 150.238, 45.6678, 1.07183},
	}
	
	COOLDOWNS = {	--	How long you need to wait after activating an ability
		["Bubble Shield"] = 30 * 30,
		["Hologram"] = 		15 * 30,
		["Regen"] = 		30 * 30,
		["EMP"] = 			15 * 30,
		["Drone"] =			30 * 30,
	}
	
	HUD_ID = {	--	Don't touch this, you won't understand it anyway
				--	For nerds that want to understand, these are ammo/age values at which HUD meters make only specific one visible
		["Bubble Shield"] = 47,
		["Hologram"] = 		75,
		["Regen"] = 		16,
		["EMP"] = 			30,
		["Drone"] =			60,
	}
	
	respawn_time = 15	-- how often abilities respawn
	x_delay = 10 			-- how much frames to wait after E was pressed until X gets pressed again to activate ability
	vehicle_leave_timer = 3	-- how many frames to wait until player can activate AA after he left a vehicle
	pick_up_range = 1.0 	-- distance from where you can pick up armor abilities
	
	bubble_shield_lifetime = 12 * 30
	health_regen_rate = 0.008
	shield_regen_rate = 0.006
	health_regen_range = 1.5
	hologram_lifetime = 10 * 30
	emp_range = 4
	
	auto_turret_lifetime = 30 * 30	-- should be lower than cooldown
	auto_turret_altitude = 0.9		-- how far above player's location it spawns
	auto_turret_vel_factor = 0.06	-- how fast it moves
	auto_turret_max_distance = 20
	auto_turret_min_distance = 1.7
	auto_turret_acceleration = 0.003
	auto_turret_lead = 1
	auto_turret_weapon_error = 0.0003
	
	--tag locations
	--you must have all of the tags for each armor ability you want to use in your map
	bubble_shield_pickup = "armor_abilities\\pickups\\bubble shield"
	bubble_shield_deployed = "armor_abilities\\bubble_shield\\deployed\\bubble_shield"
	bubble_shield_device = "armor_abilities\\bubble_shield\\deployed\\device\\device"
	hologram_pickup = "armor_abilities\\pickups\\hologram"
	hologram_deployed = "armor_abilities\\hologram\\hologram_" -- red and blue
	hologram_deployed_idle = "armor_abilities\\hologram\\hologram_idle_" -- red and blue
	hologram_destruction_effect = "armor_abilities\\hologram\\hologram_destruction"
	health_regen_pickup = "armor_abilities\\pickups\\regen"
	health_regen_deployed = "armor_abilities\\health_regen\\health_regen"
	emp_pickup = "armor_abilities\\pickups\\emp"
	emp_deployed = "armor_abilities\\emp\\emp"
	auto_turret_pickup = "armor_abilities\\pickups\\drone"
	auto_turret_weapon = "ai\\turret\\weapons\\turret\\turret"
	auto_turret_projectile = "ai\\turret\\weapons\\turret\\bullet"
	auto_turret_vehicle = "ai\\turret\\turret\\0\\idle"
	auto_turret_vehicle_death = "ai\\turret\\garbage\\turret"
--END OF CONFIG


api_version = "1.9.0.0"

PLAYERS = {}
PICKUPS = {}
REGENS = {}
HOLO = {}
DEPLOYED_ABILITIES = {}
WANTS_TURRET = {}
TURRETS = {}
AI_ACTORS_TABLE_POINTER = nil
AI_ENCOUNTERS_TABLE_POINTER = nil
AI_ENCOUNTERS = {}
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
		stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
		cprint("  AA script enabled")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_WEAPON_PICKUP'],"OnWeaponPickup")
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		for i=1,16 do
			PLAYERS[i] = {}
			PLAYERS[i]["X_KEY"] = 0
			PLAYERS[i]["STATE"] = 0
			PLAYERS[i]["ABILITY"] = default_ability -- FOR TESTING
			PLAYERS[i]["COOLDOWN"] = 0
			PLAYERS[i]["PREVIOUS_ACTION"] = 0
			PLAYERS[i]["DELAY"] = 0
			PLAYERS[i]["HOLD_X"] = 0
			PLAYERS[i]["HINT"] = 0
			PLAYERS[i]["VEHICLE_TIMER"] = 0
			WANTS_TURRET[i] = 0
			
			timer(100, "SyncAmmo", i)
		end
		
		DEPLOYED_ABILITIES = {}
		
		GetTagData()
		
		timer(3000, "RespawnArmorAbilities", game_count)
	else
		cprint("  AA script disabled")
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_WEAPON_PICKUP'])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
	end
end

function GetTagData()
	bubble_tag = GetMetaID("weap", bubble_shield_pickup)
	emp_tag = GetMetaID("weap", emp_pickup)
	health_regen_tag = GetMetaID("weap", health_regen_pickup)
	hologram_tag = GetMetaID("weap", hologram_pickup)
	auto_turret_tag = GetMetaID("weap", auto_turret_pickup)
	auto_turret_projectile_tag = GetMetaID("proj", auto_turret_projectile)
	
	-- these must be disabled so player couldn't pick them up
	-- the script just fakes picking them up
	execute_command("disable_object \""..bubble_shield_pickup.."\"")
	execute_command("disable_object "..emp_pickup)
	execute_command("disable_object "..health_regen_pickup)
	execute_command("disable_object "..hologram_pickup)
	execute_command("disable_object \""..auto_turret_pickup.."\"")
	
	local scenario_metaid = read_dword(0x40440004)
    local scenario_tag = lookup_tag(scenario_metaid)
    local scenario_data = read_dword(scenario_tag + 0x14)
end

function RespawnArmorAbilities(this_count)
	if game_count == tonumber(this_count) then
		for k,v in pairs (SPAWN_LOCATIONS) do
			pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..string.lower(v[1]), v[2], v[3], v[4])
			PICKUPS[pickup_id] = {}
			PICKUPS[pickup_id].ability = v[1]
			PICKUPS[pickup_id].lifetime = respawn_time * 30
		end
		timer(respawn_time * 1000, "RespawnArmorAbilities", this_count)
	end
end

function OnPlayerJoin(i)
	PLAYERS[i]["HINT"] = 1
	
	for ID,ALIVE in pairs (TURRETS) do
		local object = get_object_memory(ID)
		if object ~= 0 then
			timer(100, "SendDroneInfo", ID, 1)
		end
	end
end

function OnPlayerSpawn(PlayerIndex)
	PLAYERS[PlayerIndex]["ABILITY"] = default_ability
	PLAYERS[PlayerIndex]["COOLDOWN"] = 0
end

function OnPlayerDeath(i)
	if PLAYERS[i]["ABILITY"] ~= nil then
		if spawn_on_death then
			local pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..string.lower(PLAYERS[i]["ABILITY"]), PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.2)
			PICKUPS[pickup_id] = {}
			PICKUPS[pickup_id].ability = PLAYERS[i]["ABILITY"]
			PICKUPS[pickup_id].lifetime = respawn_time * 30
		end
	end
end

function OnTick()
	--	Remove despawned pickups
	for ID,INFO in pairs (PICKUPS) do
		if get_object_memory(ID) == 0 then
			PICKUPS[ID] = nil
		else
			INFO.lifetime = INFO.lifetime - 1
			if INFO.lifetime < 1 then
				RemoveObject(ID)
				PICKUPS[ID] = nil
			end
		end
	end
	
	for ID, LIFETIME in pairs (DEPLOYED_ABILITIES) do
		if get_object_memory(ID) == 0 then
			DEPLOYED_ABILITIES[ID] = nil
		else
			DEPLOYED_ABILITIES[ID] = LIFETIME - 1
			if LIFETIME < 1 then
				RemoveObject(ID)
				DEPLOYED_ABILITIES[ID] = nil
			end
		end
	end
	
	for ID,INFO in pairs (TURRETS) do
		INFO.lifetime = INFO.lifetime - 1
		local object = get_object_memory(ID)
		
		if object == 0 or TURRETS[ID].lifetime == 0 then 
			TURRETS[ID] = nil
		elseif INFO.lifetime == 1 then
			if INFO.weapon ~= nil then
				RemoveObject(INFO.weapon)
				INFO.weapon = nil
			end
			timer(10, "SendDroneInfo", ID, 2)
			if get_var(INFO.master, "$has_chimera") == "1" then
				rprint(INFO.master, "remove_nav")
			end
			local x, y, z = read_vector3d(object + 0x5C)
			local yaw = read_float(object + 0x224)
			local pitch = read_float(object + 0x228)
			RemoveObject(ID)
			INFO.dead_vehicle = spawn_object("weap", auto_turret_vehicle_death, x, y, z, GetYaw(yaw, pitch))
		else
			INFO.x, INFO.y, INFO.z = read_vector3d(object + 0x5C)
			local x, y, z = read_vector3d(object + 0x5C)
			local x_vel_current, y_vel_current, z_vel_current = read_vector3d(object + 0x68)
			local turret_health = read_float(object + 0xE0)
			if turret_health < 0.992 then
				INFO.lifetime = 2
			end
			
			if INFO.lifetime%30 == 1 then
				write_vector3d(object + 0x5C, x, y, z)
			end
			
			--FINDING TARGET
			local closest_object = nil
			local is_a_drone = false
			local closest_distance = 10000
			local x2 = 0
			local y2 = 0
			local z2 = 0
			local x2_lead = 0
			local y2_lead = 0
			local z2_lead = 0
			
			-- look for players
			for i = 1,16 do
				if player_alive(i) then
					local player = get_dynamic_player(i)
					if TURRETS[ID].team == read_word(player + 0xB8) then
						x2, y2, z2 = read_vector3d(player + 0x550 + 0x28)
						local distance = DistanceFormula(x, y, z, x2, y2, z2)
						if distance < closest_distance then
							closest_distance = distance
							closest_object = player
						end
					end
				end
			end
			
			-- look for drones
			for ID2,INFO2 in pairs (TURRETS) do
				local object = get_object_memory(ID2)
				if object ~= 0 and INFO.team ~= INFO2.team then
					local distance = DistanceFormula(x, y, z, INFO2.x, INFO2.y, INFO2.z)
					if distance < closest_distance then
						closest_distance = distance
						closest_object = object
						is_a_drone = true
					end
				end
			end
			
			-- look for holograms
			for ID2,INFO2 in pairs (HOLO) do
				local object = get_object_memory(ID2)
				if object ~= 0 and INFO.team ~= INFO2.team then
					local distance = DistanceFormula(x, y, z, INFO2.x, INFO2.y, INFO2.z)
					if distance < closest_distance then
						closest_distance = distance
						closest_object = object
						is_a_drone = true
					end
				end
			end
			
			-- set target + lead
			if closest_object ~= nil then
				if is_a_drone then
					x2, y2, z2 = read_vector3d(closest_object + 0x5C)
				else
					x2, y2, z2 = read_vector3d(closest_object + 0x550 + 0x28)
				end
				local vehicle = get_object_memory(read_dword(closest_object + 0x11C))
				if read_dword(closest_object + 0x11C) ~= 0xFFFFFFFF and vehicle ~= 0 then
					x2 = x2 + read_float(closest_object + 0x68)
					y2 = y2 + read_float(closest_object + 0x6C)
					z2 = z2 + read_float(closest_object + 0x70)
					x2_lead = x2 + read_float(closest_object + 0x68)*auto_turret_lead
					y2_lead = y2 + read_float(closest_object + 0x6C)*auto_turret_lead
					z2_lead = z2 + read_float(closest_object + 0x70)*auto_turret_lead
				else
					x2 = x2 + read_float(closest_object + 0x68)
					y2 = y2 + read_float(closest_object + 0x6C)
					z2 = z2 + read_float(closest_object + 0x70)
					x2_lead = x2 + read_float(closest_object + 0x68)*auto_turret_lead
					y2_lead = y2 + read_float(closest_object + 0x6C)*auto_turret_lead
					z2_lead = z2 + read_float(closest_object + 0x70)*auto_turret_lead
				end
			end
			
			local x_dist = (x2 - x)
			local y_dist = (y2 - y)
			local z_dist = (z2 - z)
			local x_dist_lead = (x2_lead - x)
			local y_dist_lead = (y2_lead - y)
			local z_dist_lead = (z2_lead - z)
			
			--ROTATION
			if closest_distance > auto_turret_max_distance and INFO.nav_x ~= nil then
				x_dist = (INFO.nav_x - x)
				y_dist = (INFO.nav_y - y)
				z_dist = (INFO.nav_z - z)
			end
			local rot_x = x_dist / closest_distance
			local rot_y = y_dist / closest_distance
			local rot_z = z_dist / closest_distance
			local rot_x_lead = x_dist_lead / closest_distance
			local rot_y_lead = y_dist_lead / closest_distance
			local rot_z_lead = z_dist_lead / closest_distance
			INFO.r_x = rot_x
			INFO.r_y = rot_y
			INFO.r_z = rot_z
			if (x2 == 0 and INFO.nav_x == nil) == false then
				write_vector3d(object + 0x74, rot_x, rot_y, rot_z)
				write_vector3d(object + 0x80, 0, 0, 1)	
			end
			
			--SHOOTING
			if INFO.lifetime + 30 < auto_turret_lifetime then
				local hit, x3, y3 , z3, hit_id = intersect(x, y, z, 10000*rot_x, 10000*rot_y, 10000*rot_z, ID)
				if x3 ~= nil then
					local distance_to_aim_location = DistanceFormula(x2, y2, z2, x3, y3, z3)
					if closest_distance < 18 and distance_to_aim_location < 1.8 then
						local x_error = -rand(1, 100)*auto_turret_weapon_error + auto_turret_weapon_error*50
						local y_error = -rand(1, 100)*auto_turret_weapon_error + auto_turret_weapon_error*50
						local z_error = -rand(1, 100)*auto_turret_weapon_error + auto_turret_weapon_error*50
						if INFO.lifetime%5 == 1 then
							spawn_projectile(auto_turret_projectile_tag, INFO.master_id, x + rot_x_lead*0.3, y + rot_y_lead*0.3, z + rot_z_lead*0.3, rot_x_lead + x_error, rot_y_lead + y_error, rot_z_lead + z_error)
						end
						--if TURRETS[ID].weapon == nil or get_object_memory(TURRETS[ID].weapon) == 0 then
						--	local yaw = read_float(object + 0x224)
						--	local pitch = read_float(object + 0x228)
						--	TURRETS[ID].weapon = spawn_object("weap", auto_turret_weapon, x, y, z, GetYaw(yaw, pitch))
						--end
						--if TURRETS[ID].weapon ~= nil and get_object_memory(TURRETS[ID].weapon) ~= 0 then
						--	local weapon_object = get_object_memory(TURRETS[ID].weapon)
						--	write_vector3d(weapon_object + 0x5C, x + rot_x_lead*0.3, y + rot_y_lead*0.3, z + rot_z_lead*0.3)
						--	write_vector3d(weapon_object + 0x68, x_vel_current, y_vel_current, z_vel_current)
						--	write_vector3d(weapon_object + 0x74, rot_x_lead, rot_y_lead, rot_z_lead)
						--	write_vector3d(weapon_object + 0x80, 0, 0, 1)
						--end
					--else
						--if TURRETS[ID].weapon ~= nil then
						--	RemoveObject(TURRETS[ID].weapon)
						--	TURRETS[ID].weapon = nil
						--end
					end
				end
			end
			
			--NAVPOINT
			local player = get_dynamic_player(INFO.master)
			if player ~= 0 then
				GetPlayerInput(INFO.master, player)
				if PLAYERS[INFO.master]["X_KEY"] == 1 and PLAYERS[INFO.master]["VEHICLE_TIMER"] == 0 then
					local hit, x, y, z = GetPlayerAimLocation(INFO.master)
					if x ~= 0 and z < 30 then
						TURRETS[ID].nav_x = x
						TURRETS[ID].nav_y = y
						TURRETS[ID].nav_z = z + 0.8
						if get_var(INFO.master, "$has_chimera") == "1" then
							rprint(INFO.master, "nav~default_red~"..x.."~"..y.."~"..z+0.8 .."~"..INFO.team)
							rprint(INFO.master, "play_chimera_sound~bumper")
						end
					end
				end
			end
			
			if INFO.nav_x ~= nil then
				if DistanceFormula(x, y, z, INFO.nav_x, INFO.nav_y, INFO.nav_z) < 1.2 then
					INFO.nav_x = nil
					INFO.nav_y = nil
					INFO.nav_z = nil
					if get_var(INFO.master, "$has_chimera") == "1" then
						rprint(INFO.master, "remove_nav")
					end
				else
					x_dist = (INFO.nav_x - x)
					y_dist = (INFO.nav_y - y)
					z_dist = (INFO.nav_z - z)
					distance = DistanceFormula(x, y, z, INFO.nav_x, INFO.nav_y, INFO.nav_z)
					rot_x = x_dist / distance
					rot_y = y_dist / distance
					rot_z = z_dist / distance
				end
			end
			
			--MOVING
			if false and (closest_distance < auto_turret_max_distance and closest_distance > auto_turret_min_distance) or INFO.nav_x ~= nil then
				local x_velocity = rot_x*auto_turret_vel_factor
				local y_velocity = rot_y*auto_turret_vel_factor
				local z_velocity = rot_z*auto_turret_vel_factor
				
				INFO.wanted_vel_x = x_velocity
				INFO.wanted_vel_y = y_velocity
				INFO.wanted_vel_z = z_velocity
				--INFO.wanted_vel_x = 0
				--INFO.wanted_vel_y = 0
				--INFO.wanted_vel_z = 0
			else
				INFO.wanted_vel_x = 0
				INFO.wanted_vel_y = 0
				INFO.wanted_vel_z = 0
			end
			
			if INFO.wanted_vel_x > x_vel_current then
				if INFO.wanted_vel_x > x_vel_current + auto_turret_acceleration then
					write_float(object + 0x68, x_vel_current + auto_turret_acceleration)
				else
					write_float(object + 0x68, INFO.wanted_vel_x)
				end
			else
				if INFO.wanted_vel_x < x_vel_current - auto_turret_acceleration then
					write_float(object + 0x68, x_vel_current - auto_turret_acceleration)
				else
					write_float(object + 0x68, INFO.wanted_vel_x)
				end
			end
			
			if INFO.wanted_vel_y > y_vel_current then
				if INFO.wanted_vel_y > y_vel_current + auto_turret_acceleration then
					write_float(object + 0x6C, y_vel_current + auto_turret_acceleration)
				else
					write_float(object + 0x6C, INFO.wanted_vel_y)
				end
			else
				if INFO.wanted_vel_y < y_vel_current - auto_turret_acceleration then
					write_float(object + 0x6C, y_vel_current - auto_turret_acceleration)
				else
					write_float(object + 0x6C, INFO.wanted_vel_y)
				end
			end
			
			if INFO.wanted_vel_z > z_vel_current then
				if INFO.wanted_vel_z > z_vel_current + auto_turret_acceleration then
					write_float(object + 0x70, z_vel_current + auto_turret_acceleration)
				else
					write_float(object + 0x70, INFO.wanted_vel_z)
				end
			else
				if INFO.wanted_vel_z < z_vel_current - auto_turret_acceleration then
					write_float(object + 0x70, z_vel_current - auto_turret_acceleration)
				else
					write_float(object + 0x70, INFO.wanted_vel_z)
				end
			end
			
			PushDroneAway(object, ID)
		end
	end
	
	SyncCooldowns()
	
	for i=1,16 do
		
		if player_alive(i) then
			if debug_mode == true then ClearConsole(i) end
			local player = get_dynamic_player(i)
			
			if read_dword(player + 0x11C) == 0xFFFFFFFF then -- if player is not in a vehicle
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
							local ID2 = spawn_object("eqip", bubble_shield_device, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.01)
							DEPLOYED_ABILITIES[ID] = bubble_shield_lifetime
							DEPLOYED_ABILITIES[ID2] = bubble_shield_lifetime
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
								write_vector3d(object + 0x68, pitch, yaw, 0) -- this is incorrect but whatever
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
							DEPLOYED_ABILITIES[ID] = 15 * 30
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
										write_float(turret_object + 0xE0, 0.5)
									end
								end
							end
					--DRONE
						elseif PLAYERS[i]["ABILITY"] == "Drone" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Drone"]
							local player_team = get_var(i, "$team")
							local ffa = get_var(i, "$ffa")
							local real_player_team = read_word(player + 0xB8)
							PlaceTurret(i, player_team, ffa, real_player_team)
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
						HOLO[new_ID].team = value.team
						RemoveObject(ID)
						HOLO[ID] = nil
					end
				else
					HOLO[ID] = nil
				end
			end
		else
			local destruction_effect = spawn_object("weap", hologram_destruction_effect, value.x, value.y, value.z)
			timer(100, "RemoveObject", destruction_effect)
			RemoveObject(ID)
			HOLO[ID] = nil
		end
	end
end

function RemoveObject(ID)
	ID = tonumber(ID)
	if get_object_memory(ID) ~= 0 then
		destroy_object(ID)
	else
		say_all("AA script: couldn't destroy object!")
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	if MetaID == auto_turret_projectile_tag then
		--timer(0, "ProjectileStuff", ID)
	end
end

function ProjectileStuff(ID)
	ID = tonumber(ID)
	local object = get_object_memory(ID)
	if object ~= 0 then
		local x, y, z = read_vector3d(object + 0x5C)
		local nearest_drones_master = nil
		local nearest_distance = 10000
		for ID2,INFO in pairs (TURRETS) do
			local distance = DistanceFormula(x, y, z, INFO.x, INFO.y, INFO.z)
			if distance < nearest_distance then
				nearest_drones_master = INFO.master
				nearest_distance = distance
			end
		end
		if nearest_drones_master ~= nil then
			--local player_id = read_dword(stats_globals + to_real_index(nearest_drones_master)*48 + 0x4)
			--write_dword(object + 0xC0, player_id)
			--write_dword(object + 0xC4, read_dword(get_player(nearest_drones_master) + 0x34))
			write_float(object + 0x68, read_float(object + 0x68)*10)
			write_float(object + 0x6C, read_float(object + 0x6C)*10)
			write_float(object + 0x70, read_float(object + 0x70)*10)
			return
		end
	end
end

function PushDroneAway(object, ID)
	local x, y, z = read_vector3d(object + 0x5c)
	local x_vel, y_vel, z_vel = read_vector3d(object + 0x68)
	local factor = 0.2
	local min_distance = 0.5
	local min_z_distance = 1
	local max_vel = 0.005
	
	local x_change = 0
	local y_change = 0
	local z_change = 0
	
	local x_pos_dist = DistanceToDirection(x, y, z, 10000, 0, 0, ID)
	local x_neg_dist = DistanceToDirection(x, y, z, -10000, 0, 0, ID) 
	local y_pos_dist = DistanceToDirection(x, y, z, 0, 10000, 0, ID) 
	local y_neg_dist = DistanceToDirection(x, y, z, 0, -10000, 0, ID) 
	local z_pos_dist = DistanceToDirection(x, y, z, 0, 0, 10000, ID) 
	local z_neg_dist = DistanceToDirection(x, y, z, 0, 0, -10000, ID) 
	
	if x_neg_dist < min_distance then
		x_change = (min_distance - x_neg_dist) * factor
	end
	if x_pos_dist < min_distance then
		x_change = x_change - (min_distance - x_pos_dist) * factor
	end
	if x_change > max_vel then
		x_change = max_vel
	elseif x_change < -max_vel then
		x_change = -max_vel
	end
	
	
	if y_neg_dist < min_distance then
		y_change = (min_distance - y_neg_dist) * factor
	end
	if y_pos_dist < min_distance then
		y_change = y_change - (min_distance - y_pos_dist) * factor
	end
	if y_change > max_vel then
		y_change = max_vel
	elseif y_change < -max_vel then
		y_change = -max_vel
	end
	
	
	if z_neg_dist < min_z_distance then
		z_change = (min_z_distance - z_neg_dist) * factor
	end
	if z_pos_dist < min_z_distance then
		z_change = z_change - (min_z_distance - z_pos_dist) * factor
	end
	if z_change > max_vel then
		z_change = max_vel
	elseif z_change < -max_vel then
		z_change = -max_vel
	end
	
	
	write_float(object + 0x68, x_vel + x_change)
	write_float(object + 0x6C, y_vel + y_change)
	write_float(object + 0x70, z_vel + z_change)
end

function PlaceTurret(i, player_team, ffa, real_player_team)
	i = tonumber(i)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local x, y, z = read_vector3d(player + 0x5C)
		ID = spawn_object("vehi", auto_turret_vehicle, x, y, z + auto_turret_altitude)
		local turret_object = get_object_memory(ID)
		if turret_object ~= 0 then
			TURRETS[ID] = {}
			TURRETS[ID].lifetime = auto_turret_lifetime
			TURRETS[ID].team = real_player_team
			TURRETS[ID].master = i
			TURRETS[ID].master_id = read_dword(get_player(i) + 0x34)
			TURRETS[ID].x = x
			TURRETS[ID].y = y 
			TURRETS[ID].z = z
			
			-- set health
			write_float(turret_object + 0xD8, 10000)
			write_float(turret_object + 0xE0, 1)
			
			-- change the parent of the turret to the player who spawned it
			-- this way kills will count correctly instead of getting killed by guardians
			local player_id = read_dword(stats_globals + to_real_index(i)*48 + 0x4)
			write_dword(turret_object + 0xC0, player_id)
			write_dword(turret_object + 0xC4, read_dword(get_player(i) + 0x34))
			
			write_word(turret_object + 0xB8, read_word(player + 0xB8))
			
			-- send information to users who have chimera
			TURRETS[ID].red,TURRETS[ID].green, TURRETS[ID].blue  = read_vector3d(player + 0x1D0)
			timer(200, "SendDroneInfo", ID, 1)
		else
			rprint(i, "couldn't spawn your drone.")
			RemoveObject(ID)
		end
	else
		RemoveObject(ID)
	end
end

function SendDroneInfo(ID, object_type)
	ID = tonumber(ID)
	object_type = tonumber(object_type)
	if TURRETS[ID] == nil or TURRETS[ID].red == nil then return false end
	for j=1,16 do
		if get_var(j, "$has_chimera") == "1" then
			--rprint(j, "drone_color~"..x.."~"..y.."~"..z.."~"..TURRETS[ID].red.."~"..TURRETS[ID].green.."~"..TURRETS[ID].blue)
			rprint(j, string.format("drone_color~%.4f~%.4f~%.4f~%.4f~%.4f~%.4f~%d", TURRETS[ID].x, TURRETS[ID].y, TURRETS[ID].z, TURRETS[ID].red, TURRETS[ID].green, TURRETS[ID].blue, object_type))
		end
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
			for ID,INFO in pairs (PICKUPS) do
				if picked == false then
					local x1, y1, z1 = read_vector3d(get_object_memory(ID) + 0x5C)
					if DistanceFormula(x1,y1,z1,PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"]) < pick_up_range then
						if PLAYERS[i]["ABILITY"] ~= INFO.ability then
							if PLAYERS[i]["ABILITY"] ~= nil then
								pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..string.lower(PLAYERS[i]["ABILITY"]), PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.1)
								PICKUPS[pickup_id] = {}
								PICKUPS[pickup_id].ability = PLAYERS[i]["ABILITY"]
								PICKUPS[pickup_id].lifetime = respawn_time * 30
							end
							PLAYERS[i]["ABILITY"] = INFO.ability
							
							if get_var(i, "$has_chimera") == "1" then
								rprint(i, "hud_msg~".."Picked up "..INFO.ability.." armor ability")
								rprint(i, "play_chimera_sound~aa_pickup")
							else
								rprint(i, "Picked up "..INFO.ability.." armor ability|ncA9CCE3") -- tells player that he picked up an ability
								for g = 1,15 do
									rprint(i, " ")
								end
							end
							
							RemoveObject(ID)
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
			REGENS[ID] = nil -- it was PICKUPS for some reason. did I fix it??
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
					write_float(player + 0xE4, player_shields + shield_regen_rate)
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

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetPlayerAimLocation(i)--	Finds coordinates at which player is looking (from giraffe)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local px, py, pz = read_vector3d(player + 0x5c)
		local vehicle = read_dword(player + 0x11C)
		local vehicle = get_object_memory(vehicle)
		if vehicle ~= 0 then
			px, py, pz = read_vector3d(vehicle + 0x5c)
		end
		local vx, vy, vz = read_vector3d(player + 0x230)
		local cs = read_float(player + 0x50C)
		local h = 0.62 - (cs * (0.62 - 0.35))
		pz = pz + h
		local hit, x, y , z = intersect(px, py, pz, 10000*vx, 10000*vy, 10000*vz, read_dword(get_player(i) + 0x34))
		local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - 0.1
		return intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(i) + 0x34))
	else
		return 0, 0, 0
	end
end

function DistanceToDirection(x, y, z, vx, vy, vz, ID)
	local hit, x_g, y_g , z_g, hit_id = intersect(x, y, z, vx, vy, vz, ID)
	return DistanceFormula(x_g, y_g , z_g, x, y, z)
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function GetYaw(yaw, pitch)-- Made by 002
    local cos_b = math.acos(pitch)
    
    local finalAngle = cos_b
    
    if(yaw < 0) then finalAngle = finalAngle * -1 end
 
    finalAngle = finalAngle - math.pi / 2
 
    if(finalAngle < 0) then finalAngle = finalAngle + math.pi * 2 end
 
    return  (math.pi*2) - finalAngle
end

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function OnError(Message)
	say_all("Error!"..Message)
end

function OnGameEnd()
	PICKUPS = {}
	DEPLOYED_ABILITIES = {}
	HOLO = {}
	TURRETS = {}
end

function OnScriptUnload() 
	for i=1,16 do
		if get_var(i, "$has_chimera") == "1" then
			rprint(i, "remove_nav")
		end
	end
	for ID,INFO in pairs (PICKUPS) do
		RemoveObject(ID)
	end
	for ID,LIFETIME in pairs (DEPLOYED_ABILITIES) do
		RemoveObject(ID)
	end
	for ID, value in pairs (HOLO) do
		RemoveObject(ID)
	end
	for ID, value in pairs (TURRETS) do
		if TURRETS[ID].weapon ~= nil then
			RemoveObject(TURRETS[ID].weapon)
			TURRETS[ID].weapon = nil
		end
		RemoveObject(ID)
	end
	-- need to remove turrets on unload somehow
end
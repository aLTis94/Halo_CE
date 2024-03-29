--	Armor Ability script by aLTis (altis94@gmail.com)
--	Will only work in maps like BigassV3
--	You should only edit the spawn locations unless you know what you're doing

api_version = "1.12.0.0"

--CONFIG	
	debug_mode = false -- prints debug info

	map_name = "bigass_" -- this script only works on this map (can just be a part of the map name)
	
	spawn_on_death = true	-- players drop their armor abilities when they die
	
	use_battery_hud = true 	-- set to false if you have weapons with batteries in your map
							-- requires modifying some HUD tags to use secondary loaded ammo instead of age
							-- setting to false also messes up weapon skins so don't use in bigass
	
	one_use = true	-- armor abilities can only be used once
	
	default_ability = nil --players spawn with this ability. set to nil if you don't want them to spawn with any
	-- ablities: "regen" "hologram" "emp" "bubble shield" "drone"
	
	auto_pickup = true -- players take AA aytomatically if they don't have any already
	
	SPAWN_LOCATIONS = {		-- type, x, y, z
		{"regen", -132.334, -63.0751, 0.141824},
		{"regen", 150.84, 32.4727, -0.483047},
		{"hologram", -142.047, 4.13594, 2.79},
		{"hologram", 178.821, 95.7612, 6.95},
		{"emp", 11.3799, -45.071, 1.58},
		{"emp", -40.6592, 60.4578, 9.3},
		{"bubble shield", -33.4583, 8.15652, 3.39},
		{"bubble shield", 34.6, 9.88, 1.04389},
		{"bubble shield", -126.827, -75.0669, 1.72572},
		{"bubble shield", 150.238, 45.6678, 1.07183},
		{"drone", -69.8743, -31.6166, 1.85},
		{"drone", 83.0602, 34.0942, 1.60543},
		{"regen", 7.2454, -45.7885, 3.23687},
	}
	
	COOLDOWNS = {	--	How long you need to wait after activating an ability
		["bubble shield"] = 35 * 30,
		["hologram"] = 		17 * 30,
		["regen"] = 		35 * 30,
		["emp"] = 			15 * 30,
		["drone"] =			40 * 30,
	}
	
	HUD_ID = {	--	Don't touch this, you won't understand it anyway
				--	For nerds that want to understand, these are ammo/age values at which HUD meters make only specific one visible
		["bubble shield"] = 47,
		["hologram"] = 		75,
		["regen"] = 		16,
		["emp"] = 			30,
		["drone"] =			60,
	}
	
	respawn_time = 15	-- how often abilities respawn
	x_delay = 10 			-- how much frames to wait after E was pressed until X gets pressed again to activate ability
	vehicle_leave_timer = 3	-- how many frames to wait until player can activate AA after he left a vehicle
	pick_up_range = 1.0 	-- distance from where you can pick up armor abilities
	
	bubble_shield_lifetime = 10 * 30
	health_regen_rate = 0.007
	shield_regen_rate = 0.006
	health_regen_range = 1.5
	hologram_lifetime = 10 * 30
	emp_range = 4
	
	auto_turret_lifetime = 40 * 30	-- should be lower than cooldown
	auto_turret_altitude = 0.9		-- how far above player's location it spawns
	auto_turret_vel_factor = 0.05	-- how fast it moves
	auto_turret_max_distance = 20
	auto_turret_min_distance = 1.7
	auto_turret_acceleration = 0.004
	auto_turret_lead = 1			-- how much to lead the shots based on target's velocity
	auto_turret_weapon_error = 0.0003	-- accuracy. lower = more accurate
	auto_turret_rate_of_fire = 5	-- how fast it fires. lower = faster (in ticks)
	turret_health_cutoff = 0.9948	-- how much health it has. higher value means less
	turret_hostile = false			-- for testing only! makes the turret hostile towards the owner
	
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
	
	EXPLOSIVE_PROJECTILES = {
		"altis\\vehicles\\mortargoose\\grenade",
		"altis\\vehicles\\truck_katyusha\\rocket",
		"altis\\weapons\\boom\\bomb",
		"bourrin\\halo reach\\vehicles\\warthog\\gauss\\round",
		"bourrin\\halo reach\\vehicles\\warthog\\rocket\\rocket",
		"cmt\\weapons\\human\\frag_grenade\\frag grenade",
		"my_weapons\\trip-mine\\explosion",
		"reach\\objects\\vehicles\\unsc\\falcon\\rocket\\rocket",
		"reach\\objects\\weapons\\support_high\\rocket_launcher\\projectiles\\rocket",
		"reach\\objects\\weapons\\support_high\\rocket_launcher\\projectiles\\rocket homing",
		"altis\\vehicles\\scorpion\\tank shell",
		"weapons\\gauss sniper\\gauss new",
	}
--END OF CONFIG



PLAYERS = {}
PICKUPS = {}
REGENS = {}
HOLO = {}
DEPLOYED_ABILITIES = {}
WANTS_TURRET = {}
TURRETS = {}
stats_globals = nil
game_count = 0
remove_all_aa = false
FORGE_SPAWN_LOCATIONS = {}
CUSTOM_KEYS = {}

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D") 
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
		remove_all_aa = false
		stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
		cprint("  AA script enabled")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_WEAPON_PICKUP'],"OnWeaponPickup")
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
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
			PLAYERS[i]["MELEE_TIMER"] = 0
			PLAYERS[i].CUSTOM_KEYS = nil
			
			timer(100, "SyncAmmo", i)
		end
		
		DEPLOYED_ABILITIES = {}
		FORGE_SPAWN_LOCATIONS = {}
		
		GetTagData()
		
		timer(3000, "RespawnArmorAbilities", game_count)
	else
		cprint("  AA script disabled")
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_WEAPON_PICKUP'])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_GAME_END'])
		unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
	end
end

function GetTagData()
	bubble_tag = GetMetaID("weap", bubble_shield_pickup)
	emp_tag = GetMetaID("weap", emp_pickup)
	health_regen_tag = GetMetaID("weap", health_regen_pickup)
	hologram_tag = GetMetaID("weap", hologram_pickup)
	auto_turret_tag = GetMetaID("weap", auto_turret_pickup)
	auto_turret_projectile_tag = GetMetaID("proj", auto_turret_projectile)
	
	EXPLOSIVE_PROJECTILES_TAGS = {}
	for i=1,#EXPLOSIVE_PROJECTILES do
		--cprint(EXPLOSIVE_PROJECTILES[i])
		EXPLOSIVE_PROJECTILES_TAGS[GetMetaID("proj", EXPLOSIVE_PROJECTILES[i])] = true
	end
	
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
		if remove_all_aa then
			for k,v in pairs (FORGE_SPAWN_LOCATIONS) do
				pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..v[1], v[2], v[3], v[4])
				PICKUPS[pickup_id] = {}
				PICKUPS[pickup_id].ability = v[1]
				PICKUPS[pickup_id].lifetime = respawn_time * 30
			end
		else
			for k,v in pairs (SPAWN_LOCATIONS) do
				pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..v[1], v[2], v[3], v[4])
				PICKUPS[pickup_id] = {}
				PICKUPS[pickup_id].ability = v[1]
				PICKUPS[pickup_id].lifetime = respawn_time * 30
			end
		end
		timer(respawn_time * 1000, "RespawnArmorAbilities", this_count)
	end
end

function OnPlayerJoin(i)
	PLAYERS[i]["HINT"] = 1
	PLAYERS[i].CUSTOM_KEYS = nil
	
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
			local pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..PLAYERS[i]["ABILITY"], PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.2)
			PICKUPS[pickup_id] = {}
			PICKUPS[pickup_id].ability = PLAYERS[i]["ABILITY"]
			PICKUPS[pickup_id].lifetime = respawn_time * 30
		end
	end
end

function DroneMelee()
	--	Check if player is meleeing a drone
	for ID,INFO in pairs (TURRETS) do -- only do this if there's at least one drone
		for i=1,16 do
			local player = get_dynamic_player(i)
			if player ~= 0 then
				local melee = read_byte(player + 0x505)
				local hit, x, y, z, target_id = GetPlayerAimLocation(i)
				if target_id ~= nil and target_id ~= 0xFFFFFFFF then
					local object = get_object_memory(target_id)
					if object ~= 0 then
						for ID,INFO in pairs (TURRETS) do
							if ID == target_id and INFO.team ~= read_word(player + 0xB8) then
								if get_var(i, "$has_chimera") == "1" then
									rprint(i, "red_reticle")
								end
								if PLAYERS[i]["MELEE_TIMER"] == 0 and melee ~= 0 then
									local x,y,z = read_vector3d(player + 0x5C)
									local distance = DistanceFormula(x, y, z, INFO.x, INFO.y, INFO.z)
									if distance < 1.4 then
										if get_var(i, "$has_chimera") == "1" then
											rprint(i, "play_chimera_sound~ting~0.2")
										end
										KillDrone(ID, INFO)
									end
								end
							end
						end
					end
				end
				PLAYERS[i]["MELEE_TIMER"] = melee
			end
		end
		break
	end
end

function KillDrone(ID, INFO)
	if INFO.weapon ~= nil then
		RemoveObject(INFO.weapon)
		INFO.weapon = nil
	end
	
	timer(10, "SendDroneInfo", ID, 2) -- change the color of the dead drone obj
	if get_var(INFO.master, "$has_chimera") == "1" then
		rprint(INFO.master, "remove_nav")
	end
	local object = get_object_memory(ID)
	if object ~= 0 then
		DroneHitmarker(object)
		local x, y, z = read_vector3d(object + 0x5C)
		local yaw, pitch = read_float(object + 0x23C), read_float(object + 0x240)
		RemoveObject(ID)
		INFO.dead_vehicle = spawn_object("weap", auto_turret_vehicle_death, x, y, z, GetYaw(yaw, pitch))
	end
end

function DroneHitmarker(object)
	local damage = read_word(object + 0x406)
	if damage == 45 then
		local causing_obj = get_object_memory(read_dword(object + 0x40C))
		if causing_obj ~= 0 then
			for i=1,16 do
				if get_dynamic_player(i) == causing_obj then
					if get_var(i, "$has_chimera") == "1" then
						rprint(i, "play_chimera_sound~ting~0.2")
					end
					return
				end
			end
		end
	end
end

function DroneAI()
	for ID,INFO in pairs (TURRETS) do
		INFO.lifetime = INFO.lifetime - 1
		local object = get_object_memory(ID)
		
		if object == 0 then 
			TURRETS[ID] = nil
		elseif INFO.lifetime < 2 then
			KillDrone(ID, INFO)
		else
			local x, y, z = read_vector3d(object + 0x5C)
			INFO.x, INFO.y, INFO.z = x, y, z
			local x_vel_current, y_vel_current, z_vel_current = read_vector3d(object + 0x68)
			local turret_health = read_float(object + 0xE4)
			--rprint(1, turret_health)
			if turret_health < turret_health_cutoff then
				KillDrone(ID, INFO)
				goto drone_end
			end
			
			if INFO.lifetime%30 == 1 then
				write_vector3d(object + 0x5C, x, y, z)
			end
			
			-- hitmarker sound
			DroneHitmarker(object)
			
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
					if TURRETS[ID].team ~= read_word(player + 0xB8) and read_float(player + 0x37C) < 0.3 then
						x2, y2, z2 = read_vector3d(player + 0x550 + 0x28)
						local distance = DistanceFormula(x, y, z, x2, y2, z2)
						local x_dist = (x2 - x)
						local y_dist = (y2 - y)
						local z_dist = (z2 - z)
						local rot_x = x_dist / distance
						local rot_y = y_dist / distance
						local rot_z = z_dist / distance
						local hit, x3, y3 , z3, hit_id = intersect(x, y, z, 10000*rot_x, 10000*rot_y, 10000*rot_z, ID)
						local intersection_distance_to_target = DistanceFormula(x2, y2, z2, x3, y3, z3)
						if distance < closest_distance and intersection_distance_to_target < 3 then
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
				if object ~= 0 and INFO.team ~= INFO2.real_player_team then
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
				
				if INFO.nav_x_previous ~= nil and INFO.nav_delta < 1 then
					local distance = DistanceFormula(INFO.nav_x, INFO.nav_y, INFO.nav_z, INFO.x, INFO.y, INFO.z)
					--rprint(1, 1/distance)
					x_dist = (INFO.nav_x*INFO.nav_delta + INFO.nav_x_previous*(1-INFO.nav_delta) - x)
					y_dist = (INFO.nav_y*INFO.nav_delta + INFO.nav_y_previous*(1-INFO.nav_delta) - y)
					z_dist = (INFO.nav_z*INFO.nav_delta + INFO.nav_z_previous*(1-INFO.nav_delta) - z)
					INFO.nav_delta = INFO.nav_delta + 0.3/distance
				else
					x_dist = (INFO.nav_x - x)
					y_dist = (INFO.nav_y - y)
					z_dist = (INFO.nav_z - z)
					
					SetPreviousPoint(INFO, INFO.nav_x, INFO.nav_y, INFO.nav_z)
				end
				
				if closest_distance == 10000 then
					--closest_distance = DistanceFormula(INFO.x, INFO.y, INFO.z, INFO.nav_x, INFO.nav_y, INFO.nav_z)
					closest_distance = math.abs(x_dist)+math.abs(y_dist)+math.abs(z_dist)
				end
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
				--rprint(1, rot_x.."  "..rot_y.."  "..rot_z)
				--rprint(1, math.abs(rot_x)+math.abs(rot_y)+math.abs(rot_z))
				--rprint(1, closest_distance)
				write_vector3d(object + 0x74, rot_x, rot_y, rot_z)
				write_vector3d(object + 0x80, 0, 0, 1)
			end
			
			--SHOOTING
			if INFO.lifetime + 30 < auto_turret_lifetime and INFO.rate_of_fire < 1 then
				INFO.rate_of_fire = auto_turret_rate_of_fire
				local hit, x3, y3 , z3, hit_id = intersect(x, y, z, 10000*rot_x, 10000*rot_y, 10000*rot_z, ID)
				if x3 ~= nil then
					local distance_to_aim_location = DistanceFormula(x2, y2, z2, x3, y3, z3)
					if closest_distance < 18 and distance_to_aim_location < 1.8 then
						local x_error = -rand(1, 100)*auto_turret_weapon_error + auto_turret_weapon_error*50
						local y_error = -rand(1, 100)*auto_turret_weapon_error + auto_turret_weapon_error*50
						local z_error = -rand(1, 100)*auto_turret_weapon_error + auto_turret_weapon_error*50
						spawn_projectile(auto_turret_projectile_tag, INFO.master_id, x + rot_x_lead*0.3, y + rot_y_lead*0.3, z + rot_z_lead*0.3, rot_x_lead + x_error, rot_y_lead + y_error, rot_z_lead + z_error)
					end
				end
			else
				INFO.rate_of_fire = INFO.rate_of_fire - 1
			end
			
			--NAVPOINT
			local player = get_dynamic_player(INFO.master)
			if player ~= 0 then
				GetPlayerInput(INFO.master, player)
				if PLAYERS[INFO.master]["X_KEY"] == 1 and PLAYERS[INFO.master]["VEHICLE_TIMER"] == 0 then
					local hit, x, y, z, target_id = GetPlayerAimLocation(INFO.master)
					if x ~= 0 and z < 30 then
						if INFO.nav_delta ~= nil and INFO.nav_delta ~= 1 and INFO.nav_x ~= nil then
							SetPreviousPoint(INFO, INFO.nav_x, INFO.nav_y, INFO.nav_z)
						end
						INFO.nav_delta = 0
						
						local new_target = false
						if (target_id ~= 0xFFFFFFFF or get_object_memory(target_id) ~= 0) and target_id ~= ID then
							local object = get_object_memory(target_id)
							local object_type = read_word(object + 0xB4)
							if object_type == 1 then
								INFO.target_id = target_id
								new_target = true
							elseif object_type == 0 then
								local vehicle_id = read_dword(object + 0x11C)
								if get_object_memory(vehicle_id) ~= 0 then
									INFO.target_id = vehicle_id
									new_target = true
								else
									INFO.target_id = target_id
									new_target = true
								end
							end
						end
						if DistanceFormula(x, y, z, PLAYERS[INFO.master]["x"], PLAYERS[INFO.master]["y"], PLAYERS[INFO.master]["z"]) < 1 then
							INFO.target_id = INFO.master_id
							new_target = true
						end
						
						if new_target == false then
							INFO.target_id = nil
							TURRETS[ID].nav_x = x
							TURRETS[ID].nav_y = y
							TURRETS[ID].nav_z = z + 0.8
							if get_var(INFO.master, "$has_chimera") == "1" then
								rprint(INFO.master, "nav~default_red~"..x.."~"..y.."~"..z+0.8 .."~"..INFO.team)
							end
						end
						if get_var(INFO.master, "$has_chimera") == "1" then
							rprint(INFO.master, "play_chimera_sound~bumper")
						end
					end
				end
			end
			
			if INFO.target_id ~= nil then
				local object = get_object_memory(INFO.target_id)
				if object ~= 0 then
					local object_type = read_word(object + 0xB4)
					if (read_float(object + 0xE0) > 0 or object_type == 1) and read_float(object + 0x64) > -30 and read_float(object + 0x37C) < 0.3 then
						if object_type == 0 then
							TURRETS[ID].nav_x, TURRETS[ID].nav_y, TURRETS[ID].nav_z = read_vector3d(object + 0x550 + 0x28)
						else
							TURRETS[ID].nav_x, TURRETS[ID].nav_y, TURRETS[ID].nav_z = read_vector3d(object + 0x5C)
						end
						if get_var(INFO.master, "$has_chimera") == "1" then
							rprint(INFO.master, "nav~default_red~"..TURRETS[ID].nav_x.."~"..TURRETS[ID].nav_y.."~"..TURRETS[ID].nav_z .."~"..INFO.team)
						end
					else
						RemoveDroneNavpoint(ID)
					end
				else
					RemoveDroneNavpoint(ID)
				end
			end
			
			if INFO.nav_x ~= nil then
				local distance_to_nav = DistanceFormula(x, y, z, INFO.nav_x, INFO.nav_y, INFO.nav_z)
				if distance_to_nav < 1.2 or (INFO.target_id ~= nil and distance_to_nav < 2.0) then
					INFO.nav_x = nil
					INFO.nav_y = nil
					INFO.nav_z = nil
					if get_var(INFO.master, "$has_chimera") == "1" and INFO.target_id == nil then
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
			if (closest_distance < auto_turret_max_distance and closest_distance > auto_turret_min_distance) or INFO.nav_x ~= nil then
				-- this part makes drone move faster when there is nothing in front of it
				local distance_to_aim_location = 0
				local hit, x3, y3 , z3, hit_id = intersect(x, y, z, 15*rot_x, 15*rot_y, 15*rot_z, ID)
				if x3 ~= nil then
					distance_to_aim_location = DistanceFormula(x, y, z, x3, y3, z3) * 0.1 - 0.5
					if distance_to_aim_location < 0 then
						distance_to_aim_location = 0
					end
				end
				
				local x_velocity = rot_x*auto_turret_vel_factor*(1+distance_to_aim_location)
				local y_velocity = rot_y*auto_turret_vel_factor*(1+distance_to_aim_location)
				local z_velocity = rot_z*auto_turret_vel_factor*(1+distance_to_aim_location)
				
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
			::drone_end::
		end
	end
end

function RemoveDespawnedPickups()
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
end

function RemoveDeployedAbilities()
	for ID, INFO in pairs (DEPLOYED_ABILITIES) do
		if get_object_memory(ID) == 0 then
			DEPLOYED_ABILITIES[ID] = nil
		else
			INFO.lifetime = INFO.lifetime - 1
			if INFO.lifetime < 1 then
				RemoveObject(ID)
				DEPLOYED_ABILITIES[ID] = nil
			end
		end
	end
end

function OnTick()
	
	DroneAI()
	DroneMelee()
	RemoveDespawnedPickups()
	RemoveDeployedAbilities()
	SyncCooldowns()
	
	for i=1,16 do
		
		if player_alive(i) and GetName(get_dynamic_player(i)) ~= "characters\\floodcombat_human\\player\\flood player" then
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
					ActivateAA(i)
				end
			else
				PLAYERS[i]["VEHICLE_TIMER"] = vehicle_leave_timer
			end
			
			RegenerateHealth(i, player)
			
			--	Cooldown
			if PLAYERS[i]["COOLDOWN"] > 0 then
				if one_use then
					PLAYERS[i]["ABILITY"] = nil
					PLAYERS[i]["COOLDOWN"] = 0
				else
					PLAYERS[i]["COOLDOWN"] = PLAYERS[i]["COOLDOWN"] - 1
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

function ActivateAA(i)
	i = tonumber(i)
	if PLAYERS[i]["COOLDOWN"] == 0 then
		
		local player = get_dynamic_player(i)
		
	--BUBBLE SHIELD
		if PLAYERS[i]["ABILITY"] == "bubble shield" then
			PLAYERS[i]["COOLDOWN"] = COOLDOWNS["bubble shield"]
			local ID = spawn_object("eqip", bubble_shield_deployed, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.01)
			local ID2 = spawn_object("eqip", bubble_shield_device, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.01)
			DEPLOYED_ABILITIES[ID] = {}
			DEPLOYED_ABILITIES[ID].lifetime = bubble_shield_lifetime
			DEPLOYED_ABILITIES[ID].type = PLAYERS[i]["ABILITY"]
			DEPLOYED_ABILITIES[ID2] = {}
			DEPLOYED_ABILITIES[ID2].lifetime = bubble_shield_lifetime
	--HOLOGRAM
		elseif PLAYERS[i]["ABILITY"] == "hologram" then
			PLAYERS[i]["COOLDOWN"] = COOLDOWNS["hologram"]
			local team = get_var(i, "$team")
			local real_player_team = read_word(player + 0xB8)
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
				HOLO[hologram_object].real_player_team = real_player_team
				HOLO[hologram_object].x, HOLO[hologram_object].y, HOLO[hologram_object].z = read_vector3d(object + 0x5C)
			end
			return
	--REGEN
		elseif PLAYERS[i]["ABILITY"] == "regen" then
			PLAYERS[i]["COOLDOWN"] = COOLDOWNS["regen"]
			local ID = spawn_object("eqip", health_regen_deployed, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.01)
			REGENS[ID] = 1
			DEPLOYED_ABILITIES[ID] = {}
			DEPLOYED_ABILITIES[ID].lifetime = 15 * 30
			DEPLOYED_ABILITIES[ID].type = PLAYERS[i]["ABILITY"]
			return
	--EMP
		elseif PLAYERS[i]["ABILITY"] == "emp" then
			PLAYERS[i]["COOLDOWN"] = COOLDOWNS["emp"]
			local emp = spawn_object("proj", emp_deployed, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.05)
			local player_team = get_var(i, "$team")
			local ffa = get_var(i, "$ffa")
			for j=1,16 do
				if player_alive(j) and (get_var(j, "$team") ~= player_team or ffa == "1") and j ~= i then
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
			for ID,INFO in pairs (TURRETS) do
			local turret_object = get_object_memory(ID)
				if turret_object ~= 0 then
					local x1, y1, z1 = read_vector3d(turret_object + 0x5C)
					local distance = DistanceFormula(x1, y1, z1, PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"])
					if distance < emp_range then
						KillDrone(ID, INFO)
					end
				end
			end
			return
	--DRONE
		elseif PLAYERS[i]["ABILITY"] == "drone" then
			local player_team = get_var(i, "$team")
			local ffa = get_var(i, "$ffa")
			local real_player_team = read_word(player + 0xB8)
			if PlaceTurret(i, player_team, ffa, real_player_team) then
				PLAYERS[i]["COOLDOWN"] = COOLDOWNS["drone"]
			end
			return
		end
	end
end

function CustomKey(i)
	PLAYERS[tonumber(i)]["CUSTOM_KEY"] = 1
end

function AddCustomKey(i, key)
	i = tonumber(i)
	if get_var(i, "$has_chimera") == "1" then
		PLAYERS[i].CUSTOM_KEYS = key
	end
end

function SetPreviousPoint(INFO, x, y, z)
	INFO.nav_x_previous = x
	INFO.nav_y_previous = y
	INFO.nav_z_previous = z
end

function RemoveObject(ID)
	ID = tonumber(ID)
	if get_object_memory(ID) ~= 0 then
		destroy_object(ID)
	else
		say_all("AA script: couldn't destroy object!")
	end
end

function RemoveDroneNavpoint(ID)
	TURRETS[ID].nav_x = nil
	TURRETS[ID].nav_y = nil
	TURRETS[ID].nav_z = nil
	TURRETS[ID].target_id = nil
	if get_var(TURRETS[ID].master, "$has_chimera") == "1" then
		rprint(TURRETS[ID].master, "remove_nav")
	end
end

function PushDroneAway(object, ID)
	local x, y, z = read_vector3d(object + 0x5c)
	local x_vel, y_vel, z_vel = read_vector3d(object + 0x68)
	local factor = 0.5
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
		local yaw, pitch = read_float(player + 0x23C), read_float(player + 0x240)
		ID = spawn_object("vehi", auto_turret_vehicle, x, y, z + auto_turret_altitude, GetYaw(yaw, pitch))
		local turret_object = get_object_memory(ID)
		if turret_object ~= 0 and read_dword(turret_object + 0x98) ~= 0 then
			TURRETS[ID] = {}
			TURRETS[ID].lifetime = auto_turret_lifetime
			if turret_hostile then
				TURRETS[ID].team = real_player_team + 1	
			else
				TURRETS[ID].team = real_player_team
			end
			TURRETS[ID].master = i
			TURRETS[ID].master_id = read_dword(get_player(i) + 0x34)
			TURRETS[ID].rate_of_fire = auto_turret_rate_of_fire
			TURRETS[ID].x = x
			TURRETS[ID].y = y 
			TURRETS[ID].z = z
			
			-- set health
			write_float(turret_object + 0xDC, 10000)
			write_float(turret_object + 0xE4, 1)
			
			-- change the parent of the turret to the player who spawned it
			-- this way kills will count correctly instead of getting killed by guardians
			local player_id = read_dword(stats_globals + to_real_index(i)*48 + 0x4)
			write_dword(turret_object + 0xC0, player_id)
			write_dword(turret_object + 0xC4, read_dword(get_player(i) + 0x34))
			
			write_word(turret_object + 0xB8, read_word(player + 0xB8))
			
			-- send information to users who have chimera
			TURRETS[ID].red,TURRETS[ID].green, TURRETS[ID].blue  = read_vector3d(player + 0x1D0)
			timer(200, "SendDroneInfo", ID, 1)
			return true
		else
			say(i, "Can't spawn a drone here!")
			if get_object_memory(ID) ~= 0 then
				RemoveObject(ID)
			end
			return false
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
			rprint(j, string.format("drone_color~%.4f~%.4f~%.4f~%.4f~%.4f~%.4f~%d", TURRETS[ID].x, TURRETS[ID].y, TURRETS[ID].z, TURRETS[ID].red, TURRETS[ID].green, TURRETS[ID].blue, object_type))
		end
	end
end

function SyncCooldowns()--	Get players positions and set weapon ammo to sync cooldown meter
	for i=1,16 do
		if player_alive(i) then
			local player = get_dynamic_player(i)
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 then
				PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] = read_vector3d(vehicle + 0x5C)
			else
				PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] = read_vector3d(player + 0x5C)
			end
			
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

function PickUp(i)
	local picked = false
	for ID,INFO in pairs (PICKUPS) do
		if picked == false then
			local x1, y1, z1 = read_vector3d(get_object_memory(ID) + 0x5C)
			if DistanceFormula(x1,y1,z1,PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"]) < pick_up_range then
				if PLAYERS[i]["ABILITY"] ~= INFO.ability then
					if PLAYERS[i]["ABILITY"] ~= nil then
						pickup_id = spawn_object("weap", "armor_abilities\\pickups\\"..PLAYERS[i]["ABILITY"], PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.1)
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
						if get_var(i, "$has_chimera") == "1" and PLAYERS[i].CUSTOM_KEYS ~= nil then
							say(i, "Press "..PLAYERS[i].CUSTOM_KEYS.." to activate armor ability!")
						else
							say(i, "Press [exchange weapon] (X) to activate armor ability!")
						end
						PLAYERS[i]["HINT"] = 0
					end
				end
			end
		end
	end
end

function CheckIfPickingUp(i) --	Check if player is picking up an AA
	if PLAYERS[i]["PREVIOUS_ACTION"] == 1 and PLAYERS[i]["HOLD_X"] == 0 then
		if PLAYERS[i]["STATE"] == 1 then
			PLAYERS[i]["STATE"] = 0
			PickUp(i)
		end
	else
		if auto_pickup and PLAYERS[i]["ABILITY"] == nil then
			PickUp(i)
		end
		PLAYERS[i]["STATE"] = 1
	end
end

function GetPlayerInput(i, player) -- checks if player is pressing X key
	if PLAYERS[i]["CUSTOM_KEY"] ~= nil then
		PLAYERS[i]["CUSTOM_KEY"] = nil
		PLAYERS[i]["X_KEY"] = 1
		return
	end
	
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
		--if PLAYERS[i]["ABILITY"] ~= nil then
		--	execute_command("block_all_objects "..i.." 1")
		--	say_all("block!")
		--end
	end
	
	if PLAYERS[i]["HOLD_X"] == 1 then
		if debug_mode == true then rprint(1, "holding X") end
	--elseif PLAYERS[i]["ABILITY"] then
		--execute_command("block_all_objects "..i.." 0")
		--say_all("release!")
	end
	
	if PLAYERS[i].CUSTOM_KEYS ~= nil then 
		PLAYERS[i]["X_KEY"] = 0
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

function OnDamage(i, causer, tagID)
	for ID, INFO in pairs (DEPLOYED_ABILITIES) do
		if INFO.type == "bubble shield" then
			local player = get_dynamic_player(i)
			local object = get_object_memory(ID)
			if player ~= 0 and object ~= 0 then
				local vehicle = read_dword(player + 0x11C)
				if vehicle == 0xFFFFFFFF then
					local x,y,z = read_vector3d(player + 0x5C)
					local x2,y2,z2 = read_vector3d(object + 0x5C)
					local distance = DistanceFormula(x, y, z, x2, y2, z2)
					if distance < 3 then
						local distance_to_proj = FindProjectiles(causer, x2, y2, z2)
						if distance_to_proj ~= nil then
							--rprint(1, distance)
							--rprint(1, distance_to_proj)
							if distance < 1.35 then 
								if distance_to_proj > 1.36 then
									return false
								end
							elseif distance > 1.38 then
								if distance_to_proj < 1.37 then
									return false
								end
							end
							break
						end
					end
				end
			end
		end
	end
end

function FindProjectiles(causer, x, y, z)
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	closest_projectile_distance = 1000
	
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			if object_type == 5 and EXPLOSIVE_PROJECTILES_TAGS[read_dword(object)] ~= nil then
				local proj_status = read_bit(object + 0x22C, 4)
				if proj_status == 1 then -- if exploding
					local parent_obj_id = read_dword(object + 0xC4)
					local player = get_player(causer)
					if player ~= 0 then
						if read_dword(player + 0x34) == parent_obj_id then
							local x2, y2, z2 = read_vector3d(object + 0x5c)
							local distance_to_proj = DistanceFormula(x, y, z, x2, y2, z2)
							if distance_to_proj < closest_projectile_distance then
								closest_projectile_distance = distance_to_proj
							end
						end
					end
				end
			end
		end
	end
	if closest_projectile_distance ~= 1000 then
		return closest_projectile_distance
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
		local px, py, pz = read_vector3d(player + 0xA0)
		local vx, vy, vz = read_vector3d(player + 0x230)
		local cs = read_float(player + 0x50C)
		local standing_height = 0.25
		local crouching_change = 0.17
		local h = standing_height - (cs * (standing_height - crouching_change))
		pz = pz + h
		return intersect(px, py, pz, vx*1000, vy*1000, vz*1000, read_dword(get_player(i) + 0x34))
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

function GetYaw(yaw, pitch)
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

function RemoveAllAA()
	if string.find(get_var(0, "$map"), map_name) then
		for ID,INFO in pairs (PICKUPS) do
			RemoveObject(ID)
		end
		remove_all_aa = true
	end
end

function AddArmorAbilitySpawn(ability, x, y, z)
	if ability ~= nil and z ~= nil then
		if ability == "bubble_shield" then
			ability = "bubble shield"
		end
		table.insert(FORGE_SPAWN_LOCATIONS, 0, {ability, tonumber(x), tonumber(y), tonumber(z)})
	end
end

function OnScriptUnload() 
	if string.find(get_var(0, "$map"), map_name) then
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
	end
end
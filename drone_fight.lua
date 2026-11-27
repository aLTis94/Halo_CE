--	Drone Fight script by aLTis (altis94@gmail.com), Updated by Java (java@proxeninc.net)
--	Will only work in BigassV3
--	This script spawns a bunch of drones when there is a low player count.
-- 	Admins can manually spawn in drones at any time using a command /spawn_drones

api_version = "1.12.0.0"

--CONFIG	
debug_mode = false  -- prints debug info
muzzle_offset = 0.32  -- how far in front of the drone shots spawn (was 0.3; too close may spawn inside the drone's own collision)
debug_aim_log = false -- logs each drone's aim and where its shot passes the target (server console)
DEBUG_PROJ = {}

BLACKLISTED_GAMETYPES = {
	["survival"] = true,
	["tropical"] = true,
	["autumn"] = true,
	["forkball"] = true,
	["vehicle_madness"] = true,
}

map_name = "bigass_"             -- this script only works on this map (can just be a part of the map name)

auto_turret_lifetime = 240 * 30  -- should be lower than cooldown
auto_turret_altitude = 0.9       -- how far above player's location it spawns
auto_turret_vel_factor = 0.04    -- how fast it moves
auto_turret_max_vel = 0.1
shooting_distance = 20
auto_turret_max_distance = 50
auto_turret_keep_radius = 4.5       -- drones stop approaching at this distance from their target and back away if the target gets closer
auto_turret_retreat_boost = 2.5   -- how much faster than normal drones back away when inside the radius
auto_turret_flee_health = 0.994   -- drones run away below this health. must be above turret_health_cutoff (they die below that)
auto_turret_repair_rate = 0.00002 -- health a fleeing drone repairs each tick (0.00002 = about 5 seconds per 0.003)
auto_turret_recover_health = 0.9995 -- a drone that fled keeps fleeing until it has repaired to this
auto_turret_kamikaze_chance = 0.07   -- chance a new drone is a kamikaze: it charges its target without firing and blows up on them
auto_turret_kamikaze_speed = 2.2     -- kamikaze drones move this many times faster than normal
auto_turret_kamikaze_distance = 1    -- how close a kamikaze gets before it blows up
auto_turret_kamikaze_projectile = "bourrin\\halo reach\\vehicles\\warthog\\rocket\\rocket"  -- projectile spawned on the target to make the explosion
auto_turret_flee_distance = 35  -- a fleeing drone keeps running until its target is this far away
auto_turret_flee_turn_rate = 4    -- degrees per tick a fleeing drone turns toward the direction it's running (4 = about 1.5 seconds to turn all the way around)
auto_turret_flee_time = 8 * 30   -- ticks a fleeing drone keeps running after it loses sight of what it's running from
auto_turret_acceleration = 0.004
auto_turret_lead = 0.9            -- how much to lead the shots based on target's velocity
auto_turret_weapon_error = 0.0008 		-- accuracy. lower = more accurate
auto_turret_rate_of_fire = 6       -- how fast it fires. lower = faster (in ticks)
auto_turret_shots_per_burst = 2    -- projectiles fired each time the drone shoots
turret_health_cutoff = 0.992       -- how much health it has. higher value means less

auto_turret_weapon = "ai\\turret\\weapons\\turret\\turret"
auto_turret_projectile = "ai\\turret\\weapons\\turret\\bullet"
auto_turret_vehicle = "ai\\turret\\turret\\0\\idle"
auto_turret_vehicle_death = "ai\\turret\\garbage\\turret"

map_boundary_x_min = -190
map_boundary_x_max = 190
map_boundary_y_min = -95
map_boundary_y_max = 95
map_boundary_z_min = 2
map_boundary_z_max = 10

max_drone_count = 12

max_player_count = 4
--END_OF_CONFIG


stats_globals = nil
game_count = 0
start_timer = 0

function RespawnTurrets()
	local drone_count = 0
	for k, v in pairs(TURRETS) do
		drone_count = drone_count + 1
	end

	if drone_count < max_drone_count then
		local x = math.random(map_boundary_x_min, map_boundary_x_max)
		local y = math.random(map_boundary_y_min, map_boundary_y_max)
		local z = math.random(map_boundary_z_min, map_boundary_z_max)
		PlaceTurret(x, y, z)
	end
end

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
	network_struct = read_dword(sig_scan("F3ABA1????????BA????????C740??????????E8????????668B0D") + 3)

	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	register_callback(cb['EVENT_COMMAND'], "OnCommand")
	register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
	register_callback(cb['EVENT_CHAT'], "OnChat")

	Initialize()
end

function OnGameStart()
	game_count = game_count + 1
	Initialize()
end

function OnChat(i, message)
	if drones_active then
		message = string.lower(message)
		if message == "stop drones" or message == "stop drone" then
			StopDrones(i)
		end
	end
end

function StopDrones(i)
	RemoveAllDrones()
	unregister_callback(cb["EVENT_TICK"])
	force_spawn_drones = false
	say_all("Drones stopped by " .. get_var(i, "$name") .. "!")
end

function OnCommand(i, message, Environment, Password)
	message = string.lower(message)
	if message == "spawn_drones" and (get_var(i, "$lvl") > "2" or Environment == 0) then
		register_callback(cb["EVENT_TICK"], "OnTick")
		force_spawn_drones = true
		drones_active = true
		say_all("Drones activated by " .. get_var(i, "$name") .. "!")
		return false
	elseif message == "stop_drones" then
		StopDrones(i)
		return false
	end
	return true
end

function Initialize()
	if string.find(get_var(0, "$map"), map_name) then
		stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)

		PLAYERS = {}
		TURRETS = {}

		for i = 1, 16 do
			PLAYERS[i] = {}
			PLAYERS[i]["MELEE_TIMER"] = 0
		end
		start_timer = 0
		drones_active = false
		force_spawn_drones = false

		GetTagData()

		if BLACKLISTED_GAMETYPES[string.lower(get_var(0, "$mode"))] == nil then
			register_callback(cb["EVENT_TICK"], "OnTick")
		else
			unregister_callback(cb["EVENT_TICK"])
		end
	else
		unregister_callback(cb["EVENT_TICK"])
	end
end

function GetTagData()
	auto_turret_projectile_tag = GetMetaID("proj", auto_turret_projectile)
	-- no kamikazes if the map doesn't have the explosion
	auto_turret_kamikaze_tag = GetMetaID("proj", auto_turret_kamikaze_projectile)

	local scenario_metaid = read_dword(0x40440004)
	local scenario_tag = lookup_tag(scenario_metaid)
	local scenario_data = read_dword(scenario_tag + 0x14)
end

function DroneMelee()
	--	Check if player is meleeing a drone
	for ID, INFO in pairs(TURRETS) do -- only do this if there's at least one drone
		for i = 1, 16 do
			local player = get_dynamic_player(i)
			if player ~= 0 then
				local melee = read_byte(player + 0x505)
				local hit, x, y, z, target_id = GetPlayerAimLocation(i)
				if target_id ~= nil and target_id ~= 0xFFFFFFFF then
					local object = get_object_memory(target_id)
					if object ~= 0 then
						for ID, INFO in pairs(TURRETS) do
							if ID == target_id and INFO.team ~= read_word(player + 0xB8) then
								if get_var(i, "$has_chimera") == "1" then
									rprint(i, "red_reticle")
								end
								if PLAYERS[i]["MELEE_TIMER"] == 0 and melee ~= 0 then
									local x, y, z = read_vector3d(player + 0x5C)
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
			for i = 1, 16 do
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

-- Aim debugging. Logs, for one shot per drone every second:
--   aim_dz   = how far above (+) / below (-) the target the requested aim ray passes at the target's range.
--              Large + here means the script's own math aims high.
--   pitch    = requested pitch vs the pitch needed to hit the target's body, and the projectile's real pitch.
--   speed    = the projectile's speed right after spawn (a very low value means SAPP/the engine changed it).
-- A few ticks later it logs the closest the projectile got to the target:
--   miss dz  = + means it passed above. If aim_dz is ~0 but miss dz is large, the problem is after the script.
function DebugLogShot(ID, INFO, proj, idx, x, y, z, rx, ry, rz, lz)
	if proj == nil or proj == 0xFFFFFFFF or idx == nil then
		return
	end
	if INFO.dbg_next ~= nil and INFO.lifetime > INFO.dbg_next then
		return
	end
	local count = 0
	for _ in pairs(DEBUG_PROJ) do
		count = count + 1
	end
	if count >= 6 then
		return
	end
	local target = get_dynamic_player(idx)
	if target == 0 then
		return
	end
	INFO.dbg_next = INFO.lifetime - 30

	local tx, ty, tz = GetTargetBodyPosition(target)
	local dist = DistanceFormula(x, y, z, tx, ty, tz)
	local rlen = math.sqrt(rx * rx + ry * ry + rz * rz)
	local aim_dz = (z + rz / rlen * dist) - tz
	local want_pitch = math.deg(math.asin((tz - z) / dist))
	local req_pitch = math.deg(math.asin(rz / rlen))
	local tvx, tvy, tvz = read_vector3d(target + 0x68)

	local speed, real_pitch = 0, 0
	local obj = get_object_memory(proj)
	if obj ~= 0 then
		local pvx, pvy, pvz = read_vector3d(obj + 0x68)
		speed = math.sqrt(pvx * pvx + pvy * pvy + pvz * pvz)
		if speed > 0 then
			real_pitch = math.deg(math.asin(pvz / speed))
		end
	end

	cprint(string.format(
		"[drone dbg] shot %d dist %.1f aim_dz %+.2f lead_dz %+.2f | pitch want %.1f req %.1f real %.1f | speed %.3f | target vel %.3f %.3f %.3f",
		proj, dist, aim_dz, lz - tz, want_pitch, req_pitch, real_pitch, speed, tvx, tvy, tvz))

	DEBUG_PROJ[proj] = { idx = idx, age = 0, best = 1000000, dx = 0, dy = 0, dz = 0, at = 0 }
end

function DebugTrackProjectiles()
	for proj, D in pairs(DEBUG_PROJ) do
		D.age = D.age + 1
		local obj = get_object_memory(proj)
		local target = get_dynamic_player(D.idx)
		if obj ~= 0 and target ~= 0 then
			local px, py, pz = read_vector3d(obj + 0x5C)
			local tx, ty, tz = GetTargetBodyPosition(target)
			local d = DistanceFormula(px, py, pz, tx, ty, tz)
			if d < D.best then
				D.best = d
				D.dx, D.dy, D.dz = px - tx, py - ty, pz - tz
				D.at = D.age
			end
		end
		if obj == 0 or D.age >= 90 then
			if D.best < 1000000 then
				cprint(string.format("[drone dbg] shot %d closest %.2f at tick %d | miss dx %+.2f dy %+.2f dz %+.2f (dz + = above target)",
					proj, D.best, D.at, D.dx, D.dy, D.dz))
			else
				cprint(string.format("[drone dbg] shot %d ended with no target reading", proj))
			end
			DEBUG_PROJ[proj] = nil
		end
	end
end

function DroneAI()
	if debug_aim_log then
		DebugTrackProjectiles()
	end
	for ID, INFO in pairs(TURRETS) do
		INFO.lifetime = INFO.lifetime - 1
		local object = get_object_memory(ID)

		if object == 0 then
			TURRETS[ID] = nil
		elseif INFO.lifetime < 2 then
			KillDrone(ID, INFO)
		else
			--disable respawning
			write_dword(object + 0x5AC, tonumber(get_var(0, "$ticks")))

			local x, y, z = read_vector3d(object + 0x5C)
			INFO.x, INFO.y, INFO.z = x, y, z
			local x_vel_current, y_vel_current, z_vel_current = read_vector3d(object + 0x68)
			local turret_health = read_float(object + 0xE4)
			--rprint(1, turret_health)
			if turret_health < turret_health_cutoff then
				KillDrone(ID, INFO)
				goto drone_end
			end

			if INFO.lifetime % 30 == 1 then
				write_vector3d(object + 0x5C, x, y, z)
			end

			-- hitmarker sound
			DroneHitmarker(object)

			--FINDING TARGET
			local closest_object = nil
			local closest_index = nil
			local closest_distance = 10000
			local x2 = 0
			local y2 = 0
			local z2 = 0
			local x2_lead = 0
			local y2_lead = 0
			local z2_lead = 0

			-- look for players
			for i = 1, 16 do
				if player_alive(i) then
					local player = get_dynamic_player(i)
					if TURRETS[ID].team ~= read_word(player + 0xB8) and read_float(player + 0x37C) < 0.3 then
						x2, y2, z2 = GetTargetBodyPosition(player)
						local distance = DistanceFormula(x, y, z, x2, y2, z2)
						local x_dist = (x2 - x)
						local y_dist = (y2 - y)
						local z_dist = (z2 - z)
						local rot_x = x_dist / distance
						local rot_y = y_dist / distance
						local rot_z = z_dist / distance
						local hit, x3, y3, z3, hit_id = intersect(x, y, z, 10000 * rot_x, 10000 * rot_y, 10000 * rot_z,
							ID)
						local intersection_distance_to_target = DistanceFormula(x2, y2, z2, x3, y3, z3)
						local vehicle_id = read_dword(player + 0x11C)
						local in_vehicle = vehicle_id ~= 0xFFFFFFFF and get_object_memory(vehicle_id) ~= 0
						-- a kamikaze needs a properly clear line, otherwise it charges at somebody behind a wall
						local los_tolerance = INFO.kamikaze and 1.0 or (in_vehicle and 6.0 or 3.0)
						if distance < closest_distance and (intersection_distance_to_target < los_tolerance or (in_vehicle and hit_id == vehicle_id)) then
							closest_distance = distance
							closest_object = player
							closest_index = i
						end
					end
				end
			end

			-- set target + lead
			if closest_object ~= nil and closest_distance < auto_turret_max_distance then
				INFO.can_see_target = true
				x2, y2, z2 = GetTargetBodyPosition(closest_object)
				local vehicle = get_object_memory(read_dword(closest_object + 0x11C))
				if read_dword(closest_object + 0x11C) ~= 0xFFFFFFFF and vehicle ~= 0 then
					local vx, vy, vz = read_vector3d(vehicle + 0x68)
					x2 = x2 + vx
					y2 = y2 + vy
					z2 = z2 + vz
					x2_lead = x2 + vx * auto_turret_lead
					y2_lead = y2 + vy * auto_turret_lead
					z2_lead = z2 + vz * auto_turret_lead
				else
					x2 = x2 + read_float(closest_object + 0x68)
					y2 = y2 + read_float(closest_object + 0x6C)
					z2 = z2 + read_float(closest_object + 0x70)
					x2_lead = x2 + read_float(closest_object + 0x68) * auto_turret_lead
					y2_lead = y2 + read_float(closest_object + 0x6C) * auto_turret_lead
					z2_lead = z2 + read_float(closest_object + 0x70) * auto_turret_lead
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
					x_dist = (INFO.nav_x * INFO.nav_delta + INFO.nav_x_previous * (1 - INFO.nav_delta) - x)
					y_dist = (INFO.nav_y * INFO.nav_delta + INFO.nav_y_previous * (1 - INFO.nav_delta) - y)
					z_dist = (INFO.nav_z * INFO.nav_delta + INFO.nav_z_previous * (1 - INFO.nav_delta) - z)
					INFO.nav_delta = INFO.nav_delta + 0.3 / distance
				else
					x_dist = (INFO.nav_x - x)
					y_dist = (INFO.nav_y - y)
					z_dist = (INFO.nav_z - z)

					SetPreviousPoint(INFO, INFO.nav_x, INFO.nav_y, INFO.nav_z)
				end

				if closest_distance == 10000 then
					--closest_distance = DistanceFormula(INFO.x, INFO.y, INFO.z, INFO.nav_x, INFO.nav_y, INFO.nav_z)
					closest_distance = math.abs(x_dist) + math.abs(y_dist) + math.abs(z_dist)
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

			--FLEEING
			-- a damaged drone runs from its target and keeps running for a while after losing sight of it
			local fleeing = false
			-- once hurt, a drone keeps fleeing until it has repaired well past the flee threshold
			if turret_health < auto_turret_flee_health then
				INFO.recovering = true
			elseif turret_health >= auto_turret_recover_health then
				INFO.recovering = false
			end
			if INFO.recovering and not INFO.kamikaze then
				if closest_object ~= nil and closest_distance < auto_turret_flee_distance then
					fleeing = true
					INFO.flee_timer = auto_turret_flee_time
					INFO.flee_x, INFO.flee_y, INFO.flee_z = -rot_x, -rot_y, -rot_z
				elseif INFO.flee_timer ~= nil and INFO.flee_timer > 0 then
					fleeing = true
					INFO.flee_timer = INFO.flee_timer - 1
				end
			end

			if fleeing then
				-- slowly repair while running
				turret_health = turret_health + auto_turret_repair_rate
				if turret_health > 1 then
					turret_health = 1
				end
				write_float(object + 0xE4, turret_health)

				-- turn around gradually instead of snapping to face away
				if INFO.face_x == nil then
					INFO.face_x, INFO.face_y, INFO.face_z = read_vector3d(object + 0x74)
				end
				INFO.face_x, INFO.face_y, INFO.face_z = TurnToward(INFO.face_x, INFO.face_y, INFO.face_z,
					INFO.flee_x, INFO.flee_y, INFO.flee_z, math.rad(auto_turret_flee_turn_rate))
				write_vector3d(object + 0x74, INFO.face_x, INFO.face_y, INFO.face_z)
				write_vector3d(object + 0x80, 0, 0, 1)
			else
				INFO.face_x = nil
				if (x2 == 0 and INFO.nav_x == nil) == false then
					--rprint(1, rot_x.."  "..rot_y.."  "..rot_z)
					--rprint(1, math.abs(rot_x)+math.abs(rot_y)+math.abs(rot_z))
					--rprint(1, closest_distance)
					write_vector3d(object + 0x74, rot_x, rot_y, rot_z)
					write_vector3d(object + 0x80, 0, 0, 1)
				end
			end

			--KAMIKAZE
			if INFO.kamikaze and closest_object ~= nil and closest_distance < auto_turret_kamikaze_distance then
				DetonateDrone(ID, INFO, closest_object, rot_x, rot_y, rot_z)
				goto drone_end
			end

			--SHOOTING
			if INFO.lifetime + 30 < auto_turret_lifetime and INFO.rate_of_fire < 1 then
				INFO.rate_of_fire = auto_turret_rate_of_fire
				local hit, x3, y3, z3, hit_id = intersect(x, y, z, 10000 * rot_x, 10000 * rot_y, 10000 * rot_z, ID)
				if x3 ~= nil then
					local distance_to_aim_location = DistanceFormula(x2, y2, z2, x3, y3, z3)
					local target_veh_id = closest_object ~= nil and read_dword(closest_object + 0x11C) or 0xFFFFFFFF
					local in_veh = target_veh_id ~= 0xFFFFFFFF and get_object_memory(target_veh_id) ~= 0
					local aim_tolerance = in_veh and 5.5 or 2.5
					if not fleeing and not INFO.kamikaze and closest_distance < shooting_distance and (distance_to_aim_location < aim_tolerance or (in_veh and hit_id == target_veh_id)) then
						for _ = 1, auto_turret_shots_per_burst do
							local x_error = -rand(1, 100) * auto_turret_weapon_error + auto_turret_weapon_error * 50
							local y_error = -rand(1, 100) * auto_turret_weapon_error + auto_turret_weapon_error * 50
							local z_error = -rand(1, 100) * auto_turret_weapon_error + auto_turret_weapon_error * 50
							local shot_id = spawn_projectile(auto_turret_projectile_tag, 0xFFFFFFFF, x + rot_x_lead * muzzle_offset, y + rot_y_lead *
							muzzle_offset, z + rot_z_lead * muzzle_offset, rot_x_lead + x_error, rot_y_lead + y_error, rot_z_lead + z_error)
							if debug_aim_log and _ == 1 then
								DebugLogShot(ID, INFO, shot_id, closest_index, x, y, z, rot_x_lead, rot_y_lead, rot_z_lead, z2_lead)
							end
						end
					end
				end
			else
				INFO.rate_of_fire = INFO.rate_of_fire - 1
			end

			--IDLE
			if closest_distance > auto_turret_max_distance then
				if INFO.can_see_target then
					INFO.last_seen_timer = 10 * 30
					INFO.can_see_target = false
				end
			elseif INFO.last_seen_timer ~= nil then
				if INFO.last_seen_timer == 5 * 30 then
					--rprint(1, "can't see")
				end
				INFO.last_seen_timer = INFO.last_seen_timer - 1
				if INFO.last_seen_timer == 0 then
					INFO.last_seen_timer = nil
					--rprint(1, "gave up")
				end
			end

			if INFO.last_seen_timer == nil then
				if INFO.idle_timer == nil or INFO.idle_timer == 0 then
					INFO.nav_x = math.random(map_boundary_x_min, map_boundary_x_max)
					INFO.nav_y = math.random(map_boundary_y_min, map_boundary_y_max)
					INFO.nav_z = math.random(map_boundary_z_min, map_boundary_z_max)
					INFO.idle_timer = 30 * 30
					if INFO.nav_delta ~= nil and INFO.nav_delta ~= 1 and INFO.nav_x ~= nil then
						SetPreviousPoint(INFO, INFO.nav_x, INFO.nav_y, INFO.nav_z)
					end
					INFO.nav_delta = 0
				else
					INFO.idle_timer = INFO.idle_timer - 1
				end


				if INFO.nav_x ~= nil then
					local distance_to_nav = DistanceFormula(x, y, z, INFO.nav_x, INFO.nav_y, INFO.nav_z)
					if distance_to_nav < 3 then
						INFO.nav_x = nil
						INFO.nav_y = nil
						INFO.nav_z = nil
					elseif closest_distance > auto_turret_max_distance then
						x_dist = (INFO.nav_x - x)
						y_dist = (INFO.nav_y - y)
						z_dist = (INFO.nav_z - z)
						distance = DistanceFormula(x, y, z, INFO.nav_x, INFO.nav_y, INFO.nav_z)
						rot_x = x_dist / distance
						rot_y = y_dist / distance
						rot_z = z_dist / distance
					end
				end
			end

			--MOVING
			-- keep a radius around the target: back away if it's inside the radius
			-- (a kamikaze doesn't keep its distance, it goes straight in)
			local retreating = fleeing or (not INFO.kamikaze and closest_object ~= nil and closest_distance < auto_turret_keep_radius)
			local accel = auto_turret_acceleration
			local blocked = false -- a kamikaze with a wall in front of it stops instead of pushing into it
			if retreating or (closest_distance < auto_turret_max_distance and (INFO.kamikaze or closest_distance > auto_turret_keep_radius)) or INFO.nav_x ~= nil then
				local move_x, move_y, move_z = rot_x, rot_y, rot_z
				local speed_mult = INFO.kamikaze and auto_turret_kamikaze_speed or 1
				accel = auto_turret_acceleration * speed_mult
				if retreating then
					if fleeing and closest_object == nil then
						-- lost sight of it, keep running the way it was last seen
						move_x, move_y, move_z = INFO.flee_x, INFO.flee_y, INFO.flee_z
					else
						move_x, move_y, move_z = -rot_x, -rot_y, -rot_z
					end

					-- the deeper inside the radius, the harder it backs off. fleeing is always full speed
					local depth = 1
					if not fleeing then
						depth = (auto_turret_keep_radius - closest_distance) / auto_turret_keep_radius
					end
					speed_mult = 1 + depth * auto_turret_retreat_boost
					accel = auto_turret_acceleration * speed_mult

					-- something in the way: slide around it (sideways and up) instead of running into it
					if fleeing then
						local hit, x3, y3, z3, hit_id = intersect(x, y, z, 6 * move_x, 6 * move_y, 6 * move_z, ID)
						if x3 ~= nil and DistanceFormula(x, y, z, x3, y3, z3) < 4 then
							local side = 1
							if ID % 2 == 0 then
								side = -1
							end
							move_x, move_y, move_z = move_x - move_y * side, move_y + move_x * side, move_z + 0.7
							local len = math.sqrt(move_x * move_x + move_y * move_y + move_z * move_z)
							if len > 0 then
								move_x, move_y, move_z = move_x / len, move_y / len, move_z / len
							end
						end
					end
				end

				-- this part makes drone move faster when there is nothing in front of it
				local distance_to_aim_location = 0
				if not retreating then
					local hit, x3, y3, z3, hit_id = intersect(x, y, z, 15 * move_x, 15 * move_y, 15 * move_z, ID)
					if x3 ~= nil then
						local ahead = DistanceFormula(x, y, z, x3, y3, z3)
						if INFO.kamikaze then
							-- obstacles that aren't its target. the stopping distance grows with its current speed
							local hits_target = false
							if closest_object ~= nil then
								local target_player_id = read_dword(get_player(closest_index) + 0x34)
								local target_vehicle_id = read_dword(closest_object + 0x11C)
								hits_target = hit_id == target_player_id or hit_id == target_vehicle_id
							end
							local speed = math.sqrt(x_vel_current * x_vel_current + y_vel_current * y_vel_current + z_vel_current * z_vel_current)
							if not hits_target and ahead < 1 + speed * 8 then
								blocked = true
								if closest_object == nil then
									INFO.idle_timer = 0 -- pick a different way to wander
								end
							end
						end
						distance_to_aim_location = ahead * 0.1 - 0.5
						if distance_to_aim_location < 0 then
							distance_to_aim_location = 0
						elseif distance_to_aim_location > 15 then
							distance_to_aim_location = 15
						end
					end
				end

				local x_velocity = move_x * auto_turret_vel_factor * (1 + distance_to_aim_location) * speed_mult
				local y_velocity = move_y * auto_turret_vel_factor * (1 + distance_to_aim_location) * speed_mult
				local z_velocity = move_z * auto_turret_vel_factor * (1 + distance_to_aim_location) * speed_mult

				INFO.wanted_vel_x = x_velocity
				INFO.wanted_vel_y = y_velocity
				INFO.wanted_vel_z = z_velocity

				-- limit velocity
				if retreating then
					-- the whole vector is capped (so the direction isn't bent) and the cap scales with the retreat
					-- speed, otherwise a drone backing away could never get past the normal max speed
					local max_speed = auto_turret_max_vel * speed_mult
					local wanted_speed = math.sqrt(x_velocity * x_velocity + y_velocity * y_velocity + z_velocity * z_velocity)
					if wanted_speed > max_speed then
						local scale = max_speed / wanted_speed
						INFO.wanted_vel_x = x_velocity * scale
						INFO.wanted_vel_y = y_velocity * scale
						INFO.wanted_vel_z = z_velocity * scale
					end
				else
					local max_xy = auto_turret_max_vel * speed_mult
					if INFO.wanted_vel_x > max_xy then
						INFO.wanted_vel_x = max_xy
					elseif INFO.wanted_vel_x < -max_xy then
						INFO.wanted_vel_x = -max_xy
					end
					if INFO.wanted_vel_y > max_xy then
						INFO.wanted_vel_y = max_xy
					elseif INFO.wanted_vel_y < -max_xy then
						INFO.wanted_vel_y = -max_xy
					end
				end
			else
				INFO.wanted_vel_x = 0
				INFO.wanted_vel_y = 0
				INFO.wanted_vel_z = 0
			end

			if blocked then
				INFO.wanted_vel_x = 0
				INFO.wanted_vel_y = 0
				INFO.wanted_vel_z = 0
				accel = auto_turret_acceleration * 3 -- brake harder than it accelerates
			end

			ApproachVelocity(object + 0x68, x_vel_current, INFO.wanted_vel_x, accel)
			ApproachVelocity(object + 0x6C, y_vel_current, INFO.wanted_vel_y, accel)
			ApproachVelocity(object + 0x70, z_vel_current, INFO.wanted_vel_z, accel)

			PushDroneAway(object, ID)
			::drone_end::
		end
	end
end

-- Kamikaze drone reached its target: a rocket spawned on the target makes the explosion, and the drone goes with it
function DetonateDrone(ID, INFO, target, rx, ry, rz)
	local tx, ty, tz = GetTargetBodyPosition(target)
	spawn_projectile(auto_turret_kamikaze_tag, 0xFFFFFFFF, tx - rx * 0.4, ty - ry * 0.4, tz - rz * 0.4, rx, ry, rz)
	KillDrone(ID, INFO)
end

-- Rotates direction f toward direction d by at most max_angle radians, returns the new unit direction.
function TurnToward(fx, fy, fz, dx, dy, dz, max_angle)
	local flen = math.sqrt(fx * fx + fy * fy + fz * fz)
	local dlen = math.sqrt(dx * dx + dy * dy + dz * dz)
	if dlen < 0.0001 then
		return fx, fy, fz
	end
	dx, dy, dz = dx / dlen, dy / dlen, dz / dlen
	if flen < 0.0001 then
		return dx, dy, dz
	end
	fx, fy, fz = fx / flen, fy / flen, fz / flen

	local dot = fx * dx + fy * dy + fz * dz
	if dot > 1 then
		dot = 1
	elseif dot < -1 then
		dot = -1
	end
	local angle = math.acos(dot)
	if angle <= max_angle then
		return dx, dy, dz
	end

	-- rotate around the axis perpendicular to both. Facing exactly away has no single axis, so turn around the vertical
	local ax, ay, az = fy * dz - fz * dy, fz * dx - fx * dz, fx * dy - fy * dx
	local alen = math.sqrt(ax * ax + ay * ay + az * az)
	if alen < 0.0001 then
		if math.abs(fz) < 0.99 then
			ax, ay, az, alen = 0, 0, 1, 1 -- spin around the vertical like a turn on the spot
		else
			ax, ay, az, alen = 1, 0, 0, 1 -- facing straight up or down, any sideways axis will do
		end
	end
	ax, ay, az = ax / alen, ay / alen, az / alen

	-- Rodrigues' rotation of f around the axis
	local c, s = math.cos(max_angle), math.sin(max_angle)
	local cx, cy, cz = ay * fz - az * fy, az * fx - ax * fz, ax * fy - ay * fx
	local k = (ax * fx + ay * fy + az * fz) * (1 - c)
	return fx * c + cx * s + ax * k, fy * c + cy * s + ay * k, fz * c + cz * s + az * k
end

-- moves one axis of the drone's velocity toward the wanted value by at most accel per tick
function ApproachVelocity(address, current, wanted, accel)
	if wanted > current + accel then
		wanted = current + accel
	elseif wanted < current - accel then
		wanted = current - accel
	end
	write_float(address, wanted)
end

function OnTick()
	if force_spawn_drones then
		RespawnTurrets()
		DroneAI()
		DroneMelee()
		return
	end
	local player_count = tonumber(get_var(0, "$pn"))

	if drones_active then
		if player_count == 0 or player_count > max_player_count then
			say_all("Enough players joined! Removing the drones.")
			RemoveAllDrones()
			drones_active = false
			return
		end
		RespawnTurrets()
		DroneAI()
		DroneMelee()
		start_timer = 0
	elseif player_count > 0 and player_count <= max_player_count then
		start_timer = start_timer + 1
		if start_timer == 5 * 30 then
			say_all("Low player count...")
		elseif start_timer == 7 * 30 then
			say_all("Drones are coming!")
		elseif start_timer > 10 * 30 then
			drones_active = true
			say_all("Type \"stop drones\" if you don\'t want to fight!")
		end
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
		say_all("Drone fight script: couldn't destroy object!")
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

function PlaceTurret(x, y, z)
	ID = spawn_object("vehi", auto_turret_vehicle, x, y, z + auto_turret_altitude, 0)
	local turret_object = get_object_memory(ID)
	if turret_object ~= 0 and read_dword(turret_object + 0x98) ~= 0 then
		TURRETS[ID] = {}
		TURRETS[ID].lifetime = auto_turret_lifetime
		TURRETS[ID].kamikaze = auto_turret_kamikaze_tag ~= nil and math.random() < auto_turret_kamikaze_chance
		TURRETS[ID].rate_of_fire = auto_turret_rate_of_fire
		TURRETS[ID].x = x
		TURRETS[ID].y = y
		TURRETS[ID].z = z

		-- set health
		write_float(turret_object + 0xDC, 10000)
		write_float(turret_object + 0xE4, 1)
		return true
	else
		--say_all("Can't spawn a drone here!")
		if get_object_memory(ID) ~= 0 then
			RemoveObject(ID)
		end
		return false
	end
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type, object_dir)
	if (address ~= 0) then
		--cprint(object_dir..": "..address.."     "..read_dword(address + 0xC))
		return read_dword(address + 0xC)
	end
	return nil
end

function GetName(DynamicObject) --	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetPlayerAimLocation(i) --	Finds coordinates at which player is looking (from giraffe)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local px, py, pz = read_vector3d(player + 0xA0)
		local vx, vy, vz = read_vector3d(player + 0x230)
		local cs = read_float(player + 0x50C)
		local standing_height = 0.25
		local crouching_change = 0.17
		local h = standing_height - (cs * (standing_height - crouching_change))
		pz = pz + h
		return intersect(px, py, pz, vx * 1000, vy * 1000, vz * 1000, read_dword(get_player(i) + 0x34))
	else
		return 0, 0, 0
	end
end

function DistanceToDirection(x, y, z, vx, vy, vz, ID)
	local hit, x_g, y_g, z_g, hit_id = intersect(x, y, z, vx, vy, vz, ID)
	return DistanceFormula(x_g, y_g, z_g, x, y, z)
end

function GetTargetBodyPosition(player)
	local vehicle_id = read_dword(player + 0x11C)
	if vehicle_id ~= 0xFFFFFFFF then
		local vehicle = get_object_memory(vehicle_id)
		if vehicle ~= 0 then
			local x, y, z = read_vector3d(vehicle + 0x5C)
			return x, y, z + 0.5
		end
	end
	local x, y, z = read_vector3d(player + 0x5C)
	local crouch = read_float(player + 0x50C)
	local z_offset = 0.4 - (crouch * 0.15)
	return x, y, z + z_offset
end

function DistanceFormula(x1, y1, z1, x2, y2, z2) -- Made by 002
	local dx = x1 - x2
	local dy = y1 - y2
	local dz = z1 - z2
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function GetYaw(yaw, pitch)
	local angle = math.atan2(pitch, yaw)
	if angle < 0 then
		angle = angle + math.pi * 2
	end
	return angle
end

function ClearConsole(i) --					Clears player's console from any messages
	for j = 1, 30 do
		rprint(i, " ")
	end
end

function OnError(Message)
	say_all("Error!" .. Message)
end

function OnGameEnd()
	TURRETS = {}
end

function RemoveAllDrones()
	for ID, value in pairs(TURRETS) do
		if TURRETS[ID].weapon ~= nil then
			RemoveObject(TURRETS[ID].weapon)
			TURRETS[ID].weapon = nil
		end
		RemoveObject(ID)
	end
	TURRETS = {}
	start_timer = 0
end

function OnScriptUnload()
	if string.find(get_var(0, "$map"), map_name) then
		RemoveAllDrones()
	end
end

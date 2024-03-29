
--CONFIG
	distance_from_vehicle = 50
	use_center_of_mass = false
	
	use_different_update_rates = true
	vehicle_rate = 60
--END OF CONFIG

--TODO:
-- add proper center of mass
-- keep moving players even if there is no driver
-- maybe add a custom timer to check when vehicle was touched

api_version = "1.10.1.0"

VEHS = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb["EVENT_GAME_START"],"OnGameStart")
	
	if use_different_update_rates then
		execute_command("use_new_vehicle_update_scheme 0")
		execute_command("vehicle_incremental_rate 300")
		--execute_command("vehicle_incremental_rate 30")
		--execute_command("remote_player_vehicle_update_rate "..vehicle_rate.."")
		--execute_command("local_player_vehicle_update_rate "..vehicle_rate.."")
		--execute_command("remote_player_vehicle_baseline_update_rate 300")
		--execute_command("remote_player_position_baseline_update_rate 300")
		--execute_command("local_player_update_rate 30")
	end
end

function OnScriptUnload()
end

function OnGameStart()
	VEHS = {}
end

function OnTick()
	for i = 1,16 do 
		if player_alive(i) then
			local player = get_dynamic_player(i)
			local vehicle = read_dword(player + 0x11C)
			local vehicle_object = get_object_memory(vehicle)
			local seat = read_word(player + 0x2F0)
			if vehicle_object ~= 0 and seat == 0 then
				local x, y, z = read_vector3d(vehicle_object + 0x5C)
				local x_vel, y_vel, z_vel = read_vector3d(vehicle_object + 0x68)
				local rot1, rot2, rot3 = read_vector3d(vehicle_object + 0x74)
				local rot4, rot5, rot6 = read_vector3d(vehicle_object + 0x80)
				
				local yaw = GetYaw(rot1, rot2)
				local pitch = GetPitch(rot3, rot4)
				local roll = GetRoll(rot5, rot6)
				
				local yaw_change = 0
				local pitch_change = 0
				local roll_change = 0
				if VEHS[vehicle] ~= nil then
					if VEHS[vehicle].yaw ~= nil then
						yaw_change = yaw - VEHS[vehicle].yaw
						pitch_change = pitch - VEHS[vehicle].pitch
						roll_change = roll - VEHS[vehicle].roll
						if yaw_change > math.pi then
							yaw_change = yaw_change - math.pi*2
						end
					end
					VEHS[vehicle].yaw = yaw
					VEHS[vehicle].pitch = pitch
					VEHS[vehicle].roll = roll
					
					--ClearConsole(i)
					--rprint(i, "Roll = "..string.format("%.3f", roll*180/math.pi))

					for j=1,16 do 
						if player_alive(j) and j ~= i then
							local player2 = get_dynamic_player(j)
							local seat2 = read_word(player2 + 0x2F0)
							if seat2 == 65535 then
								local x_vel2, y_vel2, z_vel2 = read_vector3d(player2 + 0x68)
								local x2, y2, z2 = read_vector3d(player2 + 0x5C)
								local distance = DistanceFormula(x,y,z,x2,y2,z2) * 1
								local bumped_obj_id = read_dword(player2 + 0x4FC)
								local time_since_last_bump = read_char(player2 + 0x500)
								
								--ClearConsole(i)
								--rprint(i, "Yaw change = "..string.format("%.3f", yaw_change))
								--rprint(i, "Pitch change = "..string.format("%.3f", pitch_change))
								--rprint(i, "Roll change = "..string.format("%.3f", roll_change))
								
								
								-- MOVE THE PLAYER
								
								if x_vel ~= 0 and distance < distance_from_vehicle and bumped_obj_id == vehicle and time_since_last_bump < 0 then
								--if x_vel ~= 0 and distance < distance_from_vehicle then -- for debugging
									write_bit(player2 + 0x10, 5, 0) -- make player not static
									
									x2, y2 = RotateAroundPoint(x, y, x2, y2, yaw_change)
									x2, z2 = RotateAroundPoint(x, z, x2, z2, pitch_change)
									y2, z2 = RotateAroundPoint(y, z, y2, z2, roll_change)
									x2 = x2+x_vel
									y2 = y2+y_vel
									z2 = z2+z_vel
									
									write_vector3d(player2 + 0x5C, x2, y2, z2)
									write_dword(get_player(j) + 0xF0, 0) -- sync instantly to the player
									write_dword(get_player(j) + 0x164, 0) -- sync instantly to others
								end
							end
						end
					end
				else
					VEHS[vehicle] = {}
				end
			end
		end
		
	end
end

function RotateAroundPoint(x, y, x2, y2, angle)
	local x_1 = x2 - x
	local y_1 = y2 - y
	local cosine = math.cos(angle)
	local sine = math.sin(angle)
	
	local x_2 = x_1 * cosine - y_1 * sine
	local y_2 = x_1 * sine + y_1 * cosine

	x2 = x_2 + x
	y2 = y_2 + y
	return x2, y2
end

function GetYaw(a, b)
    local cos_b = math.acos(b)
    
    local finalAngle = cos_b
    
    if(a < 0) then finalAngle = finalAngle * -1 end
 
    finalAngle = finalAngle - math.pi / 2
 
    if(finalAngle < 0) then finalAngle = finalAngle + math.pi * 2 end
 
	finalAngle = (math.pi*2) - finalAngle
    return  finalAngle
end

function GetPitch(a, b)
    local cos_b = math.acos(b)
    
    local finalAngle = cos_b
	
    return  finalAngle
end

function GetRoll(a, b)
    local cos_b = math.acos(b)
    
    local finalAngle = cos_b
    
    if(a < 0) then finalAngle = finalAngle * -1 end
 
	finalAngle = finalAngle * -1
    return  finalAngle
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end
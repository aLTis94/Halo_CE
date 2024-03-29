
--CONFIG
	count = 50
	offset_x = 0.5
	offset_y = -0.04
	offset_z = -1
--END OF CONFIG

VEHICLES = {}

api_version = "1.9.0.0"
previous_yaw = 0
previous_pitch = 0
previous_roll = 0

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	
	local physics = lookup_tag("phys", "altis\\vehicles\\mongoose\\mongoose")
	if physics ~= 0 then
		physics_data = read_dword(physics + 0x14)
		--local x, y, z = read_vector3d(physics_data + 0x0C)
		write_vector3d(physics_data + 0x0C, 0, 0, 0)
	end
end

function OnTick()
	execute_command("vehicle_incremental_rate 0")
	for i=1,16 do
		if player_alive(i) then
			ClearConsole(1)
			local biped_object = get_dynamic_player(i)
			local vehicle = read_dword(biped_object + 0x11C)
			local vehicle_object = get_object_memory(vehicle)
			if vehicle_object ~= 0 then
				local x, y, z = read_vector3d(vehicle_object + 0x5C)
				local x_vel, y_vel, z_vel = read_vector3d(vehicle_object + 0x68)
				local rot1, rot2, rot3 = read_vector3d(vehicle_object + 0x74)
				local rot4, rot5, rot6 = read_vector3d(vehicle_object + 0x80)
				local yaw_vel, pitch_vel, roll_vel = read_vector3d(vehicle_object + 0x8C)
				
				local matrix_00 = read_float(vehicle_object + 0x74)
				local matrix_10 = read_float(vehicle_object + 0x80)
				local matrix_11 = read_float(vehicle_object + 0x84)
				local matrix_12 = read_float(vehicle_object + 0x88)
				
				local yaw = GetYaw(rot1, rot2)
				local pitch = GetPitch(rot3, rot4)
				local roll = GetRoll(rot5, rot6)
				
				--pitch = (math.asin(matrix_10) * -1)
				--roll = (math.atan(rot5 / rot6 * -1))
				--yaw = (math.acos(matrix_00 / math.cos(pitch)))
				
				local yaw_change = yaw - previous_yaw
				local pitch_change = pitch - previous_pitch
				local roll_change = roll - previous_roll
				
				previous_yaw = yaw
				previous_pitch = pitch
				previous_roll = roll
				
				
				rprint(1, "yaw "..string.format("%.2f", yaw).." pitch "..string.format("%.2f", pitch).." roll "..string.format("%.2f", roll))
				--rprint(1, "yaw change "..string.format("%.3f", yaw_change).." pitch change "..string.format("%.3f", pitch_change).." roll change "..string.format("%.3f", roll_change))
				
				if VEHICLES[vehicle] == nil then
					--VEHICLES[vehicle] = spawn_object("vehi", "ai\\vehicles\\ghost\\ghost_mp", x, y+3, z)
					--VEHICLES[vehicle] = spawn_object("vehi", "ai\\turret\\turret\\0\\idle", x+1.5, y+1.5, z+1.5)
					VEHICLES[vehicle] = {}
					for j = 1,count do
						VEHICLES[vehicle]["veh"..j] = spawn_object("vehi", "ai\\turret\\turret\\0\\idle", x+offset_x*math.sqrt(j), y+offset_y*j*j, z+offset_z*j)
						say(1, VEHICLES[vehicle]["veh"..j])
					end
				end
				for j = 1,count do
					--rprint(1, VEHICLES[vehicle]["veh"..j])
					local new_vehicle = get_object_memory(VEHICLES[vehicle]["veh"..j])
					if new_vehicle ~= 0 then
						local x2, y2, z2 = read_vector3d(new_vehicle + 0x5C)
						x2, y2 = RotateAroundPoint(x, y, x2, y2, yaw_change)
						x2, z2 = RotateAroundPoint(x, z, x2, z2, pitch_change)
						y2, z2 = RotateAroundPoint(y, z, y2, z2, roll_change)
						
						write_bit(new_vehicle + 0x10, 5, 0)
						x2 = x2+x_vel
						y2 = y2+y_vel
						z2 = z2+z_vel
						--x2 = math.cos(yaw)*2 + x
						--y2 = math.sin(yaw)*2 + y
						--z2 = z
						
						write_vector3d(new_vehicle + 0x5C, x2, y2, z2)
						write_vector3d(new_vehicle + 0x74, rot1, rot2, rot3)
						write_vector3d(new_vehicle + 0x80, rot4, rot5, rot6)
						write_vector3d(new_vehicle + 0x68, 0, 0, 0)
					end
				end
			else
				for key,value in pairs (VEHICLES) do
					for j = 1,count do
						destroy_object(value["veh"..j])
					end
					VEHICLES[key] = nil
				end
			end
		end
	end
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
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
    rprint(1, "a = "..string.format("%.2f", a).." b = "..string.format("%.2f", b))
    local finalAngle = cos_b
    
	--if(a < 0) then finalAngle = finalAngle * -1 end
	
    return  finalAngle
end

function GetRoll(a, b)
    local finalAngle = math.atan(a / b * -1)
   
    return  finalAngle
end

function OnScriptUnload() 
	for key,value in pairs (VEHICLES) do
		for j = 1,count do
			destroy_object(value["veh"..j])
		end
		VEHICLES[key] = nil
	end
end
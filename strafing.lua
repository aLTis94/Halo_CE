--	Falcon strafing script by aLTis (altis94@gmail.com)

--	This script works on any version of Bigass
--	Press A,D to move left,right;
--	Press flashlight to lock your height

--	CONFIG

	debug_mode = false
	
	strafing = true
	
	vehicle_tag = "vehicles\\falcon\\falcon"
	
	--	how fast a vehicle moves left or right
	strafe_rate = 0.005
	
	--	lock falcon height with flashlight
	z_lock = true
	
	--	how fast vehicle moves up or down to reach locked height
	z_move_rate = 0.005
	
	--	if vehicle moves this far away from locked height then it's unlocked
	z_unclock_treshold = 3
	
--	END OF CONFIG

api_version = "1.9.0.0"

Z_LOCK = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
	for i = 1,16 do
		Z_LOCK[i] = 0
	end
end

function OnScriptUnload()
end

function OnVehicleExit(PlayerIndex)
	Z_LOCK[PlayerIndex] = 0
end

function OnTick()
	for i = 1,16 do
		if(player_alive(i)) then
			local player_object = get_dynamic_player(i)
			local vehicle = read_dword(player_object + 0x11C)
			local vehicle_object = get_object_memory(vehicle)
			if(vehicle_object ~= 0 and read_word(player_object + 0x2F0) == 0 and GetName(vehicle_object) == vehicle_tag) then
				local player_left = read_float(player_object + 0x27C)
				local player_flashlight = read_bit(player_object + 0x208,4)
				
				local z = read_float(vehicle_object + 0x64)
				local x_vel, y_vel, z_vel = read_vector3d(vehicle_object + 0x68)
				local pitch, yaw, roll = read_vector3d(vehicle_object + 0x74)
				
				if(player_flashlight == 1) then
					if(Z_LOCK[i] ~= 0) then
						rprint(i, "|cHeight lock disabled")
						Z_LOCK[i] = 0
					else
						rprint(i, "|cHeight lock enabled")
						Z_LOCK[i] = z
					end
				end
				
				if(Z_LOCK[i] ~= 0 and math.abs(z - Z_LOCK[i]) > z_unclock_treshold) then
					rprint(i, "|cHeight lock disabled")
					Z_LOCK[i] = 0
				end
				
				if(debug_mode) then
					ClearConsole(i)
					rprint(i, "left "..player_left)
					if(Z_LOCK[i] ~= 0) then
						rprint(i, "z lock enabled")
					end
					rprint(i, "yaw "..yaw)
					rprint(i, "pitch "..pitch)
					rprint(i, "x "..x_vel)
					rprint(i, "y "..y_vel)
					rprint(i, "z "..z)
				end
				
				if(strafing) then
					write_float(vehicle_object + 0x68, x_vel - player_left*strafe_rate*yaw)
					write_float(vehicle_object + 0x6C, y_vel + player_left*strafe_rate*pitch)
				end
				if(z_lock and Z_LOCK[i] ~= 0) then 
					write_float(vehicle_object + 0x70, z_vel - (z - Z_LOCK[i]) * z_move_rate)
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

function GetName(DynamicObject)--	Gets directory + name of the object
	if(DynamicObject ~= nil and DynamicObject ~= 0) then
		return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
	else
		return ""
	end
end
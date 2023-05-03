--	Falcon strafing script by aLTis (altis94@gmail.com)

--	This script works on any version of Bigass
--	Press A,D to move left,right;
--	Press flashlight to lock your height

--	CONFIG

	debug_mode = false	--	useless info :v
	
	vehicle_tag = "vehicles\\falcon\\falcon"
	
	strafing = true
	z_lock = true	--	lock falcon height with flashlight
	smooth_strafing = true
	smooth_z_lock = true
	
	strafe_rate = 0.004	--	how fast a vehicle moves left or right
	z_move_rate = 0.005	--	how fast vehicle moves up or down to reach locked height
	z_unclock_treshold = 3	--	if vehicle moves this far away from locked height then it's unlocked
	
--	END OF CONFIG

api_version = "1.12.0.0"

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
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local vehicle = read_dword(player + 0x11C)
			local vehicle_object = get_object_memory(vehicle)
			if vehicle_object ~= 0 and read_word(player + 0x2F0) == 0 and GetName(vehicle_object) == vehicle_tag then
				local player_left = read_float(player + 0x27C)
				local player_flashlight = read_bit(player + 0x208,4)
				
				local x = read_float(vehicle_object + 0x5C)
				local y = read_float(vehicle_object + 0x60)
				local z = read_float(vehicle_object + 0x64)
				local x_vel, y_vel, z_vel = read_vector3d(vehicle_object + 0x68)
				local pitch, yaw, roll = read_vector3d(vehicle_object + 0x74)
				local not_smoothed = true
				
				if(player_flashlight == 1) then
					if(Z_LOCK[i] ~= 0) then
						if get_var(i, "$has_chimera") == "1" then
							rprint(i, "hud_msg~Height lock disabled")
						else
							rprint(i, "|cHeight lock disabled|ncA9CCE3")
						end
						Z_LOCK[i] = 0
						PlaySound(i, "error")
					else
						if get_var(i, "$has_chimera") == "1" then
							rprint(i, "hud_msg~Height lock enabled")
						else
							rprint(i, "|cHeight lock enabled|ncA9CCE3")
						end
						Z_LOCK[i] = z
						PlaySound(i, "bumper")
					end
				end
				
				if(Z_LOCK[i] ~= 0 and math.abs(z - Z_LOCK[i]) > z_unclock_treshold) then
					rprint(i, " Height lock disabled|ncA9CCE3")
					Z_LOCK[i] = 0
					PlaySound(i, "error")
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
					if(smooth_strafing and player_left ~= 0) then
						execute_command("t "..i.." "..x.." "..y.." "..z)
						not_smoothed = false
					end
				end
				if(z_lock and Z_LOCK[i] ~= 0) then 
					write_float(vehicle_object + 0x70, z_vel - (z - Z_LOCK[i]) * z_move_rate)
					if(smooth_z_lock and not_smoothed) then
						execute_command("t "..i.." "..x.." "..y.." "..z)
					end
				end
			end
		else
			Z_LOCK[i] = 0
		end
	end
end

function PlaySound(i, sound)
	if get_var(i, "$has_chimera") == "1" then
		rprint(i, "play_chimera_sound~"..sound)
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
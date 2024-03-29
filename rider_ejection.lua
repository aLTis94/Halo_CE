-- Made by aLTis (altis94@gmail.com) with help from giraffe 

--	This script will eject riders when vehicle is flipped after a delay.

--	CONFIG

debug_mode = false

--	Driver will be ejected after this time (in ticks)
ejection_delay = 2*30

--	Should driver get ejected only when vehicle is standing still or moving slowly
check_velocities = true

--	How fast can the vehicle be moving
max_velocity = 0.3

--	END OF CONFIG

api_version = "1.9.0.0"

TIMERS = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	execute_command("rider_ejection 0")
	for i=1,16 do
		TIMERS[i] = 0
	end
end

function OnTick()
	if lookup_tag("senv", "altis\\levels\\halo\\shaders\\halo outer ring bsp") ~= 0 then return end
	
	for i=1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 then 
			local object_id = read_dword(player + 0x11C)
			local object = get_object_memory(object_id)
			
			if(IsVehicleFlipped(object) and CheckVelocities(object)) then
				TIMERS[i] = TIMERS[i] + 1
			else
				if(TIMERS[i] > 0) then
					TIMERS[i] = TIMERS[i] - 1
				end
			end
			if(TIMERS[i] == ejection_delay) then
				exit_vehicle(i)
				TIMERS[i] = 0
			end
			if(debug_mode == true) then rprint(i, TIMERS[i]) end
		end
	end
end

function IsVehicleFlipped(object)
     if(object ~= 0) then
         if(read_bit(object + 0x8B, 7) == 1) then return true end
     end
     return false
end

function CheckVelocities(object)
	if(check_velocities == false) then return true end
	if(object ~= 0) then
		local x = math.abs(read_float(object + 0x68))
		local y = math.abs(read_float(object + 0x6C))
		local z = math.abs(read_float(object + 0x70))
		if((x + y + z) < max_velocity) then
			return true
		end
	end
	return false
end

function OnScriptUnload()
	execute_command("rider_ejection 1")
end

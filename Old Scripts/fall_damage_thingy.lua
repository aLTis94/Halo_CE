
--CONFIG

	disable_damage_on_speed = true
	max_speed = 1.5 -- if speed is higher than this then player will recieve no fall damage

	disable_fall_damage_from_vehicles = true
	VEHICLES = {
		["vehicles\\banshee\\banshee_mp"] = true,
	}
	
--END OF CONFIG

api_version = "1.9.0.0"


function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb["EVENT_DAMAGE_APPLICATION"],"OnDamage")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	if disable_fall_damage_from_vehicles then
		register_callback(cb['EVENT_VEHICLE_EXIT'],"OnVehicleExit")
	end
	LEAVING_VEHICLE = {}
	for i=1,16 do
		LEAVING_VEHICLE[i] = 0
	end
	timer(30, "GetGlobals")
end

function OnGameStart()
	timer(3000, "GetGlobals")
end

function OnScriptUnload() 
end

function OnDamage(i, causer, tagID, damage, material, backtap)
	--say(i, "damaged")
	if falling_dmg_id == tagID or distance_dmg_id == tagID then
		if LEAVING_VEHICLE[i] > 0 then
			--say(i, "prevented damage")
			return false
		end
		local player = get_player(i)
		if player ~= 0 then
			if disable_damage_on_speed then
				local speed = read_float(player + 0x6C)
				if speed > max_speed then
					return false
				end
			end
		end
	end
end

function OnVehicleExit(i)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local vehicle_id = read_dword(player + 0x11C)
		local vehicle = get_object_memory(vehicle_id)
		if vehicle ~= 0 then
			local name = GetName(vehicle)
			if VEHICLES[name] ~= nil then
				LEAVING_VEHICLE[i] = 5
				--say(i, "leaving")
			end
		end
	end
end

function OnTick()
	for i=1,16 do
		if LEAVING_VEHICLE[i] > 0 then
			local player = get_dynamic_player(i)
			if player ~= 0 then
				local touching_ground = read_bit(player + 0x10, 1)
				local vehicle_id = read_dword(player + 0x11C)
				--rprint(i, vehicle_id)
				if touching_ground == 1 and vehicle_id == 0xFFFFFFFF then
					LEAVING_VEHICLE[i] = LEAVING_VEHICLE[i] - 1
					--if LEAVING_VEHICLE[i] < 1 then
					--	rprint(i, "touch")
					--end
				end
			end
		end
	end
end

function GetGlobals() -- taken from 002's headshots script
	
	LEAVING_VEHICLE = {}
	for i=1,16 do
		LEAVING_VEHICLE[i] = 0
	end
	
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6D617467 then
            local tag_data = read_dword(tag + 0x14)
			local falling_dmg_struct = read_dword(tag_data + 0x18C)
			falling_dmg_id = read_dword(falling_dmg_struct + 0x10 + 0xC)
			distance_dmg_id = read_dword(falling_dmg_struct + 0x2C + 0xC)
			cprint("FALLING DONE")
		end
	end
	return nil
end

function GetName(object)
	if object ~= nil then
		return read_string(read_dword(read_word(object) * 32 + 0x40440038))
	end
end
--	Vehicle health meter script by aLTis (the first real script I made completely by myself)
--	This script will sync health meters for Falcon, truck and Scorpion

--	config
	-- vehicle tag and magazine number (0 - primary mag, 1 - secondary mag)
VEHICLES = {
	{"vehicles\\falcon\\falcon", 0x1},
	{"halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\military truck", 0},
	{"altis\\vehicles\\scorpion\\scorpion", 0},
}

--	end of config

api_version = "1.9.0.0"

sound_timer = 27

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnTick()
	if true then return false end
	sound_timer = sound_timer - 1
	if sound_timer == 0 then
		sound_timer = 27
	end

	for i=1,16 do
		if(player_alive(i) == true) then
			local player_object = get_dynamic_player(i)
			local vehicle_objectid = read_dword(player_object + 0x11C)--		Check in which vehicle player is
			
			if(tonumber(vehicle_objectid) ~= 0xFFFFFFFF) then
				local vehicle_object = get_object_memory(vehicle_objectid)
				local vehicle_name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
				vehicle_name = string.format("%s", vehicle_name)
				
				for k, v in pairs(VEHICLES) do
					if(vehicle_name == v[1]) then--								Check if vehicle is in the VEHICLES list
						local weapon = read_dword(vehicle_object + 0x2F8)--		Get vehicle's weapon
						if weapon ~= 0 then
							local weapon_object = get_object_memory(weapon)
							if weapon_object ~= 0 then
								local armor = read_float(vehicle_object + 0xE4)--	Get vehicle's shield value (vehicles use shields, not actual health)
								if armor < 0.4 and sound_timer == 1 then
									PlaySound(i, "transition")
								end
								armor = math.floor(armor * 85 + 0.5)--				Multiply armor value by 85 so it would display correctly on hud meter
								write_word(weapon_object + 0x2B6 + v[2]*0xC, armor)--			Change ammo in halo's memory
							end
						end
					end
				end
			end
		end
	end
end

function PlaySound(i, sound)
	if get_var(i, "$has_chimera") == "1" then
		rprint(i, "play_chimera_sound~"..sound)
	end
end

function OnScriptUnload() end
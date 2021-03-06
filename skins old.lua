--	Weapon Skins by aLTis
--	This script will let players switch skins for some weapons

--	CONFIG

debug_mode = true

--	ASSAULT RIFLE
ar_command = "ar"
ar_weapon =  "bourrin\\weapons\\assault rifle"
ar_default_ammo = 32

AR_SKINS = {
	["default"] = 7,
	["other"] = 6,
	["fade"] = 5,
	["camo"] = 4,
}

PLAYER_CHOICES = {}

--	END OF CONFIG


api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnTick()
	for i=1,16 do
		if(player_alive(i)) then
			local player = get_dynamic_player(i)
			local currentWeapon = read_dword(player + 0x118)
			local WeaponObj = get_object_memory(currentWeapon)
			
			if(WeaponObj ~= nil and WeaponObj ~= 0) then
				local name = read_string(read_dword(read_word(WeaponObj) * 32 + 0x40440038))
				if(name == ar_weapon) then
					local ammo_required = AR_SKINS[PLAYER_CHOICES[i]]
					local current_ammo = read_word(WeaponObj + 0x2B8)
					local real_ammo_loaded = read_word(WeaponObj + 0x2B8 + 0xC)
					local real_ammo_unloaded = read_word(WeaponObj + 0x2B6 + 0xC)
					local ammo_reloaded
					local ammo_reloaded_left
					
					if(debug_mode) then rprint(1, real_ammo_unloaded) end
					if(debug_mode) then rprint(1, real_ammo_loaded) end
					
					if(ammo_required == nil) then
						PLAYER_CHOICES[i] = "default"
					else	
						write_word(WeaponObj + 0x2B6, 5)					--	unloaded ammo
						if(current_ammo ~= AR_SKINS[PLAYER_CHOICES[i]]) then
							write_word(WeaponObj + 0x2B6, 0)		
							write_word(WeaponObj + 0x2B8, ammo_required)	--	loaded ammo
							if(real_ammo_loaded < ar_default_ammo) then		--	FAKE RELOAD
								if(debug_mode) then rprint(1, "FAKE RELOAD") end

								ammo_reloaded = ar_default_ammo
								ammo_reloaded_left = real_ammo_unloaded + real_ammo_loaded - ar_default_ammo
								if(ammo_reloaded_left < 1) then
									if(debug_mode) then rprint(1, "NO MORE UNLOADED AMMO") end
									ammo_reloaded = real_ammo_unloaded + real_ammo_loaded
									ammo_reloaded_left = 0
								end

								write_word(WeaponObj + 0x2B8 + 0xC, ammo_reloaded) -- write loaded ammo
								write_word(WeaponObj + 0x2B6 + 0xC, ammo_reloaded_left) --	write unloaded ammo
								sync_ammo(currentWeapon)
							end
							sync_ammo(currentWeapon)
						end
						--write_word(WeaponObj + 0x2B8, ammo_required)
						
						--if(debug_mode) then rprint(1, read_word(WeaponObj + 0x2B6)) end
						--sync_ammo(currentWeapon)
					end
					--if(debug_mode) then rprint(1, PLAYER_CHOICES[i]) end
					--if(debug_mode) then rprint(1, current_ammo) end
				end
			end
		end
	end
end

function OnCommand (PlayerIndex,Command)
	local wanted_skin
	Command = string.lower(Command)
	commandargs = {}
    for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
    if(commandargs[1] == ar_command) then
        if(#commandargs == 1) then
            say(PlayerIndex,"Use \""..ar_command.."\" followed by skin name")
        elseif(#commandargs > 1) then
            wanted_skin = Command:sub(commandargs[1]:len() + 2)
            if(AR_SKINS[wanted_skin] == nil) then
                say(PlayerIndex,"Skin " .. wanted_skin .. " does not exist.")
            else
                PLAYER_CHOICES[PlayerIndex] = wanted_skin
                say(PlayerIndex,"You chosen " .. wanted_skin .. " skin.")
            end
         end
        return false
    end
end


function OnScriptUnload() end
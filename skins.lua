--	Weapon Skins by aLTis (altis94@gmail.com)
--	This script will let players switch skins for some weapons
--	To be used on Bigass v3

--	CONFIG
	
	skins_display_command = "my_skins"
	
	--	All weapons must have "weapon" tag in their table and "default" skin
	SKINS = {
		["ar"] = {
			["weapon"] = "bourrin\\weapons\\assault rifle",
			["default"] = 4,
			["camo"] = 3,
			["fade"] = 2,
			["ce3"] = 1,
		},
		["dmr"] = {
			["weapon"] = "bourrin\\weapons\\dmr\\dmr",
			["default"] = 4,
			["test"] = 3,
			["camo"] = 2,
			["red"] = 1,
		},
		["pistol"] = {
			["weapon"] = "reach\\objects\\weapons\\pistol\\magnum\\magnum",
			["default"] = 8,
			["gold"] = 7,
			["ecchi"] = 6,
			["lyra"] = 5,
			["mind"] = 4,
			["none4"] = 3,
			["none5"] = 2,
			["none"] = 1,
		},
	}

--	END OF CONFIG

api_version = "1.9.0.0"

PLAYER_CHOICES = {}

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_SPAWN'],"OnSpawn")
	for i = 1,16 do
		PLAYER_CHOICES[i] = {}
		for key,value in pairs (SKINS) do
			PLAYER_CHOICES[i][key] = "default"
		end
	end
end

function OnSpawn(PlayerIndex)
	timer(33, "ChangeSkin", PlayerIndex)
end

function ChangeSkin(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	local player = get_dynamic_player(PlayerIndex)
	for i = 0,1 do
		local currentWeapon = read_dword(player + 0x2F8 + i*0x4)
		local WeaponObj = get_object_memory(currentWeapon)
		
		if(WeaponObj ~= 0) then
			local name = read_string(read_dword(read_word(WeaponObj) * 32 + 0x40440038))
			for key,value in pairs (SKINS) do
				if(value["weapon"] == name) then
					local ammo_required = SKINS[key][PLAYER_CHOICES[PlayerIndex][key]]
					local current_ammo = read_word(WeaponObj + 0x2C4)
					
					if(current_ammo ~= ammo_required) then
						write_word(WeaponObj + 0x2C4, ammo_required)	
						sync_ammo(currentWeapon, 1)
					end
					--rprint(1, read_word(WeaponObj + 0x2C4))
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
	local weapon = commandargs[1]
	
    if(SKINS[weapon] ~= nil) then
        if(#commandargs == 1) then
			say(PlayerIndex,"Use \\<weapon> <skin name>, skins for "..weapon..":")
			for key,value in pairs (SKINS[weapon]) do
				if(key ~= "weapon") then
					say(PlayerIndex, key)
				end
			end
        elseif(#commandargs > 1) then
            wanted_skin = Command:sub(commandargs[1]:len() + 2)
			local skin_found = false
			
			if(SKINS[weapon][wanted_skin] == nil) then
				say(PlayerIndex,"Skin "..string.upper(wanted_skin).." for "..string.upper(weapon).." does not exist.")
			else
				PLAYER_CHOICES[PlayerIndex][weapon] = wanted_skin
				say(PlayerIndex, "You chosen "..string.upper(wanted_skin).." skin for your "..string.upper(weapon)..".")
				ChangeSkin(PlayerIndex)
			end
         end
        return false
    end
	
	if(commandargs[1] == skins_display_command) then
		for key,value in pairs (PLAYER_CHOICES[PlayerIndex]) do
			rprint(PlayerIndex, string.upper(key).." - "..string.upper(value))
		end
		return false
	end
end


function OnScriptUnload() end
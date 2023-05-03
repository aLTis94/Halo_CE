
-- Universal AI synchronization server script V.1.2 (BETA 1.8, compatible with client DELTA 1.8 (and later) versions), by IceCrow14.

-- Text tags for important stuff: "TESTING", "PENDING", "REMINDER", "DEBUGGED".
-- Sub-level function category tags: "DEVELOPMENT", "REMOTE", "DATA", "GENERIC", "FILE", "TAG".

-- BETA 1.8 introduces:
	-- Standarized base 41 number com/decom-pression system. No more hex.
	-- Optimized Float to Base 41 and Decimal to Binary functions.
	-- Adjustable number of timers. For a more detailed list of the changes from the last version, look up the client script.
	-- Firing effects. Disabling them can improve the clients' performance (to do this, set "SERVER SIDE PROJECTILES" to 1).

api_version = "1.11.1.0"

-- Globals (and their default values)
settings = nil
settings_initialized = nil

revision = "REVISION_1_2_3"
updates_per_second = 4
updater_instances = 3
biped_indexer_period = 3000
print_biped_count_period = 10000
print_biped_count = 1
server_side_projectiles = 0
debug_level = 1 -- Available values: 0 (No messages, silent) to 4 (Everything except RCON update packets, is printed to console).
excluded_maps = {}

updater_period = 1000/updates_per_second
char_table = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", 
			  "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
			  "w", "x", "y", "z", "A", "B", "C", "D", "E"}

-- Object/data tables and match specific variables.
biped_paths = {}
biped_lists = {}
weapon_paths = {}
objects = {}
undesired_objects = {}
bipeds = {}
dead_bipeds = {}
deleted_bipeds = {}

map_is_ready = nil

function OnScriptLoad()
	register_callback(cb['EVENT_OBJECT_SPAWN'],'OnObjectSpawn') -- Callbacks
	register_callback(cb['EVENT_GAME_START'],'OnGameStart')
	register_callback(cb['EVENT_GAME_END'],'OnGameEnd')

	register_callback(cb['EVENT_TICK'],'OnTick') -- TESTING: For the firing effects.

end

function OnScriptUnload()
	settings = nil
	settings_initialized = nil
	revision = nil
	updates_per_second = nil
	updater_instances = nil
	biped_indexer_period = nil
	print_biped_count_period = nil
	print_biped_count = nil
	server_side_projectiles = nil
	debug_level = nil
	excluded_maps = nil
	updater_period = nil
	char_table = nil
	biped_paths = nil
	biped_lists = nil
	weapon_paths = nil
	objects = nil
	undesired_objects = nil
	bipeds = nil
	dead_bipeds = nil
	deleted_bipeds = nil
	map_is_ready = nil -- REMINDER: Add any missing variables if more are added.
end

function OnGameStart()
	InitializeSettingsAndPBCTimer()
	MapIsExcluded()

	biped_paths = {}
	biped_lists = {}
	weapon_paths = {}
	bipeds = {}
	dead_bipeds = {}
	deleted_bipeds = {}

	if map_is_ready ~= -1 then
		TagManipulationServer(GetScenarioPath())
		map_is_ready = 1
		DebugConsolePrint("Tag manipulation stage finished.", 1, 0xA)

		BipedIndexer()
		timer(biped_indexer_period, "BipedIndexer")

		StartUpdaters()
	end
end

function OnGameEnd()
	map_is_ready = 0
	objects = {} -- Some objects will not be present if these tables are cleared in "OnGameStart".
	undesired_objects = {}
end

function OnObjectSpawn(PlayerIndex, TagID, ParentObjectID, NewObjectID, SappSpawning)
	table.insert(objects,NewObjectID)
end

function OnTick() -- TESTING: For the firing effects.
	if map_is_ready == 1 and server_side_projectiles == 0 then
		for i = 1, #bipeds do
			local biped = bipeds[i]
			local biped_m_address = get_object_memory(biped)
			if biped_m_address ~= 0 then
				local health_empty = read_bit(biped_m_address + 0x106, 2)
				if health_empty == 0 then
					local weapon_object_id = read_dword(biped_m_address + 0x118)
					if weapon_object_id ~= 0xFFFFFFFF then
						local weapon_m_address = get_object_memory(weapon_object_id)
						if weapon_m_address ~= 0 then
							local weapon_not_firing = read_bit(weapon_m_address + 0x264, 0) -- Trigger state always returns 0.
							if weapon_not_firing ~= 1 then
								local rcon_biped_index = Word16ToChar3(i)
								local rcon_final_message = "@bf"..rcon_biped_index
								for player = 1, 16 do
									rprint(player, rcon_final_message) -- Possibly try the "@bf_0_50_#####...#####", 50 "#"s thing.
								end
							end
						end
					end
				end
			end
		end
	end
end

-- >>> Sub-level functions: Used by the functions above. <<<

-- FUNCTIONS IN DEVELOPMENT

-- N.A.D.

-- (Empty)

-- SETTINGS & FILE I/O FUNCTIONS

-- N.A.D.

function InitializeSettingsAndPBCTimer()
	if settings_initialized ~= true then
		settings = io.open("uais_settings_server.txt", "r")
		DebugConsolePrint("Reading AI synchronization settings...", 1, 0xB)
		if settings == nil then -- Create file.
			DebugConsolePrint("File not found. Creating settings...", 1, 0xB)
			CreateDefaultSettings()
			DebugConsolePrint("Settings created.", 1, 0xB)
		else -- Update file (if obsolete).
			io.input(settings)
			local file_revision
			for line in settings:lines() do
				if string.sub(line, 1, 1) ~= "@" then
					file_revision = line
					break
				end
			end
			io.close(settings)
			if revision ~= file_revision then
				DebugConsolePrint("Obsolete settings file found. Updating...", 1, 0xB)
				CreateDefaultSettings()
				DebugConsolePrint("Settings updated.", 1, 0xB)
			end
		end
		settings = io.open("uais_settings_server.txt", "r") -- Read file data.
		io.input(settings)
		ReadSettingsFile()
		io.close(settings)
		DebugConsolePrint("Settings stage finished.", 1, 0xA)
		timer(print_biped_count_period, "PrintBipedCounts", print_biped_count)
		settings_initialized = true
	end
end

function CreateDefaultSettings()
	settings = io.open("uais_settings_server.txt", "w")
	io.output(settings)
	io.write("@ You can specify new values for the following settings manually as long as you don't modify the format or specify invalid ones. To add a new excluded map, just write its file name (without the .map extension) below the EXCLUDED MAPS section, specify only one map per line.\n")
	io.write("@ If for some reason you break the file (GG), just delete it, restart your dedicated server and the script will create a new one automatically for you. For questions or help, you can find me on YouTube or Discord. -IceCrow14\n")
	io.write(revision.."\n")
	io.write("UPDATES PER SECOND (Float +)\n"..updates_per_second.."\n")
	io.write("UPDATE TIMERS (Int. +)\n"..updater_instances.."\n")
	io.write("BIPED INDEXER PERIOD (Int. +, in ms)\n"..biped_indexer_period.."\n")
	io.write("PRINT BIPED COUNT PERIOD (Int +, in ms)\n"..print_biped_count_period.."\n")
	io.write("PRINT BIPED COUNT TO CHAT (0 = False / 1 = True)\n"..print_biped_count.."\n")
	io.write("SERVER SIDE PROJECTILES (0 = False / 1 = True)\n"..server_side_projectiles.."\n")
	io.write("DEBUG LEVEL (0 - 4)\n"..debug_level.."\n")
	io.write("EXCLUDED MAPS\n")
	io.write("beavercreek\nsidewinder\ndamnation\nratrace\nprisoner\nhangemhigh\nchillout\ncarousel\nboardingaction\nbloodgulch\nwizard\nputput\nlongest\nicefields\ndeathisland\ndangercanyon\ninfinity\ntimberland\ngephyrophobia\n")
	io.close(settings)
end

function ReadSettingsFile()
	local file = {}
	for line in settings:lines() do
		if string.sub(line, 1, 1) ~= "@" then
			table.insert(file, line)
		end
	end
	updates_per_second = tonumber(file[3])
	updater_instances = tonumber(file[5])
	biped_indexer_period = tonumber(file[7])
	print_biped_count_period = tonumber(file[9])
	print_biped_count = tonumber(file[11])
	server_side_projectiles = tonumber(file[13])
	debug_level = tonumber(file[15])
	for map = 17, #file do
		local c_map = file[map]
		table.insert(excluded_maps, c_map)
	end
end

function MapIsExcluded()
	local current_map = get_var(9, "$map")
	for map = 1, #excluded_maps do
		if excluded_maps[map] == current_map then
			map_is_ready = -1
			DebugConsolePrint("WARNING: Excluded map ("..current_map.."). AI sync. functions will not be executed.", 1, 0xE)
		end
	end
end

-- REMOTE CONSOLE & UPDATER FUNCTIONS

-- Used to read, prepare and communicate the information to the clients.

function BipedIndexer() -- REMINDER: This needs a re-work. The memory leak will eventually devour the server's performance.
	if map_is_ready == 1 then
		for i = 1, #objects do
			if undesired_objects[i] ~= true then
				local object_id = objects[i]
				local object_address = get_object_memory(object_id)
				if object_address ~= 0 then
					if read_word(object_address + 0xB4) == 0 then
						local object_player_id = read_dword(object_address + 0xC0)
						local object_health = read_float(object_address + 0xE0)
						local object_dead_bit = read_bit(object_address + 0x106, 2)
						if object_player_id == 0xFFFFFFFF and object_health > 0 and object_dead_bit == 0 then -- If not a player, and alive.
							local stored_in_bipeds = false
							for j = 1,#bipeds do
								if object_id == bipeds[j] then
									stored_in_bipeds = true
								end
							end
							if stored_in_bipeds == false then -- Add to a table. 
								table.insert(bipeds, object_id)
								local stored_in_biped_lists = false
								for k = 1,#biped_lists do
									local c_biped_list = biped_lists[k]
									for l = 1,#bipeds do
										local c_biped_object_id = c_biped_list[l]
										if object_id == c_biped_object_id then
											stored_in_biped_lists = true
											break
										end
									end
								end
								if stored_in_biped_lists == false then
									local biped_tag_id = read_dword(object_address)
									local biped_was_added_to_list = false
									for k = 1,#biped_paths do
										local c_biped_path = biped_paths[k]
										local c_biped_path_tag_address = lookup_tag("bipd", c_biped_path)
										local c_biped_path_tag_id = read_dword(c_biped_path_tag_address + 0xC)
										if biped_tag_id == c_biped_path_tag_id then -- Add biped object ID with this index from the bipeds table, to this biped table from the biped_lists table, then break. Oof.
											local biped_list = biped_lists[k]
											biped_list[#bipeds] = object_id
											biped_was_added_to_list = true
											DebugConsolePrint("Successfully added a #"..k, 3, 0x2)
											break
										end
									end
									if biped_was_added_to_list == false then
										DebugConsolePrint("WARNING: The biped "..#bipeds.." wasn't added to any biped table (Tag path may not match with any from the 'biped_paths' list)", 1, 0xE) -- This shouldn't happen anymore. ("Map is ready" check introduced).
									end
								end
							end
						end
					else
						undesired_objects[i] = true -- To avoid unnecessary evaluations.
					end
				else
					undesired_objects[i] = true
				end
			end
		end
		DebugConsolePrint("Biped Indexer()", 2, 0xB)
		return true
	else
		return false
	end
end

function PrintBipedCounts(PrintToChat)
	if map_is_ready == 1 then
		local bipeds_alive = 0
		local bipeds_dead = 0
		local bipeds_deleted = 0
		local final_message
		for i = 1,#bipeds do
			if bipeds[i] ~= nil then
				if dead_bipeds[i] ~= nil then
					if deleted_bipeds[i] ~= nil then
						bipeds_deleted = bipeds_deleted + 1
					else
						bipeds_dead = bipeds_dead + 1
					end
				else
					bipeds_alive = bipeds_alive + 1
				end
			end
		end
		final_message = bipeds_alive.." bipeds alive, "..bipeds_dead.." dead, "..bipeds_deleted.." deleted."
		DebugConsolePrint(final_message, 1, 0x3)
		if PrintToChat == "1" then
			say_all(final_message)
		end
	end
	return true
end

function StartUpdaters()
	for instance = 1, updater_instances do
		timer((instance - 1) * (updater_period / updater_instances), "UpdaterStarter", instance)
		DebugConsolePrint("Updater #"..instance.." started.", 1, 0xB)
	end
end

function UpdaterStarter(Instance) -- Creates a delayed timer used to start another instance of the 'Updater' function, for optimization purposes.
	timer(updater_period, "Updater", Instance)
	return false
end

function Updater(Instance)
	if map_is_ready == 1 then
		if #bipeds > 0 then
			local instance = tonumber(Instance) -- REMINDER: Timer arguments are passed as strings.
			local updater_limits = GetUpdaterLimits(instance)
			for i = updater_limits[1], updater_limits[2] do
				if bipeds[i] ~= nil then
					local biped_address = get_object_memory(bipeds[i])
					if biped_address ~= 0 then -- Both, dead and alive bipeds are updated as long as they exist.
						if (read_float(biped_address + 0xE0) <= 0) and (read_bit(biped_address + 0x106, 2) == 1) then -- 'Health' == 0 and 'Health is empty' == 1. 
							if dead_bipeds[i] == nil then
								dead_bipeds[i] = true
								DebugConsolePrint("Biped #"..i.." killed", 3, 0x2)
							end
						end
						for j = 1,#biped_lists do
							local biped_list = biped_lists[j]
							if biped_list[i] ~= nil then
								RCONUpdateBiped(i, j, biped_address)
							end
						end
					else
						if dead_bipeds[i] == true then
							if deleted_bipeds[i] == nil then
								deleted_bipeds[i] = true
								DebugConsolePrint("Biped #"..i.." deleted", 3, 0x2)
								RCONDeleteBipedStarter(i)
							end
						else
							if dead_bipeds[i] == nil then -- Deleted through commands or unknown causes.
								dead_bipeds[i] = true
							end
						end
					end
				end
			end
		end
		DebugConsolePrint("Updater()", 4, 0xB)
		return true
	else
		return false
	end
end

function GetUpdaterLimits(Instance)
	local total_bipeds = #bipeds
	while (total_bipeds % updater_instances) ~= 0 do
		total_bipeds = total_bipeds + 1
	end
	local upper_limit = (total_bipeds/updater_instances) * Instance
	local lower_limit = (total_bipeds/updater_instances) * (Instance - 1) + 1
	local limits = {lower_limit, upper_limit}
	return limits
end

function RCONUpdateBiped(Index, BipedListIndex, BipedAddress)
	local biped_address = BipedAddress
	local biped_index = Word16ToChar3(Index) -- Max value: 65535.
	local biped_list_index = Byte8ToChar2(BipedListIndex)
	local weapon_list_index = Byte8ToChar2(GetBipedWeaponType(Index))
	local x = ReadFloat32ToChar3(biped_address + 0x5C)
	local y = ReadFloat32ToChar3(biped_address + 0x60)
	local z = ReadFloat32ToChar3(biped_address + 0x64)
	local x_vel = ReadFloat32ToChar3(biped_address + 0x68)
	local y_vel = ReadFloat32ToChar3(biped_address + 0x6C)
	local z_vel = ReadFloat32ToChar3(biped_address + 0x70)
	local pitch = ReadFloat32ToChar3(biped_address + 0x74)
	local yaw = ReadFloat32ToChar3(biped_address + 0x78) -- Roll is not used by bipeds.
	local pitch_vel = ReadFloat32ToChar3(biped_address + 0x8C) -- REMINDER: Delete pitch, and yaw velocities.
	local yaw_vel = ReadFloat32ToChar3(biped_address + 0x90)
	local x_aim = ReadFloat32ToChar3(biped_address + 0x23C)
	local y_aim = ReadFloat32ToChar3(biped_address + 0x240)
	local z_aim = ReadFloat32ToChar3(biped_address + 0x244)
	local x_aim_vel = ReadFloat32ToChar3(biped_address + 0x248)
	local y_aim_vel = ReadFloat32ToChar3(biped_address + 0x24C)
	local z_aim_vel = ReadFloat32ToChar3(biped_address + 0x250)
	local animation = ReadWord16ToChar3(biped_address + 0xD0)
	local local_health = read_float(biped_address + 0xE0)
	local local_shield = read_float(biped_address + 0xE4)
	local local_health_empty = read_bit(biped_address + 0x106, 2)
	local local_shield_empty = read_bit(biped_address + 0x106, 3)
	local health_state = BipedStateBoolean(local_health, local_health_empty)
	local shield_state = BipedStateBoolean(local_shield, local_shield_empty)
	local rcon_message = "@bu"..x..y..z..x_vel..y_vel..z_vel..pitch..yaw..pitch_vel..yaw_vel..x_aim..y_aim..z_aim..x_aim_vel..y_aim_vel..z_aim_vel..biped_index..animation..biped_list_index..weapon_list_index..health_state..shield_state
	for player = 1, 16 do
		rprint(player, rcon_message)
	end
	-- DebugConsolePrint(rcon_message, 5, 0x2)
end

function RCONDeleteBipedStarter(BipedIndex)
	local attempts = 3 -- These can be changed safely, but I recommend leaving them untouched.
	local delay = 3000
	for j = 1, attempts do
		local c_attempt_delay = (j - 1) * delay
		for player = 1, 16 do
			timer(c_attempt_delay, "RCONDeleteBiped", BipedIndex, player)
		end
	end
end

function RCONDeleteBiped(BipedIndex, PlayerIndex)
	local biped_index = Word16ToChar3(tonumber(BipedIndex))
	local player_index = tonumber(PlayerIndex)
	rprint(player_index, "@bd"..biped_index)
	return false
end

-- GENERIC/MISCELLANEOUS FUNCTIONS

-- Functions that wouldn't fit anywhere else.

function DebugConsolePrint(String, MessageDebugLevel, Color)
	if MessageDebugLevel <= debug_level then -- Lower value, higher hierarchy (and less messages).
		if Color ~= nil and Color < 0x10 and Color > -1 then
			cprint(String, Color)
		else
			cprint(String)
		end
	end
end

function GetBipedWeaponType(BipedIndex)
	local biped_address = get_object_memory(bipeds[BipedIndex])
	local weapon_object_id = read_dword(biped_address + 0x118)
	local weapon_type_ready = false
	if weapon_object_id ~= 0xFFFFFFFF then
		local weapon_address = get_object_memory(weapon_object_id)
		local weapon_tag_id = read_dword(weapon_address)
		for j = 1,#weapon_paths do
			local c_weapon_tag_address = lookup_tag("weap", weapon_paths[j])
			local c_weapon_tag_id = read_dword(c_weapon_tag_address + 0xC)
			if c_weapon_tag_id == weapon_tag_id then
				weapon_type_ready = true
				return j
			end
		end
		if weapon_type_ready == false then
			return 0 -- In case the weapon type hasn't been declared yet. REMINDER: Obsolete. ("Map is ready" check introduced).
		end
	else
		return 0 -- The biped is unarmed.
	end
end

-- DATA COMPRESSION FUNCTIONS

-- The purpose of these functions is to reduce the amount of text characters necessary to represent numbers on the client-side (B, D, 41).

function ReadFloat32ToChar3(Address) -- Optimized.
	if Address ~= 0 then
		local offset = 3
		local binary = {}
		binary[1] = tostring(read_bit(Address + offset, 7)) -- Sign.
		binary[2] = {} -- Exponent.
		binary[3] = {} -- Mantissa.
		local binary_exponent_value = 0
		for i = 1, 18 do -- Read from memory.
			local c_bit_address = Address + offset
			local c_bit_index = 7 - i + 8 * (3 - offset)
			local c_bit = read_bit(c_bit_address, c_bit_index)
			if i < 9 then
				table.insert(binary[2], c_bit)
			else
				table.insert(binary[3], c_bit)
			end
			if (i + 1) % 8 == 0 then
				offset = offset - 1
			end
		end
		binary[2] = table.concat(binary[2])
		binary_exponent_value = tonumber(binary[2], 2) - 127 + 15 -- Single precision float format (32 bit), to half precision (16 bit).
		if binary_exponent_value > 31 then
			binary_exponent_value = 31
		elseif binary_exponent_value < 0 then
			binary_exponent_value = 0
		end
		binary[2] = DecimalToBinary(binary_exponent_value, 5)
		binary[3] = table.concat(binary[3])
		binary = table.concat(binary)
		local quotient = tonumber(binary, 2) -- Convert to base 41.
		local hs = 0
		local ts = 0
		local us = 0
		local base_41 = {}
		while quotient > (1640 + 40) do -- Decimal to base 41.
			quotient = quotient - 1681
			hs = hs + 1
		end
		while quotient > (40) do
			quotient = quotient - 41
			ts = ts + 1
		end
		while quotient > (0) do
			quotient = quotient - 1
			us = us + 1
		end
		table.insert(base_41, char_table[hs + 1])
		table.insert(base_41, char_table[ts + 1])
		table.insert(base_41, char_table[us + 1])
		base_41 = table.concat(base_41)
		return base_41
	else
		return "000"
	end
end

function ReadWord16ToChar3(Address)
	if Address then
		local word = read_word(Address)
		local char_3 = Word16ToChar3(word)
		return char_3
	end
end

function Word16ToChar3(Value)
	if Value >= 0 and Value < 65536 then
		local quotient = Value
		local hs = 0
		local ts = 0
		local us = 0
		local base_41 = {}
		while quotient > 1680 do
			quotient = quotient - 1681
			hs = hs + 1
		end
		while quotient > 40 do
			quotient = quotient - 41
			ts = ts + 1
		end
		while quotient > 0 do
			quotient = quotient - 1
			us = us + 1
		end
		base_41[1] = char_table[hs + 1]
		base_41[2] = char_table[ts + 1]
		base_41[3] = char_table[us + 1]
		base_41 = table.concat(base_41)
		return base_41
	else
		return "000"
	end
end

function Byte8ToChar2(Value)
	if Value >= 0 and Value < 256 then
		local quotient = Value
		local ts = 0
		local us = 0
		local base_41 = {}
		while quotient > 40 do
			quotient = quotient - 41
			ts = ts + 1
		end
		while quotient > 0 do
			quotient = quotient - 1
			us = us + 1
		end
		base_41[1] = char_table[ts + 1]
		base_41[2] = char_table[us + 1]
		base_41 = table.concat(base_41)
		return base_41
	else
		return "00"
	end
end

function BipedStateBoolean(Value, EmptyBit)
	local state = 1 -- Alive/Shields active.
	if EmptyBit == 1 and Value <= 0 then
		state = 0 -- Dead/Shields down.
	end
	return tostring(state)
end

function DecimalToBinary(Value, Digits)
	local binary = {}
	local binary_length = 0
	local digits = Digits
	local quotient = tonumber(Value)
	local modulo
	while quotient > 0 do
		modulo = quotient % 2
		quotient = math.floor(quotient/2)
		binary[digits - binary_length] = modulo
		binary_length = binary_length + 1
	end
	while binary_length < digits do
		binary[digits - binary_length] = 0
		binary_length = binary_length + 1
	end
	binary = table.concat(binary)
	return binary
end

-- TAG MANIPULATION FUNCTIONS

-- These functions are run only once, every time a new map is loaded. Only fully finished functions are placed inside this section and each one has its own sub-level ID.

function TagManipulationServer(ScenarioPath)
	local scnr_tag_address = lookup_tag("scnr",ScenarioPath)
	local scnr_tag_data = read_dword(scnr_tag_address + 0x14)
	local actors_count = read_dword(scnr_tag_data + 0x420) -- Taken from the "Actor Palette" struct.
	local actors_address = read_dword(scnr_tag_data + 0x420 + 4)
	if actors_count > 0 then
		for i = 0,actors_count - 1 do
			local c_actor_address = actors_address + i * 16
			local c_actor_dpdc_path = read_string(read_dword(c_actor_address + 0x4))
			DeclareBipedType(c_actor_dpdc_path)
		end
	end
	local bipeds_count = read_dword(scnr_tag_data + 0x234) -- Taken from the "Biped Palette" struct.
	local bipeds_address = read_dword(scnr_tag_data + 0x234 + 4)
	if bipeds_count > 0 then
		for i = 0,bipeds_count - 1 do
			local c_biped_address = bipeds_address + i * 48
			local c_biped_dpdc_path = read_string(read_dword(c_biped_address + 0x4))
			local new_biped_type = TryToAddBipedType(c_biped_dpdc_path)
			if new_biped_type == true then -- Weapons used by the bipeds should be tested and added to the weapon tag path tables (if not there yet).
				local tag_address = lookup_tag("bipd", c_biped_dpdc_path)
				local tag_data = read_dword(tag_address + 0x14)
				local biped_weapons_count = read_dword(tag_data + 0x2D8)
				local biped_weapons_address = read_dword(tag_data + 0x2D8 + 4)
				if biped_weapons_count > 0 then
					for i = 0,biped_weapons_count - 1 do
						local c_biped_weapon_address = biped_weapons_address + i * 36
						local c_biped_weapon_path = read_string(read_dword(c_biped_weapon_address + 0x4))
						DeclareWeaponType(c_biped_weapon_path)
					end
				end
			end	
		end
	end
end

function GetScenarioPath()
	local scnr_tag_name_address = read_dword(0x40440028 + 0x10) -- Doesn't work for protected maps.
	local scnr_tag_name = read_string(scnr_tag_name_address)
	return scnr_tag_name
end

function DeclareBipedType(ActorVariantPath) -- Server version.
	local actv_tag_address = lookup_tag("actv",ActorVariantPath)
	local actv_tag_data = read_dword(actv_tag_address + 0x14)
	local unit_dpdc = read_dword(actv_tag_data + 0x14)
	local unit_dpdc_path = read_string(read_dword(actv_tag_data + 0x14 + 0x4))
	TryToAddBipedType(unit_dpdc_path)
	local actv_actr_dpdc = read_dword(actv_tag_data + 0x04) -- Disable vehicle combat (it is necessary to get AI to sync in vehicles to get rid of this. Coming soon).
	local actv_actr_dpdc_path = read_string(read_dword(actv_tag_data + 0x04 + 0x4))
	local actr_tag_address = lookup_tag("actr",actv_actr_dpdc_path)
	local actr_tag_data = read_dword(actr_tag_address + 0x14)
	local actr_more_flags_bitmask = actr_tag_data + 0x04 -- Location of the bitmask.
	local disallow_vehicle_combat_bit = read_bit(actr_more_flags_bitmask, 3)
	if disallow_vehicle_combat_bit == 0 then
		write_bit(actr_more_flags_bitmask,3,1)
	end
	local actv_weap_dpdc = read_dword(actv_tag_data + 0x64) -- Declare actv's weapon.
	local actv_weap_dpdc_path = read_string(read_dword(actv_tag_data + 0x64 + 0x4))
	DeclareWeaponType(actv_weap_dpdc_path)
	local major_variant_dpdc = read_dword(actv_tag_data + 0x24) -- Declare "Major variant" of this actv.
	local major_variant_dpdc_path = read_string(read_dword(actv_tag_data + 0x24 + 0x4))
	if major_variant_dpdc_path ~= nil then
		DeclareBipedType(major_variant_dpdc_path)
	end
end

function DeclareWeaponType(WeaponPath) -- Server version.
	if WeaponPath ~= nil then -- If this actv or biped has a weapon.
		local new = true
		for i = 1,#weapon_paths do -- To avoid registering the same weapon multiple times.
			if weapon_paths[i] == WeaponPath then
				new = false
			end
		end
		if new == true then
			table.insert(weapon_paths,WeaponPath)
			DebugConsolePrint("Weapon tag registered #"..#weapon_paths..": "..WeaponPath, 1, 0x6)
			local weapon_tag_address = lookup_tag("weap",WeaponPath) -- Sets projectiles not to be client side only (So the AI's are visible too. SERVER ONLY).
			local weapon_tag_data = read_dword(weapon_tag_address + 0x14)
			local triggers_count = read_dword(weapon_tag_data + 0x4FC)
			local triggers_bitmask = read_dword(weapon_tag_data + 0x4FC + 4)
			if triggers_count > 0 then -- If this weapon has no triggers. Extremely rare if not impossible, but just in case.
				for trigger = 0,(triggers_count - 1) do
					local c_trigger_bitmask = triggers_bitmask + trigger * 276
					local projectile_is_client_side_only = read_bit(c_trigger_bitmask + 1, 5)
					if projectile_is_client_side_only == 1 and server_side_projectiles == 1 then
						write_bit(c_trigger_bitmask + 1, 5, 0) -- "Projectile is client side only" set to false.
					end
				end
			end
		end
	end
end

function TryToAddBipedType(Path) -- Server version.
	local new = true
	for i = 1,#biped_paths do -- To avoid registering the same biped type multiple times.
		if biped_paths[i] == Path then
			new = false
		end
	end
	if new == true then
		table.insert(biped_paths, Path) -- Make new list for this biped type.
		biped_lists[#biped_paths] = {}
		DebugConsolePrint("Biped tag registered #"..#biped_paths..": "..Path, 1, 0x6)
	end
	return new
end
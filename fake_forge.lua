
-- Fake forge by aLTis (some functions are made by kirby or giraffe)
-- Server script for fake forge
-- players are required to have chimera script for this to work!!!
-- use fake_forge.py to get scenery locations and stuff from a scenario tag

api_version = "1.12.0.0"

--CONFIG
	
	map_name = "bigass_"
	bigass_default_map_name = "bigass_v3"
	
	debug_mode = true	-- when enabled, players won't be forced to respawn when script is loaded
	
	object_spawn_delay = 15 -- miliseconds. reduce this to spawn objects faster
	vehicle_spawn_delay = 5000 -- miliseconds. how long it takes for vehicles to spawn since the map was loaded
	
	prefix_default = "r" -- what rcon messages start with
	prefix_bigass_v3 = "f"
	
	VEHICLES_NOT_TO_REMOVE = {
		["altis\\scenery\\armor_room\\armor_room"] = true,
		["altis\\vehicles\\scriptroomthing\\scriptroomthing"] = true,
	}
	
	SCENERY_NOT_TO_REMOVE = {
		["altis\\scenery\\ffs\\i hate all of you"] = true,
		["altis\\scenery\\fuck_this_shit\\i hate bigass"] = true,
		["altis\\scenery\\\bigass_base_stuff\\\bigass_base_stuff"] = true,
	}
	
--END OF CONFIG

--NOTES
	-- should edit everything so that things could be moved mid-game (like race flags and stuff)
	-- some powerups that were in the original map still spawn?
	-- rally is broken (no checkpoints) ??
	-- could queue rcon messages so they wouldn't add up and cause crashes or lag when joining
	-- add a way to set up starting equipment
	-- add a way to change player airborne speed and stuff
	-- make it easy for modders to include this script in their maps
	-- add ability to change position of the sun
	-- add ability to change player size?

OBJECTS_TO_SPAWN = {}
SPAWNED_OBJECTS = {}
counter = 0
initialization_timer = true
bigass_v3 = false
FALL_DAMAGE_TIMERS = {}
for i=1,16 do
	FALL_DAMAGE_TIMERS[i] = 0
end

gametype_base = 0x5F5478
ctf_globals = 0x5BDB98
koth_globals = 0x5BDBD0

function OnScriptLoad()
	game_is_running = false
	
	local timer_seconds_address_sig = sig_scan("C3D905????????D864240CD915????????D81D")
    if(timer_seconds_address_sig == 0) then return end

    local timer_seconds_address_2_sig = sig_scan("74??D905????????D864240CD915????????D81D")
    if(timer_seconds_address_2_sig == 0) then return end

    local game_over_state_address_sig = sig_scan("C705????????03??????75??C6")
    if(game_over_state_address_sig == 0) then return end

    timer_seconds_address = read_dword(timer_seconds_address_sig + 3)
    timer_seconds_address_2 = read_dword(timer_seconds_address_2_sig + 4)
    game_over_state_address = read_dword(game_over_state_address_sig + 2)
	
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D") 
	register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_TICK'],"OnTick")
	register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	Initialize()
end

function OnGameStart()
	Initialize(forge_map_to_load)
end

function OnGameEnd()
	SPAWNED_OBJECTS = {}
	OBJECTS_TO_SPAWN = {}
	NETGAME = nil
	counter = 0
	game_is_running = false
end

function EnableInitializationTimer()
	initialization_timer = true
end

function Initialize(forge_map)
	object_table = read_dword(read_dword(object_table_ptr + 2))
	
	for id, info in pairs (SPAWNED_OBJECTS) do
		RemoveObject(SPAWNED_OBJECTS[id].object_id)
	end

	for i=1,16 do
		if player_present(i) then
			timer(object_spawn_delay, "SendObjectInfo", i, 0, 100)
		end
	end
	
	current_map = get_var(0, "$map")
	
	-- check if map is loaded yet
	if current_map == "n/a" then
		game_is_running = false
		return false
	end
	
	game_is_running = true
	
	bigass_v3 = string.find(current_map, map_name)
	if bigass_v3 == nil then
		bigass_v3 = false
	else
		bigass_v3 = true
	end
	
	if bigass_v3 then
		prefix = prefix_bigass_v3
		file_path = "sapp\\bigass_forge\\"
	else
		prefix = prefix_default
		file_path = "sapp\\"..current_map.."_forge\\"
		
		--chimera detection
		add_var("has_chimera", 4)
		for i=1,16 do
			rprint(i, "|nforgereloaded")
			set_var(i, "$has_chimera", 0)
			rprint(i, "|ngot_chimera?")
		end
	end
	
	fake_forge_enabled = false
	timer(1000, "EnableInitializationTimer")
	counter = 0
	spawnpoint_counter = nil
	
	remove_all_scenery_objects = false
	remove_all_device_objects = false
	remove_all_equipment_objects = false
	remove_all_vehicle_objects = false
	netgame_flags_cleared = false
	NETGAME = nil
	fog = nil
	screen_tint = nil
	sky = nil
	terrain = nil
	disable_hud = 0
	gravity = 1
	execute_command("gravity ".. 0.003565)
	fall_damage_tag = lookup_tag("jpt!", "globals\\falling")
	if fall_damage_tag ~= nil and fall_damage_tag ~= 0 then
		fall_damage_tag = read_dword(fall_damage_tag + 0xC)
	end
	
	if initialization_timer then
		initialization_timer = false
		gametype = string.lower(get_var(0, "$mode"))
		
		if previous_forge_map ~= nil and previous_gametype == gametype then 
			gametype = previous_forge_map
		else
			previous_forge_map = nil
		end
		
		if forge_map ~= nil then
			cprint("   Attempting to load a forge map "..forge_map.." fot the map "..current_map)
			gametype = forge_map
			forge_map_to_load = nil
			previous_forge_map = forge_map
		end
		
		previous_gametype = string.lower(get_var(0, "$mode"))
		
		--INFO
		local savefile = io.open(file_path..gametype.."_info.txt", "r")
		if(savefile ~= nil) then
			cprint("  Forge info file detected for gametype "..gametype)
			fake_forge_enabled = true
			local counter = 0
			local line = savefile:read()
			while(line ~= nil) do
				local INFO = {}
				for word in string.gmatch(line, "([^"..", ".."]+)") do 
					table.insert(INFO, word)
				end
				
				
				--GRAVITY
				if INFO[1] == "gravity" then
					if INFO[2] ~= nil then
						local gravity_scale = tonumber(INFO[2])
						if gravity_scale ~= nil then
							gravity_scale = gravity_scale * 0.003565
							gravity = prefix.."gravity~"..gravity_scale
							execute_command("gravity "..gravity_scale)
							write_float(0x637BE4, gravity_scale)
						end
					end
				
				--SPRINT
				elseif INFO[1] == "disable_sprinting" then
					if INFO[2] == "1" then
						timer(1000, "DisableSprinting")
					else
						-- enable sprinting???
					end
				
				--OBJECTS
				elseif INFO[1] == "remove_all_scenery" then
					if INFO[2] == "1" then
						remove_all_scenery_objects = true
						execute_command("set forge_mode true")
					else
						remove_all_scenery_objects = false
					end
				elseif INFO[1] == "remove_all_devices" then
					if INFO[2] == "1" then
						remove_all_device_objects = true
					else
						remove_all_device_objects = false
					end
				elseif INFO[1] == "remove_all_equipment" then
					if INFO[2] == "1" then
						remove_all_equipment_objects = true
					else
						remove_all_equipment_objects = false
					end
				elseif INFO[1] == "remove_all_vehicles" then
					if INFO[2] == "1" then
						remove_all_vehicle_objects = true
					else
						remove_all_vehicle_objects = false
					end
				elseif INFO[1] == "remove_all_aa" then
					execute_command("lua_call aa RemoveAllAA")
				
				
				--BSP
				-- [2] = type
				elseif bigass_v3 and INFO[1] == "bsp" then
					--needs some work...
					execute_command("set tod "..INFO[2])
				
				
				--TERRAIN
				-- [2] = type
				elseif bigass_v3 and INFO[1] == "terrain" then
					if INFO[2] ~= nil then
						terrain = prefix.."terrain~"..INFO[2]
					end
				
				
				--SKY
				-- [2] = type
				elseif INFO[1] == "sky" then
					if INFO[2] ~= nil then
						if INFO[3] ~= nil and INFO[4] ~= nil then
							sky = prefix.."sky~"..INFO[2].."~"..INFO[3].."~"..INFO[4]
						else
							sky = prefix.."sky~"..INFO[2]
						end
					end
				
				
				--FOG
				-- [2] = red [3] = green [4] = blue [5] = maximum density [6] = start distance [7] = end distance [8] = move camera
				elseif INFO[1] == "fog" then
					if INFO[2] ~= nil and INFO[9] ~= nil then
						fog = prefix.."fog~"..INFO[2].."~"..INFO[3].."~"..INFO[4].."~"..INFO[5].."~"..INFO[6].."~"..INFO[7].."~"..INFO[8].."~"..INFO[9]
					end
				
				
				--SCREEN TINT
				-- [2] = type [3] = intensity [4] = red [5] = green [6] = blue
				elseif bigass_v3 and INFO[1] == "screen_tint" then
					if INFO[2] ~= nil and INFO[6] ~= nil then
						screen_tint = prefix.."screen_tint~"..INFO[2].."~"..INFO[3].."~"..INFO[4].."~"..INFO[5].."~"..INFO[6]
					end
				
				--HUD
				elseif bigass_v3 and INFO[1] == "disable_hud" then
					disable_hud = INFO[2]
					--cprint("disable hud "..INFO[2])
				end
				
				line = savefile:read()
				counter = counter + 1
			end
			savefile:close()
		end
		
		DestroyAllObjects()
		
		--NETGAME
		local savefile = io.open(file_path..gametype.."_netgame.txt", "r")
		if(savefile ~= nil) then
			cprint("  Forge netgame file detected for gametype "..gametype)
			fake_forge_enabled = true
			NETGAME = {}
			NETGAME.spawnpoints = {}
			NETGAME.equipment = {}
			DiscoverNetgame()
			local equipment_counter = 0
			local line = savefile:read()
			while(line ~= nil) do
				local INFO = {}
				for word in string.gmatch(line, "([^"..",".."]+)") do 
					table.insert(INFO, word)
				end
				
				--SPAWNPOINTS
				-- [2] = x, [3] = y, [4] = z, [5] = rotation, [6] = team
				if INFO[1] == "spawnpoint" then
					for i = 2,7 do
						INFO[i] = tonumber(INFO[i])
					end
					if spawnpoint_counter == nil then
						spawnpoint_counter = 0
						for i = 0,starting_location_count do
							UpdateSpawnpoint(i,0,0,0,0,3, 0)
						end
					end
					UpdateSpawnpoint(spawnpoint_counter,INFO[2],INFO[3],INFO[4],INFO[5],INFO[6],INFO[7])
					spawnpoint_counter = spawnpoint_counter + 1
				
				
				--NETGAME FLAGS
				-- [2] = x, [3] = y, [4] = z, [5] = rot, [6] = team, [7] = type
				elseif INFO[1] == "net_flag" then
					for i = 2,7 do
						INFO[i] = tonumber(INFO[i])
					end
					
					if netgame_flags_cleared ~= true then
						ClearNetgameFlags()
						netgame_flags_cleared = true
					end
							
					-- for ctf flags
					if INFO[7] == 0 and netgame_flag_count > 2 then
						local current_flag = netgame_flags + (INFO[6] + 1)*148
						write_vector3d(current_flag, INFO[2], INFO[3], INFO[4])
						write_float(current_flag + 0x0C, INFO[5])
						write_short(current_flag + 0x12, INFO[6])
						write_word(current_flag + 0x10, INFO[7])	
					elseif netgame_flag_counter > netgame_flag_count then
						cprint("  ERROR! Ran out of netgame flag slots! count:"..netgame_flag_counter)
					-- for other flags
					elseif INFO[7] ~= 8 then
						local current_flag = netgame_flags + netgame_flag_counter*148
						write_vector3d(current_flag, INFO[2], INFO[3], INFO[4])
						write_float(current_flag + 0x0C, INFO[5])
						write_short(current_flag + 0x12, INFO[6])
						write_word(current_flag + 0x10, INFO[7])
						netgame_flag_counter = netgame_flag_counter + 1
					end
					
					
					-- CTF FLAGS
					if INFO[7] == 0 and get_var(0, "$gt") == "ctf" then
						if NETGAME.ctf == nil then
							NETGAME.ctf = {}
						end
						local assault = read_byte(gametype_base + 0x9C)
						if INFO[6] == 0 then
							local ctf_flag_red = read_dword(ctf_globals)
							local flag_object_id = read_dword(ctf_globals + 0x8)
							if assault == 1 then
								ctf_flag_red = read_dword(ctf_globals + 4)
								flag_object_id = read_dword(ctf_globals + 0x8 + 4)
							end
							local object = get_object_memory(flag_object_id)
							if object ~= 0 then
								write_vector3d(object + 0x5C, INFO[2], INFO[3], INFO[4])
							end
							write_vector3d(ctf_flag_red, INFO[2], INFO[3], INFO[4])
							NETGAME.ctf.red = {}
							NETGAME.ctf.red.x = INFO[2]
							NETGAME.ctf.red.y = INFO[3]
							NETGAME.ctf.red.z = INFO[4]
						else
							local ctf_flag_blue = read_dword(ctf_globals + 4)
							local flag_object_id = read_dword(ctf_globals + 0x8 + 4)
							if assault == 1 then
								ctf_flag_blue = read_dword(ctf_globals)
								flag_object_id = read_dword(ctf_globals + 0x8)
							end
							local object = get_object_memory(flag_object_id)
							if object ~= 0 then
								write_vector3d(object + 0x5C, INFO[2], INFO[3], INFO[4])
							end
							write_vector3d(ctf_flag_blue, INFO[2], INFO[3], INFO[4])
							NETGAME.ctf.blue = {}
							NETGAME.ctf.blue.x = INFO[2]
							NETGAME.ctf.blue.y = INFO[3]
							NETGAME.ctf.blue.z = INFO[4]
						end
					end
					
					-- KING OF THE HILL
					if INFO[7] == 8 and get_var(0, "$gt") == "king" then
						if NETGAME.hills == nil then
							NETGAME.hills = true
						end
						
						-- we only need the first hill if the gametype doesn't have moving hill
						local moving_hill = read_byte(gametype_base + 0x9C)
						if (moving_hill == 0 and INFO[6] > 0) == false then
							local current_flag = netgame_flags + netgame_flag_counter*148
							write_vector3d(current_flag, INFO[2], INFO[3], INFO[4])
							write_float(current_flag + 0x0C, INFO[5])
							write_short(current_flag + 0x12, INFO[6])
							write_word(current_flag + 0x10, INFO[7])
							netgame_flag_counter = netgame_flag_counter + 1
						end
					
					-- TELEPORTERS
					elseif INFO[7] == 6 then
						if NETGAME.teleport_from == nil then
							NETGAME.teleport_from = {}
						end
						
						for i=0,netgame_flag_count do
							if NETGAME.teleport_from[i] == nil then
								NETGAME.teleport_from[i] = {}
								--[2] = x, [3] = y, [4] = z, [5] = rot, [6] = team,
								NETGAME.teleport_from[i].x = INFO[2]
								NETGAME.teleport_from[i].y = INFO[3]
								NETGAME.teleport_from[i].z = INFO[4]
								NETGAME.teleport_from[i].rot = math.rad(INFO[5])
								NETGAME.teleport_from[i].team = INFO[6]
								break
							end
						end
					elseif INFO[7] == 7 then
						if NETGAME.teleport_to == nil then
							NETGAME.teleport_to = {}
						end
						
						for i=0,netgame_flag_count do
							if NETGAME.teleport_to[i] == nil then
								NETGAME.teleport_to[i] = {}
								--[2] = x, [3] = y, [4] = z, [5] = rot, [6] = team,
								NETGAME.teleport_to[i].x = INFO[2]
								NETGAME.teleport_to[i].y = INFO[3]
								NETGAME.teleport_to[i].z = INFO[4]
								NETGAME.teleport_to[i].rot = math.rad(INFO[5])
								NETGAME.teleport_to[i].team = INFO[6]
								break
							end
						end
					end
					
					-- RACE
					if INFO[7] == 3 and get_var(0, "$gt") == "race" then
						if NETGAME.race == nil then
							NETGAME.race = {}
						end
						
						NETGAME.race[INFO[6]] = {}
						NETGAME.race[INFO[6]].x = INFO[2]
						NETGAME.race[INFO[6]].y = INFO[3]
						NETGAME.race[INFO[6]].z = INFO[4]
					end
				
				--EQUIPMENT
				-- [2] = tag path, [3], = x, [4] = y, [5] = z, [6] = rot, [7] = levitate, [8] = respawn time
				elseif INFO[1] == "equipment" then
					for i = 3,8 do
						INFO[i] = tonumber(INFO[i])
					end
					local address = lookup_tag("itmc", INFO[2])
					if address ~= nil and address ~= 0 then
						UpdateEquipment(equipment_counter,address,INFO[3],INFO[4],INFO[5],INFO[6],INFO[7],INFO[8])
						equipment_counter = equipment_counter + 1
					else
						cprint("  ERROR! Couldn't find item collection tag "..INFO[2])
					end
				
				--ARMOR ABILITIES
				elseif INFO[1] == "aa" then
					local aa_type = nil
					for word in string.gmatch(INFO[2], "([^".."\\".."]+)") do
						aa_type = word
					end
					if aa_type ~= nil then
						if aa_type == "bubble shield" then
							aa_type = "bubble_shield"
						end
						execute_command("lua_call aa AddArmorAbilitySpawn "..aa_type.." "..INFO[3].." "..INFO[4].." "..INFO[5].." "..INFO[6])
					end
				
				--VEHICLES
				-- [2] = tag path, [3] = x, [4] = y, [5] = z, [6] = rot
				elseif INFO[1] == "vehicle" then
					
					timer(vehicle_spawn_delay, "SpawnVehicle", INFO[2], INFO[3], INFO[4], INFO[5], INFO[6])
					
				end
				
				line = savefile:read()
			end
			savefile:close()
		else
			NETGAME = nil
		end
		
		--SCENERY
		local savefile = io.open(file_path..gametype.."_sceneries.txt", "r")
		if(savefile ~= nil) then
			cprint("  Forge sceneries file detected for gametype "..gametype)
			fake_forge_enabled = true
			OBJECTS_TO_SPAWN = {}
			
			local line = savefile:read()
			while(line ~= nil) do
				local INFO = {}
				for word in string.gmatch(line, "([^"..",".."]+)") do 
					table.insert(INFO, word)
				end
				
				INFO[1] = string.sub(INFO[1], 2, -2)
				for i = 2,4 do
					INFO[i] = round(tonumber(INFO[i]), 2)
				end
				for i = 5,7 do
					INFO[i] = round(tonumber(INFO[i]), 2)
				end

				INFO[8] = tonumber(INFO[8])
				INFO[9] = tonumber(INFO[9])
				if tonumber(INFO[10]) == -1 then
					INFO[10] = 0
				else
					INFO[10] = 1
				end
				
				OBJECTS_TO_SPAWN[counter] = {}
				OBJECTS_TO_SPAWN[counter] = INFO
				
				line = savefile:read()
				counter = counter + 1
			end
			cprint("   Scenery objects to spawn: "..counter)
			savefile:close()
			
		end
		
		for j, info in pairs (OBJECTS_TO_SPAWN) do
			SpawnForgeObject(info[8], info[1], info[2], info[3], info[4], info[5], info[6], info[7], info[9], info[10], j)
			if false then
				local ID
				if info[8] == 6 then
					ID = spawn_object("scen", info[1], info[2], info[3], info[4])
				elseif info[8] == 7 then
					ID = spawn_object("mach", info[1], info[2], info[3], info[4])
				elseif info[8] == 8 then
					ID = spawn_object("ctrl", info[1], info[2], info[3], info[4])
				elseif info[8] == 9 then
					ID = spawn_object("lifi", info[1], info[2], info[3], info[4])
				end
				if ID ~= nil then
					local object = get_object_memory(ID) 
					if object ~= 0 then
						SPAWNED_OBJECTS[j] = {}
						SPAWNED_OBJECTS[j].object_id = ID
						if info[8] == 6 then
							SPAWNED_OBJECTS[j].metaid = GetMetaID("scen", info[1])
						elseif info[8] == 7 then
							--write_vector3d(object + 0x21C, info[2], info[3], info[4])
							SPAWNED_OBJECTS[j].metaid = GetMetaID("mach", info[1])
						elseif info[8] == 8 then
							SPAWNED_OBJECTS[j].metaid = GetMetaID("ctrl", info[1])
						elseif info[8] == 9 then
							SPAWNED_OBJECTS[j].metaid = GetMetaID("lifi", info[1])
						end
						SPAWNED_OBJECTS[j].name = info[1]
						SPAWNED_OBJECTS[j].x = info[2]
						SPAWNED_OBJECTS[j].y = info[3]
						SPAWNED_OBJECTS[j].z = info[4]
						SPAWNED_OBJECTS[j].rot1 = info[5]
						SPAWNED_OBJECTS[j].rot2 = info[6]
						SPAWNED_OBJECTS[j].rot3 = info[7]
						SPAWNED_OBJECTS[j].type = info[8]
						SPAWNED_OBJECTS[j].permutation = info[9]
						SPAWNED_OBJECTS[j].shadow = info[10]
						
						rot = convert(SPAWNED_OBJECTS[j].rot1, SPAWNED_OBJECTS[j].rot2, SPAWNED_OBJECTS[j].rot3)
						write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
						write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
						
						write_char(object + 0x180, SPAWNED_OBJECTS[j].permutation)
					else
						cprint("   ERROR! Couldn't spawn forge object "..info[1])
					end
				else
					cprint("   ERROR! Couldn't spawn forge object "..info[1])
				end
			end
		end
	end
	
	if fake_forge_enabled == false then
		SPAWNED_OBJECTS = {}
	end
	
	local race_checkpoint_count = 0
	if NETGAME ~= nil then
		if NETGAME.race ~= nil then
			for team,info in pairs (NETGAME.race) do
				race_checkpoint_count = race_checkpoint_count + 1
			end
			write_dword(0x5BDFA0, math.pow(2, race_checkpoint_count) - 1)
		end
		
		if NETGAME.hills ~= nil then
			timer(300, "ResetKOTH")
			for i=1,16 do
				if player_present(i) then
					SendKOTHInfo(i)
				end
			end
		end
	end
	
	if fake_forge_enabled and debug_mode == false then
		for i=1,16 do
			kill(i)
		end
	end
end

function OnObjectSpawn(i, MetaID, ParentID, ID, SappSpawn)
	if fake_forge_enabled and SappSpawn == 0 and ParentID == 0xFFFFFFFF then
		timer(0, "CheckObj", ID)
	end
end

function CheckObj(ID)
	local object = get_object_memory(tonumber(ID))
	if object ~= 0 then
		local object_type = read_word(object + 0xB4)
		if object_type == 2 or object_type == 3 then
			--say_all(GetName(object))
			--timer(1000, "FixWeaponPos", ID, 0.01)
			timer(3000, "FixWeaponPos", ID, 0.01)
			timer(3033, "FixWeaponPos", ID, -0.01)
			--timer(11000, "FixWeaponPos", ID, 0.01)
			--timer(11033, "FixWeaponPos", ID, -0.01)
		end
	end
	return false
end

function FixWeaponPos(ID, z)
	if fake_forge_enabled == false then return false end
	local object = get_object_memory(tonumber(ID))
	if object ~= 0 then
		local object_type = read_word(object + 0xB4)
		if object_type == 2 or object_type == 3 then
			--write_dword(object + 0x204, tonumber(get_var(0, "$ticks")))
			write_bit(object + 0x10, 5, 0)
			--write_float(object + 0x70, (read_float(object + 0x70))+z)
			write_float(object + 0x64, (read_float(object + 0x64))+tonumber(z))
			--say_all(GetName(object).."   "..z)
		end
	end
	return false
end

function DisableSprinting()
	execute_command("lua_call sprinting DisableSprinting")
end

function SpawnForgeObject(object_type, tag, x, y, z, rot1, rot2, rot3, permutation, shadow, id)
	local external_spawn = false
	if id == nil then
		id = #SPAWNED_OBJECTS + 1
		external_spawn = true
	end
	object_type = tonumber(object_type)
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)
	rot1 = tonumber(rot1)
	rot2 = tonumber(rot2)
	rot3 = tonumber(rot3)
	permutation = tonumber(permutation)
	shadow = tonumber(shadow)
	local ID
	if object_type == 6 then
		ID = spawn_object("scen", tag, x, y, z)
	elseif object_type == 7 then
		ID = spawn_object("mach", tag, x, y, z)
	elseif object_type == 8 then
		ID = spawn_object("ctrl", tag, x, y, z)
	elseif object_type == 9 then
		ID = spawn_object("lifi", tag, x, y, z)
	end
	if ID ~= nil then
		local object = get_object_memory(ID) 
		if object ~= 0 then
			SPAWNED_OBJECTS[id] = {}
			SPAWNED_OBJECTS[id].object_id = ID
			if object_type == 6 then
				SPAWNED_OBJECTS[id].metaid = GetMetaID("scen", tag)
			elseif object_type == 7 then
				SPAWNED_OBJECTS[id].metaid = GetMetaID("mach", tag)
			elseif object_type == 8 then
				SPAWNED_OBJECTS[id].metaid = GetMetaID("ctrl", tag)
			elseif object_type == 9 then
				SPAWNED_OBJECTS[id].metaid = GetMetaID("lifi", tag)
			end
			SPAWNED_OBJECTS[id].name = tag
			SPAWNED_OBJECTS[id].x = x
			SPAWNED_OBJECTS[id].y = y
			SPAWNED_OBJECTS[id].z = z
			SPAWNED_OBJECTS[id].rot1 = rot1
			SPAWNED_OBJECTS[id].rot2 = rot2
			SPAWNED_OBJECTS[id].rot3 = rot3
			SPAWNED_OBJECTS[id].type = object_type
			SPAWNED_OBJECTS[id].permutation = permutation
			SPAWNED_OBJECTS[id].shadow = shadow
			
			rot = convert(SPAWNED_OBJECTS[id].rot1, SPAWNED_OBJECTS[id].rot2, SPAWNED_OBJECTS[id].rot3)
			write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
			write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
			
			write_char(object + 0x180, SPAWNED_OBJECTS[id].permutation)
			
			if external_spawn then
				for i = 1,16 do
					rprint(i, prefix.."s~"..SPAWNED_OBJECTS[id].metaid.."~"..SPAWNED_OBJECTS[id].x.."~"..SPAWNED_OBJECTS[id].y.."~"..SPAWNED_OBJECTS[id].z.."~"..SPAWNED_OBJECTS[id].rot1.."~"..SPAWNED_OBJECTS[id].rot2.."~"..SPAWNED_OBJECTS[id].rot3.."~"..SPAWNED_OBJECTS[id].type.."~"..SPAWNED_OBJECTS[id].permutation.."~"..SPAWNED_OBJECTS[id].shadow)
				end
			end
		else
			cprint("   ERROR! Couldn't spawn forge object "..tag)
		end
	else
		cprint("   ERROR! Couldn't spawn forge object "..tag)
	end
end

function DeleteForgeObject(i,object_id)
	local deleted = false
	for id,INFO in pairs (SPAWNED_OBJECTS) do
		if SPAWNED_OBJECTS[id].object_id==object_id then
			local object = get_object_memory(object_id)
			if object ~= 0 then
				destroy_object(object_id)
			end
			for j=1,16 do
				rprint(j, prefix.."d~"..SPAWNED_OBJECTS[id].metaid.."~"..SPAWNED_OBJECTS[id].x.."~"..SPAWNED_OBJECTS[id].y.."~"..SPAWNED_OBJECTS[id].z)
			end
			deleted = true
		end
		
		if deleted then
			if SPAWNED_OBJECTS[id+1]~=nil then
				SPAWNED_OBJECTS[id] = SPAWNED_OBJECTS[id+1]
			else
				SPAWNED_OBJECTS[id] = nil
			end
		end
	end
	
	if deleted then
		say(i,"object deleted successfully!")
	else
		if object_id~=0xFFFFFFFF then
			say(i,"object is not in the table")
		else
			say(i,"no object selected")
		end
	end
end

function UpdateForgeObject(id, x, y, z, rot1, rot2, rot3, permutation, shadow)
	id = tonumber(id)
	if SPAWNED_OBJECTS[id] ~= nil then
		local object = get_object_memory(SPAWNED_OBJECTS[id].object_id) 
		if object ~= 0 then
			for i = 1,16 do
				rprint(i, prefix.."o~"..SPAWNED_OBJECTS[id].x.."~"..SPAWNED_OBJECTS[id].y.."~"..SPAWNED_OBJECTS[id].z)
			end
			if x ~= nil then SPAWNED_OBJECTS[id].x = tonumber(x) end
			if y ~= nil then SPAWNED_OBJECTS[id].y = tonumber(y) end
			if z ~= nil then SPAWNED_OBJECTS[id].z = tonumber(z) end
			if rot1 ~= nil then SPAWNED_OBJECTS[id].rot1 = tonumber(rot1) end
			if rot2 ~= nil then SPAWNED_OBJECTS[id].rot2 = tonumber(rot2) end
			if rot3 ~= nil then SPAWNED_OBJECTS[id].rot3 = tonumber(rot3) end
			if permutation ~= nil then SPAWNED_OBJECTS[id].permutation = tonumber(permutation) end
			if shadow ~= nil then SPAWNED_OBJECTS[id].shadow = tonumber(shadow) end
			
			write_vector3d(object + 0x5C, SPAWNED_OBJECTS[id].x, SPAWNED_OBJECTS[id].y, SPAWNED_OBJECTS[id].z)
			rot = convert(SPAWNED_OBJECTS[id].rot1, SPAWNED_OBJECTS[id].rot2, SPAWNED_OBJECTS[id].rot3)
			write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
			write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
			
			write_char(object + 0x180, SPAWNED_OBJECTS[id].permutation)
			
			for i = 1,16 do
				rprint(i, prefix.."u~"..SPAWNED_OBJECTS[id].x.."~"..SPAWNED_OBJECTS[id].y.."~"..SPAWNED_OBJECTS[id].z.."~"..SPAWNED_OBJECTS[id].rot1.."~"..SPAWNED_OBJECTS[id].rot2.."~"..SPAWNED_OBJECTS[id].rot3.."~"..SPAWNED_OBJECTS[id].permutation.."~"..SPAWNED_OBJECTS[id].shadow)
			end
		else
			cprint("   ERROR! Couldn't update forge object "..id)
		end
	else
		cprint("   ERROR! Couldn't update forge object "..id)
	end
end

function SpawnVehicle(tag_path, x, y, z, rot)
	if NETGAME == nil then
		return false
	end
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)
	rot = math.rad(tonumber(rot))
	
	if tag_path ~= nil and rot ~= nil then
		if NETGAME.vehicles == nil then
			NETGAME.vehicles = {}
		end
		local ID = spawn_object("vehi", tag_path,x,y,z,rot)
		if ID ~= nil and ID ~= 0 then
			NETGAME.vehicles[ID] = true
		else
			cprint("  ERROR! Couldn't spawn vehicle on line "..line)
		end
	else
		cprint("  ERROR! Couldn't spawn vehicle on line "..line)
	end
end

function OnPlayerJoin(i)
	if bigass_v3 == false then
		set_var(i, "$has_chimera", 0)
		rprint(i, "|ngot_chimera?")
		timer(33, "CheckChimera", i, 200)
	end
	timer(object_spawn_delay, "SendObjectInfo", i, 0, 100)
	
	--timer(2000, "SendMapName", i)
end

function SendMapName(i)
	i = tonumber(i)
	if fake_forge_enabled and gametype ~= nil and get_var(i, "$has_chimera") == "1" then
		rprint(1, "title~"..gametype)
	end
end

function CheckChimera(i, chimera_timer)
	i = tonumber(i)
	chimera_timer = tonumber(chimera_timer)
	if player_present(i) == false then
		return false
	elseif chimera_timer < 1 then
		if fake_forge_enabled then
			if get_var(i, "$has_chimera") ~= "1" then
				if bigass_v3 == false then
					rprint(i, "WARNING! No Chimera or fake_forge.lua detected!")
					say(i, "You must have Chimera -572 and latest fake forge script!")
				else
					rprint(i, "WARNING! You must have Chimera and the Lua script installed for forge maps!!!")
					say(i, "WARNING! You must have Chimera and the Lua script installed for forge maps!!!")
					timer(5000, "KickPlayer", i)
				end
			end
			
			if NETGAME ~= nil and NETGAME.vehicles ~= nil then
				for ID,info in pairs (NETGAME.vehicles) do
					local object = get_object_memory(ID)
					if object ~= 0 then
						write_bit(object + 0x10, 5, 0) 
					end
				end
			end
		end
	else
		timer(33, "CheckChimera", i, chimera_timer - 1)
	end
	
	return false
end

function KickPlayer(i)
	i = tonumber(i)
	if player_present(i) then
		execute_command("k "..i.." \"No Chimera or Lua script installed!\"")
	end
end

function OnTick()
	for i=1,16 do
		if FALL_DAMAGE_TIMERS[i] > 0 then
			FALL_DAMAGE_TIMERS[i] = FALL_DAMAGE_TIMERS[i] - 1
		end
	end
	if NETGAME ~= nil and NETGAME.hills ~= nil then
		local hill_move_timer = read_dword(koth_globals + 0x1A8)
		if hill_move_timer == 1795 then
			for i=1,16 do
				if player_present(i) then
					SendKOTHInfo(i)
				end
			end
		end
	end
	
	Machines()
end

function Machines()
	for j,info in pairs (SPAWNED_OBJECTS) do
		if info.type == 7 then
			local object = get_object_memory(info.object_id)
			if object ~= 0 then
				local x = read_float(object + 0x5C)
				local y = read_float(object + 0x60)
				local z = read_float(object + 0x64)
				
				if info.name == "forge\\halo4\\scenery\\gravlift\\gravlift" or info.name == "forge\\halo4\\scenery\\mancannon\\mancannon" then
					local object_count = read_word(object_table + 0x2E)
					local first_object = read_dword(object_table + 0x34)
					for i=0,object_count-1 do
						local ID = read_word(first_object + i*12)*0x10000 + i
						local object2 = read_dword(first_object + i * 0xC + 0x8)
						if object2 ~= 0 and object2 ~= 0xFFFFFFFF then
							local object_type = read_word(object2 + 0xB4)
							if object_type == 0 or object_type == 1 or object_type == 2 or object_type == 5 then
								local distance = GetObjectDistance(object, object2)
								if distance < 0.65 then
									local push_amount = 0.2
									if info.permutation ~= 0 then
										push_amount = 0.07 + 0.03 * info.permutation
									end
									local rot = convert(info.rot1, info.rot2, info.rot3)
									
									if object_type == 5 then
										write_float(object2 + 0x68, rot[1]*push_amount*0.15 + read_float(object2 + 0x68))
										write_float(object2 + 0x6C, rot[2]*push_amount*0.15 + read_float(object2 + 0x6C))
										write_float(object2 + 0x70, rot[3]*push_amount*0.15 + read_float(object2 + 0x70))
									else
										write_float(object2 + 0x68, rot[1]*push_amount)
										write_float(object2 + 0x6C, rot[2]*push_amount)
										write_float(object2 + 0x70, rot[3]*push_amount)
									end
									
									if object_type == 0 then
										local player_id = read_word(object2 + 0xC0)
										if(player_id ~= 0xFFFF) and read_float(object2 + 0xE0) > 0 then
											local player_id = tonumber(to_player_index(player_id))
											if FALL_DAMAGE_TIMERS[player_id] < 190 and get_var(player_id, "$has_chimera") == "1" then
												rprint(player_id, "play_chimera_sound~gravlift")
											end
											FALL_DAMAGE_TIMERS[player_id] = 200
										end
									end
								end
							end
						end
					end
				else
					local should_open = false
					local elevator = read_dword(object + 0x21C)
					local machine_power = read_float(object + 0x208)
					for i=1,16 do
						local player = get_dynamic_player(i)
						if player ~= 0 then
							local x1 = read_float(player + 0x5C)
							local y1 = read_float(player + 0x60)
							local z1 = read_float(player + 0x64)
							local x_dist = x1 - x
							local y_dist = y1 - y
							local z_dist = z1 - z
							local distance
							if elevator == 0 then
								distance = GetObjectDistance(object, player)
							else
								distance = math.sqrt(x_dist*x_dist + y_dist*y_dist)
							end
							if (distance < 2.7 and elevator == 0) or (distance < 0.65 and elevator ~= 0) then
								should_open = true
							end
						end
					end
					
					if should_open then
						if machine_power < 0.98 then
							if elevator == 0 then
								write_float(object + 0x208, machine_power + 0.02)
							else
								write_float(object + 0x208, machine_power + 0.003)
							end
							write_float(object + 0x20C, 1)
						else
							write_float(object + 0x20C, 0)
						end
					elseif machine_power > 0 then
						if elevator == 0 then
							write_float(object + 0x208, machine_power - 0.01)
						else
							write_float(object + 0x208, machine_power - 0.005)
						end
						write_float(object + 0x20C, 1)
					else
						write_float(object + 0x20C, 0)
					end
				end
			end
		end
	end
end

function OnDamage(i, causer, damage_tag, damage, material, backtap)
	if damage_tag == fall_damage_tag and FALL_DAMAGE_TIMERS[i] > 0 then
		local player = get_dynamic_player(i)
		if player~=0 and read_bit(player + 0x4CC, 0)==0 then
			return false
		end
	end
end

function SendNetgameInfo(i)
	if get_var(i, "$has_chimera") == "1" then --or bigass_v3 == false then
		
		SendKOTHInfo(i)
		
		if sky ~= nil then
			rprint(i, sky)
		end
		
		if terrain ~= nil then
			rprint(i, terrain)
		end
		
		if fog ~= nil then
			rprint(i, fog)
		end
		
		if screen_tint ~= nil then
			rprint(i, screen_tint)
		end
		
		if gravity ~= nil then
			rprint(i, gravity)
		end
		
		if disable_hud ~= nil and disable_hud ~= 0 then
			rprint(i, prefix.."disable_hud~"..disable_hud)
		end
		
		if NETGAME ~= nil then
			rprint(i, prefix.."clear_netgame_flags")
			if NETGAME.ctf ~= nil then
				if NETGAME.ctf.red ~= nil then
					rprint(i, prefix.."ctf~0~"..NETGAME.ctf.red.x.."~"..NETGAME.ctf.red.y.."~"..NETGAME.ctf.red.z)
				end
				if NETGAME.ctf.blue ~= nil then
					rprint(i, prefix.."ctf~1~"..NETGAME.ctf.blue.x.."~"..NETGAME.ctf.blue.y.."~"..NETGAME.ctf.blue.z)
				end
			end
			
			if NETGAME.teleport_from ~= nil and NETGAME.teleport_to ~= nil then
				for j = 0, #NETGAME.teleport_from do
					if NETGAME.teleport_from[j] ~= nil then
						rprint(i, prefix.."tpfrom~"..NETGAME.teleport_from[j].x.."~"..NETGAME.teleport_from[j].y.."~"..NETGAME.teleport_from[j].z.."~"..NETGAME.teleport_from[j].rot.."~"..NETGAME.teleport_from[j].team)
					end
					if NETGAME.teleport_to[j] ~= nil then
						rprint(i, prefix.."tpto~"..NETGAME.teleport_to[j].x.."~"..NETGAME.teleport_to[j].y.."~"..NETGAME.teleport_to[j].z.."~"..NETGAME.teleport_to[j].rot.."~"..NETGAME.teleport_to[j].team)
					end
				end
			end
			
			if NETGAME.race ~= nil then
				for team,info in pairs (NETGAME.race) do
					rprint(i, prefix.."race~"..info.x.."~"..info.y.."~"..info.z.."~"..team)
				end
			end
		end
	end
end

function SendObjectInfo(i, id, chimera_timer)
	if game_is_running == false then
		cprint("   Cancelled sending object info because game is not running!")
		return false
	end
	
	if player_present(i) == false then
		cprint("   Cancelled sending object info because player left!")
		return false
	end
	
	chimera_timer = tonumber(chimera_timer)
	
	if get_var(i, "$has_chimera") == "0" then
		if chimera_timer < 1 then
			cprint("   Player "..get_var(i, "$name").." doesn't have chimera")
		else
			timer(object_spawn_delay, "SendObjectInfo", i, id, chimera_timer - 1)
		end
		return false
	end
	
	id = tonumber(id)
	
	if id == 0 then
		if remove_all_scenery_objects then
			rprint(i, prefix.."destroy_all_scenery")
		end
		if remove_all_device_objects then
			rprint(i, prefix.."destroy_all_devices")
		end
		SendNetgameInfo(i)
	end
	
	if SPAWNED_OBJECTS[id] == nil then
		return false
	else
		rprint(i, prefix.."s~"..SPAWNED_OBJECTS[id].metaid.."~"..SPAWNED_OBJECTS[id].x.."~"..SPAWNED_OBJECTS[id].y.."~"..SPAWNED_OBJECTS[id].z.."~"..SPAWNED_OBJECTS[id].rot1.."~"..SPAWNED_OBJECTS[id].rot2.."~"..SPAWNED_OBJECTS[id].rot3.."~"..SPAWNED_OBJECTS[id].type.."~"..SPAWNED_OBJECTS[id].permutation.."~"..SPAWNED_OBJECTS[id].shadow)
		id = id + 1
	end
	
	timer(object_spawn_delay, "SendObjectInfo", i, id, chimera_timer)
	return false
end

function OnCommand(PlayerIndex,Command,Environment,Password)
	MESSAGE = {}
	for word in string.gmatch(Command, "([^".." ".."]+)") do 
		table.insert(MESSAGE, word)
	end
	
	if Environment == 1 and MESSAGE[1] == "chimera_reloaded" then
		timer(object_spawn_delay, "SendObjectInfo", PlayerIndex, 0, 100)
		set_var(PlayerIndex, "$has_chimera", 1)
		return false
	end
	
	if MESSAGE[1]=="del" then
		if get_var(PlayerIndex, "$lvl") > "2" or Environment == 0 then
			DeleteForgeObject(PlayerIndex,tonumber(GetAimObject(PlayerIndex)))
		else
			say(PlayerIndex, "You don't have permission to delete objects")
		end
		return false
	end
	
	if MESSAGE[1]=="perm" then
		if get_var(PlayerIndex, "$lvl") > "2" or Environment == 0 then
			if MESSAGE[2]~=nil then
				local id = GetAimObject(PlayerIndex)
				if id ~= nil then
					UpdateForgeObject(id, nil, nil, nil, nil, nil, nil, tonumber(MESSAGE[2]), nil)
				else
					say(PlayerIndex, "Can't change object")
				end
			else
				say(PlayerIndex, "Use /perm <id> to change object's permutation")
			end
		else
			say(PlayerIndex, "You don't have permission to use this command")
		end
		return false
	end
	
	if MESSAGE[1] == "forge" then
		if MESSAGE[2] ~= nil then
			if get_var(PlayerIndex, "$lvl") > "2" or Environment == 0 then
				for i=1,16 do
					rprint(i, "|nforgereloaded")
				end
				Initialize(MESSAGE[2])
				say(PlayerIndex, "Loading forge map "..MESSAGE[2].." for the map "..current_map)
			else
				say(PlayerIndex, "You don't have permission to load forge maps!")
			end
		else
			say(PlayerIndex, "to load a forge map for this map use /forge <forge map name>")
		end
		return false
	end
	
	if MESSAGE[1] == "forge_map_list" or MESSAGE[1] == "forge_maps_list" then
		rprint(PlayerIndex, "These are all of the forge maps. Use /fmap or /forge commands to load them")
		local FORGE_MAPS = {}
		local popen = io.popen
		for dir_name in popen('dir "sapp\\" /b'):lines() do
			local map_name = string.find(dir_name, "_forge")
			if map_name ~= nil then
				local popen2 = io.popen
				for file_name in popen2('dir "sapp\\'..dir_name..'\\" /b'):lines() do
					local forge_map_name = string.find(file_name, "_info.txt")
					if forge_map_name ~= nil then
						forge_map_name = string.sub(file_name, 0, forge_map_name-1)
						if FORGE_MAPS[forge_map_name] == nil then
							FORGE_MAPS[forge_map_name] = 1
							local map_name = string.sub(dir_name, 0, map_name-1)
							rprint(PlayerIndex, forge_map_name.." (for the map "..map_name..")")
						end
					end
				end
			end
		end
		return false
	end
	
	if MESSAGE[1] == "fmap" or MESSAGE[1] == "ffmap" then
		if get_var(PlayerIndex, "$lvl") > "2" or Environment == 0 then
			if MESSAGE[2] ~= nil and MESSAGE[3] ~= nil then
				local found_forge_map = false
				local popen = io.popen
				for dir_name in popen('dir "sapp\\" /b'):lines() do
					local map_name = string.find(dir_name, "_forge")
					if map_name ~= nil then
						local popen2 = io.popen
						for file_name in popen2('dir "sapp\\'..dir_name..'\\" /b'):lines() do
							local forge_map_name = string.find(file_name, "_info.txt")
							if forge_map_name ~= nil and found_forge_map == false then
								forge_map_name = string.sub(file_name, 0, forge_map_name-1)
								if forge_map_name == MESSAGE[2] then
									found_forge_map = true
									local map_name = string.sub(dir_name, 0, map_name-1)
									if map_name == "bigass" then
										map_name = bigass_default_map_name -- WILL NEED TO BE CHANGED ONCE BIGASS V3 IS RELEASED!!!
									end
									say(PlayerIndex, "Loading forge map "..forge_map_name.." for the map "..map_name.." on "..MESSAGE[3])
									if MESSAGE[1] == "ffmap" then
										--execute_command("mf "..map_name.." "..MESSAGE[3])
										LoadNewMap(map_name, MESSAGE[3])
									else
										--execute_command("map "..map_name.." "..MESSAGE[3])
										LoadNewMap(map_name, MESSAGE[3])
									end
									forge_map_to_load = forge_map_name
									break
								end
							end
						end
					end
				end
				
				if found_forge_map == false then
					say(PlayerIndex, "could not find a forge map called "..MESSAGE[2])
				end
				
			else
				say(PlayerIndex, "to switch to a forge map use /fmap <forge map name> <gametype>")
				say(PlayerIndex, "use /ffmap instead to load the map instantly")
			end
		else
			say(PlayerIndex, "You don't have permission to load forge maps!")
		end
		return false
	end
	
	-- chimera detection
	if Environment == 1 and MESSAGE[1] == "yee_boi_ive_got_chi_meras" then
		--say(PlayerIndex, "Chimera detected!")
		set_var(PlayerIndex, "$has_chimera", 1)
        return false
    end
end

function LoadNewMap(map, gametype)
	execute_command("map "..map.." "..gametype)
	NextGameNow()
end

--These are from 002's next game script
function EditTimerOne()
    write_float(timer_seconds_address, -1.0)
    timer(100,"EditTimerTwo")
    return false
end

function EditTimerTwo()
    write_float(timer_seconds_address_2, -1.0)
    return false
end

function NextGameNow()
    if(read_dword(game_over_state_address) == 1) then
		execute_command("sv_map_next")
		write_float(timer_seconds_address, -1.0)
		timer(100,"EditTimerOne")
	end
end

function OnScriptUnload()
	for i=1,16 do
		if player_present(i) and get_var(i, "$has_chimera") == "1" and #SPAWNED_OBJECTS > 0 then --or bigass_v3 == false) then
			rprint(i, prefix.."remove_spawned_objects")
		end
	end
	for id, info in pairs (SPAWNED_OBJECTS) do
		RemoveObject(SPAWNED_OBJECTS[id].object_id)
	end
	
	if NETGAME ~= nil and NETGAME.vehicles ~= nil then
		for id, info in pairs (NETGAME.vehicles) do
			RemoveObject(id)
		end
	end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function DestroyAllObjects()
	if remove_all_scenery_objects then
		timer(500, "DestroyHay")
		timer(1500, "DestroyHay")
		timer(3500, "DestroyHay")
	end
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			
			-- scenery
			if object_type == 6 and remove_all_scenery_objects then
				if SCENERY_NOT_TO_REMOVE[GetName(object)] == nil then
					destroy_object(read_word(first_object + i*12)*0x10000 + i)
				end
				
			-- devices
			elseif remove_all_device_objects and (object_type == 7 or object_type == 8 or object_type == 9) then
				destroy_object(read_word(first_object + i*12)*0x10000 + i)
				
			-- equipment
			elseif remove_all_equipment_objects and (object_type == 2 or object_type == 3) then
				-- make sure a player isn't holding the weapon and the weapon is not a flag or oddball
				if read_dword(object + 0xC4) == 0xFFFFFFFF and read_word(object + 0xB8) == 0xFFFF then
					destroy_object(read_word(first_object + i*12)*0x10000 + i)
				end
			end
		end
	end
	
	if remove_all_vehicle_objects then
		timer(4000, "RemoveVehicles")
	end
end

function RemoveVehicles()
	local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			if object_type==1 and VEHICLES_NOT_TO_REMOVE[GetName(object)]==nil and read_word(object+0xBA)~=0 and read_dword(object+0x324)==0xFFFFFFFF then
				destroy_object(read_word(first_object + i*12)*0x10000 + i)
			end
		end
	end
end

function DestroyHay()
	execute_command("object_destroy_containing hay")
end

function ClearNetgameFlags()
	netgame_flag_counter = 3
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_data = read_dword(scenario_tag + 0x14)
	netgame_flag_count = read_dword(scenario_data + 0x378)
	netgame_flags = read_dword(scenario_data + 0x378 + 4)
	cprint("   Netgame flag count: "..netgame_flag_count)
	
	for i=0,netgame_flag_count do
		local current_flag = netgame_flags + i*148
		write_word(current_flag + 0x10, 5)
	end
end

function DiscoverNetgame()
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_tag_data = read_dword(scenario_tag + 0x14)

    local starting_location_reflexive = scenario_tag_data + 0x354
    starting_location_count = read_dword(starting_location_reflexive)
    local starting_location_address = read_dword(starting_location_reflexive + 0x4)
	cprint("   Netgame spawnpoint count: "..starting_location_count)
	
    for i=0,starting_location_count do
        local starting_location = starting_location_address + 52 * i
		local x,y,z = read_vector3d(starting_location)
		local rotation = read_float(starting_location + 0xC)
		local team = read_word(starting_location + 0x10)
		NETGAME.spawnpoints[i] = {starting_location,x,y,z,rotation,team}
    end
	
	local netgame_equipment_count = read_dword(scenario_tag_data + 0x384)
	local netgame_equipment = read_dword(scenario_tag_data + 0x384 + 4)
	cprint("   Netgame equipment count: "..netgame_equipment_count)
	
	for i=0,netgame_equipment_count do
		local current_equipment = netgame_equipment + 144 * i
		if remove_all_equipment_objects then
			write_word(current_equipment + 0x04, 0)
		end
		NETGAME.equipment[i] = current_equipment
	end
end

function UpdateEquipment(i,address,x,y,z,rot,levitate,respawn_time)
	if x~= nil and respawn_time ~= nil then
		if NETGAME.equipment[i] ~= nil then
			write_vector3d(NETGAME.equipment[i] + 0x40, x, y, z)
			write_float(NETGAME.equipment[i] + 0x4C, math.rad(rot))
			write_bit(NETGAME.equipment[i], 0, levitate)
			write_short(NETGAME.equipment[i] + 0x0E, 1)
			write_word(NETGAME.equipment[i] + 0x04, 12)
			write_dword(NETGAME.equipment[i] + 0x50, address)
			write_dword(NETGAME.equipment[i] + 0x50 + 0xC, read_dword(address + 0xC))
			timer(1000, "SetCorrectEquipmentSpawnTime", i, respawn_time)
		else
			cprint("  ERROR! Not enough equipment slots!")
		end
	else
		cprint("  ERROR! Wrong info for netgame equipment!")
	end
end

function SetCorrectEquipmentSpawnTime(i, respawn_time)
	write_short(NETGAME.equipment[tonumber(i)] + 0x0E, tonumber(respawn_time))
end

function UpdateSpawnpoint(i,x,y,z,rotation,team,gametype)
	if NETGAME.spawnpoints[i] ~= nil then
		if (x ~= nil) then
			NETGAME.spawnpoints[i][2]=x
			NETGAME.spawnpoints[i][3]=y
			NETGAME.spawnpoints[i][4]=z
			NETGAME.spawnpoints[i][5]=rotation
			write_vector3d(NETGAME.spawnpoints[i][1], x,y,z)
			write_float(NETGAME.spawnpoints[i][1] + 0xC, math.rad(rotation))
			write_short(NETGAME.spawnpoints[i][1] + 0x14, gametype)
			write_short(NETGAME.spawnpoints[i][1] + 0x16, gametype)
			write_short(NETGAME.spawnpoints[i][1] + 0x18, gametype)
			write_short(NETGAME.spawnpoints[i][1] + 0x1A, gametype)
		end
		if (team ~= nil) then
			NETGAME.spawnpoints[i][6]=team
			write_word(NETGAME.spawnpoints[i][1] + 0x10, team)
		end
	else
		cprint("  ERROR! Not enough spawnpoint slots!")
	end
end

function ResetKOTH()
	local moving_hill = read_byte(gametype_base + 0x9C)
	if moving_hill == 0 then
		write_byte(gametype_base + 0x9C, 1)
		write_dword(koth_globals + 0x1A8, 1)
		timer(1000, "ResetNotMovingHill")
	else
		write_dword(koth_globals + 0x1A8, 1)
	end
end

function ResetNotMovingHill()
	write_byte(gametype_base + 0x9C, 0)
end

function SendKOTHInfo(PlayerIndex)
	if NETGAME ~= nil and NETGAME.hills ~= nil and get_var(0, "$gt") == "king" and get_var(PlayerIndex, "$has_chimera") == "1" then
		local marker_count = read_dword(koth_globals + 0x90)
		rprint(1, " ")
		rprint(1, " ")
		rprint(1, " ")
		for i = 0,marker_count - 1 do
			local x, y, z = read_vector3d(koth_globals + i*12 + 0x94)
			rprint(PlayerIndex, prefix.."hill_marker~"..x.."~"..y.."~"..z.."~"..i.."~"..marker_count)
		end
	end
end

function GetAimObject(i)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local px, py, pz = read_vector3d(player + 0xA0)
		local vx, vy, vz = read_vector3d(player + 0x230)
		local cs = read_float(player + 0x50C)
		local standing_height = 0.25
		local crouching_change = 0.17
		local h = standing_height - (cs * (standing_height - crouching_change))
		pz = pz + h
		local hit,x,y,z,ID = intersect(px, py, pz, vx*1000, vy*1000, vz*1000, read_dword(get_player(i) + 0x34))
		
		for id,INFO in pairs (SPAWNED_OBJECTS) do
			if SPAWNED_OBJECTS[id].object_id==ID then
				return id
			end
		end
	end
end

function rotate(X, Y, alpha)
	local c, s = math.cos(math.rad(alpha)), math.sin(math.rad(alpha))
	local t1, t2, t3 = X[1]*s, X[2]*s, X[3]*s
	X[1], X[2], X[3] = X[1]*c+Y[1]*s, X[2]*c+Y[2]*s, X[3]*c+Y[3]*s
	Y[1], Y[2], Y[3] = Y[1]*c-t1, Y[2]*c-t2, Y[3]*c-t3
end

function convert(Yaw, Pitch, Roll)
	local F, L, T = {1,0,0}, {0,1,0}, {0,0,1}
	rotate(F, L, Yaw)
	rotate(F, T, Pitch)
	rotate(T, L, Roll)
	return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}
end

function Get3DVectorFromAngles(yaw,pitch)
	local x = math.cos(yaw) * math.cos(pitch)
	local y = math.sin(yaw) * math.cos(pitch)
	local z = math.sin(pitch)
	return x, y, z, 1
end

function RemoveObject(ID)
	if ID ~= nil then
		ID = tonumber(ID)
		if get_object_memory(ID) ~= 0 then
			destroy_object(ID)
		end
	end
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if address ~= 0 then
		return read_dword(address + 0xC)
	end
	return nil
end

function GetName(DynamicObject)
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetDistance(x, y, z, x2, y2, z2)
	return math.sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2) + (z1 - z2)*(z1 - z2))
end

function GetObjectDistance(object, object2)
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	local x1 = read_float(object2 + 0x5C)
	local y1 = read_float(object2 + 0x60)
	local z1 = read_float(object2 + 0x64)
	local x_dist = x1 - x
	local y_dist = y1 - y
	local z_dist = z1 - z
	return math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function OnError(Message)
	say_all("Error! "..Message)
end
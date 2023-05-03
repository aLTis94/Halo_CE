--	AI synchronization and zombie mode by aLTis (altis94@gmail.com)

--	This script will only work on bigassv3

--	CONFIG

--BIPEDS
	tag_directory = "characters\\floodcombat_human\\"--where all of your biped tags are.
	biped = tag_directory.."floodcombat_human"	--the biped you want to sync
	dead_weapon = tag_directory.."dead_zombie"	--weapon that will be used to fake a dead biped

	-- Biped animation state and corresponding vehicle tag. The comments tell you which animations those are
	BIPED_ANIMATION_STATE = {
		[0] = "flood_vehicle",				--idle
		[4] = "flood_vehicle walking",		--walking
		[20] = "flood_vehicle leap_airborne", 	--airborne
		[21] = "flood_vehicle", 	--land_soft
		[22] = "flood_vehicle", 	--land_hard
		[23] = "flood_vehicle",				--ping
		[24] = "flood_vehicle kill_back",	--airborne dead
		[25] = "flood_vehicle kill_back",	--dead
		[30] = "flood_vehicle melee",		--melee
		[31] = "flood_vehicle melee",		--melee airborne
		[34] = "flood_vehicle resurrect",	--resurrect front
		[35] = "flood_vehicle resurrect",	--resurrect back
		[39] = "flood_vehicle leap_start",	--leap start
		[40] = "flood_vehicle leap_airborne",	--leap airborne
		[41] = "flood_vehicle melee",	--leap melee
	}
	
--VEHICLES
	--	0 = should not spawn, 1 = uses fuel, 2 = to be replaced
	VEHICLES = {
		["halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\military truck"] = 2,
		["halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\military truck mp"] = 1,
		["altis\\vehicles\\spade\\spade"] = 1,
		["altis\\vehicles\\mongoose\\mongoose"] = 0,
		["bourrin\\halo reach\\vehicles\\warthog\\h2 mp_warthog"] = 0,
		["bourrin\\halo reach\\vehicles\\warthog\\reach gauss hog"] = 0,
		["bourrin\\halo reach\\vehicles\\warthog\\rocket warthog"] = 0,
		["vehicles\\falcon\\falcon"] = 0,
		["altis\\vehicles\\scorpion\\scorpion"] = 0,
	}
	
	--	How fast fuel gets depleted (higher value means faster) (5 seems to work fine)
	fuel_rate = 4
	--	How to display fuel - 0 = in console, 1 on hud
	fuel_hud_type = 1
	--	At what distance can players refuel a vehicle
	fuel_distance = 2
	--	Fuel canister weapon tag
	fuel_weapon = "altis\\weapons\\jerry_can\\jerry_can"
	
--RADIATION
	--	1 = low, 2 = medium, 3 = high
	RADIATION_TAGS = {
		[1] = "altis\\scenery\\radiation\\low",
		[2] = "altis\\scenery\\radiation\\medium",
		[3] = "altis\\scenery\\radiation\\radiation_high",
	}
	radiation_low = "altis\\scenery\\radiation\\low"
	radiation_medium = "altis\\scenery\\radiation\\medium"
	radiation_high = "altis\\scenery\\radiation\\radiation_high"
	--	How many world units it takes to switch radiation levels (low->medium->high)
	radiation_rate = 3
	
	--	Zones that have radiation (obviously)
	--	v[1] = x min, v[2] = x max, v[3] = y min, v[4] = y max
	RADIATION_BOXES = {
		--	Map boundaries
		{190, 300, -300, 300},
		{-300, -185, -300, 300},
		{-300, 300, 95, 300},
		{-300, 300, -300, -85},
	}
	--	v[1] = x, v[2] = y, v[3] = z, v[4] = radius
	RADIATION_SPHERES = {
		{37, 2, 5, 5},
		{89, -7, 3, 5},
		{-16, 23, 4, 8},
		{-175, 90, 12, 20},
		{-62, 71, 8, 7},
		{-20, 47, 8, 7},
		{8, -23, 1, 4},
		{52, -80, 3, 21},
		{182, -73, 14, 14},
		{-44, -23, 5, 14},
		{-81, -45, 2, 8},
		{7, -47, 3, 4},
		{72, 30, 1, 10},
		{24, -28, 1, 8},
	}
	
--SHOP
	--	Capsule tag; items will spawn on this object
	shop_capsule = "altis\\weapons\\capsule\\falling capsule"
	--	This tag will be used to determine where item should spawn (on a capsule)
	shop_item_location = "altis\\weapons\\capsule\\item_spawn_location"
	--	How much money you get for killing a common zombie
	zombie_kill_normal = 10
	--	How much money player loses for killing another player
	player_kill_penalty = 150
	
	--	Shop items; v[1] = name, v[2] = price, v[3] = tag type , v[4+] = tag directory
	SHOP = {
		{"Ammo", 50, "eqip", "altis\\weapons\\capsule\\ammo"},
		{"Grenades", 50, "eqip", "my_weapons\\trip-mine\\trip-mine", "cmt\\weapons\\human\\frag_grenade\\frag grenade"},
		{"Health Pack", 50, "eqip", "powerups\\health pack"},
		{"Machete", 50, "weap", "ptm\\weapons\\machete\\machete"},
		{"Magnum", 75, "weap", "reach\\objects\\weapons\\pistol\\magnum\\magnum"},
		{"Fuel", 100, "weap", "altis\\weapons\\jerry_can\\jerry_can"},
		{"OverShield", 100, "eqip", "powerups\\over shield"},
		{"Battle Rifle", 100, "weap", "altis\\weapons\\br_spec_ops\\br_spec_ops"},
		{"Spartan Laser", 150, "weap", "halo reach\\objects\\weapons\\support_high\\spartan_laser\\spartan laser"},
		{"Gauss Rifle", 150, "weap", "weapons\\gauss sniper\\gauss sniper"},
		{"Exit", 0, "", ""}
	}
	
--COMMANDS AND STUFF
	--Commands for players
	--	Commands that will give you shop weapon
	shop_command = {"shop","store","buy","comprar","tienda"}
	--	Command to give your score to another player
	give_command = {"give","dar"}
	--	At what distance players must be from each other in order to be able to give score
	give_distance = 30
	--	Command that will drop player's weapon
	weapon_drop_command = {"drop", "d","tirar","soltar"}
	
	--Commands for admins
	--	Default state of debug_mode
	debug_mode = false
	--	Command used to change debug mode state
	debug_command = "debug"
	--	Command to change player's score
	score_command = "score"
	-- Time until new wave of zombies spawns (seconds)
	wave_time = 50
	--	Command used to change wave time
	wave_time_command = "wave_time"
	-- Command used to start waves (stops previous waves if they were still running)
	wave_start_command = "wave_start"
	--	Maximum number of AI, exceeding this limit will destroy any zombie bipeds that are created (should be below 150)
	ai_max = 100 
	--	Command used to change AI limit 
	ai_max_command = "ai_limit"
	--	After this time the biped will be removed (seconds)
	ai_life_time = 420 * 30
	--	Command used to change AI life time
	ai_life_time_command = "ai_life_time"
	--	Distance that AI must be away from the player in order to get deleted (world units)
	ai_deletion_distance = 20
	--	How often to remove all AI vehicles (in seconds)
	ai_purge_rate = 10
	--	Should a zombie spawn where a player died?
	player_death_zombie_spawn = true
	
	

--	END OF CONFIG

api_version = "1.9.0.0"

wave = 0
debug_person = 0
ai_id_count = 0 -- used for counting bipeds
second_count = 0 -- used for counting seconds
game_count = 0
AI = {}
PLAYERS = {}
VEHICLE_FUEL = {}
object_table_ptr = nil

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	register_callback(cb["EVENT_CHAT"],"OnChat")
	if(lookup_tag("weap", dead_weapon) ~= 0) then
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_COMMAND'],"OnCommand")
		execute_command("ai_place flood_base")
		execute_command("set remove_barrier 1")
		for i = 1,16 do
			ResetPlayerStats(i)
		end
		execute_command("scorelimit 10000")
	else
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_COMMAND'])
	end
end

function OnGameStart()
	game_count = game_count + 1
	if(lookup_tag("weap", dead_weapon) ~= 0) then
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_COMMAND'],"OnCommand")
		execute_command("scorelimit 10000")
		execute_command("object_create spade")
		execute_command("set remove_barrier 1")
		
		for i = 1,16 do
			ResetPlayerStats(i)
		end
		wave = 1
		
		--say_all("Wave "..wave)
		execute_command("ai_place flood_night")
		timer(wave_time * 1000, "NewWave", game_count)
	else
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_COMMAND'])
	end
end

function NewWave(current_game)
	if(tonumber(current_game) ~= game_count) then say_all("new game") return false end
	
	local player_count = 0
	for i = 1,16 do
		if(player_alive(i)) then
			player_count = player_count + 1
		end
	end
	
	if(ai_id_count < ai_max - 19 and player_count > 0) then
		wave = wave + 1
		--say_all("Wave "..wave)
		execute_command("ai_place flood_night")
		if(ai_id_count < 15) then
			execute_command("ai_place flood_night")
		end
	end
	return true
end

function OnScriptUnload()--	Remove all AI on unload (we don't need invisible AI)
	for ID, info in pairs (AI) do
		destroy_object(ID)
		if(AI[ID]["vehicle"] ~= nil) then
			destroy_object(AI[ID]["vehicle"])
		end
	end
end

function OnPlayerJoin(PlayerIndex)
	ResetPlayerStats(PlayerIndex)
	VehiID = spawn_object("vehi", "altis\\vehicles\\scriptroomthing\\scriptroomthing", -61.1943, -151.848, -110.493)
	timer(1000, "destroy_object", VehiID)
end

function OnPlayerDeath(PlayerIndex, KilledIndex)
	PlayerIndex = tonumber(PlayerIndex)
	KilledIndex = tonumber(KilledIndex)
	PLAYERS[PlayerIndex]["item"] = nil
	--	Spawn a zombie where player died
	if(PLAYERS[PlayerIndex]["x"] ~= nil) then
		execute_command("ai_place flood_base")
		PLAYERS[PlayerIndex]["died"] = 1
	end
	
	--	Penalise the killer
	if(KilledIndex == PlayerIndex) then
		return false
	end
	PLAYERS[PlayerIndex]["score"] = 0
	if(KilledIndex > 0) then
		say(KilledIndex, "You lost $"..player_kill_penalty.." for killing another player.")
		if(PLAYERS[KilledIndex]["score"] - player_kill_penalty > 0) then
			PLAYERS[KilledIndex]["score"] = PLAYERS[KilledIndex]["score"] - player_kill_penalty
		else
			PLAYERS[KilledIndex]["score"] = 0
		end
	end
end

function ResetPlayerStats(PlayerIndex)
	PLAYERS[PlayerIndex] = {}
	PLAYERS[PlayerIndex]["kills"] = 0
	PLAYERS[PlayerIndex]["score"] = 0
	PLAYERS[PlayerIndex]["shop"] = nil
	PLAYERS[PlayerIndex]["item"] = nil
	PLAYERS[PlayerIndex]["flashlight"] = 0
end

function OnTick()
	--	DEBUG
	local vehicle_count = 0
	local biped_count = 0
	local weapon_count = 0
	local scenery_count = 0
	local equipment_count = 0
	local total_objects = 0
	local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if(object ~= 0 and object ~= 0xFFFFFFFF) then
			total_objects = total_objects + 1
			local object_type = read_word(object + 0xB4)
            if(object_type == 0) then
				biped_count = biped_count + 1
			elseif(object_type == 1) then
				vehicle_count = vehicle_count + 1
			elseif(object_type == 2) then
				weapon_count = weapon_count + 1
			elseif(object_type == 6) then
				scenery_count = scenery_count + 1
			elseif(object_type == 3) then
				equipment_count = equipment_count + 1
			end
		end
	end
	if(debug_mode == true and PLAYERS[debug_person]["shop"] == nil) then
		ClearConsole(debug_person)
		rprint(debug_person, "|rAI "..ai_id_count.." (should be "..biped_count - 4 - get_var(0, "$pn")..")")
		rprint(debug_person, "|rBipeds "..biped_count)
		rprint(debug_person, "|rVehicles "..vehicle_count)
		rprint(debug_person, "|rWeapons "..weapon_count)
		rprint(debug_person, "|rEquipment "..equipment_count)
		rprint(debug_person, "|rSynced objects "..biped_count + vehicle_count + weapon_count + equipment_count)
		rprint(debug_person, "|rScenery "..scenery_count)
		rprint(debug_person, "|rObject count "..total_objects.."/"..object_count)
	end
	ai_id_count = 0
	
	--	Count seconds
	second_count = second_count + 1
	if(second_count == 30) then
		second_count = 0
	end
	
	--	Set player scores and get info
	for i = 1,16 do
		if(player_alive(i)) then
			execute_command("kills "..i.." "..PLAYERS[i]["kills"])
			execute_command("score  "..i.." "..PLAYERS[i]["score"])
			local player_object = get_dynamic_player(i)
			
			if(read_bit(player_object + 0x208,4) == 1 and PLAYERS[i]["flashlight"] == 0) then
				PLAYERS[i]["flashlight"] = 15
			end
			if(PLAYERS[i]["flashlight"] > 0) then
				PLAYERS[i]["flashlight"] = PLAYERS[i]["flashlight"] - 1
			end
			
			PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] = read_vector3d(player_object + 0x5C)
		end
	end
	
	--	Make sure host is always on bsp 0 since path finding doesn't work on others
	execute_command("switch_bsp 0")
	execute_command("object_destroy d")
	
	--*****************************************	AI SYNC STUFF!	**************************************************************
	
	--	Go through all of the bipeds that are in the AI table
	for ID, info in pairs (AI) do
	
		local biped_object = get_object_memory(ID)

		if(AI[ID] ~= nil and biped_object ~= 0) then	--			Read biped info
			if(read_float(biped_object + 0xE0) < 0.01) then --			If biped is dead
				RemoveBiped(ID, biped_object)
			else 
				ai_id_count = ai_id_count + 1
				--		Increase time alive
				AI[ID]["time_alive"] = AI[ID]["time_alive"] + 1
				--			Remove the biped if he's been alive too long and is far from players
				if(AI[ID]["time_alive"] > ai_life_time) then
					local able_to_remove = true
					for i = 1,16 do
						if(player_alive(i)) then
							local player_object = get_dynamic_player(i)
							if(player_object ~= 0) then
								local x, y, z = read_vector3d(player_object + 0x5C)
								if(DistanceFormula(x,y,z,AI[ID]["x"], AI[ID]["y"], AI[ID]["z"]) < ai_deletion_distance) then
									able_to_remove = false
								end
							end
						end
					end
					if(able_to_remove) then
						RemoveBiped(ID, biped_object)
					end
				end
			
				--			If biped is alive then get its info
				if(AI[ID] ~= nil) then
					AI[ID]["x"], AI[ID]["y"], AI[ID]["z"] = read_vector3d(biped_object + 0x5C)
					AI[ID]["yaw"] = read_float(biped_object + 0x224)
					AI[ID]["pitch"] = read_float(biped_object + 0x228)
					
					GetDamagerID(ID, biped_object)
					
					local unit_state = read_byte(biped_object + 0x2A3)
					local unit_animation = BIPED_ANIMATION_STATE[unit_state]
					--			If animation for this state does not exist then set it to idle
					--			I don't know why I forgot to do this before
					if(unit_animation == nil) then
						unit_animation = BIPED_ANIMATION_STATE[0]
						say_all("Biped had no vehicle for this animation. This would have caused issues before D:")
					end
					
					--			Check if the biped has a vehicle assigned to it
					if(AI[ID]["vehicle"] == nil) then
						SpawnVehicle(ID, unit_animation)
					else
						--		Sync vehicle animations with biped's
						local vehicle_object = get_object_memory(AI[ID]["vehicle"])
						if(vehicle_object ~= 0) then
							local vehicle_name = read_string(read_dword(read_word(vehicle_object) * 32 + 0x40440038))
							if(unit_animation ~= nil and vehicle_name ~= tag_directory..unit_animation) then
								destroy_object(AI[ID]["vehicle"])
								SpawnVehicle(ID, unit_animation)
							end
							
							--	Sync vehicle coordinates with biped's
							--write_bit(vehicle_object +  0x8, 8, 1) ???
							write_vector3d(vehicle_object + 0x5C, AI[ID]["x"], AI[ID]["y"], AI[ID]["z"])
							write_vector3d(vehicle_object + 0x74, AI[ID]["yaw"], AI[ID]["pitch"], 0)
						else
							--	For some reason some of the vehicles get this, dunno how to fix yet
							SpawnVehicle(ID, unit_animation)
							--RemoveBiped(ID, biped_object)
						end
					end
				end
			end
		else
		--					If biped does not exist any more
			RemoveBiped(ID, biped_object)
		end
	end

	--*******************************************	SHOP **************************************************
	for i = 1,16 do
		if(player_alive(i)) then
			local player_object = get_dynamic_player(i)
			if(read_bit(player_object + 0x208,4) == 1 and PLAYERS[i]["flashlight"] > 0 and PLAYERS[i]["flashlight"] < 13) then
				if(PLAYERS[i]["shop"] == nil) then
					PLAYERS[i]["shop"] = 1
				else
					PLAYERS[i]["shop"] = nil
					write_float(get_player(i) + 0x6C, 1.0)
					ClearConsole(i)
				end
			end
			if(PLAYERS[i]["shop"] ~= nil) then
				ClearConsole(i)
				write_float(get_player(i) + 0x6C, 0)--change speed
				local unit_forward = read_float(player_object + 0x278)
				if(PLAYERS[i]["delay"] == nil) then
					PLAYERS[i]["delay"] = 0
				else
					PLAYERS[i]["delay"] = PLAYERS[i]["delay"] + 1
				end
				if(PLAYERS[i]["delay"] > 5) then
					if(unit_forward == 1) then
						if(PLAYERS[i]["shop"] == 1) then
							PLAYERS[i]["shop"] = #SHOP
							PLAYERS[i]["delay"] = 0
						else
							PLAYERS[i]["shop"] = PLAYERS[i]["shop"] - 1
							PLAYERS[i]["delay"] = 0
						end
					elseif(unit_forward == -1) then
						if(PLAYERS[i]["shop"] == #SHOP) then
							PLAYERS[i]["shop"] = 1
							PLAYERS[i]["delay"] = 0
						else
							PLAYERS[i]["shop"] = PLAYERS[i]["shop"] + 1
							PLAYERS[i]["delay"] = 0
						end
					end
				end
				local item_selection = 1
				if(read_bit(player_object + 0x208,6) == 1) then
					Buy(i, PLAYERS[i]["shop"])
					PLAYERS[i]["shop"] = nil
					write_float(get_player(i) + 0x6C, 1.0)--change speed
				else
					for key,value in pairs (SHOP) do
						if(item_selection == PLAYERS[i]["shop"]) then
							if(value[2] == 0) then
								rprint(i, "|r>> "..value[1])
							elseif(PLAYERS[i]["score"] < value[2]) then
								rprint(i, "|r>> "..value[1].."   ~$"..value[2])
							else
								rprint(i, "|r>> "..value[1].."   $"..value[2])
							end	
						elseif(value[2] == 0) then
							rprint(i, "|r "..value[1])
						elseif(PLAYERS[i]["score"] < value[2]) then
							rprint(i, "|r "..value[1].."   ~$"..value[2])
						else
							rprint(i, "|r "..value[1].."   $"..value[2])
						end	
						item_selection = item_selection + 1
					end
					rprint(i, "|lYou have $"..PLAYERS[i]["score"]..". |rLook at the place where you want to drop your item and press E")
				end
			end
		end
	end
	
	
	--*****************************************	VEHICLE FUEL **************************************************
	
	for ID, info in pairs(VEHICLE_FUEL) do
		local vehicle_object = get_object_memory(ID)
		if(vehicle_object ~= 0) then
			local x,y,z = read_vector3d(vehicle_object + 0x68)
			local x1,y1,z1 = read_vector3d(vehicle_object + 0x5C)
			for i = 1,16 do
				if(player_alive(i)) then
					local player_object = get_dynamic_player(i)
					local weapon_ID = read_dword(player_object + 0x118)
					local weapon_object = get_object_memory(weapon_ID)
					if(weapon_object ~= 0 and GetName(weapon_object) == fuel_weapon and read_float(player_object + 0x490) == 1) then
						local x2,y2,z2 = read_vector3d(player_object + 0x5C)
						if(DistanceFormula(x1,y1,z1,x2,y2,z2) < fuel_distance) then
							if(VEHICLE_FUEL[ID] < 9900) then
								destroy_object(weapon_ID)
								VEHICLE_FUEL[ID] = 10000
								say(i, "The vehicle was refuelled!")
							else
								if(VEHICLE_FUEL[ID] ~= 9900) then
									say(i, "Fuel tank is already full")
									VEHICLE_FUEL[ID] = 9900
								else
									VEHICLE_FUEL[ID] = 9900
								end
							end
						end
					end
				end
			end
			
			local driver = read_dword(vehicle_object + 0x324)
			if(driver ~= 0xFFFFFFFF) then
				local driver_object = get_object_memory(driver)
				local driver_ID = 0
				for i = 1,16 do
					if(player_alive(i)) then
						local player_object = get_dynamic_player(i)
						if(driver_object == player_object) then
							driver_ID = i
						end
					end
				end
				
				if(VEHICLE_FUEL[ID] < 100) then
					exit_vehicle(driver_ID)
					--	PREVENT VEHICLE FROM DRIVING
				else
					if(VEHICLE_FUEL[ID] < 200) then
						VEHICLE_FUEL[ID] = VEHICLE_FUEL[ID] - 101
						exit_vehicle(driver_ID)
						say(driver_ID, "Out of fuel!")
					else
						VEHICLE_FUEL[ID] = VEHICLE_FUEL[ID] - fuel_rate * (0.1 + math.abs(x) + math.abs(y) + math.abs(z))
					end
				end
				if(fuel_hud_type == 0) then
					ClearConsole(driver_ID)
					rprint(driver_ID, math.floor(VEHICLE_FUEL[ID] / 100))
				else
					local weapon = read_dword(vehicle_object + 0x2F8)--		Get vehicle's weapon
					if(weapon ~= 0xFFFFFFFF) then
						local weapon_object = get_object_memory(weapon)
						write_word(weapon_object + 0x2B8, math.floor(VEHICLE_FUEL[ID] / 100))
						sync_ammo(weapon)
					end
				end
			end
		end
	end

	for i = 1,16 do--	drop fuel canister if player was not refueling a vehicle
		if(player_alive(i)) then
			local player_object = get_dynamic_player(i)
			local weapon_ID = read_dword(player_object + 0x118)
			local weapon_object = get_object_memory(weapon_ID)
			if(weapon_object ~= 0 and GetName(weapon_object) == fuel_weapon and read_float(player_object + 0x490) == 1) then
				drop_weapon(i)
			end
		end
	end
	
	--*****************************************	RADIATION **************************************************
	for i = 1,16 do
		if(player_alive(i)) then
			local player_object = get_dynamic_player(i)
			if(player_object ~= 0) then
				local x,y,z = read_vector3d(player_object + 0x5C)
				local current_radiation_level = 0
				for k, v in pairs(RADIATION_BOXES) do
					for j = 1,3 do
						if(x > v[1]+j*radiation_rate and x < v[2]-j*radiation_rate and y > v[3]+j*radiation_rate and y < v[4]-j*radiation_rate) then
							current_radiation_level = j
						else
							break
						end
					end
					if(current_radiation_level ~= 0) then break end
				end
				if(current_radiation_level == 0) then
					for k, v in pairs(RADIATION_SPHERES) do
						local distance = DistanceFormula(x,y,z,v[1],v[2],v[3])
						for j = 1,3 do
							if(distance < v[4]-j*radiation_rate+radiation_rate) then
								current_radiation_level = j
							else
								break
							end
						end
						if(current_radiation_level ~= 0) then break end
					end
				end
				if(current_radiation_level ~= 0) then
					local radiation_ID = spawn_object("garb", RADIATION_TAGS[current_radiation_level], x, y, z + 0.2)
					timer(33, "destroy_object", radiation_ID)
				end
			end
		end
	end
end

function Buy(PlayerIndex, ItemID)
	item = SHOP[ItemID]
	if(item[1] == "Exit") then
		return false
	end
	if(PLAYERS[PlayerIndex]["item"] ~= nil) then
		say(PlayerIndex, "Please wait until the previous item is dropped.")
		return false
	end
	if(PLAYERS[PlayerIndex]["score"] - item[2] >= 0) then
		local hit, x, y, z = GetPlayerAimLocation(PlayerIndex)
		if(z>16 or x>202 or x<(-195) or y>105 or y<(-100)) then
			say(PlayerIndex, "Can't drop the item in this location!")
		else
			say(PlayerIndex, item[1].." incoming...")
			PLAYERS[PlayerIndex]["score"] = PLAYERS[PlayerIndex]["score"] - item[2]
			spawn_object("proj", shop_capsule, x, y, z + 50)
			PLAYERS[PlayerIndex]["item"] = ItemID
			timer(5000, "ResetItem", PlayerIndex, ItemID)
		end
	else
		say(PlayerIndex, "Not enough money")
	end
end

function ResetItem(PlayerIndex, ItemID)
	PlayerIndex = tonumber(PlayerIndex)
	if(PLAYERS[PlayerIndex]["item"] ~= nil and tonumber(ItemID) == PLAYERS[PlayerIndex]["item"]) then
		PLAYERS[PlayerIndex]["item"] = nil
	end
end

function GetDamagerID(ID, biped_object)-- From 002
	for k=0,3 do
		local struct = biped_object + 0x430 + 0x10 * k
		local damager_pid = read_word(struct + 0xC)
		if(damager_pid ~= 0xFFFF) then
			AI[ID]["damage_causer"] = tonumber(to_player_index(damager_pid))
		end
	end
end

function RemoveBiped(ID, biped_object)--	Remove dead/non-existent biped and spawn dead weapon
	destroy_object(ID)
	if(AI[ID]["vehicle"] ~= nil) then
		destroy_object(AI[ID]["vehicle"])
	end
	if(biped_object ~= 0) then
		GetDamagerID(ID, biped_object)
	end
	if(AI[ID]["x"] ~= nil and AI[ID]["y"] ~= nil and AI[ID]["pitch"] ~= nil) then
		--	Spawn a weapon that fakes biped death (could use a vehicle as well)
		local dead_zombie = spawn_object("weap", dead_weapon,  AI[ID]["x"], AI[ID]["y"], AI[ID]["z"], GetYaw(ID))
		--	Set player stats
		if(AI[ID]["damage_causer"] ~= nil) then
			if(player_alive(AI[ID]["damage_causer"])) then
				local PlayerIndex = AI[ID]["damage_causer"]
				if(PLAYERS[PlayerIndex]~= nil and PLAYERS[PlayerIndex]["kills"] ~= nil) then
					PLAYERS[PlayerIndex]["kills"] = PLAYERS[PlayerIndex]["kills"] + 1
					PLAYERS[PlayerIndex]["score"] = PLAYERS[PlayerIndex]["score"] + zombie_kill_normal
				end
			end
		end
	end
	AI[ID] = nil
end

function SpawnVehicle(ID, unit_animation)
	AI[ID]["vehicle"] = spawn_object("vehi", tag_directory..unit_animation, AI[ID]["x"], AI[ID]["y"], AI[ID]["z"], GetYaw(ID))
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	timer(33, "ObjectCheck", ID)
end

function ObjectCheck(ID)
	if(ID == nil) then 
		return true 
	end
	ID = tonumber(ID)
	local object = get_object_memory(ID)
	
	if(object ~= 0) then
		local name = read_string(read_dword(read_word(object) * 32 + 0x40440038))
		--	Check if the object is our biped
		if(name == biped) then
			if(ai_id_count > ai_max) then
				destroy_object(ID)
				return false
			else
				AI[ID] = {}
				AI[ID]["time_alive"] = 0
				--	Check if a player just died then teleport a zombie to its location
				if(player_death_zombie_spawn) then
					for key,value in pairs (PLAYERS) do
						if(PLAYERS[key]["died"] ~= nil) then
							write_vector3d(object + 0x5C, PLAYERS[key]["x"], PLAYERS[key]["y"], PLAYERS[key]["z"])
							PLAYERS[key]["died"] = nil
							break
						end
					end
				end
			end
		elseif(read_word(object + 0xB4) == 2) then-- weap
			if(name == shop_item_location) then
				for i = 1,16 do
					if(player_present(i)) then
						if(PLAYERS[i]["item"] ~= nil) then
							local item = SHOP[PLAYERS[i]["item"]]
							local x,y,z = read_vector3d(object + 0x5C)
							for j = 4,16 do
								if(item[j] ~= nil) then
									spawn_object(item[3], item[j], x+0.11, y+0.1, z+0.05, 0)
								end
							end
							destroy_object(object)
							PLAYERS[i]["item"] = nil
							return false
						end
					end
				end
			end
		else
			--	Check if the object is one of our vehicles
			if(read_word(object + 0xB4) == 1) then
				if(VEHICLES[name] == 0) then
					destroy_object(ID)
				else
					if(VEHICLES[name] == 1) then
						VEHICLE_FUEL[ID] = rand(0, 10000)
					else
						--	Replace truck with mp variant
						if(VEHICLES[name] == 2) then
							local x,y,z = read_vector3d(object + 0x5C)
							local a = read_float(object + 0x76)
							local b = read_float(object + 0x7A)
							local c = read_float(object + 0x7E)
							local d = read_float(object + 0x82)
							destroy_object(ID)
							respawnedVehicleID = spawn_object("vehi", "halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\military truck mp", x, y, z, 0)
							respawnedVehicle = get_object_memory(respawnedVehicleID)
							if(respawnedVehicle ~= nil) then
								write_float(respawnedVehicle + 0x76, a)
								write_float(respawnedVehicle + 0x7A, b)
								write_float(respawnedVehicle + 0x7E, c)
								write_float(respawnedVehicle + 0x82, d)
							end
						--else
						--	for key,value in pairs (BIPED_ANIMATION_STATE) do
						--		if(name == tag_directory..value) then
						--			timer(1000*ai_purge_rate, "destroy_object", ID)
						--			break
						--		end
						--	end
						end
					end
				end
			end
		end
	end
end

function PurgeAIVehicles()--	Removes all of AI vehicles in order to get rid of duplicates (does not work)
	local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if(object ~= 0 and object ~= 0xFFFFFFFF) then
			local object_type = read_word(object + 0xB4)
            if(object_type == 1) then
				local name = GetName(object)
				for key,value in pairs (BIPED_ANIMATION_STATE) do
					if(name == tag_directory..value) then
						--remove vehicle somehow????
						break
					end
				end
			end
		end
	end
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	commandargs = {}
	for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
	
--ADMIN COMMANDS
	if(commandargs[1] == score_command) then
		if(commandargs[2] == nil or commandargs[3] == nil) then
			say(PlayerIndex, "Incorrect arguments! Command usage: /"..score_command.." <player ID> <score>")
			return false
		end
		if(player_alive(commandargs[2])) then
			PLAYERS[tonumber(commandargs[2])]["score"] = tonumber(commandargs[3])
			say(PlayerIndex, "Player's score successfully set")
			return false
		end
		say(PlayerIndex, "Player does not exist or is dead")
		return false
	end
	if(commandargs[1] == wave_start_command) then
		game_count = game_count + 1
		wave = 1
		say_all("Wave "..wave)
		execute_command("ai_place flood_night")
		timer(wave_time * 1000, "NewWave", game_count)
		return false
	end
	
	if(commandargs[1] == ai_max_command) then
		local value_wanted = tonumber(Command:sub(commandargs[1]:len() + 2))
		if(value_wanted < 200 and value_wanted > 0) then
			ai_max = value_wanted
			say(PlayerIndex, "AI limit successfully set to "..ai_max)
			return false
		else
			say(PlayerIndex, "Incorrect arguments!")
			return false
		end
	end
	
	if(commandargs[1] == debug_command) then
		local value_wanted = tonumber(commandargs[2])
		if(value_wanted == 0) then
			debug_mode = false
			say_all("Debug mode disabled.")
			return false
		else
			if(value_wanted == 1) then
				debug_mode = true
				debug_person = PlayerIndex
				say_all("Debug mode enabled.")
				return false
			else
				say(PlayerIndex, "Incorrect arguments! Command usage: /"..debug_command.." <1/0>")
				return false
			end
		end
	end
	
	if(commandargs[1] == ai_life_time_command) then
		local value_wanted = tonumber(Command:sub(commandargs[1]:len() + 2))
		if(value_wanted < 32000 and value_wanted > 0) then
			ai_life_time = value_wanted*30
			say(PlayerIndex, "AI life time set to "..ai_life_time / 30 .." seconds.")
			return false
		else
			say(PlayerIndex, "Incorrect arguments!")
			return false
		end
	end
	
	if(commandargs[1] == wave_time_command) then
		local value_wanted = tonumber(Command:sub(commandargs[1]:len() + 2))
		if(value_wanted < 32000 and value_wanted > 10) then
			wave_time = value_wanted
			say(PlayerIndex, "wave time set to "..wave_time .." seconds.")
			return false
		else
			say(PlayerIndex, "Incorrect arguments!")
			return false
		end
	end
	
--PLAYER COMMANDS
	for i = 1,4 do	--	drop
		if(commandargs[1] == weapon_drop_command[i]) then
			drop_weapon(PlayerIndex)
			return false
		end
	end
	
	for i = 1,2 do	--	give
		if(commandargs[1] == give_command[i]) then
			if(commandargs[2] == nil or commandargs[3] == nil) then
				say(PlayerIndex, "Incorrect arguments! Command usage: /"..give_command[i].." <player name> <score>")
				return false
			end
			
			local name_wanted = string.lower(commandargs[2])
			local score_wanted = tonumber(commandargs[3])
			if(score_wanted == nil) then
				say(PlayerIndex, "Incorrect arguments! You probably used space symbol in the name.")
				return false
			end
			if(score_wanted > 0 and score_wanted <= PLAYERS[PlayerIndex]["score"]) then
				for i = 1,16 do
					if(player_alive(i) and i ~= PlayerIndex) then
						local player_name = string.lower(get_var(i, "$name"))
						if(string.find(player_name, name_wanted) ~= nil) then
							local player_object = get_dynamic_player(i)
							local giver_object = get_dynamic_player(PlayerIndex)
							if(player_object == 0 or giver_object == 0) then
								say(PlayerIndex, "Error at giving, probably one of the players is dead!")
							end
							local x,y,z = read_vector3d(player_object + 0x5C)
							local x2,y2,z2 = read_vector3d(giver_object + 0x5C)
							if(DistanceFormula(x,y,z,x2,y2,z2) < give_distance) then
								PLAYERS[PlayerIndex]["score"] = PLAYERS[PlayerIndex]["score"] - score_wanted
								PLAYERS[i]["score"] = PLAYERS[i]["score"] + score_wanted
								say(PlayerIndex, "You gave "..get_var(i, "$name").." $"..score_wanted)
								say(i, "You received $"..score_wanted.." from "..get_var(PlayerIndex, "$name"))
								return false
							end
							say(PlayerIndex, "You are too far away from "..player_name)
							return false
						end
					end
				end
				say(PlayerIndex, "Could not find player "..name_wanted)
				return false
			else
				say(PlayerIndex, "You don't have enough $!")
				return false
			end
			
			return false
		end
	end
	
	for i = 1,3 do	--	shop
		if(commandargs[1] == shop_command[i]) then
		PLAYERS[PlayerIndex]["shop"] = 1
		return false
		end
	end
	return true
end

function OnChat(PlayerIndex, message)
	message = string.lower(message)
	if(message == "uwu") then
		say_all("DON'T UWU. $350 PENALTY")
		if(PLAYERS[PlayerIndex]["score"] - 350 > 0) then
			PLAYERS[PlayerIndex]["score"] = PLAYERS[PlayerIndex]["score"] - 350
		else
			PLAYERS[PlayerIndex]["score"] = 0
		end
	end
	if(message == "neko") then
		say_all(":3")
	end
	if(message == "owo") then
		say_all("What's that?")
	end
	if(message == ">:u") then
		say_all("RAGE MAPPING TEAM >:u")
	end
	if(message == "o_0") then
		say_all("0_o")
	end
	if(message == "give me your pants") then
		say_all("Now give me your other pants!")
	end
	if(string.find(message, "secret") ~= nil) then
		say_all("Where? :o")
	end
	if(string.find(message, "girl") ~= nil) then
		say_all("aLTis is watching...")
	end
	if(string.find(message, "tits") ~= nil) then
		say_all("( . Y . )")
	end
	if(string.find(message, "8ball") ~= nil) then
		local number = rand(1,10)
		if(number == 1) then
			say_all("Yes!")
		end
		if(number == 2) then
			say_all("No.")
		end
		if(number == 3) then
			say_all("My sources say yes")
		end
		if(number == 4) then
			say_all("Maybe")
		end
		if(number == 5) then
			say_all("Don't count on it")
		end
		if(number == 6) then
			say_all("Sure buddy")
		end
		if(number == 7) then
			say_all("For sure")
		end
		if(number == 8) then
			say_all("Wouldn't think about it")
		end
		if(number == 9) then
			say_all("That's a secret...")
		end
		if(number == 10) then
			say_all("What is life?")
		end
	end
	if(string.find(message, "crawling") ~= nil) then
		say_all("THESE WOUNDS THEY WILL NOT HEAL")
	end
	if(string.find(message, "fear is how i") ~= nil) then
		say_all("CONFUSING WHAT IS REAL")
	end
	if(string.find(message, "wake up") ~= nil) then
		say_all("WAKE ME UP INSIDE")
	end
	if(string.find(message, "wake me") ~= nil) then
		say_all("CAN'T WAKE UP")
	end
	return true
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetPlayerAimLocation(PlayerIndex)--	Finds location where player is looking, from giraffe's script
	local player = get_dynamic_player(PlayerIndex)
	local px, py, pz = read_vector3d(player + 0x5c)
    local vx, vy, vz = read_vector3d(player + 0x230)
    local cs = read_float(player + 0x50C)
    local h = 0.62 - (cs * (0.62 - 0.35))
    pz = pz + h
	local hit, x, y , z = intersect(px, py, pz, 10000*vx, 10000*vy, 10000*vz, read_dword(get_player(PlayerIndex) + 0x34))
	local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - 0.1
	return intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(PlayerIndex) + 0x34))
end

function GetYaw(ID)-- Made by 002
    local a = AI[ID]["yaw"]
    local b = AI[ID]["pitch"]
 
    local cos_b = math.acos(b)
    
    local finalAngle = cos_b
    
    if(a < 0) then finalAngle = finalAngle * -1 end
 
    return finalAngle
end
--	AI synchronization by aLTis (altis94@gmail.com)

--	This script will only work on AI maps that were made for this script. It will not work on the floods or other stupid AI maps.

--	CONFIG
	debug_mode = true	--		Default state of debug_mode
	
--	PERFORMANCE
	ai_max = 20 --				Maximum number of AI, exceeding this limit will destroy any bipeds that are created (should be 100)
				--				It could be set higher on large single player maps to make sure encounters don't get removed.
	ai_deletion_distance = 50--	Distance that AI must be away from the player in order to get deleted (world units)
	dynamic_deletion_distance = false-- Will change the ai_deletion_distance depending on synced AI count
	synced_ai_limit = 30--		How many AI can be synced at once (if dynamic_deletion_distance is true)
	veh_spawn_max = 4	--		Maximum amount of vehicles that can be spawned per tick. Should be 3-30, crashes above 60
						--		This value only makes sure client doesn't crash when too many objects are spawned at once.
	projectile_rate = 3	--		How often projectile position updates. Default is 15
	ai_position_rate = 4--		How often AI position updates in ticks. Default is 4, setting below 4 causes desync
	ai_animation_rate = 5--		How often AI animation states are updated in ticks. Setting this to low values
						--		will cause AI to turn to T pose more often.
	ignore_rate = true	--		Ignore the above value and change animations instantly

--BIPEDS
	ai_dir = "ai\\"
	veh_dir = "\\veh\\"
	biped_dir = "\\biped"
	ai_check_tag = "ai\\all_ai"
	dead_tag = "4\\kill-back"
	
	BIPEDS = {
		["elite"] = {
			["id"] = 0,
			["score"] = 10,			--how much score you get for killing this biped
			["units"] = {3, 4, 8, 29},		--animation tag's units. usually 3 = crouch and 4 = stand
			["default_unit"] = 4, 	--if there is a missing animation for other unit, this unit will be used instead (it should have ALL animations)
			["death_timer"] = 66 *(1000/30),	--how long death animation is (ticks turned into ms)
			["no_physics"] = {			--unit states that have no physics/velocity sync
				[0] = 1,	--idle
				[23] = 1,	--ping
			},
			unit_states = {
				[0] = "idle",    		--idle
				[4] = "move-front",  		--walking front
				[5] = "move-back",  		--walking back
				[6] = "move-left",  		--walking left
				[7] = "move-right",  		--walking right
				[20]= "move-front",		--airborne
				[21]= "move-front",  		--land_soft
				[22]= "move-front",  		--land_hard
				[23]= "ping",    		--ping
				[24]= "idle", 		--airborne dead
				[25]= "idle", 		--dead
				[29]= "impulse", 		--impulse
				[30]= "melee",  		--melee
				[31]= "melee",  		--melee airborne
			},
			animations = {				-- these animations are only used for impulse unit state. If biped doesn't have impulse state just ignore these
										-- all of these animations MUST be in default_unit folder!
				[86] = "berserk",
				[87] = "dive-front",
				[88] = "dive-left",
				[89] = "dive-right",
				[90] = "evade-left",
				[91] = "evade-right",
				[103] = "surprise-back",
				[104] = "surprise-front",
				[112] = "berserk",
				[113] = "dive-front",
				[114] = "dive-left",
				[115] = "dive-right",
				[116] = "evade-left",
				[117] = "evade-right",
			},
		}
	}
	
--COMMANDS AND STUFF	
	--Commands for admins
	debug_command = "ai_debug"--	Command used to change debug mode state
	ai_max_command = "ai_limit"--	Command used to change AI limit 
	synced_ai_max_command = "synced_ai_limit"--	Command used to change AI limit 
	
	affect_player_stats = false --	Should players get kills/score for killing AI
	dynamic_ai_health = false	--	Increase AI health when they spawn depending on player count
	dynamic_ai_health_multiplier = 0.1 --	How much AI health increases for each player in the game (0.1 - 10% for each player)

--	END OF CONFIG

api_version = "1.10.0.0"

	--	Global values. Do not touch these
debug_person    = 1	-- person who will receive the debug messages
second_count    = 0 -- used for counting seconds
spawned_vehicle_count = 0
synced_ai_count = 0
ai_count = 0
AI              = {}
PLAYERS         = {}
object_table_ptr= nil

function OnScriptLoad()
	cprint("AI loading script...")
	execute_command("vehicle_incremental_rate "..ai_position_rate)
	execute_command("projectile_incremental_rate "..projectile_rate)
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	--if get_var(0, "$mode") ~= "n/a" then
	--	cprint("AI game: started.")
		Initialize(0)
		FindBipeds()
	--else
	--	cprint("AI game: not started.")
	--end
	cprint("AI script loaded!")
end

function OnGameStart()
	Initialize(1)
	FindBipeds()
end

function Initialize(NewGame)
	cprint("AI Initialization started")
	if lookup_tag("bipd", ai_check_tag) ~= 0 then
		--if NewGame then
			InitializeVehicles()
		--end
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		--register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_COMMAND'],"OnCommand")
		--register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		execute_command("scorelimit 10000")
		for i = 1,16 do
			ResetPlayerStats(i, 0)
		end
		--execute_command("ai_place elite")
		execute_command("cheat_infinite_ammo 1")
		for i=0,1 do
			--timer(i*100, "temp")
		end
	else
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_JOIN'])
		--unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_COMMAND'])
		--unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
	end
	cprint("AI Initialization finished")
end

function temp()
	execute_command("ai_place red_elites")
	execute_command("ai_place blue_elites")
end

function FindBipeds()	--	Find all of the bipeds that are on the map
	cprint("AI Finding bipeds... ")
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local object_table_base = read_dword(object_table + 0x34)
	for i=0,object_count-1 do
		local ID = read_word(object_table_base + i*12)*0x10000 + i
		local object = get_object_memory(ID)
		if object ~= 0 and read_word(object + 0xB4) == 0 then
			local MetaID = read_dword(object)
			CheckBiped(ID, MetaID)
		end
	end
	cprint("AI Bipeds found.")
end

function InitializeVehicles()	--	Remove collision geometry from all AI vehicles
	cprint("AI Initializing vehicles..")
	for biped, data in pairs (BIPEDS) do
		local address = lookup_tag("bipd", ai_dir..biped..biped_dir)
		if address ~= 0 then
			data.id = read_dword(address + 0xC)
		end
		--	This part could be optimized to not change the same tags again
		for none, unit in pairs (BIPEDS[biped].units) do
			for key,vehicle in pairs (data.unit_states) do
				local vehicle_tag = lookup_tag("vehi", ai_dir..biped..veh_dir..unit.."\\"..vehicle)
				if vehicle_tag ~= 0 then
					local vehicle_data = read_dword(vehicle_tag + 0x14)
					write_dword(vehicle_data + 0x70, 0x65666665)
					write_dword(vehicle_data + 0x70 + 0x4, 0)
					write_dword(vehicle_data + 0x70 + 0x8, 0)
					write_dword(vehicle_data + 0x70 + 0xC, 0xFFFFFFFF)
				end
			end
		end
		for id, vehicle in pairs (BIPEDS[biped].animations) do
			local vehicle_tag = lookup_tag("vehi", ai_dir..biped..veh_dir..BIPEDS[biped].default_unit.."\\"..vehicle)
			if vehicle_tag ~= 0 then
				local vehicle_data = read_dword(vehicle_tag + 0x14)
				write_dword(vehicle_data + 0x70, 0x65666665)
				write_dword(vehicle_data + 0x70 + 0x4, 0)
				write_dword(vehicle_data + 0x70 + 0x8, 0)
				write_dword(vehicle_data + 0x70 + 0xC, 0xFFFFFFFF)
			end
		end
	end
	cprint("AI Vehicle initialization finished.")
end

function OnScriptUnload()--	Remove all AI vehicles (and optionally bipeds)
	cprint("AI unloading script..")
	for ID, info in pairs (AI) do
		destroy_object(ID) -- May crash the server if there's a lot of AI
		local biped_object = get_object_memory(ID)
		--RemoveBiped(ID, biped_object)
		if biped_object then
			write_float(biped_object + 0xE0, 0)
		end
		if AI[ID]["vehicle"] ~= nil and AI[ID]["vehicle"] ~= -1 then
			destroy_object(AI[ID].vehicle)
		end
	end
	cprint("AI script unloaded.")
end

function OnPlayerJoin(PlayerIndex)
	ResetPlayerStats(PlayerIndex, 0)
end

function ResetPlayerStats(PlayerIndex, NewStats)
	PLAYERS[PlayerIndex] = {}
	if affect_player_stats then
		if NewStats == 1 then
			PLAYERS[PlayerIndex]["kills"] = get_var(PlayerIndex, "$kills")
			PLAYERS[PlayerIndex]["score"] = get_var(PlayerIndex, "$score")
		else
			PLAYERS[PlayerIndex]["kills"] = 0
			PLAYERS[PlayerIndex]["score"] = 0
		end
	end
end

function OnTick()
	--	Count seconds
	second_count = second_count + 1
	if(second_count == 30) then
		second_count = 0
	end
	
	--	Set player scores and get info
	for i = 1,16 do
		if(player_alive(i)) then
			if affect_player_stats then
				execute_command("kills "..i.." "..PLAYERS[i].kills)
				execute_command("score  "..i.." "..PLAYERS[i].score)
			end
			local player_object = get_dynamic_player(i)
			if player_object then
				PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z = read_vector3d(player_object + 0x5C)
				local vehicle = read_dword(player_object + 0x11C)
				if vehicle ~= 0xFFFFFFFF then
					PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z = read_vector3d(get_object_memory(vehicle) + 0x5C)
				end
			end
		end
	end
	
	--	Make sure host is always on bsp 0 since path finding doesn't work on others (for bigassv3 only)
	--execute_command("switch_bsp 0")
	--execute_command("object_destroy d")
	
	--*****************************************	AI SYNC STUFF!	**************************************************************
	
	--	Go through all of the bipeds that are in the AI table
	for ID, info in pairs (AI) do
		local biped_object = get_object_memory(ID)
		if AI[ID] ~= nil and biped_object then
			ai_count = ai_count + 1
			if read_float(biped_object + 0xE0) <= 0 then --	If biped is dead
				RemoveBiped(ID, biped_object)
			elseif AI[ID].vehicle ~= -1 then
				AI[ID].x, AI[ID].y, AI[ID].z = read_vector3d(biped_object + 0x5C)
				AI[ID].x_vel, AI[ID].y_vel, AI[ID].z_vel = read_vector3d(biped_object + 0x68)
				AI[ID].yaw = read_float(biped_object + 0x224)
				AI[ID].pitch = read_float(biped_object + 0x228)
				GetDamagerID(ID, biped_object)
				local unit = read_byte(biped_object + 0x2A0)
				local unit_state = read_byte(biped_object + 0x2A3)
				local real_anim = read_byte(biped_object + 0xD0)
				local anim = BIPEDS[AI[ID].type].unit_states[unit_state]
				
				if anim == "impulse" then
					local anim_table = BIPEDS[AI[ID].type].animations
					anim = anim_table[real_anim]
					unit = BIPEDS[AI[ID].type].default_unit
					--rprint(1, "impulse! using "..real_anim.." which is "..anim)
				end
				
				--the server crashed when I ran over a biped but after a second invisible biped shot at me.
				--seemed like the script thought the biped died when it actually stayed alive for some reason.
				if false then
					safe_read(true)
					
					ClearConsole(1)
					rprint(1, "|c|tbyte "..read_byte(biped_object + 0x508))
					rprint(1, "|c|tword "..read_word(biped_object + 0xD0))
					rprint(1, "|c|tdword "..read_dword(biped_object + 0x58))
					rprint(1, "|c|tfloat "..read_float(biped_object + 0x510))
					for f=0,7 do
					local o = 0xC8
						rprint(1, f .."    "..read_bit(biped_object+o,f).."|t "..f+8 .."     "..read_bit(biped_object+o,f+8).."|t "..f+16 .."     "..read_bit(biped_object+o,f+16).."|t "..f+24 .."      "..read_bit(biped_object+o,f+24))
					end
					
					safe_read(false)
				end
				
				--rprint(1, unit.."   "..unit_state)
				--			If animation for this state does not exist then set it to idle
				if anim == nil then
					rprint(1, AI[ID].type.." had no vehicle for state "..unit_state..", real anim "..real_anim)
					anim = BIPEDS[AI[ID].type].unit_states[0]
				end
				
				local min_distance = 1000
				for i = 1,16 do
					if player_alive(i) and PLAYERS[i].z ~= nil then
						local distance = DistanceFormula(PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z,AI[ID].x, AI[ID].y, AI[ID].z)
						if distance < min_distance then
							min_distance = distance
						end
					end
				end		
				--			Remove the biped if he's been alive too long and is far from players
				if min_distance > ai_deletion_distance then
					if AI[ID].vehicle ~= nil then
						destroy_object(AI[ID].vehicle)
						AI[ID].vehicle = nil
					end
				else
					synced_ai_count = synced_ai_count + 1
					--		Check if the biped has a vehicle assigned to it
					if AI[ID].vehicle == nil then
						SpawnVehicle(ID, anim, BIPEDS[AI[ID].type].default_unit, 0)--	changed this to use default unit. this might have fixed potential issues
					end										--	currently the script can instantly remove this vehicle, would that cause crashes?
					if AI[ID].vehicle ~= -1 then
						--		Sync vehicle animations with biped's
						if lookup_tag("vehi", ai_dir..AI[ID].type..veh_dir..unit.."\\"..anim) == 0 then	--	check if there is this state's animation for this unit
							--rprint(1, AI[ID].type.." missing "..unit.."  "..unit_state)
							unit = BIPEDS[AI[ID].type].default_unit
						end
						local vehicle_object = get_object_memory(AI[ID].vehicle)
						if vehicle_object ~= 0 then
							local name = GetName(vehicle_object)
							if anim ~= nil and name ~= ai_dir..AI[ID].type..veh_dir..unit.."\\"..anim and (ignore_rate or second_count%ai_animation_rate == 0) then
								destroy_object(AI[ID].vehicle)
								AI[ID].vehicle = nil
								SpawnVehicle(ID, anim, unit, 0)
								vehicle_object = get_object_memory(AI[ID].vehicle)
							end
							if AI[ID].vehicle ~= -1 then
								--	Sync vehicle coordinates with biped's
								if AI[ID].x_vel ~= 0 or AI[ID].y_vel then
									write_bit(vehicle_object + 0x10, 5, 0)		--	make vehicle not stationary
									write_vector3d(vehicle_object + 0x68, AI[ID].x_vel, AI[ID].y_vel, AI[ID].z_vel)	--	sync velocities
								end
								write_vector3d(vehicle_object + 0x74, AI[ID].yaw, AI[ID].pitch, 0)	--	sync rotation
								if BIPEDS[AI[ID].type].no_physics[unit_state] ~= nil then	--	sync locations for states where biped usually doesn't move
									write_vector3d(vehicle_object + 0x5C, AI[ID].x, AI[ID].y, AI[ID].z)
								end
							end
							
							--Set biped health depending on player count
							if dynamic_ai_health and AI[ID].time_alive == 100 then
								local player_count = get_var(0, "$pn")
								write_float(biped_object + 0xE0, 1.0 + (player_count - 1)*dynamic_ai_health_multiplier)
								--rprint(1, player_count..", health = ".. 1.0+player_count*0.1)
							end
						else
							SpawnVehicle(ID, anim, unit, 0)
						end
					end
				end
			end
		else
		--					If biped does not exist any more
			RemoveBiped(ID, biped_object)
		end
	end
	
	if dynamic_deletion_distance and second_count == 0 then
		if synced_ai_count > synced_ai_limit and ai_deletion_distance > 10 then
			ai_deletion_distance = ai_deletion_distance - 1
		elseif synced_ai_count < synced_ai_limit + 3 and ai_deletion_distance < 100 then
			ai_deletion_distance = ai_deletion_distance + 1
		end
	end
	
	DebugStuff()
	ai_count = 0
	synced_ai_count = 0
	spawned_vehicle_count = 0
end

function GetDamagerID(ID, biped_object)-- From 002; Checks which player killed the biped
	for k=0,3 do
		local struct = biped_object + 0x430 + 0x10 * k
		local damager_pid = read_word(struct + 0xC)
		if(damager_pid ~= 0xFFFF) then
			AI[ID].damage_causer = tonumber(to_player_index(damager_pid))
		end
	end
end

function RemoveBiped(ID, biped_object)--	Remove dead/non-existent biped
	cprint("AI removing biped")
	if AI[ID].vehicle ~= nil then
		destroy_object(AI[ID].vehicle)
	end
	if biped_object then
		GetDamagerID(ID, biped_object)
	end
	if AI[ID].x ~= nil and AI[ID].y ~= nil and AI[ID].pitch ~= nil then
		local dead = spawn_object("vehi", ai_dir..AI[ID].type..veh_dir..dead_tag,  AI[ID].x, AI[ID].y, AI[ID].z, GetYaw(ID))
		timer(BIPEDS[AI[ID].type].death_timer - 33, "destroy_object", dead)
		--	Set player stats
		if AI[ID].damage_causer ~= nil then
			if player_alive(AI[ID].damage_causer) then
				local PlayerIndex = AI[ID].damage_causer
				if PLAYERS[PlayerIndex]~= nil and PLAYERS[PlayerIndex].kills ~= nil then
					PLAYERS[PlayerIndex].kills = PLAYERS[PlayerIndex].kills + 1
					PLAYERS[PlayerIndex].score = PLAYERS[PlayerIndex].score + BIPEDS[AI[ID].type].score
				end
			end
		end
	end
	timer(BIPEDS[AI[ID].type].death_timer + 1000, "destroy_object", ID)--	this MIGHT cause crashes.
	AI[ID] = nil
end

function SpawnVehicle(ID, anim, unit, delayed)
	if delayed ~= 0 then
		ID = tonumber(ID)
		unit = tonumber(unit)
		cprint("AI changed "..ID.."  "..anim.."  "..unit.."  "..delayed)
	end
	if ID ~= nil and AI[ID] ~= nil then
		if AI[ID].vehicle == nil or AI[ID].vehicle == -1 then
			if spawned_vehicle_count < veh_spawn_max then
				spawned_vehicle_count = spawned_vehicle_count + 1
				local tag_dir = ai_dir..AI[ID].type..veh_dir..unit.."\\"..anim
				AI[ID].vehicle = spawn_object("vehi", tag_dir, AI[ID].x, AI[ID].y, AI[ID].z, GetYaw(ID))
			else
				AI[ID].vehicle = -1
				local rand = rand(33,500)
				--cprint(rand)
				timer(rand, "SpawnVehicle", ID, anim, unit, "1")
			end
		end
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	timer(0, "ObjectCheck", ID, MetaID)
end

function CheckBiped(ID, MetaID)--	Check if biped needs to be synced
	for biped, data in pairs (BIPEDS) do
		if data.id == tonumber(MetaID) then
			if AI[ID] == nil then
				local ai_counter = 0
				for key,value in pairs (AI) do
					ai_counter = ai_counter + 1
				end
				if ai_counter > ai_max then
					--cprint("AI AI limit reached! "..ai_count)
					destroy_object(ID)
					return false
				else
					AI[ID] = {}
					AI[ID].time_alive = 0
					AI[ID].type = biped
					cprint("AI Spawning AI "..ID)
				end
			end
			return false
		end
	end
end

function ObjectCheck(ID, MetaID)--	Check if object is a biped
	if(ID == nil) then 
		return true 
	end
	ID = tonumber(ID)
	local object = get_object_memory(ID)
	
	if object then
		if(read_word(object + 0xB4) == 0) then
			CheckBiped(ID, MetaID)
		end
	end
end

function DebugStuff()--	Prints objects counts and stuff
	if debug_mode then
		local vehicle_count = 0
		local biped_count = 0
		local weapon_count = 0
		local scenery_count = 0
		local equipment_count = 0
		local projectile_count = 0
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
				elseif(object_type == 5) then
					projectile_count = projectile_count + 1
				elseif(object_type == 3) then
					equipment_count = equipment_count + 1
				end
			end
		end
		ClearConsole(debug_person)
		rprint(debug_person, "|rDistance "..ai_deletion_distance)
		rprint(debug_person, "|rAI "..ai_count.." ("..synced_ai_count.." synced)")
		rprint(debug_person, "|rVehicles/tick "..spawned_vehicle_count)
		--rprint(debug_person, "|rBipeds "..biped_count)
		--rprint(debug_person, "|rVehicles "..vehicle_count)
		rprint(debug_person, "|rWeapons "..weapon_count)
		--rprint(debug_person, "|rProjectiles "..projectile_count)
		--rprint(debug_person, "|rEquipment "..equipment_count)
		rprint(debug_person, "|rSynced objects "..biped_count + vehicle_count + weapon_count + equipment_count)
		--rprint(debug_person, "|rScenery "..scenery_count)
		rprint(debug_person, "|rObject count "..total_objects.."/"..object_count)
	end
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	commandargs = {}
	for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
	
--ADMIN COMMANDS	
	if(commandargs[1] == ai_max_command) then
		local value_wanted = tonumber(Command:sub(commandargs[1]:len() + 2))
		if(value_wanted < 200 and value_wanted > 0) then
			ai_limit = value_wanted
			say(PlayerIndex, "AI limit successfully set to "..ai_limit)
			return false
		else
			say(PlayerIndex, "Incorrect arguments!")
			return false
		end
	end
	
	if(commandargs[1] == synced_ai_max_command) then
		local value_wanted = tonumber(Command:sub(commandargs[1]:len() + 2))
		if(value_wanted < 200 and value_wanted > 0) then
			synced_ai_limit = value_wanted
			say(PlayerIndex, "Synced AI limit successfully set to "..synced_ai_limit)
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
				say(debug_person, "Debug mode enabled.")
				return false
			else
				say(PlayerIndex, "Incorrect arguments! Command usage: /"..debug_command.." <1/0>")
				return false
			end
		end
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

function GetYaw(ID)-- Made by 002
    local a = AI[ID]["yaw"]
    local b = AI[ID]["pitch"]
 
    local cos_b = math.acos(b)
    
    local finalAngle = cos_b
    
    if(a < 0) then finalAngle = finalAngle * -1 end
 
    finalAngle = finalAngle - math.pi / 2
 
    if(finalAngle < 0) then finalAngle = finalAngle + math.pi * 2 end
 
    return  (math.pi*2) - finalAngle
end

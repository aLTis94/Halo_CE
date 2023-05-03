--	AI synchronization by aLTis (altis94@gmail.com)

--	This script will only work on AI maps that were made for this script. It will not work on the floods or other stupid AI maps.

--	CONFIG
	projectile_rate = 5			--How often projectile position updates. Default is 15
	ai_position_rate = 4		--How often AI position updates in ticks. Default is 4, setting below 4 causes desync
	ai_animation_rate = 11		--How often AI animation states are updated in ticks. Setting this to low values
									--will cause AI to turn to T pose more often.
	ignore_rate = true	--Ignore the above value and change animations instantly

--BIPEDS
	ai_dir = "ai\\"
	veh_dir = "\\veh\\"
	biped_dir = "\\biped"
	ai_check_tag = "ai\\all_ai"
	dead_tag = "\\dead"
	
	BIPEDS = {
		["floodcombat_human"] = {
			["id"] = 0,
			["score"] = 10,			--how much score you get for killing this biped
			[0] = "idle",    		--idle
			[4] = "walking",  		--walking
			[20]= "walking",		--airborne
			[21]= "walking",  		--land_soft
			[22]= "walking",  		--land_hard
			[23]= "idle",    		--ping
			[24]= "kill_back", 		--airborne dead
			[25]= "kill_back", 		--dead
			[30]= "melee",  		--melee
			[31]= "melee",  		--melee airborne
			[34]= "resurrect", 		--resurrect front
			[35]= "resurrect", 		--resurrect back
			[39]= "leap_airborne", 	--leap start
			[40]= "leap_airborne",	--leap airborne
			[41]= "melee", 			--leap melee
		},
		["elite"] = {
			["id"] = 0,
			["score"] = 10,			--how much score you get for killing this biped
			[0] = "idle",    		--idle
			[4] = "move-front",  		--walking front
			[5] = "move-back",  		--walking back
			[6] = "move-left",  		--walking left
			[7] = "move-right",  		--walking right
			[20]= "move-front",		--airborne
			[21]= "move-front",  		--land_soft
			[22]= "move-front",  		--land_hard
			[23]= "idle",    		--ping
			[24]= "idle", 		--airborne dead
			[25]= "idle", 		--dead
			[29]= "berserk", 		--impulse??? seems to happen when AI dives or something, no idea which animation to use here
			[30]= "melee",  		--melee
			[31]= "melee",  		--melee airborne
		}
	}
	
	NO_VELOCITY_STATES = {
		[0] = 1,	--idle
		[23] = 1,	--ping
	}
	
--COMMANDS AND STUFF	
	--Commands for admins
	debug_command = "ai_debug"--	Command used to change debug mode state
	ai_max_command = "ai_limit"--	Command used to change AI limit 
	
	affect_player_stats = false --	Should players get kills/score for killing AI
	dynamic_ai_health = false	--	Increase AI health when they spawn depending on player count
	dynamic_ai_health_multiplier = 0.1 --	How much AI health increases for each player in the game (0.1 - 10% for each player)
	debug_mode = false--	Default state of debug_mode
	ai_max = 150 --			Maximum number of AI, exceeding this limit will destroy any zombie bipeds that are created (should be below 150)
	ai_deletion_distance = 40--	Distance that AI must be away from the player in order to get deleted (world units)

--	END OF CONFIG

api_version = "1.9.0.0"

	--	Global values. Do not touch these
debug_person    = 0	-- person who will receive the debug messages
second_count    = 0 -- used for counting seconds
AI              = {}
PLAYERS         = {}
object_table_ptr= nil

function OnScriptLoad()
	execute_command("vehicle_incremental_rate "..ai_position_rate)
	execute_command("projectile_incremental_rate "..projectile_rate)
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	Initialize(0)
	FindBipeds()
end

function OnGameStart()
	Initialize(1)
	FindBipeds()
end

function Initialize(NewGame)
	if lookup_tag("bipd", ai_check_tag) ~= 0 then
		InitializeVehicles()
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
		
		execute_command("ai_place elite")
	else
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_JOIN'])
		--unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_COMMAND'])
		--unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
	end
end

function FindBipeds()
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
end

function InitializeVehicles()
	for biped, data in pairs (BIPEDS) do
		local address = lookup_tag("bipd", ai_dir..biped..biped_dir)
		if address ~= 0 then
			data.id = read_dword(address + 0xC)
		end
		for key,vehicle in pairs (data) do
			local vehicle_tag = lookup_tag("vehi", ai_dir..biped..veh_dir..vehicle)
			if vehicle_tag ~= 0 then
				local vehicle_data = read_dword(vehicle_tag + 0x14)
				write_dword(vehicle_data + 0x70, 0x65666665)
				write_dword(vehicle_data + 0x70 + 0x4, 0)
				write_dword(vehicle_data + 0x70 + 0x8, 0)
				write_dword(vehicle_data + 0x70 + 0xC, 0xFFFFFFFF)
			end
		end
	end
end

function OnScriptUnload()--	Remove all AI vehicles
	for ID, info in pairs (AI) do
		destroy_object(ID)
		if(AI[ID]["vehicle"] ~= nil) then
			destroy_object(AI[ID].vehicle)
		end
	end
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
	DebugStuff()
	
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
			if player_object ~= 0 then
				PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z = read_vector3d(player_object + 0x5C)
				local vehicle = read_dword(player_object + 0x11C)
				if vehicle ~= 0xFFFFFFFF then
					PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z = read_vector3d(get_object_memory(vehicle) + 0x5C)
				end
			end
		end
	end
	
	--	Make sure host is always on bsp 0 since path finding doesn't work on others (for bigassv3 only)
	execute_command("switch_bsp 0")
	execute_command("object_destroy d")
	
	--*****************************************	AI SYNC STUFF!	**************************************************************
	
	--	Go through all of the bipeds that are in the AI table
	for ID, info in pairs (AI) do
		local biped_object = get_object_memory(ID)
		if AI[ID] ~= nil and biped_object ~= 0 then
			if read_float(biped_object + 0xE0) < 0.01 then --	If biped is dead
				RemoveBiped(ID, biped_object)
			else 
				AI[ID].x, AI[ID].y, AI[ID].z = read_vector3d(biped_object + 0x5C)
				AI[ID].x_vel, AI[ID].y_vel, AI[ID].z_vel = read_vector3d(biped_object + 0x68)
				AI[ID].yaw = read_float(biped_object + 0x224)
				AI[ID].pitch = read_float(biped_object + 0x228)
				GetDamagerID(ID, biped_object)
				local unit_state = read_byte(biped_object + 0x2A3)
				local crouch_state = read_byte(biped_object + 0x2A0)
				--rprint(1, unit_state)
				--rprint(1, crouch_state) --	3 - crouching, 4 - standing, 0 - vehicle
				local anim = BIPEDS[AI[ID].type][unit_state]
				--			If animation for this state does not exist then set it to idle
				if(anim == nil) then
					say_all(AI[ID].type.." had no vehicle for state "..unit_state)
					anim = BIPEDS[AI[ID].type][0]
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
				if min_distance > ai_deletion_distance and AI[ID].vehicle ~= nil then
					destroy_object(AI[ID].vehicle)
				else
					--			Check if the biped has a vehicle assigned to it
					if(AI[ID].vehicle == nil) then
						SpawnVehicle(ID, anim)
					end
					--		Sync vehicle animations with biped's
					local vehicle_object = get_object_memory(AI[ID].vehicle)
					if vehicle_object ~= 0 then
						local name = GetName(vehicle_object)
						if(anim ~= nil and name ~= ai_dir..AI[ID].type..veh_dir..anim and (ignore_rate or second_count%ai_animation_rate == 0)) then
							destroy_object(AI[ID].vehicle)
							SpawnVehicle(ID, anim)
							vehicle_object = get_object_memory(AI[ID].vehicle)
						end
						
						--	Sync vehicle coordinates with biped's
						if AI[ID].x_vel ~= 0 or AI[ID].y_vel ~= 0 then
							write_bit(vehicle_object + 0x10, 5, 0)		--	make vehicle not stationary
							write_vector3d(vehicle_object + 0x68, AI[ID].x_vel, AI[ID].y_vel, AI[ID].z_vel)	--	sync velocities
						end
						write_vector3d(vehicle_object + 0x74, AI[ID].yaw, AI[ID].pitch, 0)	--	sync rotation
						if NO_VELOCITY_STATES[unit_state] ~= nil then	--	sync locations for states where biped usually doesn't move
							write_vector3d(vehicle_object + 0x5C, AI[ID].x, AI[ID].y, AI[ID].z)
						end
						
						--Set biped health depending on player count
						if dynamic_ai_health and AI[ID].time_alive == 100 then
							local player_count = get_var(0, "$pn")
							write_float(biped_object + 0xE0, 1.0 + (player_count - 1)*dynamic_ai_health_multiplier)
							--rprint(1, player_count..", health = ".. 1.0+player_count*0.1)
						end
					else
						--	For some reason some of the vehicles get this, dunno how to fix yet
						--	Actually, this doesn't happen often so I'll just leave it like this
						SpawnVehicle(ID, anim)
					end
				end
			end
		else
		--					If biped does not exist any more
			RemoveBiped(ID, biped_object)
		end
	end

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

function RemoveBiped(ID, biped_object)--	Remove dead/non-existent biped and spawn dead weapon
	if AI[ID].vehicle ~= nil then
		destroy_object(AI[ID].vehicle)
	end
	if biped_object ~= 0 then
		GetDamagerID(ID, biped_object)
	end
	if(AI[ID].x ~= nil and AI[ID].y ~= nil and AI[ID].pitch ~= nil) then
		--	Spawn a weapon that fakes biped death (could use a vehicle as well I guess)
		local dead_zombie = spawn_object("weap", ai_dir..AI[ID].type..dead_tag,  AI[ID].x, AI[ID].y, AI[ID].z, GetYaw(ID))
		--	Set player stats
		if(AI[ID].damage_causer ~= nil) then
			if(player_alive(AI[ID].damage_causer)) then
				local PlayerIndex = AI[ID].damage_causer
				if(PLAYERS[PlayerIndex]~= nil and PLAYERS[PlayerIndex].kills ~= nil) then
					PLAYERS[PlayerIndex].kills = PLAYERS[PlayerIndex].kills + 1
					PLAYERS[PlayerIndex].score = PLAYERS[PlayerIndex].score + BIPEDS[AI[ID].type].score
				end
			end
		end
	end
	--destroy_object(ID)
	timer(1000, "destroy_object", ID)
	AI[ID] = nil
end

function SpawnVehicle(ID, anim)
	AI[ID].vehicle = spawn_object("vehi", ai_dir..AI[ID].type..veh_dir..anim, AI[ID].x, AI[ID].y, AI[ID].z, GetYaw(ID))
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	timer(0, "ObjectCheck", ID, MetaID)
end

function CheckBiped(ID, MetaID)
	for biped, data in pairs (BIPEDS) do
		if data.id == tonumber(MetaID) then
			if AI[ID] == nil then
				if #AI > ai_max then
					destroy_object(ID)
					return false
				else
					AI[ID] = {}
					AI[ID].time_alive = 0
					AI[ID].type = biped
					--say_all("biped spawned! "..biped)
				end
			end
			return false
		end
	end
end

function ObjectCheck(ID, MetaID)
	if(ID == nil) then 
		return true 
	end
	ID = tonumber(ID)
	local object = get_object_memory(ID)
	
	if(object ~= 0) then
		if(read_word(object + 0xB4) == 0) then
			CheckBiped(ID, MetaID)
		end
	end
end

function DebugStuff()
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
					projectile_count = scenery_count + 1
				elseif(object_type == 3) then
					equipment_count = equipment_count + 1
				end
			end
		end
		ClearConsole(debug_person)
		rprint(debug_person, "|rBipeds "..biped_count)
		rprint(debug_person, "|rVehicles "..vehicle_count)
		rprint(debug_person, "|rWeapons "..weapon_count)
		rprint(debug_person, "|rProjectiles "..projectile_count)
		--rprint(debug_person, "|rEquipment "..equipment_count)
		--rprint(debug_person, "|rSynced objects "..biped_count + vehicle_count + weapon_count + equipment_count)
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
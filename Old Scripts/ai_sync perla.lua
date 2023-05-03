--	AI synchronization and zombie mode by aLTis (altis94@gmail.com)
--	This script is work in progress, expect crashes

--	This script will only work on maps that were made to be used with this script
--	It will not work on your shitty blood gulch with ai

--	CONFIG

--BIPEDS
	tag_directory= "characters\\floodcombat_human\\"	--where all of your biped tags are.
	biped        = tag_directory.."floodcombat_human" 	--the biped you want to sync
	dead_weapon  = tag_directory.."dead_zombie" 		--weapon that will be used to fake a dead biped

	-- Biped animation state and corresponding vehicle tag. The comments tell you which animations those are
	BIPED_ANIMATION_STATE = {
		[0] = "flood_vehicle",    			--idle
		[4] = "flood_vehicle walking",  	--walking
		[20]= "flood_vehicle leap_airborne",--airborne
		[21]= "flood_vehicle",  			--land_soft
		[22]= "flood_vehicle",  			--land_hard
		[23]= "flood_vehicle",    			--ping
		[24]= "flood_vehicle kill_back", 	--airborne dead
		[25]= "flood_vehicle kill_back", 	--dead
		[30]= "flood_vehicle melee",  		--melee
		[31]= "flood_vehicle melee",  		--melee airborne
		[34]= "flood_vehicle resurrect", 	--resurrect front
		[35]= "flood_vehicle resurrect", 	--resurrect back
		[39]= "flood_vehicle leap_start", 	--leap start
		[40]= "flood_vehicle leap_airborne",--leap airborne
		[41]= "flood_vehicle melee", 		--leap melee
	}
	
	ai_max = 100 
	--	After this time the biped will be removed (seconds)
	ai_life_time = 420 * 30
	--	Distance that AI must be away from the player in order to get deleted (world units)
	ai_deletion_distance = 20
	
--	END OF CONFIG

api_version = "1.9.0.0"

AI              = {}


function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	if(lookup_tag("weap", dead_weapon) ~= 0) then
		register_callback(cb["EVENT_TICK"],"OnTick")
	end
end


function OnScriptUnload()--	Remove all AI on unload (we don't need invisible AI)
	for ID, info in pairs (AI) do
		destroy_object(ID)
		if(AI[ID]["vehicle"] ~= nil) then
			destroy_object(AI[ID]["vehicle"])
		end
	end
end

function OnGameStart()
	if(lookup_tag("weap", dead_weapon) ~= 0) then
		register_callback(cb["EVENT_TICK"],"OnTick")
	else
		unregister_callback(cb["EVENT_TICK"])
	end
end

function OnTick()
	--	Uncomment these 2 lines if your AI doesn't move
	--	Make sure host is always on bsp 0 since path finding doesn't work on others
	--execute_command("switch_bsp 0")
	--execute_command("object_destroy d")
	
	--*****************************************	AI SYNC STUFF!	**************************************************************
	
	--	Go through all of the bipeds that are in the AI table
	for ID, info in pairs (AI) do
	
		local biped_object = get_object_memory(ID)

		if(AI[ID] ~= nil and biped_object ~= 0) then	--			Read biped info
			if(read_float(biped_object + 0xE0) < 0.01) then --			If biped is dead
				RemoveBiped(ID, biped_object)
			else 
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
end

function RemoveBiped(ID, biped_object)--	Remove dead/non-existent biped and spawn dead weapon
	destroy_object(ID)
	if(AI[ID]["vehicle"] ~= nil) then
		destroy_object(AI[ID]["vehicle"])
	end
	if(AI[ID]["x"] ~= nil and AI[ID]["y"] ~= nil and AI[ID]["pitch"] ~= nil) then
		--	Spawn a weapon that fakes biped death (could use a vehicle as well)
		local dead_zombie = spawn_object("weap", dead_weapon,  AI[ID]["x"], AI[ID]["y"], AI[ID]["z"], GetYaw(ID))
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
			AI[ID] = {}
			AI[ID]["time_alive"] = 0
		end
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
 
    return finalAngle
end




	
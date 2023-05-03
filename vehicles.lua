api_version = "1.10.1.0"

--CONFIG
	default_vehicle = "shadow"	--	vehicle that players will spawn with by default
	explosion_projectile = "" -- for now this will not work. you need to create a new invisible projectile and make its creation effect look like an explosion.
	--							then just put the tag location of it in here and when you die in a vehicle it will explode!
	
	--	list of all vehicles is in this table. you can just add more and the script will still work just fine
	VEHICLES = {
		["shadow"] = "altis\\crashday\\judge\\judge",
		["crimsonfury"] = "twisted_metal\\vehicles\\_v2\\crimsonfury\\crimsonfury",
		["junkyarddog"] = "twisted_metal\\vehicles\\_v2\\junkyarddog\\junkyarddog",
		["crazy8"] = "twisted_metal\\vehicles\\_v2\\crazy8\\crazy8",
		["roadkill"] = "twisted_metal\\vehicles\\interceptor\\interceptor",
		["outlaw"] = "twisted_metal\\vehicles\\outlaw\\outlaw",
		["outback"] = "twisted_metal\\vehicles\\komatsu\\komatsu",
		["manslaughter"] = "twisted_metal\\vehicles\\primeval\\primeval",
		["kamikaze"] = "twisted_metal\\vehicles\\_v2\\kamikaze\\kamikaze",
		["roadboat"] = "twisted_metal\\vehicles\\_v2\\roadboat\\roadboat",
		["881077"] = "twisted_metal\\vehicles\\aventador\\aventador",
	}
--END OF CONFIG

VEHICLE_CHOICES = {}	--	what vehicle each player chose is stored here
COORDINATES = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
    register_callback(cb['EVENT_SPAWN'],"OnSpawn")
    register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_DIE'],"OnPlayerDeath")
	register_callback(cb['EVENT_LEAVE'],"OnPlayerLeave")
	register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
	
	for i=1,16 do	--	use loops so you don't have to rewrite script for each player
		VEHICLE_CHOICES[i] = default_vehicle
		COORDINATES[i] = {} --	a table as table value. each player will have x, y and z coordinate
	end
end

function OnScriptUnload()
end

function resetCharacters(PlayerIndex)
	VEHICLE_CHOICES[PlayerIndex] = default_vehicle
end

function OnCommand(PlayerIndex,Command,Environment,Password)
	if(player_present(PlayerIndex)) then
		Command = string.lower(Command)
		if(Command == "characters") then
			say(PlayerIndex, "Crimson Fury, Junkyard Dog, Crazy 8")
			say(PlayerIndex, "Roadkill, Outlaw, Outback")
			say(PlayerIndex, "Manslaughter, Kamikaze, Roadboat")
			say(PlayerIndex, "Shadow")
			return false	--	return false if command completed successfully
		end
		for name,tag in pairs (VEHICLES) do	--	in pairs is a very powerful thing. use it to go through all of the items in a table
			if Command == name then
				say(PlayerIndex, "You will respawn as "..name)
				VEHICLE_CHOICES[PlayerIndex] = name
				return false	--	return false if command completed successfully
			end
		end
	end
	return true	--	return true if you didn't execute any of these commands
end

function OnPlayerDeath(PlayerIndex)
	execute_command("w8 5")
	execute_command("w8 5;vdel "..PlayerIndex)
	--	spawn projectile which will explode. this might seemt too hard for you :v
	if COORDINATES[PlayerIndex]["x"] ~= nil then
		spawn_object("proj", explosion_projectile, COORDINATES[PlayerIndex]["x"], COORDINATES[PlayerIndex]["y"], COORDINATES[PlayerIndex]["z"] + 0.1)
	end
end

function OnPlayerLeave(PlayerIndex)
	execute_command("w8 1;vdel "..PlayerIndex)
end

function vehicleSpawn(PlayerIndex)
	--say(PlayerIndex, "Getcha ass together boy!")
	PlayerIndex = tonumber(PlayerIndex)	--	values passed by "timer" command turn into strings. use tonumber to change them back to numbers
	if player_present(PlayerIndex) then
		execute_command("m "..PlayerIndex.." 0 0 0.4")
		execute_command("spawn vehi "..VEHICLES[VEHICLE_CHOICES[PlayerIndex]].." "..PlayerIndex) 
		execute_command("venter "..PlayerIndex)
	end
end

function OnSpawn(PlayerIndex, MapID, ParentID, ObjectID)
	timer(33, "vehicleSpawn", PlayerIndex)	--	Seems like using a timer here fixes the camera glitch
end

function OnPlayerJoin(PlayerIndex)
	timer (1000, "test", PlayerIndex)
end

function test(PlayerIndex)
	resetCharacters(PlayerIndex) --	sets default vehicle for the new player
	say(PlayerIndex, "Welcome to Twisted Metal.")
	say(PlayerIndex, "Select your vehicle using /characters")
	--execute_command("spawn vehi altis\\crashday\\judge\\judge "..PlayerIndex) 
	--execute_command("venter "..PlayerIndex)
	--cprint("OnPlayerJoin successfully completed!", 3)
end

function OnTick()
	for i=1,16 do
		if player_alive(i) then
			local player = get_dynamic_player(i)
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 then
				COORDINATES[i]["x"], COORDINATES[i]["y"], COORDINATES[i]["z"] = read_vector3d(vehicle + 0x5C)--	read player's coordinates
			else
				COORDINATES[i]["x"] = nil
			end
		end
	end
end
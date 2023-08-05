--CONFIG
	mapvote_count = 7
	
	VEHICLE_TAGS = {
		["falcon"] = "vehicles\\falcon\\falcon",
		["katyusha"] = "altis\\vehicles\\truck_katyusha\\truck_katyusha",
		["scorpion"] = "altis\\vehicles\\scorpion\\scorpion",
		["rocket_hog"] = "bourrin\\halo reach\\vehicles\\warthog\\rocket warthog",
		["mortargoose"] = "altis\\vehicles\\mortargoose\\mortargoose_no_target",
		["bulldog"] = "vehicles\\bulldog\\bulldog",
		["football"] = "forge\\vehicles\\football\\football",
	}
--END_OF_CONFIG

api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	--register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
	--register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	--OnGameStart()
end

function OnGameStart()
	if get_var(0, "$mode") == "team_slayer_night" then
		timer(0, "SetTOD", 1)
	elseif get_var(0, "$mode") == "team_king_snow" then
		timer(0, "SetTOD", 2)
	elseif get_var(0, "$mode") == "vehicle_madness" then
		timer(0, "SetTOD", 2)
		timer(0, "VehicleMandess")
	end
end

function OnPlayerJoin()
	timer(1000, "OnGameEnd")
end

function OnGameEnd()
	--Add or remove forge maps based on whether all players have Chimera
	if CheckChimera() then
		execute_command("mapvote_del "..mapvote_count)
		execute_command("mapvote_del "..mapvote_count+1)
		execute_command("mapvote_del "..mapvote_count+2)
		execute_command("mapvote_del "..mapvote_count+3)
		execute_command("mapvote_del "..mapvote_count+4)
		execute_command("mapvote_del "..mapvote_count+5)
		execute_command("mapvote_add bigass_v3 forkball Forkball 1 8")
		execute_command("mapvote_add bigass_v3 autumn \"Autumn Slayer\" 1 16")
		execute_command("mapvote_add bigass_v3 tropical \"Tropical CTF\" 1 16")
	else
		execute_command("mapvote_del "..mapvote_count)
		execute_command("mapvote_del "..mapvote_count+1)
		execute_command("mapvote_del "..mapvote_count+2)
		execute_command("mapvote_del "..mapvote_count+3)
		execute_command("mapvote_del "..mapvote_count+4)
		execute_command("mapvote_del "..mapvote_count+5)
	end
	return false
end

function VehicleMandess()
	execute_command("object_create_containing a")
	spawn_object("vehi", VEHICLE_TAGS.falcon, 8, -45, 6, math.rad(110))
	spawn_object("vehi", VEHICLE_TAGS.falcon, -10, 85, 13, math.rad(-90))
	spawn_object("vehi", VEHICLE_TAGS.scorpion, 11, -8, 1, math.rad(-90))
	spawn_object("vehi", VEHICLE_TAGS.katyusha, 126, -74, 6, math.rad(70))
	spawn_object("vehi", VEHICLE_TAGS.katyusha, -154, 88, 9, math.rad(-130))
	spawn_object("vehi", VEHICLE_TAGS.football, 10, -26, 30)
	spawn_object("vehi", VEHICLE_TAGS.mortargoose, 176.8, 95.28, 6.52, math.rad(-90))
	spawn_object("vehi", VEHICLE_TAGS.rocket_hog, 174, 95.5, 7, math.rad(90))
	spawn_object("vehi", VEHICLE_TAGS.mortargoose, -141, 6.2, 2.3, math.rad(150))
	spawn_object("vehi", VEHICLE_TAGS.rocket_hog, -134, 6.6, 3, math.rad(-90))
	spawn_object("vehi", VEHICLE_TAGS.bulldog, -77, -32, 1.1, math.rad(90))
	spawn_object("vehi", VEHICLE_TAGS.bulldog, 81.5, 28, 0.7, math.rad(-150))
	spawn_object("vehi", VEHICLE_TAGS.mortargoose, -40, -2.7, 1, math.rad(-90))
	spawn_object("vehi", VEHICLE_TAGS.mortargoose, 41, 7.5, 0.4, math.rad(-30))
	spawn_object("vehi", VEHICLE_TAGS.rocket_hog, 72, -17, 5.6)
	
	timer(3100, "DestroyHay")
end

function DestroyHay()
	execute_command("object_destroy_containing hay")
end

function SetTOD(tod)
	execute_command("set tod "..tod)
	return false
end

function CheckChimera()
	for i=1,16 do
		if player_present(i) and get_var(i, "$has_chimera") == "0" then
			return false
		end
	end
	if get_var(0, "$pn") == "0" then
		return false
	end
	return true
end

function OnScriptUnload() 

end
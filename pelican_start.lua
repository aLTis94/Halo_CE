--	Pelican start script by altis (altis94@gmail.com)
--	This script will put players inside a peican on ctf (only works on specific maps like tsce mp)

--CONFIG
	pelican_vehicle = "altis\\vehicles\\pelican_drop\\pelican"
	pelican_weapon = "altis\\vehicles\\pelican_drop\\cmt\\pelican"
	--	x y z rotation (in radians)
	red_team_location = {-121.552,-59.8537,0.86082, 0}
	blue_team_location = {1,2,3,20}
	
	players_vexit_time = 20--	players are dropped after this time
	enable_damage_time = 10--	players can't be damaged after dropping for this time
	pelican_life_time = 40--	pelican object is removed after this time
	
--END OF CONFIG

api_version = "1.9.0.0"

RED_PELICAN_ID = nil
BLUE_PELICAN_ID = nil
kill_players_on_leave = false
disable_damage = false
i_have_no_idea_how_to_call_this = false

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	CheckGametypeAndStuff()
end

function OnGameStart()
	CheckGametypeAndStuff()
	
	if(i_have_no_idea_how_to_call_this) then
		RED_PELICAN_ID = spawn_object("vehi", pelican_vehicle, red_team_location[1], red_team_location[2], red_team_location[3], red_team_location[4])
		BLUE_PELICAN_ID = spawn_object("vehi", pelican_vehicle, blue_team_location[1], blue_team_location[2], blue_team_location[3], blue_team_location[4])
		spawn_object("weap", pelican_weapon, blue_team_location[1], blue_team_location[2], blue_team_location[3], blue_team_location[4])
		spawn_object("weap", pelican_weapon, red_team_location[1], red_team_location[2], red_team_location[3], red_team_location[4])
		timer(pelican_life_time*1000, "RemovePelicans")
		timer(players_vexit_time*1000, "DropPlayers")
		kill_players_on_leave = true
		disable_damage = true
	end
end

function CheckGametypeAndStuff()
	safe_read = true
	if(get_var(0, "$gt") == "ctf" and lookup_tag("weap", pelican_weapon) ~= 0) then
		i_have_no_idea_how_to_call_this = true
		register_callback(cb['EVENT_SPAWN'], "OnPlayerSpawn")
		register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
		register_callback(cb['EVENT_DAMAGE_APPLICATION'], "OnDamage")
	else
		unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_VEHICLE_EXIT'])
		unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
		i_have_no_idea_how_to_call_this = false
	end
	safe_read = false
end

function OnVehicleExit(PlayerIndex)
	if(kill_players_on_leave) then
		kill(PlayerIndex)
	end
end

function OnDamage()
	if(disable_damage) then
		return false
	end
	return true
end

function RemovePelicans()
	destroy_object(RED_PELICAN_ID)
	RED_PELICAN_ID = nil
	destroy_object(BLUE_PELICAN_ID)
	BLUE_PELICAN_ID = nil
end

function DropPlayers()
	kill_players_on_leave = false
	for i = 1,16 do
		exit_vehicle(i)
	end
	timer(enable_damage_time*1000, "EnableDamage")
end

function EnableDamage()
	say_all("damage enabled")
	disable_damage = false
end

function OnPlayerSpawn(PlayerIndex)
	if(not(kill_players_on_leave)) then
		return false
	end
	
	player_object = get_dynamic_player(PlayerIndex)
	
	if(get_var(PlayerIndex, "$team") == "red") then
		if(RED_PELICAN_ID ~= nil) then
			for i = 0,9 do
				enter_vehicle(RED_PELICAN_ID, PlayerIndex, i) 
				if(read_word(player_object + 0x2F0) ~= 0xFFFF) then
					break
				end
			end
		end
	else
		if(BLUE_PELICAN_ID ~= nil) then
			for i = 0,9 do
				enter_vehicle(BLUE_PELICAN_ID, PlayerIndex, i) 
				rprint(PlayerIndex, i)
				if(read_word(player_object + 0x2F0) ~= 0xFFFF) then
					rprint(PlayerIndex, "You were seated")
					break
				end
			end
		end
	end
end

function OnScriptUnload()
	
end
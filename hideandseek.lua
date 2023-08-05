-- 	Made by aLTis (altis94@gmail.com)

--	This script is kind of a hide and seek game mode, similar to the one in gmod

--CONFIG
	
	debug_mode = false
	
	console_messages = true		--Enables console messages
	console_message_rate = 1	--How often console messages will update (in seconds)
	
	--	If true then the script will only work on game_mode_name gametype
	--	If false then it will work on any gametype. This may cause issues on incorrect gametypes
	game_mode_required = true
	game_mode_name = "altis_ts_nr"	--This script will only work on this game mode
	
	
	remove_hider_bodies = true
	remove_hider_body_delay = 500 --In ticks. Increase if bodies don't disappear
	catch_distance = 0.7	--Players need to be this close from each other in order to catch (in world units)
	seeker_blind_time = 25	--How long seeker cannot do anything to let hiders hide (in seconds)
	game_start_delay = 8	--Game will start after this delay (in seconds)
	
	round_count = 3			--How many rounds until game over
	round_time = 240		--Round time (in seconds)
	
	--	Where seeker will be teleported when they are blinded
	x = 1000
	y = 1000
	z = 1000
	
	--	Player speed multipliers (1.0 is default)
	--	Note that red team is hiders and blue team is seekers!
	red_speed = 1.0
	blue_speed = 1.2
	
	--	Hider boosts
	camo_time = 10
	boost_time = 4
	boost_speed = 1.7
	
	--	How much score players get
	red_score = 3
	blue_score = 1
	
--	GEOLOCATION
	--	This uses giraffe's geolocation script to see where the player is from
	--	And to change language automatically
	--	In order to use this, you need to download and put these in your hce folder:
	--	http://downloads.sourceforge.net/gnuwin32/wget-1.11.4-1-dep.zip
	--	https://eternallybored.org/misc/wget/releases/wget-1.16.3-win32.zip
	
	--	Do you have the files and want to use this feature?
	use_geolocation = false
	
	--	Which language to use if geolocation is disabled?
	--	0 is English, 1 is Spanish
	default_language = 0
	
	--	Countries which will get Spanish messages
	spanish_speaking_countries = {"argentina", "bolivia", "chile", "colombia", "costa rica", "cuba", "dominican republic", "ecuador", "equatorial guinea", "el salvador", "guatemala", "honduras", "mexico", "nicaragua", "panama", "paraguay", "puerto rico", "spain", "uruguay", "venezuela"}
	
	english_messages = {"Hiders won!", "Seekers won!", " was caught by ", "Waiting for more players...", " is the seeker!", "Seekers have been released!", " died and was switched!", "This is Hide and Seek gametype", "Catch other players to win!"}
	
	spanish_messages = {"Ganaron los evasores!", "Ganaron los buscadores!", " fue atrapado por ", "Esperando mas jugadores...", " es el buscador!", "Se a liberado a los buscadores!", " Murio y cambio de equipo!", "Estas son las escondidas", "Atrapa otros jugadores para ganar!"}
	
	color_blue = "|nc5353ff"
	color_red = "|ncff5353"
	
--	END OF CONFIG



api_version = "1.9.0.0"

rounds = 0
current_round_time = round_time * 30
message_time = 0
last_caught = 0
player_locations = {}
player_country = {}
boost = {}
camo = {}
game_started = false
game_was_started = false
round_started = false
game_over = false
delay = 10

function say_all_languages(var1, message, var2)
	if(var1 == nil) then
		var1 = ""
	end
	if(var2 == nil) then
		var2 = ""
	end
	
	if(tonumber(var1) ~= nil and tonumber(var1) >= 0 and tonumber(var1) <= 16) then
		if(player_country[var1] == 1) then
			say(var1, spanish_messages[message]..var2)
		else
			say(var1, english_messages[message]..var2)
		end
	else
		for i = 1,16 do
			if(player_present(i)) then
				if(player_country[i] == 1) then
					say(i, var1..spanish_messages[message]..var2)
				else
					say(i, var1..english_messages[message]..var2)
				end
			end
		end
	end
end

function OnScriptLoad()
	if(debug_mode) then
		game_start_delay = 1
		round_time = 50
		seeker_blind_time = 2
		round_count = 10
		boost_time = 30
	end
	disable_killmsg_addr = sig_scan("8B42348A8C28D500000084C9")	+ 3
	original_code_1 = read_dword(disable_killmsg_addr)
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	
	for i = 1,16 do
		player_country[i] = default_language
	end
	
	CheckGameMode()
end

function OnScriptUnload()
	execute_command("disable_all_objects 0 0")
	execute_command("disable_sj 0")
	execute_command("block_tc 0")
	
	safe_write(true)
	write_dword(disable_killmsg_addr, original_code_1)
	safe_write(false)
end

function OnGameStart()
	CheckGameMode()
end

function OnGameEnd()
	game_over = true
	game_started = false
end

function CheckGameMode()
	if(game_mode_required == false or get_var(0, "$mode") == game_mode_name) then
		rounds = 0
		game_started = false
		game_over = false
		game_was_started = true
		player_locations = {}
	
		execute_command("disable_all_objects 0 1")
		execute_command("disable_all_objects 1 1")
		execute_command("disable_all_vehicles 0 1")
		execute_command("disable_all_vehicles 1 1")
		execute_command("disable_sj 1")
		execute_command("block_tc 1")
		
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		
		say_all("Game will start in "..game_start_delay.." seconds")
		timer(game_start_delay * 1000, "StartRound")
		
		-- suppress halo's death messages (from H® Shaft)
		safe_write(true)
		write_dword(disable_killmsg_addr, 0x03EB01B1)
		safe_write(false)
	else
		
		if game_was_started then
			timer(3500, "BalanceTeams")
			execute_command("disable_all_objects 0 0")
			execute_command("disable_all_objects 1 0")
			execute_command("disable_all_vehicles 0 0")
			execute_command("disable_all_vehicles 1 0")
			execute_command("disable_sj 0")
			execute_command("block_tc 0")
		end
		
		game_was_started = false
		
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_SPAWN'])
		unregister_callback(cb['EVENT_GAME_END'])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_DIE'])
		
		safe_write(true)
		write_dword(disable_killmsg_addr, original_code_1)
		safe_write(false)
	end
end

function BalanceTeams()
	if get_var(0, "$ffa") == 1 then return end
	
	local RED_PLAYERS = {}
	local BLUE_PLAYERS = {}
	local red_count = 0
	local blue_count = 0
	for i=1,16 do
		if player_present(i) then
			local team = get_var(i, "$team")
			if team == "red" then
				RED_PLAYERS[i] = true
				red_count = red_count + 1
			else
				BLUE_PLAYERS[i] = true
				blue_count = blue_count + 1
			end
		end
	end
	
	local difference = math.floor((red_count - blue_count)/2)
	if difference > 0 then -- more reds
		for i,j in pairs (RED_PLAYERS) do
			if difference > 0 then
				execute_command("st "..i.." blue")
			end
			difference = difference-1
		end
		say_all("Teams were balanced!")
	elseif difference < 0 then -- more blues
		for i,j in pairs (BLUE_PLAYERS) do
			if difference < 0 then
				execute_command("st "..i.." red")
			end
			difference = difference+1
		end
		say_all("Teams were balanced!")
	end
end

function StartRound()
	if(game_over or game_started or round_started) then
		return false
	end
	
	if(rounds == round_count) then
		execute_command("sv_map_next")
		return false
	end
	
	delay = delay - 1
	--	Check if there are enough players for a game
	if(tonumber(get_var(0, "$pn")) < 2) then
		
		if(delay == 0) then
			say_all_languages(nil, 4)
			delay = 10
		end
		return true
	end
	
	--if rounds ~= 0 and rounds < round_count then
	--	PlayAnnouncerSound(1)
	--end
	
	round_started = true
	rounds = rounds + 1
	timer(1000, "say_all", "Round "..rounds)
	timer(1000 * seeker_blind_time, "StartGame")
	current_round_time = round_time * 30
	
	
	--	Switch all players to red team
	for i = 1,16 do
		if(player_present(i)) then
			if(get_var(i, "$team") == "blue") then
				ChooseTeam(i, 0)
			elseif(player_alive(i)) then
				kill(i)
				execute_command("deaths "..i.." -1")
			end
		end
	end
	
	--	Choose seeker and switch their team to blue
	--	If there is a player who was caught last, they will be the seeker
	--	Otherwise a random player will be chosen
	if(player_present(last_caught)) then
		ChooseTeam(last_caught, 1)--todo	Change to ChooseTeam???
	else
		while (1) do
			local random_player = rand(1,16)
			if(player_present(random_player)) then
				ChooseTeam(random_player, 1)
				last_caught = random_player
				break
			end
		end
	end
	say_all_languages(get_var(last_caught, "$name"), 5)
	last_caught = 0
	return false
end

--	Release the seekers
function StartGame()
	if(game_over or tonumber(get_var(0, "$pn")) < 2 or game_started) then
		round_started = false
		return false
	end
	
	PlayAnnouncerSound(31)
	
	say_all_languages(nil, 6)
	round_started = false
	game_started = true
	for i=1,16 do
		if(get_var(i, "$team") == "blue" and player_alive(i) ~= false) then
			kill(i)
			execute_command("deaths "..i.." -1")
		else
			boost[i] = 1
			camo[i] = 1
		end
	end
end

function OnPlayerJoin(PlayerIndex)
	if(use_geolocation) then
		player_country[PlayerIndex] = 0
		local location = string.lower(get_geolocation(get_var(PlayerIndex,'$ip'):split(':')[1]))
		if(location ~= nil) then
			for i=1,#spanish_speaking_countries do
				if(string.find(location, spanish_speaking_countries[i]) ~= nil) then
					player_country[PlayerIndex] = 1
					break
				end
			end
		end
	end
	
	if(tonumber(get_var(0, "$pn")) == 2) then
		StartRound()
		return
	end
	
	if(game_started and tonumber(get_var(0, "$reds")) ~= 0) then
		--say_all("switched to blue")
		timer(0, "ChooseTeam", PlayerIndex, 1)--todo	Check if game has started???
	else
		--say_all("Switched to red")
		timer(0, "ChooseTeam", PlayerIndex, 0)
	end
	say_all_languages(PlayerIndex, 8)
	say_all_languages(PlayerIndex, 9)
end

function OnPlayerSpawn(PlayerIndex)
	if(player_locations[PlayerIndex] ~= nil) then
		timer(33, "MovePlayer", PlayerIndex)
	end
	boost[PlayerIndex] = 0
	camo[PlayerIndex] = 0
end

function ChangeSpeed(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	player = get_player(PlayerIndex)
	if(player_present(PlayerIndex)) then
		local player_speed = read_float(player + 0x6C)
		
		if(get_var(PlayerIndex, "$team") == "red") then
			if((red_speed - player_speed) > 0.02) then
				write_float(player + 0x6C, red_speed)
			end
		else
			if((blue_speed - player_speed) > 0.02) then
				write_float(player + 0x6C, blue_speed)
			end
		end
	end
	return false
end

function ResetSpeed(PlayerIndex) --	Used to reset player's speed after boost
	PlayerIndex = tonumber(PlayerIndex)
	player = get_player(PlayerIndex)
	
	if(player_present(PlayerIndex)) then
		write_float(player + 0x6C, red_speed)
	end
end

--	Teleport a switched player to the location where he was caught
function MovePlayer(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	
	if(player_alive(PlayerIndex)) then
		local player_object = get_dynamic_player(PlayerIndex)
		if(player_object == 0) then
			say_all("Player was unable to be moved")
			return false
		end
		write_vector3d(player_object + 0x5C, player_locations[PlayerIndex].x, player_locations[PlayerIndex].y, player_locations[PlayerIndex].z)
		
		player_locations[PlayerIndex] = nil
	else
		return true
	end
	return false
end

-- Move player to x y z location
function BlindPlayer(PlayerIndex)
	local player_object = get_dynamic_player(PlayerIndex)
	if(player_object ~= 0) then
		write_vector3d(player_object + 0x5C, x, y, (z + PlayerIndex*3))
		write_vector3d(player_object + 0x68, 0, 0, 0)
	end
end

--	If hider died from fall damage or other reasons, they will be switched
function OnPlayerDeath(PlayerIndex)
	timer(0, "HaloIsDumb", PlayerIndex)
end

function HaloIsDumb(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	if(game_started and get_var(PlayerIndex, "$team") == "red") then
		say_all_languages(get_var(PlayerIndex, "$name"), 7)
		last_caught = PlayerIndex
		ChooseTeam(PlayerIndex, 1)
		PlayAnnouncerSound(30)
	end
end

function ChooseTeam(PlayerIndex, team)
	PlayerIndex = tonumber(PlayerIndex)
	team = tonumber(team)
	if(player_present(PlayerIndex)) then
		write_byte(get_player(PlayerIndex) + 0x20, team)
		if(player_alive(PlayerIndex)) then
			kill(PlayerIndex)
			execute_command("deaths "..PlayerIndex.." -1")
		end
	end
end

--	Where magic happens
function OnTick()
	-- testing only
	if false then
		for i=1,16 do
			if(player_alive(i) == true) then 
				player = get_dynamic_player(i)
				rprint(i, player)
				--rprint(i, read_bit(player + 0x10, 3))
			end
		end
	end
	
	if(game_over) then
		return false
	end
	
	--	Check if there are enough players for a game
	if(tonumber(get_var(0, "$pn")) < 2) then
		rounds = 0
		current_round_time = round_time * 30
		game_started = false
		round_started = false
		return false
	end
	
	current_round_time = current_round_time - 1
	message_time = message_time + 1
	if(message_time > console_message_rate*30) then
		message_time = 0
	end
	
	--	Move seekers out of the map and print console messages
	if(game_started == false) then
	
		if release_timer ~= nil and release_timer > 1 and release_timer < 11 and current_round_time%30 == 5 then
			PlayAnnouncerSound(29)
		end
	
		if(tonumber(get_var(0, "$reds")) == 0) then
			while (1) do
				local random_player = rand(1,16)
				if(player_present(random_player)) then
					ChooseTeam(random_player, 0)
					say_all("Random player was made hider!")
					break
				end
			end
		end
		if(tonumber(get_var(0, "$blues")) == 0 and round_started == true) then
			while (1) do
				local random_player = rand(1,16)
				if(player_present(random_player)) then
					ChooseTeam(random_player, 1)--todo 	Change st to choose team???
					last_caught = random_player
					say_all_languages(get_var(random_player, "$name"), 5)
					break
				end
			end
		end
		for i=1,16 do
			if(player_alive(i) == true) then 
				ChangeSpeed(i)
				if(boost[i] == nil or camo[i] == nil) then
					boost[i] = 0
					camo[i] = 0
				end
			
				if(console_messages and message_time == 0) then
					ClearConsole(i)
				end
				release_timer = seeker_blind_time - round_time + 1 + math.floor(current_round_time/30)
				
				if(get_var(i, "$team") == "blue") then
					BlindPlayer(i)
					
					if(release_timer > 0 and console_messages and message_time == 0) then
						if(player_country[i] == 1) then
							rprint(i, "|rSeras liberado en "..release_timer..color_blue)	
							rprint(i, "|rTu eres un buscador"..color_blue)
							rprint(i, "|rQuedan "..get_var(0, "$reds").." evasores"..color_blue)
						else
							rprint(i, "|rYou will be released in "..release_timer..color_blue)	
							rprint(i, "|rYou are a seeker"..color_blue)
							rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_blue)
						end
					end
				elseif(release_timer > 0 and console_messages and message_time == 0) then
					if(player_country[i] == 1) then
						rprint(i, "|rSe liberara a los buscadores en "..release_timer..color_red)	
						rprint(i, "|rTu eres un evasor"..color_red)
						rprint(i, "|rQuedan "..get_var(0, "$reds").." evasores"..color_red)
					else
						rprint(i, "|rSeekers will be released in "..release_timer..color_red)	
						rprint(i, "|rYou are a hider"..color_red)
						rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_red)
					end
				end
			elseif(player_present(i)) then
				local player = get_player(i)
				write_dword(player + 0x2C, 0)
			end
		end
		return false
	else--	game started
	
		if current_round_time/30 == 60 then
			PlayAnnouncerSound(2)
		elseif current_round_time/30 == 30 then
			PlayAnnouncerSound(3)
		end
	
		for i = 1,16 do
			--	Boosts and stuff
			if(boost[i] == nil or camo[i] == nil) then
				boost[i] = 0
				camo[i] = 0
			end
			if(player_alive(i)) then
				ChangeSpeed(i)
				local player_object = get_dynamic_player(i)
				if(boost[i] == 1 and read_bit(player_object + 0x208,6) == 1) then
					say(i, "Boost activated!")
					boost[i] = 0
					execute_command("s "..i.." ".. boost_speed)
					timer(boost_time*1000, "ResetSpeed", i)
				end
				if(camo[i] == 1 and read_bit(player_object + 0x208,7) == 1) then
					camo[i] = 0
					say(i, "Camo activated!")
					timer(1000*camo_time, "say", i, "Camo deactivated")
					execute_command("camo "..i.." ".. camo_time)
				end
				
				local time_left = math.floor(current_round_time/30)
				
				if(console_messages and message_time == 0) then
					ClearConsole(i)
					if(player_country[i] == 1) then
						if(get_var(i, "$team") == "red") then
							rprint(i, "(E) Boost: "..boost[i].."|rTiempo restante "..time_left..color_red)
							rprint(i, "(F) Camo: "..camo[i].."|rTu eres un evasor"..color_red)
							rprint(i, "|rQuedan "..get_var(0, "$reds").." evasores"..color_red)
						else
							rprint(i, "|rTiempo restante "..time_left..color_blue)
							rprint(i, "|rTu eres un buscador"..color_blue)
							rprint(i, "|rQuedan "..get_var(0, "$reds").." evasores"..color_blue)
						end
					else
						local player_speed = read_float((get_player(i)) + 0x6C)
						--rprint(i, "Your speed is "..tonumber(player_speed))
						if(get_var(i, "$team") == "red") then
							rprint(i, "(E) Boost: "..boost[i].."|rTime left "..time_left..color_red)
							rprint(i, "(F) Camo: "..camo[i].."|rYou are a hider"..color_red)
							rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_red)
						else
							rprint(i, "|rTime left "..time_left..color_blue)
							rprint(i, "|rYou are a seeker"..color_blue)
							rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_blue)
						end
					end
				end
			end
		end
	end
	
	--	Check if hiders won by reaching the time limit
	if(current_round_time == 0) then
		PlayAnnouncerSound(13)
		say_all_languages(nil, 1)
		execute_command("team_score red +1")
		for i = 1,16 do
			if(get_var(i, "$team") == "red") then
				execute_command("score "..i.." +"..red_score)
				BlindPlayer(i)
			end
		end
		game_started = false
		timer(1000, "StartRound")
		return false
	end
	
	--	Check if seekers won by catching all hiders
	if(tonumber(get_var(0, "$reds")) == 0) then
		PlayAnnouncerSound(10)
		say_all_languages(nil, 2)
		execute_command("team_score blue +1")
		game_started = false
		for i = 1,16 do
			BlindPlayer(i)
		end
		timer(1000, "StartRound")
		return false
	end
	
	if(tonumber(get_var(0, "$blues")) == 0) then
		StartRound()
		return false
	end
	
	--	Check if seekers are close enough hiders to catch them
	for i=1,16 do
		if(player_alive(i) == true) then 
			local player_object = get_dynamic_player(i)
			local x1,y1,z1 = read_vector3d(player_object + 0x5C)
			local player_team = get_var(i, "$team")
			
			if(player_team == "blue") then
				--	Go through all other alive players
				for j=1,16 do
					if(player_alive(j) and get_var(j, "$team") == "red") then
						other_player_object = get_dynamic_player(j)
						local x2,y2,z2 = read_vector3d(other_player_object + 0x5C)
						if(DistanceFormula(x1,y1,z1,x2,y2,z2) < catch_distance) then
							PlayAnnouncerSound(30)
							player_locations[j] = {}
							player_locations[j].x = x2
							player_locations[j].y = y2
							player_locations[j].z = z2
							last_caught = j
							execute_command("score "..i.." +"..blue_score)
							execute_command("deaths "..j.." +1")
							say_all_languages(get_var(j, "$name"), 3, get_var(i, "$name").."!")
							if(remove_hider_bodies) then
								BlindPlayer(j)
								timer(remove_hider_body_delay, "ChooseTeam", j, 1)
							else
								execute_command("st "..j.." blue")
							end
						end
					end
				end
			end
		elseif(player_present(i)) then
			--	If player is dead then respawn them instantly
			local player = get_player(i)
			write_dword(player + 0x2C, 0)
		end
	end	
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentObjectID, ObjectID)
	timer(33, "ObjectCheck", ObjectID)
end

--	Check if spawned object is a weapon, vehicle or equipment and remove it
function ObjectCheck(ObjectID)
	local object = get_object_memory(ObjectID)
	
	if(object ~= 0) then
		if(read_word(object + 0xB4) == 2 or read_word(object + 0xB4) == 1 or read_word(object + 0xB4) == 3) then
			destroy_object(ObjectID)
		end
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)	-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function PlayAnnouncerSound(sound_id)
	local server_announcer_address = 0x5BDE00
	write_dword(server_announcer_address + 0x8, 1) -- time until first sound in the queue stops playing
	write_dword(server_announcer_address + 0x14, sound_id) -- second sound ID in the queue (from globals multiplayer information > sounds)
	write_dword(server_announcer_address + 0x1C, 1) -- second sound in the queue will play
	write_dword(server_announcer_address + 0x50, 2) -- announcer sound queue
end

function string:split(sep)--	From giraffe
    local sep, fields = sep or ':', {}
    local pattern = string.format('([^%s]+)', sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function string:startsWith(prefix)
    return self:sub(1, string.len(prefix)) == prefix
end

function get_geolocation(IP)--	From giraffe
    if(IP:startsWith('127.') or IP:startsWith('192.168.')) then
        IP = ''
    end
    local p = assert(io.popen('wget -qO- http://ip-api.com/line/' .. IP .. '?fields=country'))
    local result = p:read('*all')
    p:close()
    if(result ~= nil) then
        return result
    end
    return nil
end

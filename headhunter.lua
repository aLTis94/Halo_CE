-- headhunter gametype by aLTis
--CONFIG
	
	-- gametypes for this script. the second variable is the score limit for that gametype
	GAMETYPES = {
		["headhunter"] = 50,
		["headhunter_ffa"] = 30,
		["headhunter_custom_ffa"] = 30,
	}
	
	welcome_message = "This is headhunter gametype!" -- this will be sent to chat
	rules_message = "Collect skulls from dead players and bring them to the hill to score" -- this will be distplayed on the console
	player_in_hill_message = "Collect skulls from dead enemies to score!" -- this is sent if a player stays in the hill for a while
	
	print_stats_to_console = true
	
	-- console colors change based on actions
	console_color_default = "|nc7FB3D5"
	console_color_holding = "|nc4dff4d"
	console_color_grabbed = "|ncFC0303"
	console_color_dropped = "|nc20FC03"
	console_color_teammate = "|nc3b7fff"
	console_color_enemy = "|ncff3b3b"
	
	skull_spread = 0.25 -- when a skull is spawned its position is slightly randomised so they wouldn't all fall in one spot
	
--END OF CONFIG

--known issues:
--picking up a skull interrupts your weapon animation
--the sound "hill controlled" only plays if a single player is in the hill


api_version = "1.12.0.0"
koth_globals = 0x5BDBD0

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	Initialize()
end

function OnScriptUnload() 
	if ball_id ~= nil then
		RemoveAllSkulls()
	end
end

function OnGameStart()
	Initialize()
end

function Initialize()
	local globals = GetGlobals()
	if GAMETYPES[get_var(0, "$mode")] ~= nil and globals ~= nil and get_var(0, "$gt") == "king" then
		ball_id = read_dword(read_dword(globals + 0x164 + 4) + 0x4C + 0xC)
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		
		PLAYER = {}
		for i=1,16 do
			PLAYER[i] = {}
			PLAYER[i].skulls = 0
			PLAYER[i].score = 0
			PLAYER[i].console_color = console_color_default
			PLAYER[i].hill_timer = 0
			PLAYER[i].display_rules_timer = 0
		end
		TEAM_SCORE = {}
		TEAM_SCORE.red = 0
		TEAM_SCORE.blue = 0
	else
		ball_id = nil
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_JOIN'])
	end
end

function OnPlayerJoin(i)
	PLAYER[i].skulls = 0
	PLAYER[i].score = 0
	PLAYER[i].display_rules_timer = 25
	say(i, welcome_message)
end

function OnPlayerDeath(i, causer)
	i = tonumber(i)
	causer = tonumber(causer)
	
	-- drop skulls
	if PLAYER[i].x ~= nil then
		local killed = 1
		if i == causer or causer < 1 or GetTeamID(i) == GetTeamID(causer) then
			killed = 0
		end
		--console(get_var(i, "$name").." (team".. got killed by "..get_var(causer, "$name"))
		
		for j=1,PLAYER[i].skulls+killed do
			math.randomseed(j*i)
			local rand1 = skull_spread * 0.5 - skull_spread * math.random()
			math.randomseed(get_var(0, "$ticks")*j)
			local rand2 = skull_spread * 0.5 - skull_spread * math.random()
			local object = spawn_object("weap", "ball", PLAYER[i].x + rand1, PLAYER[i].y + rand2, PLAYER[i].z, 0, ball_id)
		end
	end
	
	PLAYER[i].skulls = 0
end

function OnTick()
	--override "hill controlled" announcement
	write_dword(koth_globals + 0x190, 0)
	write_dword(koth_globals + 0x194, 300)
	
	for i=1,16 do
		if player_alive(i) then
			local player = get_dynamic_player(i)
			PLAYER[i].x, PLAYER[i].y, PLAYER[i].z = read_vector3d(player + 0x7C0 + 0x28) -- gets location of player's head
			RemoveSkullFromPlayer(i, player)
			PlayerInHill(i, player)
		end
	end
	
	PrintStats()
	SetScore()
	CheckIfGameOver()
end

function PrintStats()
	if print_stats_to_console then
		if get_var(0, "$ticks")%10 == 1 then
			for i=1,16 do
				if CheckArmorRoom(i) then
					ClearConsole(i)
					
					if PLAYER[i].display_rules_timer > 0 then
						rprint(i, "|c"..rules_message..console_color_default)
						PLAYER[i].display_rules_timer = PLAYER[i].display_rules_timer - 1
					else
						rprint(i, "|rENEMY:     "..console_color_default)
						for j=1,16 do
							if player_present(j) and GetTeamID(i)~=GetTeamID(j) and PLAYER[j].skulls > 0 then
								rprint(i, "|r"..get_var(j, "$name")..":   "..PLAYER[j].skulls..console_color_enemy)
							end
						end
						
						
						if get_var(0, "$ffa")=="0" and ((get_var(i, "$team")=="red" and get_var(i, "$reds")~="0") or (get_var(i, "$team")=="blue" and get_var(i, "$blues")~="0")) then
							rprint(i, "|rALLY:     "..console_color_default)
							for j=1,16 do
								if player_present(j) and GetTeamID(i)==GetTeamID(j) and i~=j and PLAYER[j].skulls > 0 then
									rprint(i, "|r"..get_var(j, "$name")..":   "..PLAYER[j].skulls..console_color_teammate)
								end
							end
						end
						
						rprint(i, "|cSKULLS: "..PLAYER[i].skulls..PLAYER[i].console_color)
						
						if PLAYER[i].skulls > 0 then
							PLAYER[i].console_color = console_color_holding
						else
							PLAYER[i].console_color = console_color_default
						end
					end
				else
					PLAYER[i].skulls = 0
					--if player_present(i) then
					--	ClearConsole(i)
					--end
				end
			end
		end
	end
end

function GetTeamID(i)
	local m_player = get_player(i)
	if m_player ~= 0 then
		return read_byte(m_player + 0x20)
	end
end

function ClearConsole(i)
	for j=1,25 do
		rprint(i, " ")
	end
end

function CheckArmorRoom(i)
	if string.find(get_var(0,"$map"), "bigass") ~= nil then
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 and GetName(vehicle) == "altis\\scenery\\armor_room\\armor_room" then
				return false
			end
		end
	end
	return true
end

function SetScore()
	for i=1,16 do
		execute_command("score "..i.." "..PLAYER[i].score)
	end
	
	if get_var(0, "$ffa") == "0" then
		execute_command("team_score red "..TEAM_SCORE.red)
		execute_command("team_score blue "..TEAM_SCORE.blue)
	end
end

function GetGlobals() -- taken from 002's headshots script
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6D617467 then
            return read_dword(tag + 0x14)
		end
	end
	return nil
end

function RemoveAllSkulls()
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 and object ~= 0xFFFFFFFF then
			if read_dword(object) == ball_id then
				destroy_object(ID)
			end
		end
	end
end

function CheckIfGameOver()
	if get_var(0, "$ffa") == "0" then
		if TEAM_SCORE.red >= GAMETYPES[get_var(0, "$mode")] or TEAM_SCORE.blue >= GAMETYPES[get_var(0, "$mode")] then
			execute_command("sv_map_next")
		end
	else
		for i=1,16 do
			if PLAYER[i].score >= GAMETYPES[get_var(0, "$mode")] then
				execute_command("sv_map_next")
			end
		end
	end
end

function RemoveSkullFromPlayer(i, player)
	for j=0,3 do
		local weapon_id = read_dword(player + 0x2F8 + 4*j)
		local weapon = get_object_memory(weapon_id)
		if weapon ~= 0 then
			if read_dword(weapon) == ball_id then
				destroy_object(weapon_id)
				PLAYER[i].skulls = PLAYER[i].skulls + 1
				PLAYER[i].console_color = console_color_grabbed
				PlayAnnouncerSound(42)
			end
		end
	end
end

function PlayerInHill(i, player)
	local player_in_hill = read_byte(koth_globals + to_real_index(i) + 0x80)
	if player_in_hill == 1 then
		if PLAYER[i].skulls > 0 then
			PLAYER[i].score = PLAYER[i].score + PLAYER[i].skulls
			PLAYER[i].console_color = console_color_dropped
			
			if get_var(0, "$ffa") == "0" then
				if PLAYER[i].skulls > 1 then
					say_all(get_var(i, "$name").." scored "..PLAYER[i].skulls.." skulls for "..get_var(i, "$team").." team!")
				else
					say_all(get_var(i, "$name").." scored "..PLAYER[i].skulls.." skull for "..get_var(i, "$team").." team!")
				end
				
				if get_var(i, "$team") == "red" then
					TEAM_SCORE.red = TEAM_SCORE.red + PLAYER[i].skulls
				else
					TEAM_SCORE.blue = TEAM_SCORE.blue + PLAYER[i].skulls
				end
				
				PlayAnnouncerSound(26)
			else
				if PLAYER[i].skulls > 1 then
					say_all(get_var(i, "$name").." scored "..PLAYER[i].skulls.." skulls!")
				else
					say_all(get_var(i, "$name").." scored "..PLAYER[i].skulls.." skull!")
				end
				
				PlayAnnouncerSound(26)
			end
			
			PLAYER[i].skulls = 0
		end
		
		PLAYER[i].hill_timer = PLAYER[i].hill_timer + 1
		
		if PLAYER[i].hill_timer > 30*10 then
			say(i, player_in_hill_message)
			PLAYER[i].hill_timer = 0
		end
	else
		PLAYER[i].hill_timer = 0
	end
end

function PlayAnnouncerSound(sound_id)
	local server_announcer_address = 0x5BDE00
	write_dword(server_announcer_address + 0x8, 1) -- time until first sound in the queue stops playing
	write_dword(server_announcer_address + 0x14, sound_id) -- second sound ID in the queue (from globals multiplayer information > sounds)
	write_dword(server_announcer_address + 0x1C, 1) -- second sound in the queue will play
	write_dword(server_announcer_address + 0x50, 2) -- announcer sound queue
end

function OnError(Message)
	say_all("Error!"..Message)
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end
-- Zombies by: Skylace aka Devieth
-- Version 4.0 for Sapp 10+
-- Website: http://pastebin.com/u/it300


flood_gametype = "survival"

-- Team setup
human_team, zombie_team = 0, 1

-- Spawning
zombie_spawn_time = 0
human_spawn_time = 3

-- Scoring
score_per_kill = 5
score_per_infect = 15
score_per_combo = 1 -- This * combo count
score_per_spree = 2 -- This * Spree count
human_score_per_second = 1
zombie_score_per_second = 0.2

-- Other
last_camo_time = 15
last_is_next_zombie = true
disable_vehicles = true

-- Kill messages
infect_msg = "infected"
suicide_msg = "couldn't take the pressure!"
unknown_msg = "was infected due to a mysterious force."

-- Other messages
human_again_msg = "has become human again for killing %s humans!"
game_over_msg = "All humans have been infected!!! The game will now end..."
no_more_zombies_msg = "There are no more zombies!"
no_zombies_countdown_msg = "A random player will become a zombie in"
lastman_msg = "is the last person alive, find them and eat their brains!!!"

-- Required
api_version = "1.10.0.0"
svcmd = execute_command_sequence
score, player_weapon_id = {}, {}
h_count, z_count, count = 0, 0, 0
nozomz,last_name = false, nil
msg = nil

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	Initialize()
end

function Initialize()
	local gametype = string.lower(get_var(0, "$mode"))
	if gametype == flood_gametype then
		gameinfo_header = read_dword(sig_scan("A1????????8B480C894D00") + 0x1)
		register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_TICK'], "OnEventTick")
		server_setup()
		return true
	else
		unregister_callback(cb['EVENT_GAME_END'])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_LEAVE'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_TICK'])
		return false
	end
end

function OnScriptUnload()
	for i = 1,#player_weapon_id do
		destroy_object(player_weapon_id[i])
	end
end

function OnGameStart()
	if Initialize() then
		gameinfo_base = read_dword(gameinfo_header)
		game_active, last, join_call = false, false, false
		for i = 1,16 do
			score[i], player_weapon_id[i] = 0, nil
		end
	end
end

function OnGameEnd()
	game_active = false
end

function OnPlayerJoin(PlayerIndex)
	local players = tonumber(get_var(PlayerIndex, "$pn"))
	if game_active ~= true then
		set_team(PlayerIndex, human_team, false)
		if players > 1 then
			if join_call == false then
				join_call = true
				timer(1000, "start_game_timer")
			end
		else
			say(PlayerIndex, "Please wait for more players to join.")
		end
	else
		set_navs()
		if players > 1 then
			set_team(PlayerIndex, zombie_team, false)
			timer(100, "check_game_state")
		else
			game_active = false
			say(PlayerIndex, "The game has been stopped, not enough players.")
		end
	end
end

function OnPlayerLeave(PlayerIndex)
	timer(100, "check_game_state")
end

function OnPlayerDeath(VictimIndex, KillerIndex)
	if game_active then
		local VictimIndex, KillerIndex = tonumber(VictimIndex), tonumber(KillerIndex) -- Making sure they are numbers.
		
		if VictimIndex == nil or KillerIndex == nil then return end
		
		local victim_name, victim_team = get_var(VictimIndex, "$name"), get_team(VictimIndex) -- Victim name & team
		if KillerIndex > 0 then -- Players
			local killer_name, killer_team = get_var(KillerIndex, "$name"), get_team(KillerIndex) -- Killer name & team
			if VictimIndex ~= KillerIndex then -- PvP
				if killer_team == zombie_team and victim_team == human_team then -- Zombie vs Human
					set_team(VictimIndex, zombie_team, false)
					say_all(killer_name .. " " .. infect_msg .. " " .. victim_name)
				end
				set_player_score(1, KillerIndex, false)
			else -- Suicide
				if victim_team == human_team then
					set_team(VictimIndex, zombie_team, false)
					say_all(victim_name .. " " .. suicide_msg)
				end
				set_player_score(1, KillerIndex, true)
			end
		elseif KillerIndex == 0 then -- Guardians
			if victim_team == human_team then
				set_team(VictimIndex, zombie_team, false)
				say_all(victim_name .. " " .. unknown_msg)
			end
		elseif KillerIndex == -1 then
			if victim_team == human_team then
				set_team(VictimIndex, zombie_team, false)
				say_all(victim_name .. " " .. unknown_msg)
			end
		end
		set_spawn_time(VictimIndex)
		timer(100, "check_game_state")
	end
end

function OnEventTick()
	for i = 0,16 do
		if player_present(i) then
			if player_alive(i) and game_active then
				local zero = math.fmod(read_dword(gameinfo_base + 0xC), 15)
				local crouch, team = read_byte(get_dynamic_player(i) + 0x2A0), get_team(i)
				if team == zombie_team then if crouch == 3 then camo(i, 1) end end -- Crouch camo for zombies
				if zero == 0 then set_player_score(0, i, team) end
			end
			if msg ~= nil then
				for x = 0,10 do rprint(i, " ") end
				rprint(i, "|c"..msg)
				for x = 0,12 do rprint(i, " ") end
			end
		end
	end
end

function start_game_timer()
	local allow_return, present = true, false
	count = count + 1
	msg = "The game will start in " .. 6 - count
	if count >= 6 then
		if last_is_next_zombie then
			if last_name ~= nil then
				for i = 1,16 do
					if player_present(i) then
						if get_var(i, "$name") == last_name then
							present, last_name = true, nil
							set_team(i, zombie_team, false)
							break
						end
					end
				end
			end
		end
		if present == false then
			get_random_player(zombie_team, false)
		end
		count, allow_return = 0, false
		svcmd("sv_map_reset")
		msg = "The game has started!"
		timer(50, "activate")
		timer(1500, "remove_msg")
	end
	return allow_return
end

function activate() set_navs() check_game_state() game_active = true end -- Set naves above players own heads.
function remove_msg() msg = nil end

function get_random_player(NewTeam, ForceKill)
	local players, Count = {}, 0
	for i = 1,16 do
		if player_present(i) then
			if get_team(i) ~= NewTeam then
				Count = Count + 1
				players[Count] = i
	end	end	end
	if #players >= 1 then
		local PlayerIndex = players[rand(1,#players)]
		set_team(PlayerIndex, NewTeam, ForceKill)
	end
end

function check_game_state()
	get_counts()
	if game_active and t_count > 1 then
		if h_count > 1 and z_count == 0 then
			if not nozomz then
				nozomz = true
				timer(1000, "no_zombies_left")
				say_all(no_more_zombies_msg)
			end
		elseif h_count == 1 and z_count >= 1 then
			timer(500, "on_last_man")
		elseif h_count >= 2 and z_count >= 1 then
			last = false
		elseif h_count == 0 and z_count >= 1 then
			svcmd("sv_map_next")
			say_all(game_over_msg)
		end
	end
end

function no_zombies_left()
	local allow_return = true
	count = count + 1
	say_all(no_zombies_countdown_msg.. " " .. 3-count)
	if count >= 3 then
		get_random_player(zombie_team, true)
		timer(100, "reset")
		count, allow_return = 0, false
	end
	return allow_return
end

function reset() nozomz = false end

function on_last_man() -- There is only one human, lets give him the tools to concure.
	last = true
	for i = 1,16 do
		if player_present(i) then
			if get_team(i) == human_team and get_var(i,"$name") ~= last_name then
				last_name = get_var(i,"$name")
				camo(i, last_camo_time)
				say_all(last_name .. " " .. lastman_msg)
				set_navs(i)
				break
			end
		end
	end
end

function get_counts()
	if human_team == 0 then
		h_count, z_count = tonumber(get_var(0, "$reds")), tonumber(get_var(0, "$blues"))
	else
		h_count, z_count = tonumber(get_var(0, "$blues")), tonumber(get_var(0, "$reds"))
	end
	t_count = h_count + z_count
end

function set_player_score(Mode, PlayerIndex, etc)
	if Mode ~= 0 then
		if etc then -- etc = bool | Punish asshole humans.
			if score[tonumber(PlayerIndex)] > 100 then
				score[tonumber(PlayerIndex)] = score[tonumber(PlayerIndex)] - 100
			end
		else
			local combo, spree = tonumber(get_var(PlayerIndex, "$combo")), tonumber(get_var(PlayerIndex, "$streak"))
			local combo_score, spree_score = combo * score_per_combo, 0
			if math.fmod(spree, 5) == 0 then
				spree_score = spree * score_per_spree
			end
			if get_team(PlayerIndex) == human_team then
				score[tonumber(PlayerIndex)] = score[tonumber(PlayerIndex)] + (score_per_kill + combo_score + spree_score)
			else
				score[tonumber(PlayerIndex)] = score[tonumber(PlayerIndex)] + (score_per_infect + combo_score + spree_score)
			end
		end
	else
		if etc == zombie_team then -- etc = team | Apply team scores per second (while alive.)
			score[tonumber(PlayerIndex)] = score[tonumber(PlayerIndex)] + (zombie_score_per_second / 2)
		else
			score[tonumber(PlayerIndex)] = score[tonumber(PlayerIndex)] + (human_score_per_second / 2)
		end
		svcmd("team_score 2 0;score " .. PlayerIndex .. " " .. math.floor(tonumber(score[tonumber(PlayerIndex)])))
	end
end

function set_spawn_time(PlayerIndex)
	if player_present(PlayerIndex) then
		local m_player = get_player(PlayerIndex)
		if get_team(PlayerIndex) == zombie_team then
			write_dword(m_player + 0x2C, zombie_spawn_time * 30)
		else
			write_dword(m_player + 0x2C, human_spawn_time * 30)
		end
	end
end

function GetTag(class,path) -- Thanks to 002
    local tagarray = read_dword(0x40440000)
    for i=0,read_word(0x4044000C)-1 do
        local tag = tagarray + i * 0x20
        local tagclass = string.reverse(string.sub(read_string(tag),1,4))
        if(tagclass == class) then
            if(read_string(read_dword(tag + 0x10)) == path) then
				return read_dword(tag + 0xC)
			end
        end
    end
    return nil
end

function get_team(PlayerIndex)
	local m_player = get_player(PlayerIndex)
	if m_player ~= 0 then
		return read_byte(m_player + 0x20)
	end
	return nil
end

function set_team(PlayerIndex, NewTeam, ForceKill)
	local m_player = get_player(PlayerIndex)
	if m_player ~= 0 then
		write_byte(m_player + 0x20, NewTeam)
		if ForceKill then kill(PlayerIndex) end
	end
end

function set_speed(PlayerIndex, Speed)
	local m_player = get_player(PlayerIndex)
	if m_player then
		write_float(m_player + 0x6c, Speed)
	end
end

function get_tag(PlayerIndex)
	local m_object = get_dynamic_player(PlayerIndex)
	if m_object ~= 0 then
		local weapon_address = get_object_memory(read_dword(m_object + 0x118))
		if weapon_address ~= 0 then
			local weapon_tag = lookup_tag(read_dword(weapon_address))
			if weapon_tag then
				return read_string(read_dword(weapon_tag + 0x10))
			end
		end
	end
end

function set_navs(PlayerIndex)
	for i = 1,16 do
		if player_present(i) then
			local m_player = get_player(i)
			local player = to_real_index(i)
			if m_player ~= 0 then
				if PlayerIndex ~= nil then
					write_word(m_player + 0x88, to_real_index(PlayerIndex))
				else
					write_word(m_player + 0x88, player)
				end
			end
		end
	end
end

function server_setup()
	gameinfo_base = read_dword(gameinfo_header)
	join_call, last_name, nozomz = false, nil, false
	local disable_team = zombie_team + 1
	svcmd("disable_all_objects  "..disable_team)
	for i = 1,16 do
		if player_present(i) then
			set_team(i, human_team, false)
		end
	end
	if tonumber(get_var(0, "$pn")) > 1 then
		timer(1000, "start_game_timer")
	end
	if disable_vehicles then svcmd("disable_all_vehicles 0 1") end
	svcmd("block_tc enabled;disable_object 'weapons\\ball\\ball' 0;disable_object 'weapons\\flag\\flag' 0")
end
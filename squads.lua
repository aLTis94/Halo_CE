api_version = "1.12.0.0"

-- Squads script by aLTis
-- Some code taken from https://opencarnage.net/index.php?/topic/3951-custom-team-colors/

-- CONFIG

	-- GAMETYPE
	local use_specific_gametype = false -- if you want this script to only work on a specific gametype. If false then it will work on all team gametypes
	local gametype_name = "ctf"
	
	-- VOTING
	local minimum_players_per_team = 2 -- the script starts when each team has at least this many players
	local voting_time = 15 		-- in seconds. How long the voting lasts
	local voting_delay = 12 	-- in seconds. How long it takes for voting to start after a new map has started (takes longer if there aren't enough players)
	local vote_message_delay = 10 -- in seconds. How often the list of candidates is shown
	
	-- LEADER BOOSTS
	local speed_boost = false 		-- if you want the leader to move faster. Won't work with sprinting scripts and on some gametypes!
	local speed_boost_multiplier = 1.1
	local damage_resistance = true 	-- if you want the leader to take less/more damage
	local damage_resistance_multiplier = 0.75
	local damage_increase = true	-- if you want the leader to do less/more damage
	local damage_increase_multiplier = 1.25
	
	-- SPAWNPOINTS
	local respawn_players_near_leader = true -- if you want players to respawn near the leader instead of their default spawns
	local respawn_distance_check = 0.8 -- in world units. If a player is this close to a spawnpoint then other players can't spawn here
	local cant_respawn_if_leader_is_dead = true -- other players won't be able to respawn if their leader is dead
	
	-- COLORS
	local red_color = 2
	local blue_color = 3
	local red_leader_color = 7
	local blue_leader_color = 9
	--colors: white=0,black=1,red=2,blue=3,gray=4,yellow=5,green=6,pink=7,purple=8,cyan=9,cobalt=10,orange=11,teal=12,sage=13,brown=14,tan=15,maroon=16,salmon=17 

	
-- END OF CONFIG

local squads_enabled = false
local squad_leader_red = -1
local squad_leader_blue = -1
local voting_active = 0
local VOTERS = {}
local CANDIDATES_RED = {}
local CANDIDATES_BLUE = {}
local game_running = false
local SPAWNPOINTS = {}

function OnScriptLoad()
	Initialize()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	register_callback(cb['EVENT_CHAT'],"OnChat")
	register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
	register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	register_callback(cb['EVENT_PRESPAWN'],"OnPlayerSpawn")
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb["EVENT_TEAM_SWITCH"],"OnPlayerLeave") -- same as player leave
	register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
end

function OnScriptUnload()
	if(location_store == 0) then return end
    safe_write(true)
    write_char(location_store,116)
    safe_write(false)
end

function OnGameStart()
	Initialize()
end

function OnGameEnd()
	game_running = false
	squads_enabled = false
	if(location_store == 0 or location_store == nil) then return end
    safe_write(true)
    write_char(location_store,116)
    safe_write(false)
end

function Initialize()
	if get_var(0, "$ffa") == "0" and (use_specific_gametype == false or string.lower(get_var(0, "$mode")) == gametype_name) then
		location_store = sig_scan("741F8B482085C9750C")
		if(location_store == 0) then
			location_store = sig_scan("EB1F8B482085C9750C")
			if(location_store == 0) then
				cprint("Failed to find color assignment signature")
			end
		end
		safe_write(true)
		write_char(location_store,235)
		safe_write(false)
		game_running = true
		squads_enabled = true
		squad_leader_red = -1
		quad_leader_blue = -1
		CANDIDATES_RED = {}
		CANDIDATES_BLUE = {}
		voting_active = 0
		GetSpawnpoints()
		for i=1,16 do
			VOTERS[i] = 0
		end
		timer(voting_delay * 1000, "StartVoting")
	else
		squads_enabled = false
	end
end

function StartVoting()
	if tonumber(get_var(0, "$reds")) >= minimum_players_per_team and tonumber(get_var(0, "$blues")) >= minimum_players_per_team then
		local id = 1
		for i=1,16 do
			if get_var(i, "$team") == "red" then
				CANDIDATES_RED[id] = {}
				CANDIDATES_RED[id].name = get_var(i, "$name")
				CANDIDATES_RED[id].votes = 0
				CANDIDATES_RED[id].player_id = i
				id = id + 1
			end
		end
		local id = 1
		for i=1,16 do
			if get_var(i, "$team") == "blue" then
				CANDIDATES_BLUE[id] = {}
				CANDIDATES_BLUE[id].name = get_var(i, "$name")
				CANDIDATES_BLUE[id].votes = 0
				CANDIDATES_BLUE[id].player_id = i
				id = id + 1
			end
		end
		voting_active = voting_time * 30
		Voting()
	else
		if game_running then
			timer(2000, "StartVoting")
		end
	end
end

function Voting()
	if voting_active > 0 then
		say_all("Vote for your squad leader by entering their number in the chat!")
		local red_players = ""
		for id,info in pairs (CANDIDATES_RED) do
			if player_present(info.player_id) then
				if id > 1 then
					red_players = red_players..", "
				end
				red_players = red_players.."["..id.."] "..info.name
			end
		end
		local blue_players = ""
		for id,info in pairs (CANDIDATES_BLUE) do
			if player_present(info.player_id) then
				if id > 1 then
					blue_players = blue_players..", "
				end
				blue_players = blue_players.."["..id.."] "..info.name
			end
		end
		for i=1,16 do
			if get_var(i, "$team") == "red" then
				say(i, red_players)
			else
				say(i, blue_players)
			end
		end
		timer(vote_message_delay * 1000, "Voting")
	end
end

function OnChat(i, command)
	if squads_enabled then
		command = tonumber(command)
		if voting_active > 0 then
			if VOTERS[i] == 0 then
				if i ~= command then
					if get_var(i, "$team") == "red" then
						if CANDIDATES_RED[command] ~= nil then
							CANDIDATES_RED[command].votes = CANDIDATES_RED[command].votes + 1
							say(i, "You voted for "..CANDIDATES_RED[command].name)
							VOTERS[i] = 1
							return false
						end
					else
						if CANDIDATES_BLUE[command] ~= nil then
							CANDIDATES_BLUE[command].votes = CANDIDATES_BLUE[command].votes + 1
							say(i, "You voted for "..CANDIDATES_BLUE[command].name)
							VOTERS[i] = 1
							return false
						end
					end
				else
					say(i, "You can't vote for yourself :v")
					return false
				end
			else
				say(i, "You already voted!")
				return false
			end
		end
	end
	return true
end

function OnTick()
	if squads_enabled == false then return false end
	if game_running == false then
		voting_active = 0
	else
		-- SPEED BOOST
		if speed_boost then
			for i=1,16 do
				if player_present(i) then
					local m_player = get_player(i)
					if i == squad_leader_red or i == squad_leader_blue then
						write_float(m_player + 0x6C, speed_boost_multiplier)
					else
						write_float(m_player + 0x6C, 1)
					end
				end
			end
		end
		
		-- RESPAWN
		if cant_respawn_if_leader_is_dead then
			for i=1,16 do
				if player_present(i) and i ~= squad_leader_red and i ~= squad_leader_blue then
					local m_player = get_player(i)
					local respawn_timer = read_dword(m_player + 0x2C)
					if get_var(i, "$team") == "red" then
						if squad_leader_red ~= -1 and player_alive(squad_leader_red) == false and respawn_timer < 10 then
							write_dword(m_player + 0x2C, 10)
						end
					elseif get_var(i, "$team") == "blue" then
						if squad_leader_blue ~= -1 and player_alive(squad_leader_blue) == false and respawn_timer < 10 then
							write_dword(m_player + 0x2C, 10)
						end
					end
				end
			end
		end
		
		-- VOTING
		if voting_active > 0 then
			voting_active = voting_active - 1
			if voting_active == 0 then
				say_all("Voting has finished!")
				squad_leader_red = -1
				local max_red_votes = 0
				local TIES = {}
				for id,info in pairs (CANDIDATES_RED) do
					if player_present(info.player_id) and get_var(info.player_id, "$team") == "red" then
						if info.votes > max_red_votes then
							max_red_votes = info.votes
							squad_leader_red = info.player_id
							TIES = {}
							table.insert(TIES, info.player_id)
						elseif info.votes == max_red_votes then
							table.insert(TIES, info.player_id)
						end
					end
				end
				
				if #TIES > 0 then
					math.randomseed(os.time())
					squad_leader_red = TIES[math.random(1, #TIES)]
				else
					squad_leader_red = ChooseRandomPlayer("red")
					if squad_leader_red == -1 then
						timer(1000, "SetRandomLeader", "red")
					end
				end
				
				squad_leader_blue = -1
				local max_blue_votes = 0
				local TIES = {}
				for id,info in pairs (CANDIDATES_BLUE) do
					if player_present(info.player_id) and get_var(info.player_id, "$team") == "blue" then
						if info.votes > max_blue_votes then
							max_blue_votes = info.votes
							squad_leader_blue = info.player_id
							TIES = {}
							table.insert(TIES, info.player_id)
						elseif info.votes == max_blue_votes then
							table.insert(TIES, info.player_id)
						end
					end
				end
				
				-- choose random winner from tied candidates
				if #TIES > 0 then
					math.randomseed(os.time())
					squad_leader_blue = TIES[math.random(1, #TIES)]
				else
					-- if all of the tied players quit or something
					squad_leader_blue = ChooseRandomPlayer("blue")
					if squad_leader_blue == -1 then
						timer(1000, "SetRandomLeader", "blue")
					end
				end
				
				for i=1,16 do
					if player_present(i) then
						if get_var(i, "$team") == "red" then
							if squad_leader_red ~= -1 then
								say(i, get_var(squad_leader_red, "$name").." has been chosen as your leader!")
							else
								say(i, "Your team doesn't have a leader :(")
							end
						else
							if squad_leader_blue ~= -1 then
								say(i, get_var(squad_leader_blue, "$name").." has been chosen as your leader!")
							else
								say(i, "Your team doesn't have a leader :(")
							end
						end
						
						DeletePlayer(i)
					end
				end
			end
		end
	end
end

function DeletePlayer(i)
	SetPlayerColors()
	local m_player = get_player(i)
	local player_obj_id = read_dword(m_player + 0x34)
	local object = get_object_memory(player_obj_id)
	if object ~= 0 then
		drop_weapon(i)
		destroy_object(player_obj_id)
	end
end

function ChooseRandomPlayer(team)
	local chosen_player = -1
	local CANDIDATES = {}
	for i=1,16 do
		if get_var(i, "$team") == team then
			table.insert(CANDIDATES, i)
		end
	end
	if #CANDIDATES > 0 then
		math.randomseed(os.time())
		chosen_player = CANDIDATES[math.random(1, #CANDIDATES)]
	end
	return chosen_player
end

function OnError(Message)
	say_all("Error!"..Message)
end

function OnPlayerJoin(i)
	if squads_enabled then
		SetPlayerColors()
		say(i, "This server is using squads script.")
		if tonumber(get_var(0, "$reds")) >= minimum_players_per_team and tonumber(get_var(0, "$blues")) >= minimum_players_per_team then
			timer(1000, "TellWhoLeaderIs", i)
		else
			say(i, "Each team must have at least "..minimum_players_per_team.." players for squads to work!")
		end
	end
end

function TellWhoLeaderIs(i)
	i = tonumber(i)
	if get_var(i, "$team") == "red" then
		if squad_leader_red ~= -1 and i ~= squad_leader_red then
			say(i, "Your squad leader is "..get_var(squad_leader_red, "$name"))
		end
	else
		if squad_leader_blue ~= -1 and i ~= squad_leader_blue then
			say(i, "Your squad leader is "..get_var(squad_leader_blue, "$name"))
		end
	end
end

function SetRandomLeader(team)
	if team == "red" then
		squad_leader_red = ChooseRandomPlayer("red")
		if squad_leader_red ~= -1 then
			say_all(get_var(squad_leader_red, "$name").." has been chosen as a leader of the red squad!")
			DeletePlayer(squad_leader_red)
		else
			timer(1000, "SetRandomLeader", team)
		end
	else
		squad_leader_blue = ChooseRandomPlayer("blue")
		if squad_leader_blue ~= -1 then
			say_all(get_var(squad_leader_blue, "$name").." has been chosen as a leader of the blue squad!")
			DeletePlayer(squad_leader_blue)
		else
			timer(1000, "SetRandomLeader", team)
		end
	end
end

function OnPlayerLeave(i)
	if squads_enabled then
		if i == squad_leader_red then
			say_all("Red squad leader left. Choosing a new one...")
			timer(1000, "SetRandomLeader", "red")
		elseif i == squad_leader_blue then
			say_all("Blue squad leader left. Choosing a new one...")
			timer(1000, "SetRandomLeader", "blue")
		end
	end
end

function OnPlayerDeath(i)
	if squads_enabled then
		SetPlayerColors()
	end
end

function OnDamage(i, causer, DamageTagID, damage)
	if squads_enabled then
		new_damage = damage
		if damage_resistance and i == squad_leader_red or i == squad_leader_blue then
			new_damage = new_damage*damage_resistance_multiplier
		end
		if damage_increase and causer == squad_leader_red or causer == squad_leader_blue then
			new_damage = new_damage*damage_increase_multiplier
		end
		return true, new_damage
	end
end

function SetPlayerColors()
	if squads_enabled then
		for i=1,16 do
			if player_present(i) then
				if i == squad_leader_red then
					write_word(get_player(i) + 0x60, red_leader_color)
				elseif i == squad_leader_blue then
					write_word(get_player(i) + 0x60, blue_leader_color)
				elseif(get_var(i,"$team") == "red") then
					write_word(get_player(i) + 0x60, red_color)
				else
					write_word(get_player(i) + 0x60, blue_color)
				end
			end
		end
	end
end

function OnPlayerSpawn(i)
	if squads_enabled then
		SetPlayerColors()
		if respawn_players_near_leader and i ~= squad_leader_red and i ~= squad_leader_red then
			local player = get_dynamic_player(i)
			if player ~= 0 then
				FindClosestSpawn(i)
			end
		end
	end
end

function FindClosestSpawn(i)
	local team = get_var(i, "$team")
	local k = nil
	if team == "red" then
		k = squad_leader_red
	else
		k = squad_leader_blue
	end
	if k ~= -1 then
		local BLOCKED_SPAWNS = {}
		for j=1,16 do
			if i~= j and player_alive(j) then
				local player = get_dynamic_player(j)
				local x, y, z = read_vector3d(player + 0x5C)
				for id,info in pairs (SPAWNPOINTS) do
					local distance = DistanceFormula(x,y,z,info[1], info[2], info[3])
					if distance < respawn_distance_check then
						BLOCKED_SPAWNS[id] = distance
					end
				end
			end
		end

		
		local player = get_dynamic_player(k)
		local closest_spawn_id = -1
		local closest_spawn_distance = 10000
		if player ~= 0 then
			local x, y, z = read_vector3d(player + 0x5C)
			for id,info in pairs (SPAWNPOINTS) do
				if BLOCKED_SPAWNS[id] == nil then
					local distance = DistanceFormula(x,y,z,info[1], info[2], info[3])
					if distance < closest_spawn_distance then
						closest_spawn_distance = distance
						closest_spawn_id = id
					end
				end
			end
		end
		
		if closest_spawn_id ~= -1 then
			local player = get_dynamic_player(i)
			--say(i, "Spawning near leader.")
			write_vector3d(player + 0x5C, SPAWNPOINTS[closest_spawn_id][1], SPAWNPOINTS[closest_spawn_id][2], SPAWNPOINTS[closest_spawn_id][3])
		end
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Finds distance between two coordinates (from 002)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function GetSpawnpoints()
	SPAWNPOINTS = {}
	
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_tag_data = read_dword(scenario_tag + 0x14)

    local starting_location_reflexive = scenario_tag_data + 0x354
    local starting_location_count = read_dword(starting_location_reflexive)
    local starting_location_address = read_dword(starting_location_reflexive + 0x4)
	--say_all("spawnpoint count: "..starting_location_count)
	
    for i=0,starting_location_count do
        local starting_location = starting_location_address + 52 * i
		local x,y,z = read_vector3d(starting_location)
		local rotation = read_float(starting_location + 0xC)
		local team = read_word(starting_location + 0x10)
		SPAWNPOINTS[i] = {x,y,z,rotation,team}
    end
end
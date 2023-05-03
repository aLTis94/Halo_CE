-- 	Made by aLTis (altis94@gmail.com)

--	This is prop hunt game mode, similar to the one in gmod

--CONFIG
	
	debug_mode = false
	
	console_messages = true		--Enables console messages
	console_message_rate = 1	--How often console messages will update (in seconds)
	
	--	If true then the script will only work on game_mode_name gametype
	--	If false then it will work on any gametype. This may cause issues on incorrect gametypes
	game_mode_required = true
	game_mode_name = "prophunt"	--This script will only work on this game mode
	
	
	seeker_blind_time = 30	--How long seeker cannot do anything to let hiders hide (in seconds)
	game_start_delay = 8	--Game will start after this delay (in seconds)
	
	round_count = 3			--How many rounds until game over
	round_time = 240		--Round time (in seconds)
	dynamic_round_time = true --Ignore value above and generate time based on map size
	
	min_players = 2
	
	grenade_timer = 45		--Seekers will get a grenade after this time passes
	hint_time = 55			--Seekers will get a hint after this time passes
	
	--	Where seeker will be teleported when they are blinded
	x = 1000
	y = 1000
	z = 1000
	
	--	Player speed multipliers (1.0 is default)
	--	Note that red team is hiders and blue team is seekers!
	red_speed = 1.0
	red_speed_unreleased = 1.5 -- speed of hiders when seekers aren't released yet
	blue_speed = 1.2
	
	--	How much score players get
	red_score = 3
	blue_score = 1
	
	color_blue = "|nc5353ff"
	color_red = "|ncffb500"
	
	BLACKLISTED_OBJECTS = {
		["altis\\scenery\\underwater\\underwater"] = true,
		["spiralheempy\\objects\\scenery\\hsh\\panel_a\\panel_a"] = true,
	}
	
--	END OF CONFIG

--TODO
-- hints get sent twice sometimes
-- players can die for no reason?
--let players take a weapon if they don't have any?
--tree_leafy_fallentrunk_short has no collision serverside?

--GT:
--shotguns?

api_version = "1.12.0.0"

local rounds = 0
local current_round_time = round_time * 30
local message_time = 0
local last_caught = 0 
local player_locations = {}
local game_started = false
local game_was_started = false
local round_started = false
local game_over = false
local delay = 10
local last_player_to_shoot = 0

local PROPS = {}
local RADIUS = {}
local HINTS = {}
local MELEE_TIMERS = {}

ffi = require("ffi")
ffi.cdef [[
	bool damage_object(float amount, uint32_t receiver, int8_t causer);
	bool damage_player(float amount, uint8_t receiver, int8_t causer);
]]
damage_module = ffi.load("damage_module")
damage_object = damage_module.damage_object
damage_player = damage_module.damage_player

for i=1,16 do
	PROPS[i] = {}
end

function OnScriptLoad()
	add_var("has_chimera", 4)
	for i=1,16 do
		set_var(i, "$has_chimera", 0)
	end
	if(debug_mode) then
		game_start_delay = 1
		--round_time = 50
		seeker_blind_time = 2
		round_count = 10
	end
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	
	CheckGameMode()
end

function OnScriptUnload()
	if game_was_started then
		execute_command("disable_all_objects 0 0")
		execute_command("disable_sj 0")
		execute_command("block_tc 0")
		for i=1,16 do
			rprint(i, "reloaded_sapp")
			RemoveProp(i)
		end
	end
end

function OnGameStart()
	CheckGameMode()
end

function OnGameEnd()
	game_over = true
	game_started = false
end

function GetMapSize()
	if dynamic_round_time == false then return end
	
	local min_x = 1000
	local max_x = -1000
	local min_y = 1000
	local max_y = -1000
	local scen_count = 0
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	for i=0,object_count-1 do
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			local tag_id = read_dword(object)
			if object_type == 6 and RADIUS[tag_id] ~= nil then
				scen_count = scen_count + 1
				local x,y = read_vector3d(object + 0x5C)
				if x < min_x then
					min_x = x
				end
				if x > max_x then
					max_x = x
				end
				
				if y < min_y then
					min_y = y
				end
				if y > max_y then
					max_y = y
				end
			end
		end
	end
	
	local x = min_x - max_x
	local y = min_y - max_y
	local map_size = math.sqrt(x*y)/50
	
	round_time = math.ceil(80 + 100*map_size + scen_count/2)
	
	--rprint(1, "count "..scen_count)
	--rprint(1, "size "..map_size)
	--rprint(1, "round time "..round_time.."  "..round_time/60)
end

function CheckGameMode()
	if(game_mode_required == false or get_var(0, "$mode") == game_mode_name) and MapIsProtected() == false then
		local object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
		object_table = read_dword(read_dword(object_table_ptr + 2))
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
		register_callback(cb['EVENT_COMMAND'],"OnCommand")
		
		say_all("Game will start in "..game_start_delay.." seconds")
		timer(game_start_delay * 1000, "StartRound")
		
		EditTags()
		GetMapSize()
		for i=1,16 do
			MELEE_TIMERS[i] = 0
			rprint(i, "|nphunt")
		end
	else
		
		if game_was_started then
			timer(5500, "BalanceTeams")
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
		unregister_callback(cb['EVENT_COMMAND'])
	end
end

function BalanceTeams()
	if get_var(0, "$ffa") == 1 then return end
	
	local RED_PLAYERS = {}
	local BLUE_PLAYERS = {}
	for i=1,16 do
		if player_present(i) then
			local team = get_var(i, "$team")
			if team == "red" then
				RED_PLAYERS[i] = true
			else
				BLUE_PLAYERS[i] = true
			end
		end
	end
	
	local difference = #RED_PLAYERS - #BLUE_PLAYERS
	if difference > 1 then -- more reds
		for i,j in pairs (RED_PLAYERS) do
			difference = difference-1
			if difference > 0 then
				execute_command("st "..i.." blue")
			end
		end
		say_all("Teams were balanced!")
	elseif difference < -1 then -- more blues
		for i,j in pairs (BLUE_PLAYERS) do
			difference = difference+1
			if difference < 0 then
				execute_command("st "..i.." red")
			end
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
	if(tonumber(get_var(0, "$pn")) < min_players) then
		
		if(delay == 0) then
			say_all("Waiting for more players...")
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
	say_all(get_var(last_caught, "$name").." is the seeker!")
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
	
	say_all("Seekers have been released!")
	round_started = false
	game_started = true
	for i=1,16 do
		if(get_var(i, "$team") == "blue" and player_alive(i) ~= false) then
			kill(i)
			execute_command("deaths "..i.." -1")
		end
	end
end

function CheckChimera(i)
	i=tonumber(i)
	if get_var(i, "$has_chimera") == "0" then
		say_all(get_var(i, "$name").." was kicked for not having the script!")
		execute_command("sv_kick "..i)
	end
	return false
end

function OnPlayerJoin(PlayerIndex)
	timer(3000, "CheckChimera", PlayerIndex)
	set_var(PlayerIndex, "$has_chimera", 0)
	rprint(PlayerIndex, "|nphunt")
	PROPS[PlayerIndex] = {}
	
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
	say(PlayerIndex, "This is Prop Hunt gametype")
	--say(PlayerIndex, "Find other players hidden as objects and kill them!")
end

function OnPlayerSpawn(i)
	player_locations[i] = nil
	HINTS[i] = nil
	
	execute_command("nades "..i.." 0 1")
	execute_command("nades "..i.." 0 2")
	
	if(get_var(i, "$team") == "red") then
		execute_command("wdel "..i.." 1")
		execute_command("wdel "..i.." 2")
		execute_command("wdel "..i.." 3")
		execute_command("wdel "..i.." 4")
		--execute_command("mag "..i.." 0 1")
		--execute_command("battery "..i.." 0 1")
	else
		execute_command("ammo "..i.." 0 5")
	end
	timer(2000, "SendHint", i, get_dynamic_player(i))
end

function SendHint(i, player2)
	i = tonumber(i)
	local player = get_dynamic_player(i)
	if player ~= 0 and (player2 == nil or player == tonumber(player2)) then
		if(get_var(i, "$team") == "red") then
			if PROPS[i].id ~= nil then
				say(i, "Hold action key (E) to rotate")
			else
				say(i, "Touch an object to turn into it!")
			end
		elseif read_float(player + 0x64) < 990 then
			say(i, "Find players disguised as objects and kill them!")
		end
	end
	return false
end

function ChangeSpeed(i, released)
	i = tonumber(i)
	player = get_player(i)
	if player_present(i) then
		local player_speed = read_float(player + 0x6C)
		
		if get_var(i, "$team") == "red" then
			if released then
				if math.abs(red_speed - player_speed) > 0.02 then
					write_float(player + 0x6C, red_speed)
				end
			elseif (red_speed_unreleased - player_speed) > 0.02 then
				write_float(player + 0x6C, red_speed_unreleased)
			end
		else
			if math.abs(blue_speed - player_speed) > 0.02 then
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

-- Move player to x y z location
function BlindPlayer(PlayerIndex)
	local player_object = get_dynamic_player(PlayerIndex)
	if(player_object ~= 0) then
		write_vector3d(player_object + 0x5C, x, y, (z + PlayerIndex*3))
		write_vector3d(player_object + 0x68, 0, 0, 0)
	end
end

--	If hider died from fall damage or other reasons, they will be switched
function OnPlayerDeath(i, j)
	timer(0, "HaloIsDumb", i, j)
	
	RemoveProp(i)
	PROPS[i] = {}
end

function HaloIsDumb(i, j)
	i = tonumber(i)
	j = tonumber(j)
	if game_started and get_var(i, "$team") == "red" then
		if j < 1 or j == i then
			say_all(get_var(i, "$name").." died and was switched!")
			--rprint(1, "TEST! "..i.." WAS KILLED BY "..j)
		end
		last_caught = i
		ChooseTeam(i, 1)
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

function SendRconMessage(i, loc)
	local player_info = get_player(i)
	local player_name = read_wide_string(player_info + 0x4, 12)
	local message = ""
	if loc == nil then
		message = "|nphunt~"..player_name.."~"..PROPS[i].id.."~"..PROPS[i].perm
	elseif PROPS[i].x ~= nil then
		message = "|nphunt~"..player_name.."~loc~"..PROPS[i].x.."~"..PROPS[i].y.."~"..PROPS[i].z
		if PROPS[i].rot1 ~= 1 then
			message = "|nphunt~"..player_name.."~rot~"..PROPS[i].rot1.."~"..PROPS[i].rot2
		end
	end
	for j=1,16 do
		if player_present(j) then
			rprint(j, message)
		end
	end
	return false
end

function ChimeraWarn()
	for i=1,16 do
		if player_present(i) and get_var(i, "$has_chimera") == "0" then
			if PROPS[i].timer == nil then
				PROPS[i].timer = 45
			end
			
			if PROPS[i].timer > 0 then
				PROPS[i].timer = PROPS[i].timer - 1
			else	
				if tonumber(get_var(0, "$ticks"))%90 == 1 then
					rprint(i, "You must have a Chimera script for this game mode!")
					say(i, "You must have a Chimera script for this game mode!")
				end
				BlindPlayer(i)
			end
		end
	end
end

function PropRconMSG()
	if tonumber(get_var(0, "$ticks"))%29 == 1 then
		for i=1,16 do
			if player_alive(i) and PROPS[i].id ~= nil then
				SendRconMessage(i)
			end
		end
	end
end

function SpawnProp(i,bumped_object,x,y,z)
	if PROPS[i].object == nil or PROPS[i].id ~= read_dword(get_object_memory(PROPS[i].object)) then
	
		if PROPS[i].id == nil and bumped_object ~= nil then
			timer(2000, "SendHint", i)
		end
	
		RemoveProp(i)
		
		if bumped_object ~= nil then
			if PROPS[i].id == nil or read_dword(bumped_object) ~= PROPS[i].id then
				for word in string.gmatch(GetName(bumped_object), "([^".."\\".."]+)") do 
					PROPS[i].prop_name = word
				end
			end
			PROPS[i].name = GetName(bumped_object)
			PROPS[i].id = read_dword(bumped_object)
			PROPS[i].perm = read_char(bumped_object + 0x180)
			SendRconMessage(i)
		else
			PROPS[i].object = nil
			for j=0,10 do
				local object_id = spawn_object("scen", PROPS[i].name, x,y,z+j*0.05)
				local object = get_object_memory(object_id)
				if object ~= 0 then
					if read_bit(object + 0x12, 5) == 1 then
						--rprint(1,"fail at z+"..j*0.1)
						destroy_object(object_id)
					else
						write_char(object + 0x180, PROPS[i].perm)
						for k=0,7 do
							write_char(object + 0x181+k, 0)
						end
						
						if PROPS[i].rot1 == nil then
							PROPS[i].rot1 = 1
							PROPS[i].rot2 = 0
						end
						PROPS[i].object = object_id
						PROPS[i].x, PROPS[i].y, PROPS[i].z = x,y,z
						--rprint(1,"success at "..z.."+"..j*0.1)
						--rprint(1, "spawning object "..PROPS[i].name)
						break
					end
				end
			end
		end
		
		SendRconMessage(i, true)
	end
end

function RemoveProp(i)
	if PROPS[i].object ~= nil then
		local object = get_object_memory(PROPS[i].object)
		if object ~= 0 then
			--rprint(1, "Removing "..GetName(object))
			destroy_object(PROPS[i].object)
		end
		PROPS[i].object = nil
		PROPS[i].x, PROPS[i].y, PROPS[i].z = nil, nil, nil
	end
end

function CheckDamage(i, object)
	write_float(object + 0xD8, 1000)
	local current_body_damage = read_float(object + 0xF8)
	--local damage_time = read_dword(object + 0x100)
	if current_body_damage > 0 then
		local bounding_radius = RADIUS[PROPS[i].id]
		local dmg_multiplier = 1 + bounding_radius*0.35
		local dmg = current_body_damage*1500/dmg_multiplier
		--say_all(dmg)
		damage_player(dmg, to_real_index(i), to_real_index(last_player_to_shoot))
		write_float(object + 0xF8, 0)
	end
end

function PropHuntMagic()
	for i=1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 and get_var(i, "$team") == "red" then
			local x,y,z = read_vector3d(player + 0x5C)
			local x_vel,y_vel,z_vel = read_vector3d(player + 0x68)
			local bump_time = read_char(player + 0x500)
			local bumped_object = read_dword(player + 0x4FC)
			local moving = math.abs(x_vel)+math.abs(y_vel)+math.abs(z_vel) > 0.0001
			local wants_to_move = (read_float(player + 0x278)==0 and read_float(player + 0x27C)==0 and read_bit(player + 0x208, 1)==0 and read_char(player + 0x501)<6) == false
			
			for j=1,16 do
				if i~=j and PROPS[j].object ~= nil and PROPS[j].object == bumped_object then
					bump_time = 0
				end
			end
			
			bumped_object = get_object_memory(bumped_object)
			
			if bump_time == 1 and bumped_object ~= 0 and read_word(bumped_object + 0xB4) == 6 and RADIUS[read_dword(bumped_object)] ~= nil then
				--say_all("bumped!")
				SpawnProp(i,bumped_object,x,y,z)
			elseif PROPS[i].id ~= nil and moving == false then
				SpawnProp(i,nil,x,y,z)
				--rprint(1, "spawning")
			end
			
			if PROPS[i].object ~= nil then
				local object = get_object_memory(PROPS[i].object)
				if object ~= 0 then
					local tag_id = read_dword(object)
					if tag_id ~= PROPS[i].id then
						say_all("ERROR! TAG ID DOESNT MATCH!!!")
					end
					
					if wants_to_move == false then
						local m_player = get_player(i)
						local crouch = read_bit(m_player + 0x11C, 6)
						if crouch == 1 then
							PROPS[i].rot1 = read_float(player + 0x224)
							PROPS[i].rot2 = read_float(player + 0x228)
						end
						-- if player is not moving
						--rprint(1, "not moving")
						write_float(player + 0x37C, 1)
						write_bit(player + 0x10, 0, 1)
						write_vector3d(player + 0x5C, PROPS[i].x, PROPS[i].y, PROPS[i].z)
						write_vector3d(player + 0x68, 0, 0, 0)
						write_float(object + 0x74, PROPS[i].rot1)
						write_float(object + 0x78, PROPS[i].rot2)
						CheckDamage(i, object)
						if tonumber(get_var(0, "$ticks"))%100 == i then
							SendRconMessage(i, true)
						end
					else
						-- if player is moving
						--rprint(1, "moving")
						write_float(player + 0x37C, 0)
						write_bit(player + 0x10, 0, 0)
						PROPS[i].rot1 = 1
						PROPS[i].rot2 = 0
						RemoveProp(i)
					end
				else
					say_all("object doesn't exist anymore")
					PROPS[i].object = nil
				end
			else
				write_float(player + 0x37C, 0)
			end
		else
			RemoveProp(i)
			PROPS[i] = {}
		end
	end
end

function OutOfMapFix()
	for i=1,16 do
		if(player_present(i)) then
			local player = get_dynamic_player(i)
			if player ~= 0 then
				
				-- check if player is out of the map
				if read_bit(player + 0x12, 5) == 0 then
					if player_locations[i] == nil then
						player_locations[i] = {}
						for j=0,20 do
							player_locations[i][j] = {}
						end
					end
					for j=20,1,-1 do
						if player_locations[i][j-1].x ~= nil then
							player_locations[i][j].x = player_locations[i][j-1].x
							player_locations[i][j].y = player_locations[i][j-1].y
							player_locations[i][j].z = player_locations[i][j-1].z
							--rprint(1, j.."  "..player_locations[i][j].x)
						end
					end
					player_locations[i][0].x, player_locations[i][0].y, player_locations[i][0].z = read_vector3d(player + 0x5C)
				elseif player_locations[i] ~= nil and player_locations[i][20] ~= nil and player_locations[i][20].x ~= nil and player_locations[i][0].z < 990 then
					--say_all("MOVING "..player_locations[i][20].z)
					
					write_vector3d(player + 0x5C, player_locations[i][20].x, player_locations[i][20].y, player_locations[i][20].z)
					write_vector3d(player + 0x68, 0, 0, 0)
					
					--for j=0,10 do
					--	if player_locations[i][j+1] ~= nil then
					--		player_locations[i][j].x = player_locations[i][j+1].x
					--		player_locations[i][j].y = player_locations[i][j+1].y
					--		player_locations[i][j].z = player_locations[i][j+1].z
					--	end
					--end
				end
			end
			--	If player is dead then respawn them instantly
			local player = get_player(i)
			write_dword(player + 0x2C, 0)
		end
	end	
end

--	Where magic happens
function OnTick()
	if(game_over) then
		return false
	end
	
	Melee()
	ChimeraWarn()
	PropHuntMagic()
	PropRconMSG()
	OutOfMapFix()
	
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
					--say_all("Random player was made hider!")
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
					say_all(get_var(random_player, "$name").." is the seeker!")
					break
				end
			end
		end
		for i=1,16 do
			if(player_alive(i) == true) then 
				ChangeSpeed(i, false)
			
				if(console_messages and message_time == 0) then
					ClearConsole(i)
				end
				release_timer = seeker_blind_time - round_time + 1 + math.floor(current_round_time/30)
				
				if(get_var(i, "$team") == "blue") then
					BlindPlayer(i)
					
					if(release_timer > 0 and console_messages and message_time == 0) then
						rprint(i, "|rYou will be released in "..release_timer.."s"..color_blue)	
						rprint(i, "|rYou are a seeker"..color_blue)
						rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_blue)
					end
				elseif(release_timer > 0 and console_messages and message_time == 0) then
					rprint(i, "|rSeekers will be released in "..release_timer.."s"..color_red)	
					rprint(i, "|rYou are a hider"..color_red)
					rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_red)
					if PROPS[i].prop_name ~= nil then
						rprint(i, "|rProp: "..PROPS[i].prop_name..color_red)
					else
						rprint(i, "|rProp: none"..color_red)
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
	
		local time_left = math.floor(current_round_time/30)
		local minutes = math.floor(time_left/60)
		local seconds = time_left%60
		local time_left_msg = "Time left: "
		if minutes > 0 then
			time_left_msg = time_left_msg..minutes.."m "	
		end
		time_left_msg = time_left_msg..seconds.."s "	
	
		for i = 1,16 do
			if(player_alive(i)) then
				ChangeSpeed(i, true)
				local player_object = get_dynamic_player(i)
				
				if HINTS[i] ~= nil and HINTS[i] == 0 then
					local m_player = get_player(i)
					if read_bit(m_player + 0x11C, 6) == 1 then
						GiveHint(i)
						HINTS[i] = hint_time
					end
				end
				
				if(console_messages and message_time == 0) then
					ClearConsole(i)
					if(get_var(i, "$team") == "red") then
						rprint(i, "|rYou are a hider"..color_red)
						rprint(i, "|r"..time_left_msg..color_red)
						rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_red)
						if PROPS[i].prop_name ~= nil then
							rprint(i, "|rProp: "..PROPS[i].prop_name..color_red)
						else
							rprint(i, "|rProp: none"..color_red)
						end
					else
						
						if math.floor(time_left%3) == 0 then
							execute_command("ammo "..i.." +1 5")
						end
						
						if HINTS[i] == nil then
							HINTS[i] = hint_time
						end
						if HINTS[i] > 0 then
							HINTS[i] = HINTS[i] - 1
							if HINTS[i] == 0 then
								say(i, "Press (E) to get a hint!")
							end
						end
						
						rprint(i, "|rYou are a seeker"..color_blue)
						if HINTS[i] == 0 then
							rprint(i, "|rGive hint (E) [READY!]"..color_blue)
						else
							rprint(i, "|rGive hint (E) ["..PrintBar(hint_time-HINTS[i], hint_time, 12, "left").."]"..color_blue)
						end
						rprint(i, "|r"..time_left_msg..color_blue)
						rprint(i, "|r"..get_var(0, "$reds").." hiders left"..color_blue)
						
						if math.floor((current_round_time/30)%grenade_timer) == 0 then
							execute_command("nades "..i.." +1 1")
							say(i, "You've got a grenade")
						end
					end
				end
			end
		end
	end
	
	--	Check if hiders won by reaching the time limit
	if(current_round_time == 0) then
		PlayAnnouncerSound(13)
		say_all("Hiders won!")
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
		say_all("Seekers won!")
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
	
end

function GiveHint(i)
	local closest_distance = 10000
	local player = get_dynamic_player(i)
	local x,y,z = read_vector3d(player + 0x5C)
	for j=1,16 do
		player = get_dynamic_player(j)
		if player ~= 0 and i~=j then
			local x2,y2,z2 = read_vector3d(player + 0x5C)
			local dist = DistanceFormula(x,y,z,x2,y2,z2)
			if dist < closest_distance then
				closest_distance = dist
			end
		end
	end
	
	--say(i, "distance "..closest_distance)
	if closest_distance < 8.5 then
		say(i, "There is a prop very close!")
	elseif closest_distance < 20 then
		say(i, "There may be a prop somewhat close")
	else
		say(i, "There are no props nearby...")
	end
end

function PrintBar(val_min, val_max, length, side)
	if val_min == -100 then
		val_min = val_max
	end
	local bar = ""
	for i=1,length do
		if i > val_min/val_max*length then
			if side == "left" then
				bar = bar.."."
			else
				bar = "."..bar
			end
		else
			if side == "left" then
				bar = bar.."|"
			else
				bar = "|"..bar
			end
		end
	end
	return bar
end

function OnCommand(PlayerIndex,Command,Environment,Password)
	-- chimera detection
	if Environment == 1 and Command == "i_have_chimera" then
		--say(PlayerIndex, "Chimera detected!")
		set_var(PlayerIndex, "$has_chimera", 1)
        return false
    end
end

function OnObjectSpawn(i, MetaID, ParentObjectID, ObjectID)
	
	if PROJECTILE_TAGS[MetaID] ~= nil then
		last_player_to_shoot = i
	end
	
	timer(0, "ObjectCheck", ObjectID)
end

--	Check if spawned object is a vehicle or equipment and remove it
function ObjectCheck(ObjectID)
	local object = get_object_memory(ObjectID)
	
	if(object ~= 0) then
		local obj_type = read_word(object + 0xB4)
		if obj_type == 1 or obj_type == 3 then
			destroy_object(ObjectID)
		end
	end
end

function Melee()
	for i=1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local melee = read_byte(player + 0x505)
			if MELEE_TIMERS[i]==0 and melee~=0 then
				local hit, x, y, z, target_id = GetPlayerAimLocation(i)
				if target_id ~= nil then
					for j=1,16 do
						if PROPS[j].object ~= nil and PROPS[j].object == target_id then
							local x2,y2,z2 = read_vector3d(player + 0x5C)
							local distance = DistanceFormula(x, y, z, x2,y2,z2)
							if distance < 1 then
								local bounding_radius = RADIUS[PROPS[j].id]
								local dmg_multiplier = 1 + bounding_radius*0.35
								local dmg = 57/dmg_multiplier
								damage_player(dmg, to_real_index(j), to_real_index(i))
							end
							break
						end
					end
				end
			end
			MELEE_TIMERS[i] = melee
		end
	end
end

function GetPlayerAimLocation(i)--	Finds coordinates at which player is looking (from giraffe)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local px, py, pz = read_vector3d(player + 0x5c)
		local vehicle = read_dword(player + 0x11C)
		if vehicle ~= 0xFFFFFFFF then
			local vehicle = get_object_memory(vehicle)
			if vehicle ~= 0 then
				px, py, pz = read_vector3d(vehicle + 0x5c)
			end
		end
		local vx, vy, vz = read_vector3d(player + 0x230)
		local cs = read_float(player + 0x50C)
		local h = 0.62 - (cs * (0.62 - 0.35))
		pz = pz + h
		return intersect(px, py, pz, vx*1000, vy*1000, vz*1000, read_dword(get_player(i) + 0x34))
	else
		return 0, 0, 0
	end
end

function EditTags()
	
	PROJECTILE_TAGS = {}
	RADIUS = {}
	
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6A707421 then --jpt!
			local tag_data = read_dword(tag + 0x14)
            local cyborg_dmg = read_float(tag_data + 0x254)
			for j=0,31 do
				write_float(tag_data + 0x200 + j*4, cyborg_dmg)
			end
			local name = read_string(read_dword(tag + 0x10))
			if string.find(name, "grenade") ~= nil then
				write_float(tag_data + 0x1D4, 500)
				write_float(tag_data + 0x1D8, 500)
			end
		elseif tag_class == 0x70726F6A then --proj
			PROJECTILE_TAGS[read_dword(tag + 0xC)] = true
			
			local name = read_string(read_dword(tag + 0x10))
			if string.find(name, "grenade") == nil then
				local tag_data = read_dword(tag + 0x14)
				local material_count = read_dword(tag_data + 0x240)
				local material_address = read_dword(tag_data + 0x244)
				for j=0,material_count-1 do
					local address = material_address + j*160
					write_word(address + 0x02, 1)
				end
			end
		elseif tag_class == 0x62697064 then
			local tag_data = read_dword(tag + 0x14)
			write_float(tag_data + 0x42C, 0.1)
		elseif tag_class == 0x7363656E then --scen
			local tag_data = read_dword(tag + 0x14)
			local collision_tag = lookup_tag(read_dword(tag_data + 0x70 + 0xC))
			if collision_tag ~= 0 then
				tag_data = read_dword(collision_tag + 0x14)
				local name = read_string(read_dword(tag + 0x10))
				
				write_bit(tag_data, 31 - 26, 0)--only dmged by explosives
				write_bit(tag_data, 31 - 25, 0)--only dmged when occupied
				
				--if string.find(name, "c_field") == nil then
					write_dword(tag_data + 0x04, 0) -- indirect damage material
				--end
				
				local material_count = read_dword(tag_data + 0x234)
				local material_address = read_dword(tag_data + 0x238)
				for j=0,material_count-1 do
					local address = material_address + j*72
					write_float(address + 0x2C, 1)
					write_float(address + 0x3C, 1)
				end
				
				local furthest_vert = 0
				local node_count = read_dword(tag_data + 0x28C)
				local node_address = read_dword(tag_data + 0x28C+4)
				for j=0,node_count-1 do
					local address = node_address + j*64
					local bsp_count = read_dword(address + 0x34)
					local bsp_address = read_dword(address + 0x34+4)
					for k=0,bsp_count-1 do
						address = bsp_address + k*96
						local vertex_count = read_dword(address + 0x54)
						local vertex_address = read_dword(address + 0x54+4)
						for h=0,vertex_count-1 do
							address = vertex_address + h*16
							local dist = GetDistance(read_vector3d(address))
							if dist > furthest_vert then
								furthest_vert = dist
							end
						end
					end
				end
				
				if furthest_vert < 40 and BLACKLISTED_OBJECTS[name] == nil then
					local tag_id = read_dword(tag + 0xC)
					RADIUS[tag_id] = furthest_vert + 0.3
				end
			end
		end
	end
end

function GetDistance(x,y,z)
	return math.sqrt(x*x + y*y + z*z)
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

function MapIsProtected()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_dword(0x4044000C)
	if tag_count > 50 then
		tag_count = 50
	end
    for i = 0,tag_count - 1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        local tag_path = read_string(read_dword(tag + 0x10))
        for k = 0,i - 1 do
            local tag_k = tag_array + k * 0x20
            if read_dword(tag_k) == tag_class and read_string(read_dword(tag_k + 0x10)) == tag_path and tag_path ~= "MISSINGNO." then
                return true
            end
        end
    end
    return false
end

function read_wide_string(address, length)
	local string = ""
	
	for i=0, length do
		local character = read_word(address + i*2)
		if character ~= 0 and character < 256 then
			string = string..read_string(address + i*2)
		end
	end
	
	return string
end

function OnError(Message)
	say_all("Error!"..Message)
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end
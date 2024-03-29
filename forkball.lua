
-- forkball gametype
-- this script requires a ctf gametype called forkball, fake_forge.lua, forklift.lua and fake forge map forkball.


--CONFIG
	
	local show_console_scores = false
	
	--respawns the ball on game start or after a score
	local ball_spawn_ball_timer = 8
	
	--respawn the ball if it's not moving for this long
	local ball_not_moving_respawn_ball_timer = 15
	
	local ball_vehicle = "forge\\vehicles\\football\\football"
	
--END OF CONFIG


api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	Initialize()
end

function OnScriptUnload()
	if ball ~= nil and get_object_memory(ball) ~= 0 then
		RemoveObject(ball)
	end
	if FORKLIFTS ~= nil then
		for i=1,16 do
			if FORKLIFTS[i] ~= nil then
				RemoveObject(FORKLIFTS[i])
			end
		end
	end
end

function OnGameStart()
	Initialize()
end

function Initialize()
	if get_var(0, "$mode") == "forkball" then
		ball = nil
		ball_timer = 0
		ball_static_ball_timer = 0
		FORKLIFTS = {}
		red_score = 0
		blue_score = 0
		closest_player = -1
		closest_player_distance = 100
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_ALIVE'],"OnPlayerAlive")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
		register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
		
		execute_command("use_new_vehicle_update_scheme 0")
		execute_command("vehicle_incremental_rate 10")
		
		for i=1,16 do
			if player_present(i) then
				xprint(i, "|nforgeball")
			end
		end
	else
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_ALIVE'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_VEHICLE_EXIT'])
		unregister_callback(cb['EVENT_JOIN'])
		
		-- set default values
		execute_command("use_new_vehicle_update_scheme 1")
		execute_command("vehicle_incremental_rate 4")
	end
end

function OnPlayerDeath(i)
	if FORKLIFTS[i] ~= nil then
		RemoveObject(FORKLIFTS[i])
		FORKLIFTS[i] = nil
	end
end

function OnPlayerAlive(i)
	if show_console_scores then
		ClearConsole(i)
		xprint(i, "|rRED TEAM SCORE: "..red_score.."|ncFF0000")
		xprint(i, "|rBLUE TEAM SCORE: "..blue_score.."|nc0000FF")
	end
end

function OnPlayerJoin(i)
	xprint(i, "|nforgeball")
end

function xprint(i, message)
	if get_var(i, "$has_chimera") == "1" then
		rprint(i, message)
	end
end

function OnVehicleExit(i)
	--kill(i)
	local player = get_dynamic_player(i)
	if player ~= 0 and FORKLIFTS[i] ~= nil then
		local vehicle = get_object_memory(FORKLIFTS[i])
		if vehicle ~= 0 then
			--write_float(vehicle + 0x64, 5)
			--write_vector3d(vehicle + 0x74, 1, 0, 0)
			--write_float(vehicle + 0x7C, 0)
			write_vector3d(vehicle + 0x80, 0, 0, 1)
			write_vector3d(vehicle + 0x68, 0, 0, -0.2)
			write_bit(vehicle + 0x10, 5, 0)
		end
	end
end

function OnTick()
	for i = 1,16 do
		xprint(i, "remove_nav")
		execute_command("wdel " .. i .. " 0")
		execute_command("nades " .. i .. " 0 0")
	end
	
	if ball == nil then
		if ball_timer < ball_spawn_ball_timer * 30 then
			if ball_timer == 30 then
				say_all("Ball will spawn in "..ball_spawn_ball_timer - 1 .." seconds!")
			end
			ball_timer = ball_timer + 1
		else
			ball = spawn_object("vehi", ball_vehicle, 2.5, -25.5, 5)
			ball_timer = 0
			PlaySound("hill_move")
		end
	else
		local object = get_object_memory(ball)
		if object == 0 then
			ball = nil
		else
			local x, y, z = read_vector3d(object + 0x5C)
			for i = 1,16 do
				local player = get_dynamic_player(i)
				if player ~= 0 then
					local team = read_word(player + 0xB8)
					xprint(i, "nav~default_red~"..x.."~"..y.."~"..z .."~"..team)
				end
			end
			
			if read_float(object + 0x68) == 0 then
				ball_static_ball_timer = ball_static_ball_timer + 1
				if ball_static_ball_timer > ball_not_moving_respawn_ball_timer * 30 then
					local x, y, z = read_vector3d(object + 0x5C)
					local distance = math.sqrt(math.pow(x - 2.5,2) + math.pow(y - -25.5,2) + math.pow(z - 1,2))
					if distance > 2 then
						RemoveObject(ball)
						ball = spawn_object("vehi", ball_vehicle, 2.5, -25.5, 5)
						PlaySound("hill_move")
						say_all("Ball has been respawned!")
						ball_static_ball_timer = 0
						closest_player = -1
						closest_player_distance = 100
					else
						ball_static_ball_timer = 0
					end
				end
			else
				ball_static_ball_timer = 0
			end
			
			if y < -23 and y > -28 and z < 3.5 and z > 0.5 then
				if x < 25 and x > 22.46 then
					PlaySound("crowd_cheer")
					PlaySound("red_team_score")
					if closest_player ~= -1 and player_present(closest_player) then
						if get_var(closest_player, "$team") == "red" then
							say_all(get_var(closest_player, "$name").." scored for the red team!")
							execute_command("score "..closest_player.." +1")
						else
							say_all(get_var(closest_player, "$name").." scored their own goal!")
							execute_command("score "..closest_player.." -1")
						end
					else
						say_all("Red team scored!")
					end
					timer(1000, "RemoveObject", ball)
					ball = nil
					red_score = red_score + 1
					execute_command("team_score red "..red_score)
				elseif x > -20 and x < -17.45 then
					PlaySound("crowd_cheer")
					PlaySound("blue_team_score")
					if closest_player ~= -1 and player_present(closest_player) then
						if get_var(closest_player, "$team") == "blue" then
							say_all(get_var(closest_player, "$name").." scored for the blue team!")
							execute_command("score "..closest_player.." +1")
						else
							say_all(get_var(closest_player, "$name").." scored their own goal!")
							execute_command("score "..closest_player.." -1")
						end
					else
						say_all("Blue team scored!")
					end
					timer(1000, "RemoveObject", ball)
					ball = nil
					blue_score = blue_score + 1
					execute_command("team_score blue "..blue_score)
				end
			end
		end
	end
	
	local ball_touched = false
	for i = 1,16 do
		local player = get_dynamic_player(i)
		if FORKLIFTS[i] == nil then
			if player ~= 0 then
				if get_object_memory(read_dword(player + 0x11C)) == 0 then
					local x, y, z = read_vector3d(player + 0x5C)
					local team = read_word(player + 0xB8)
					FORKLIFTS[i] = spawn_object("vehi", "altis\\vehicles\\forklift\\forklift", x, y, z, team*math.pi)
					enter_vehicle(FORKLIFTS[i], i, 0)
				end
			end
		else
			local forklift_object = get_object_memory(FORKLIFTS[i])
			if forklift_object ~= nil then
				enter_vehicle(FORKLIFTS[i], i, 0)
				if player ~= 0 then
					if ball ~= nil then
						local object = get_object_memory(ball)
						if object ~= 0 then
							local x = read_float(forklift_object + 0x5C0 + 0x34 * 6 + 0x28)
							local y = read_float(forklift_object + 0x5C0 + 0x34 * 6 + 0x2C)
							local z = read_float(forklift_object + 0x5C0 + 0x34 * 6 + 0x30)
							local x2, y2, z2 = read_vector3d(object + 0x5C)
							local distance = math.sqrt(math.pow(x - x2,2) + math.pow(y - y2,2) + math.pow(z - z2,2))
							if distance < 1.8 then
								ball_touched = true
								if distance < closest_player_distance then
									closest_player_distance = distance
									closest_player = i
								end
							end
						end
					end
					if read_bit(player + 0x208, 4) > 0 then
						exit_vehicle(i)
					end
				else
					if get_object_memory(FORKLIFTS[i]) ~= 0 then
						destroy_object(FORKLIFTS[i])
					end	
					FORKLIFTS[i] = nil
				end
			else
				FORKLIFTS[i] = nil
			end
		end
	end
	
	if ball_touched == false then
		closest_player_distance = 100
	end
end

function PlaySound(sound_file)
	for i=1,16 do
		xprint(i, "play_chimera_sound~"..sound_file)
	end
end

function RemoveObject(ID)
	ID = tonumber(ID)
	if get_object_memory(ID) ~= 0 then
		destroy_object(ID)
	end
end

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,30 do
		xprint(i," ")
	end
end
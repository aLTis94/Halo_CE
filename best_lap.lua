--	Best race lap script by aLTis (altis94@gmail.com)

-- Change log
--2016-07-30:
--	Removed RALLY_GAMETYPES variable
--	Modes on PC are now read correctly (thanks to Samuco)
--2016-07-31:
--	Added player_limit variable
--	Fixed a glitch that didn't display time needed on any-order mode
--2016-08-02
--	Added player_limit_message_time variable
--2016-10-07
--	Added anti_death variable

--	Configuration
	
	--	If you want to edit messages just edit them in the script itself, I didn't add them to the config
	
	--	If server has this many players then the script will not record any laps anymore
	player_limit = 6
	--	Should players be announced if there's too many players
	player_limit_message = true
	--	Time after game start needed to send player_limit_messages messages (in seconds)
	player_limit_message_time = 15
	
	--	Player's time will not be recorded if they warped during the lap
	anti_warp = true
	--	If player died during a lap then their time will not be reorded
	anti_death = true
	
	-- Only driver can get records
	driver_only = true
	
	--	Notify player by how much time he needed to beat current record
	current_needed_message = true
	--	Notify player by how much time he needed to beat all time record
	all_time_needed_message = true
	--	How many seconds does player's time have to be away in order to display above messages
	time_needed_treshold = 20
	
	--	Admin level required to reset times
	admin_level = 4
	--	Command used to reset best times for all maps (must be lowercase)
	reset_command = "reset_times"
	--	Command that displays best times on all maps (must be lowercase)
	display_command = "times"
	--	Command that displays best any-order times on all maps (must be lowercase)
	display_any_order_command = "times_any"
	--	How long the times will be shown after entering the command (in seconds) (will show each page for this time)
	display_time = 5
	--	How many lines to display on the console at once?? (should be 20 or less)
	page_size = 15
	--	Number of decimal places to display
	idp = 2
	
	--	Display best player on game over
	display_most_records_on_game_over = false
	--	Display best player on game over
	display_current_record_on_game_over = true
	--	Display best player on game over
	display_all_time_record_on_game_over = false
	
--	End of configuration

api_version = "1.9.0.0"

best_current_lap = 32000--	In ticks
best_lap_all_time = {}--	In ticks
best_lap_all_time_any_order = {}--	In ticks
current_name = nil--	Player name
all_time_name = {}--	Player name
all_time_name_any_order = {}--	Player name
current_map = nil--		Map that the server is currently running
race = false--			Is the gametype race
previous_time = {}
mode = 0--				0 = normal, 1 = any order, 2 = rally
player_warps = {}--		0 = did not warp, 1 = warped
game_started = false

function OnScriptLoad()
	if (halo_type == "PC") then
        gametype_base = 0x671340    
    else
        gametype_base = 0x5F5498    
    end  
	ReadFromFile()
	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
	register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
	register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	if(anti_death) then
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	end
	if(anti_warp) then
		register_callback(cb['EVENT_WARP'],"OnWarp")
	end
	
	CheckMapAndGametype(true)
	
	for i = 1,16 do--	Reset personal stats
		previous_time[i] = 32000
		player_warps[i] = 0
	end
end

function OnWarp(PlayerIndex)
	player_warps[PlayerIndex] = 1
end

function OnPlayerDeath(PlayerIndex)
	player_warps[PlayerIndex] = 1
end

function OnPlayerJoin(PlayerIndex)--	Inform player about the best time!
	if(race) then
		if(player_limit_message and game_started == false) then
			if(tonumber(get_var(1, "$pn")) == player_limit) then
				say_all("There are too many players and lap times will not be recorded!")
			end
		end
		if(mode == 0) then
			if(all_time_name[current_map] ~= nil) then
				say(PlayerIndex, "All time lap record for this map by "..all_time_name[current_map].." is "..best_lap_all_time[current_map].." seconds!")
			else
				say(PlayerIndex, "There is no lap record for this map yet!")
			end
		else
			if(mode == 1) then
				if(all_time_name_any_order[current_map] ~= nil) then
					say(PlayerIndex, "All time any-order lap record for this map by "..all_time_name_any_order[current_map].." is "..best_lap_all_time_any_order[current_map].." seconds!")
				else
					say(PlayerIndex, "There is no any-order lap record for this map yet!")
				end
			end
		end
	else
		CheckMapAndGametype(false)
	end
end

function OnPlayerLeave()
	if(player_limit_message and game_started == false) then
		if(tonumber(get_var(1, "$pn")) == player_limit) then
			say_all("Lap times are being recorded again!")
		end
	end
end

function CheckMapAndGametype(NewGame)
	if(get_var(1, "$gt") == "race") then--	Check if gametype is race
		current_map = get_var(1, "$map")--	Set current map
		if(NewGame == false and race == true) then
			return false
		end
		race = true
		register_callback(cb['EVENT_TICK'],"OnTick")
			
		safe_read(true)--    We don't want to crash the server if no map is loaded :P
		if (halo_type == "PC") then
			mode = read_byte(gametype_base + 0x7C - 32)
		else
			mode = read_byte(gametype_base + 0x7C)
		end
		safe_read(false)
			
		if(best_lap_all_time[current_map] == nil) then--	If current map doesn't have all time record then set it to a high value
			best_lap_all_time[current_map] = 32000
		end
		if(best_lap_all_time_any_order[current_map] == nil) then--	If current map doesn't have all time record then set it to a high value
			best_lap_all_time_any_order[current_map] = 32000
		end
			
		if(NewGame) then
			best_current_lap = 32000--	Reset current map record
		end
	else
		race = false
		unregister_callback(cb['EVENT_TICK'])
	end
end

function OnGameStart()
	CheckMapAndGametype(true)
	game_started = true
	timer(1000*player_limit_message_time, "ResetGameStarted")
	
	for i = 1,16 do--	Reset personal stats
		previous_time[i] = 32000
	end
end

function ResetGameStarted()
	game_started = false
end

function OnGameEnd()
	for i = 1,16 do
		player_warps[i] = 0
	end
	if(race == false or mode == 2) then
		return false
	end
	timer(1000, "DisplayOnGameEnd")
end

function DisplayOnGameEnd()
	if(display_most_records_on_game_over and race) then
		say_all("Player with most records is "..FindPlayerWithMostRecords().."!")
	end
	if(display_current_record_on_game_over)then
		if(current_name ~= nil and best_current_lap ~= 32000) then
			say_all("Current record for this map is "..best_current_lap.." seconds by "..current_name.."!")
		end
	end
	if(display_all_time_record_on_game_over) then
		if(mode == 0) then
			if(all_time_name[current_map] ~= nil and best_lap_all_time[current_map] ~= 32000) then
				say_all("All time record for this map is "..best_lap_all_time[current_map].." seconds by "..all_time_name[current_map].."!")
			end
		else
			if(all_time_name_any_order[current_map] ~= nil and best_lap_all_time_any_order[current_map] ~= 32000) then
				say_all("All time record for this map is "..best_lap_all_time_any_order[current_map].." seconds by "..all_time_name_any_order[current_map].."!")
			end
		end
	end
end

function OnTick()--	Check players best times and compare them to current and all time best laps
	if(mode ~= 0 and mode ~= 1 or tonumber(get_var(1, "$pn")) > player_limit - 1) then
		return false
	end
	for i=1,16 do
		if(player_alive(i)) then 
			local player = get_player(i)
			local player_address = get_dynamic_player(i)
			local best_time = 32000
			local seat = 0--	0 - driver or on foot, 1 - passenger or gunner
			
			if(driver_only) then--	Get vehicle seat
				local vehicle_objectid = read_dword(player_address + 0x11C)
				if(tonumber(vehicle_objectid) ~= 0xFFFFFFFF) then
					local vehicle = get_object_memory(tonumber(vehicle_objectid))
					local driver = read_dword(vehicle + 0x324)
					driver = get_object_memory(tonumber(driver))
					if(driver == player_address) then
						seat = 0
					else
						seat = 1
					end
				end
			end
				
			best_time = read_word(player + 0xC4)--	Player's current best time
			best_time = round(best_time/30)
				
			if(seat == 1) then
				previous_time[i] = best_time
			end
			
			if(seat == 0 and previous_time[i] ~= best_time and player_warps[i] == 0) then
				if(best_time ~= 0 and best_time < best_current_lap) then
					best_current_lap = best_time
					current_name = get_var(i, "$name")
					say_all("New current record by "..current_name.."! "..best_time.." seconds")
					
					if(mode == 0) then
						if(best_current_lap < best_lap_all_time[current_map]) then
							best_lap_all_time[current_map] = best_current_lap
							all_time_name[current_map] = get_var(i, "$name")
							say_all("New all time record by "..all_time_name[current_map].."! "..best_time.." seconds")
							WriteToFile()
						else
							if(all_time_needed_message and best_time > 0 and best_time ~= 32000 and (best_time - best_lap_all_time[current_map]) < time_needed_treshold) then
								say(i, "ALL time record is "..best_lap_all_time[current_map].." seconds and you had to be "..(best_time - best_lap_all_time[current_map]).." seconds faster to beat it!")
							end
						end
					else
						if(mode == 1) then
							if(best_current_lap < best_lap_all_time_any_order[current_map]) then
								best_lap_all_time_any_order[current_map] = best_current_lap
								all_time_name_any_order[current_map] = get_var(i, "$name")
								say_all("New all time any-order record by "..all_time_name_any_order[current_map].."! "..best_time.." seconds")
								WriteToFile()
							else
								if(all_time_needed_message and best_time > 0 and best_time ~= 32000 and (best_time - best_lap_all_time_any_order[current_map]) < time_needed_treshold) then
									say(i, "ALL time any-order record is "..best_lap_all_time_any_order[current_map].." seconds and you had to be "..(best_time - best_lap_all_time_any_order[current_map]).." seconds faster to beat it!")
								end
							end
						end
					end
				else
					if(mode == 0 and best_time > 0) then
						if(current_name ~= get_var(i, "$name")) then
							if(current_needed_message and (best_time - best_current_lap) < time_needed_treshold) then
								say(i, "Current record is "..best_current_lap.." seconds and you had to be "..(best_time - best_current_lap).." seconds faster to beat it!")
							end
						else
							if(all_time_needed_message  and (best_time - best_current_lap) < time_needed_treshold) then
								say(i, "ALL time record is "..best_lap_all_time[current_map].." seconds and you had to be "..(best_time - best_lap_all_time[current_map]).." seconds faster to beat it!")	
							end
						end
					else
						if(mode == 1 and best_time > 0) then
							if(current_name ~= get_var(i, "$name")) then
								if(current_needed_message and (best_time - best_current_lap) < time_needed_treshold) then
									say(i, "Current record is "..best_current_lap.." seconds and you had to be "..(best_time - best_current_lap).." seconds faster to beat it!")
								end
							else
								if(all_time_needed_message and (best_time - best_lap_all_time_any_order[current_map]) < time_needed_treshold) then
									say(i, "ALL time any-order record is "..best_lap_all_time_any_order[current_map].." seconds and you had to be "..(best_time - best_lap_all_time_any_order[current_map]).." seconds faster to beat it!")
								end
							end
						end
					end
				end
			end
			
			if(previous_time[i] ~= best_time and player_warps[i] == 1) then
				say(i, "Your time was not recorded because you were warping or died during this lap!")
				player_warps[i] = 0
			end
			
			previous_time[i] = best_time
		end
	end
end

function WriteToFile()
	--write mode, map string, time number, player string
	local savefile = io.open("sapp\\lap_records.txt", "w")
	
	for map,value in pairs(all_time_name) do
		savefile:write(0, ",", map,",", best_lap_all_time[map],",", value..",\n")
	end
	for map,value in pairs(all_time_name_any_order) do
		savefile:write(1, ",", map,",", best_lap_all_time_any_order[map],",", value..",\n")
	end
	savefile:close()
end

function ReadFromFile()
	--read the same info and put in the tables
	local savefile = io.open("sapp\\lap_records.txt", "r")
	local n = 0
	
	if(savefile ~= nil) then
		local line = savefile:read("*line")
		while(line ~= nil) do
			local words = {}
			for word in string.gmatch(line, "([^,]+)") do 
				words[n] = word
				
				if(n < 3) then
					n = n + 1
				else
					n = 0
				end
			end
		
			if(tonumber(words[0]) == 0) then--if mode is normal or any-order
				best_lap_all_time[words[1]] = tonumber(words[2])
				all_time_name[words[1]] = words[3]
			else
				best_lap_all_time_any_order[words[1]] = tonumber(words[2])
				all_time_name_any_order[words[1]] = words[3]
			end
			
			line = savefile:read("*line")
		end
		savefile:close()
	end
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	if(Command == display_command) then
		DisplayBestTimes(PlayerIndex, display_time, 1)
		return false
	end
	if(Command == display_any_order_command) then
		DisplayBestAnyOrderTimes(PlayerIndex, display_time, 1)
		return false
	end
	if(Command == reset_command) then
		if(tonumber(get_var(PlayerIndex, "$lvl")) >= admin_level) then
			ResetTimes(PlayerIndex)
			return false
		else
			say(PlayerIndex, "You don't have the rights to reset times!")
			return false
		end
	end
	return true
end

function FindPlayerWithMostRecords()
	local best_player = nil--		name of the player who scored the most
	local records = {} -- 		names and how many records they have
	
	for map,value in pairs(all_time_name) do
		if(records[value] == nil) then
			records[value] = 1
		else
			records[value] = records[value] + 1
		end
	end
	
	for map,value in pairs(all_time_name_any_order) do
		if(records[value] == nil) then
			records[value] = 1
		else
			records[value] = records[value] + 1
		end
	end
	
	for name,count in pairs(records) do
		if(records[best_player] == nil or records[best_player] < records[name]) then
			best_player = name
		end
	end
	
	return best_player
end

function DisplayBestAnyOrderTimes(PlayerIndex, time_left, page)
	page = tonumber(page)
	local not_used = true
	local record_count = 0
	
	ClearConsole(PlayerIndex)
	
	for map,value in pairs(all_time_name_any_order) do
		if(not_used) then
			if(page == 1) then
				rprint(PlayerIndex, "Player with most records is "..FindPlayerWithMostRecords().."!")
			end
			rprint(PlayerIndex, "Fastest any-order laps are:")
			not_used = false
		end
		
		record_count = record_count + 1
		
		if(record_count > page * page_size - page_size and record_count < page * page_size) then
			rprint(PlayerIndex, "    "..map.." - "..best_lap_all_time_any_order[map].." seconds by "..value)
		end
	end
	
	if(not_used) then
		rprint(PlayerIndex, "There are no records yet")
	end
	
	local total_pages = math.floor(record_count/page_size) + 1
	if(total_pages > 1) then
		rprint(PlayerIndex, "Page "..page.."/"..total_pages)
	end
	
	if(tonumber(time_left) > 0) then
		timer(1000, "DisplayBestAnyOrderTimes", PlayerIndex, time_left - 1, page)
	else
		if(page < total_pages) then
			timer(1000, "DisplayBestAnyOrderTimes", PlayerIndex, display_time, page + 1)
		else
			timer(1000, "ClearConsole", PlayerIndex)
			return false
		end
	end
end

function DisplayBestTimes(PlayerIndex, time_left, page)
	page = tonumber(page)
	local not_used = true
	local record_count = 0
	
	ClearConsole(PlayerIndex)
	
	for map,value in pairs(all_time_name) do
		if(not_used) then
			if(page == 1) then
				rprint(PlayerIndex, "Player with most records is "..FindPlayerWithMostRecords().."!")
			end
			rprint(PlayerIndex, "Fastest normal laps are:")
			not_used = false
		end
		
		record_count = record_count + 1
		
		if(record_count > page * page_size - page_size and record_count < page * page_size) then
			rprint(PlayerIndex, "    "..map.." - "..best_lap_all_time[map].." seconds by "..value)
		end
	end
	
	if(not_used) then
		rprint(PlayerIndex, "There are no records yet")
	end
	
	local total_pages = math.floor(record_count/page_size) + 1
	if(total_pages > 1) then
		rprint(PlayerIndex, "Page "..page.."/"..total_pages)
	end
	
	if(tonumber(time_left) > 0) then
		timer(1000, "DisplayBestTimes", PlayerIndex, time_left - 1, page)
	else
		if(page < total_pages) then
			timer(1000, "DisplayBestTimes", PlayerIndex, display_time, page + 1)
		else
			timer(1000, "ClearConsole", PlayerIndex)
			return false
		end
	end
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function ResetTimes(PlayerIndex)--	resets all times
	local savefile = io.open("sapp\\lap_records.txt", "w")
	savefile:write("")
	savefile:close()
	
	best_lap_all_time = {}
	best_lap_all_time_any_order = {}
	all_time_name = {}
	all_time_name_any_order = {}
	
	current_name = nil
	best_current_lap = 32000
	if(best_lap_all_time[current_map] == nil) then--	If current map doesn't have all time record then set it to a high value
		table.insert(best_lap_all_time, {current_map, 32000})
		best_lap_all_time[current_map] = 32000
	end
	if(best_lap_all_time_any_order[current_map] == nil) then--	If current map doesn't have all time record then set it to a high value
		table.insert(best_lap_all_time_any_order, {current_map, 32000})
		best_lap_all_time_any_order[current_map] = 32000
	end
	
	say(PlayerIndex, "All times have been reset!")
end

function round(num)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function OnScriptUnload()
end
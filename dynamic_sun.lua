
api_version = "1.12.0.0"

--CONFIG
	sky_id = 4
	
	sun_yaw = 0
	sun_pitch = 90
	sun_move_ratio = 31
	
	use_real_time = false
	time_speed = 0.0003 -- how fast time changes
	time = 11 -- starting time in hours
	
	-- hour, rgb, fog distance, fog density, tint type, tint intensity
	COLORS_OF_SKY = {
		[0] = {15,14,20, 		5, 0.75,	6, 0},--midnight
		[1] = {14,14,22, 		10, 0.75,	6, 0},
		[2] = {14,14,25, 		20, 0.76,	6, 0},
		[3] = {25,26,36, 		40, 0.77,	6, 0},
		[4] = {45,46,61, 		60, 0.78,	6, 0},
		[5] = {63,64,87, 		70, 0.79,	6, 0},
		[6] = {184,143,127, 	70, 0.76,	1, 0.00001},--sunrise
		[7] = {213,187,170,		70, 0.7,	1, 0.0027},
		[8] = {170,182,194, 	70, 0.68,	1, 0.0023},
		[9] = {126,150,173, 	70, 0.66,	1, 0.002},
		[10] = {132,159,185,	40, 0.63,	1, 0.0015},
		[11] = {120,170,192,	70, 0.6,	1, 0.0006},
		[12] = {133,179,198, 	80, 0.57,	1, 0.0003},
		[13] = {133,179,198, 	90, 0.54,	1, 0.0001},
		[14] = {121,157,181, 	100, 0.52,	1, 0.0001},
		[15] = {116,143,169, 	100, 0.52,	1, 0.0001},
		[16] = {103,126,144, 	80, 0.54,	1, 0.004},
		[17] = {94,111,98, 		70, 0.56,	1, 0.005},
		[18] = {145,140,86, 	50, 0.6,	1, 0.01},
		[19] = {156,123,69, 	40, 0.65,	1, 0.018},
		[20] = {123,58,23, 		30, 0.7,	1, 0.035},
		[21] = {105,53,25, 		20, 0.75,	1, 0.025},
		[22] = {66,34,20, 		15, 0.8,	1, 0.00001},
		[23] = {48,27,16, 		10, 0.78,	6, 0},
		[24] = {15,14,20, 		5, 0.75,	6, 0},-- must be same as 0
	}
	
	message_update_rate = 10 -- how many ticks to skip before sending the clients data
	message_update_rate_colors = 53
	
	show_time = false
	announce_hours = true
--END OF CONFIG

local sin = math.sin
local cos = math.cos
local rad = math.rad
local console_timer = 10
local console_timer2 = -5
local previous_hour = -1

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb["EVENT_TICK"],"OnTick")
	for id,rgb in pairs (COLORS_OF_SKY) do
		for i=1,3 do
			COLORS_OF_SKY[id][i] = COLORS_OF_SKY[id][i] / 255
		end
	end
end

function OnScriptUnload()
end

function OnTick()
	local min
	local hours
	local minutes
	local temp_time
	
	if show_time then
		ClearConsole()
	end
	if use_real_time == false then
		time = time + time_speed
		if time > 24 then
			time = 0
		end
		
		temp_time = time - 6
		if temp_time < 0 then
			temp_time = temp_time + 24
		end
		min = time%1
		hours = math.floor(time)
		minutes = math.floor((min)*60)
	else
		min = os.date("%M")/60
		hours = os.date("%H")
		minutes = os.date("%M")
		seconds = os.date("%S")
		temp_time = hours + min - 6
	end
	
	sun_pitch = temp_time/sun_move_ratio * 360
	
	if show_time then
		rprint(1, "time "..string.format("%02d",hours)..":"..string.format("%02d",minutes))
	end
	--rprint(1, "pitch "..math.floor(sun_pitch))
	
	if announce_hours and previous_hour ~= hours then
		if time > 12 then
			if time > 13 then
				say_all("It's "..hours - 12 .."PM...")
			else
				say_all("It's 12PM...")
			end
		else
			if time > 1 then
				say_all("It's "..hours .."AM...")
			else
				say_all("It's 12AM...")
			end
		end
	end
	previous_hour = hours
	
	local r1,r2 = COLORS_OF_SKY[hours][1], COLORS_OF_SKY[hours+1][1]
	local g1,g2 = COLORS_OF_SKY[hours][2], COLORS_OF_SKY[hours+1][2]
	local b1,b2 = COLORS_OF_SKY[hours][3], COLORS_OF_SKY[hours+1][3]
	local red = r1 * (1 - min) + r2 * min
	local green = g1 * (1 - min) + g2 * min
	local blue = b1 * (1 - min) + b2 * min
	
	local t1,t2 = COLORS_OF_SKY[hours][7], COLORS_OF_SKY[hours+1][7]
	local tint = t1 * (1 - min) + t2 * min
	local tint_type = COLORS_OF_SKY[hours][6]
	
	console_timer = console_timer + 1
	console_timer2 = console_timer2 + 1
	if console_timer > message_update_rate then
		console_timer = 0
		for i=1,16 do
			if player_present(i) and get_var(i, "$has_chimera") == "1" then
				rprint(i, "fsky~"..sky_id.."~"..rad(sun_yaw).."~"..rad(sun_pitch))
			end
		end
	end
	if console_timer2 > message_update_rate_colors then
		console_timer2 = 0
		for i=1,16 do
			if player_present(i) and get_var(i, "$has_chimera") == "1" then
				rprint(i, "fscreen_tint~"..tint_type.."~"..round(tint, 5).."~"..round(red, 4).."~"..round(green, 4).."~"..round(blue, 4))
				rprint(i, "ffog~"..round(red, 3).."~"..round(green, 3).."~"..round(blue, 3).."~"..COLORS_OF_SKY[hours][5].."~0~"..COLORS_OF_SKY[hours][4].."~0~0")
			end
		end
	end
end

function ClearConsole()
	for i=1,16 do
		if player_present(i) then
			for j=0,27 do
				rprint(i, " ")
			end
		end
	end
end

function OnCommand(i,Command,Environment,Password)
	MESSAGE = {}
	for word in string.gmatch(Command, "([^".." ".."]+)") do 
		table.insert(MESSAGE, word)
	end
	
	if MESSAGE[1] == "set_time" then
		if get_var(i, "$lvl") > "2" or Environment == 0 then
			local wanted_time = MESSAGE[2]
			if wanted_time ~= nil and tonumber(wanted_time) ~= nil then
				wanted_time = tonumber(wanted_time)
				if wanted_time >= 0 and wanted_time <= 24 then
					time = wanted_time
				else
					say(i, "time must be between 0 and 24 hours!")
				end
			else
				say(i, "set_time <time>")
			end
		else
			say(i, "you don't have permission to use this command")
		end
		return false
	end
	return true
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
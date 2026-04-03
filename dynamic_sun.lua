--- Dynamic Sun Bigass V3 Script ---
--- Originally by Altis94 ---
--- Updated by Java ---

api_version = "1.12.0.0"

-- CONFIG
local sky_id = 4
local sun_yaw = 0
local sun_move_ratio = 30

local use_real_time = false
local time_speed = 0.0002 
local time = 11 

-- hour = { r, g, b, fog_dist, fog_dens, tint_type, tint_intensity }
local COLORS_OF_SKY = {
    [0]  = {10, 10, 18,     5,   0.78, 6, 0},
    [1]  = {12, 12, 20,     8,   0.77, 6, 0},
    [2]  = {14, 14, 24,     15,  0.76, 6, 0},
    [3]  = {20, 22, 32,     30,  0.75, 6, 0},
    [4]  = {35, 38, 52,     45,  0.74, 6, 0},
    [5]  = {60, 62, 85,     60,  0.73, 6, 0},
    [6]  = {170, 120, 105,  70,  0.70, 1, 0.0005},
    [7]  = {205, 165, 150,  75,  0.68, 1, 0.002},
    [8]  = {185, 190, 205,  80,  0.66, 1, 0.002},
    [9]  = {150, 170, 190,  85,  0.64, 1, 0.0018},
    [10] = {135, 175, 205,  90,  0.60, 1, 0.0012},
    [11] = {120, 185, 210,  95,  0.58, 1, 0.0008},
    [12] = {115, 195, 220,  100, 0.55, 1, 0.0005},
    [13] = {115, 195, 220,  100, 0.53, 1, 0.0004},
    [14] = {110, 175, 205,  100, 0.52, 1, 0.0004},
    [15] = {105, 160, 185,  95,  0.52, 1, 0.0004},
    [16] = {120, 140, 150,  80,  0.54, 1, 0.003},
    [17] = {140, 130, 110,  70,  0.56, 1, 0.004},
    [18] = {165, 140, 90,   60,  0.60, 1, 0.008},
    [19] = {180, 120, 70,   50,  0.65, 1, 0.015},
    [20] = {150, 70,  35,   40,  0.70, 1, 0.030},
    [21] = {110, 55,  28,   25,  0.75, 1, 0.020},
    [22] = {70,  35,  22,   15,  0.78, 1, 0.002},
    [23] = {40,  25,  15,   10,  0.78, 6, 0},
    [24] = {10, 10, 18,     5,   0.78, 6, 0},
}

local message_update_rate = 15 
local message_update_rate_colors = 30
local show_time = false
local announce_hours = true
--END OF CONFIG

local timer1, timer2 = 0, 0
local previous_hour = -1
local current_tod = -1

function OnScriptLoad()
    register_callback(cb['EVENT_COMMAND'], "OnCommand")
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")

    -- Normalize RGB values once on load
    for h, data in pairs(COLORS_OF_SKY) do
        data[1], data[2], data[3] = data[1]/255, data[2]/255, data[3]/255
    end
end

-- Helper for smooth transitions
local function lerp(a, b, t) return a + (b - a) * t end

local function UpdateTimeAndSun()
    if use_real_time then
        local h = tonumber(os.date("%H"))
        local m = tonumber(os.date("%M"))
        local s = tonumber(os.date("%S"))
        time = h + (m/60) + (s/3600)
    else
        time = (time + time_speed) % 24
    end

    local temp_time = (time - 6) % 24
    local sun_pitch = (temp_time / sun_move_ratio) * 360
    return math.floor(time), time % 1, sun_pitch
end

local function SetTOD(t)
    local target = (t >= 8 and t < 20) and 0 or 1
    if current_tod ~= target then
        execute_command_sequence("set tod " .. target)
        current_tod = target
    end
end

function OnGameStart()
    current_tod = -1 -- Reset state
    SetTOD(time)
end

function OnTick()
    local hour, fraction, sun_pitch = UpdateTimeAndSun()
    SetTOD(time)

    if show_time then ClearConsole() end

    -- Announce hours (12-hour format logic)
    if announce_hours and previous_hour ~= hour then
        local display_h = hour % 12
        if display_h == 0 then display_h = 12 end
        local suffix = hour < 12 and "AM" or "PM"
        say_all(string.format("It's %d%s...", display_h, suffix))
        previous_hour = hour
    end

    -- Interpolate sky values
    local c1, c2 = COLORS_OF_SKY[hour], COLORS_OF_SKY[hour + 1]
    local r = lerp(c1[1], c2[1], fraction)
    local g = lerp(c1[2], c2[2], fraction)
    local b = lerp(c1[3], c2[3], fraction)
    local f_dist = lerp(c1[4], c2[4], fraction)
    local f_dens = lerp(c1[5], c2[5], fraction)
    local tint_i = lerp(c1[7], c2[7], fraction)
    local tint_t = c1[6]

    timer1 = timer1 + 1
    timer2 = timer2 + 1

    -- Combined Player Loop for efficiency
    if timer1 > message_update_rate or timer2 > message_update_rate_colors then
        for i = 1, 16 do
            if player_present(i) and get_var(i, "$has_chimera") == "1" then
                if timer1 > message_update_rate then
                    rprint(i, string.format("fsky~%d~%.4f~%.4f", sky_id, math.rad(sun_yaw), math.rad(sun_pitch)))
                end
                if timer2 > message_update_rate_colors then
                    rprint(i, string.format("fscreen_tint~%d~%.5f~%.4f~%.4f~%.4f", tint_t, tint_i, r, g, b))
                    rprint(i, string.format("ffog~%.3f~%.3f~%.3f~%.2f~0~%.1f~0~0", r, g, b, f_dens, f_dist))
                end
            end
        end
        if timer1 > message_update_rate then timer1 = 0 end
        if timer2 > message_update_rate_colors then timer2 = 0 end
    end
end

function ClearConsole()
    for i = 1, 16 do
        if player_present(i) then
            for j = 0, 25 do rprint(i, " ") end
        end
    end
end

function OnCommand(i, command, env, password)
    local args = {}
    for word in command:gmatch("%S+") do table.insert(args, word) end

    if args[1] == "set_time" then
        if tonumber(get_var(i, "$lvl")) > 2 or env == 0 then
            local val = tonumber(args[2])
            if val and val >= 0 and val <= 24 then
                time = val
                previous_hour = -1 -- Trigger re-announcement
            else
                say(i, "Usage: set_time <0-24>")
            end
        else
            say(i, "No permission.")
        end
        return false
    end
    return true
end

-- Player of the Day by 002, edited by aLTis (altis94@gmail.com)

--	Change log:
--	2016-04-26: messages are now sent to the console instead of chat
--	2016-04-29: added STAT_TIME variable, the console messages will be sent every second for that amount of time
--	2016-07-06: messages can now be sent at the end of the game only

-- Only shows messages on game over
SHOW_ON_GAME_OVER = true

-- Frequency to display these messages in X seconds...
STAT_FREQUENCY = 30

-- Time that messages stay on screen in seconds (it will stay a bit longer than this value depending on player's fps)
STAT_TIME = 15

-- These are the messages that will be displayed every STAT_FREQUENCY seconds:
--  $name       - This is substituted for the player's name.
--  $stat       - This is substituted for the relevant stat.
--  $pl_s       - This is substituted for a plural "s" when $stat is not 1.
--  $pl_es      - This is substituted for a plural "es" when $stat is not 1.
MOST_KILLS_TEXT     = "The player with the most kills today is $name ($stat kill$pl_s)"
MOST_KILLS_ENABLED  = true
MOST_FLAGS_TEXT     = "The player with the most flag captures today is $name ($stat cap$pl_s)"
MOST_FLAGS_ENABLED  = true
MOST_DEATHS_TEXT    = "The player with the most deaths today is $name ($stat death$pl_s)"
MOST_DEATHS_ENABLED = true


-- End of configuration

api_version = "1.9.0.0"

stats = {}
stat_timer = 0
last_date = 0

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function OnScriptLoad()
	if(SHOW_ON_GAME_OVER == true) then
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	end
    if MOST_KILLS_ENABLED then
        register_callback(cb["EVENT_KILL"],"OnKill")
    end
    if MOST_DEATHS_ENABLED then
        register_callback(cb["EVENT_DIE"],"OnDie")
    end
    if MOST_FLAGS_ENABLED then
        register_callback(cb["EVENT_SCORE"],"OnScore")
    end
    ResetStats()
    if(SHOW_ON_GAME_OVER == false) then
		timer(1000 * STAT_FREQUENCY,"CheckStats", STAT_TIME)
	end
end

function OnGameEnd()
	CheckStats(STAT_TIME)
end

function CheckStats(stat_time_left)
	stat_time_left = (stat_time_left - 1)
	for i=1,16 do
		ClearConsole(i)
	end
    if MOST_KILLS_ENABLED then
        local name,stat = BestOfStat("kills")
        if name ~= nil then
            execute_command("rprint * \""..FormatString(MOST_KILLS_TEXT,name,stat))
        end
    end
    if MOST_DEATHS_ENABLED then
        local name,stat = BestOfStat("deaths")
        if name ~= nil then
            execute_command("rprint * \""..FormatString(MOST_DEATHS_TEXT,name,stat))
        end
    end
    if MOST_FLAGS_ENABLED then
        local name,stat = BestOfStat("caps")
        if name ~= nil then
            execute_command("rprint * \""..FormatString(MOST_FLAGS_TEXT,name,stat))
        end
    end
    if os.date("*t",os.time()).day ~= last_date then
        ResetStats()
    end
	if(stat_time_left > 0) then
		timer(1000 ,"CheckStats", stat_time_left)
		return false
	end
	if(SHOW_ON_GAME_OVER == false) then
		timer(1000 * STAT_FREQUENCY - STAT_TIME,"CheckStats", STAT_TIME)
	end
end

function ResetStats()
    stats = {
        ["kills"] = {},
        ["deaths"] = {},
        ["caps"] = {}
    }
    last_date = os.date("*t",os.time()).day
end

function BestOfStat(StatName)
    local stat = 0
    local name = nil
    for k,v in pairs(stats[StatName]) do
        if v.stat > stat then
            stat = v.stat
            name = v.name
        end
    end
    if stat == 0 then return nil,nil end
    return name,stat
end

function RegisterStat(PlayerHash,PlayerName,StatName,StatCount)
    for k,v in pairs(stats[StatName]) do
        if PlayerHash == k then
            stats[StatName][k].stat = stats[StatName][k].stat + StatCount
            stats[StatName][k].name = PlayerName
            return
        end
    end
    stats[StatName][PlayerHash] = {
        ["name"] = PlayerName,
        ["stat"] = StatCount
    }
end

function OnScriptUnload()
end

function FormatString(BaseString,Name,Stat)
    local formatted_string = BaseString
    if Stat == 1 then
        formatted_string = string.gsub(formatted_string,"$pl_s","")
        formatted_string = string.gsub(formatted_string,"$pl_es","")
    else
        formatted_string = string.gsub(formatted_string,"$pl_s","s")
        formatted_string = string.gsub(formatted_string,"$pl_es","es")
    end
    formatted_string = string.gsub(formatted_string,"$stat",Stat)
    formatted_string = string.gsub(formatted_string,"$name",Name)
    return formatted_string
end

function OnKill(PlayerIndex)
    RegisterStat(get_var(PlayerIndex,"$hash"),get_var(PlayerIndex,"$name"),"kills",1)
end

function OnDie(PlayerIndex)
    RegisterStat(get_var(PlayerIndex,"$hash"),get_var(PlayerIndex,"$name"),"deaths",1)
end

function OnScore(PlayerIndex)
    if get_var(PlayerIndex,"$gt") ~= "ctf" then return end
    RegisterStat(get_var(PlayerIndex,"$hash"),get_var(PlayerIndex,"$name"),"caps",1)
end
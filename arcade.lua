-- Arcade by 002 v1.0 alpha

-- Configuration

-- Each team starts with this number of points and gains points as players join.
-- Note that:
--    All teams will gain the same number of points at the same time.
--    Points gained are based on the most players that there were in the game at
--        the same time. That means that points will not be taken away if any
--        players leave afterwards.
--    The game is over when one team loses all of their points. Teams cannot
--        have less than 0 points, so if both teams hit 0 at the same time, then
--        the game ends in a draw.

INITIAL_SCORE = 2000
POINTS_INCREASED_EVERY_FOUR_PLAYERS = 1000

POINTS_LOST_PER_MINUTE = 100
POINTS_LOST_PER_KILLED_PLAYER = 25
POINTS_LOST_PER_FLAG_CAPPED_BY_ENEMY = 400
POINTS_LOST_PER_SECOND_PER_PLAYER_BASE_CONTESTED = 1


-- Default contesting distance. Player must be this many world units from the
--     enemy's flag spawn point to be considered "occupying" the base. Note that
--     1 world unit = 3 meters. Also, for players in a vehicle to score points,
--     their bodies must be within this distance, not the vehicle.
CONTEST_DISTANCE_DEFAULT = 10

-- Override the contest distance for each map?
CONTEST_DISTANCE_OVERRIDE = {
    ["beavercreek"] = 3,
    ["ratrace"] = 6,
    ["sidewinder"] = 11,
    ["bloodgulch"] = 9,
    ["damnation"] = 7,
    ["prisoner"] = 3,
    ["hangemhigh"] = 6,
    ["chillout"] = 8,
    ["derelict"] = 4,
    ["boardingaction"] = 5,
    ["wizard"] = 3,
    ["carousel"] = 10,
    ["longest"] = 6,
    ["icefields"] = 7,
    ["deathisland"] = 10,
    ["dangercanyon"] = 8,
    ["infinity"] = 5,
    ["timberland"] = 5,
    ["gephyrophobia"] = 10,
	["bigass"] = 10,

}

MESSAGE_BASE_CONTESTED = "You will gain 1 point per second on the enemy base."


-- Any time an MVP causes his/her enemy to lose points, the points lost are 
--    multiplied by this number. The MVP is the player with the highest points
--    on a team.

MVP_BONUS = 1.20


-- These points are given to players for doing things.

POINTS_GAINED_FOR_CONTESTING = 1
POINTS_GAINED_PER_KILL = 25
POINTS_GAINED_PER_CAP = 400


-- Players do not get POINTS_GAINED_PER_KILL for committing suicide or betraying
--     teammates.

POINTS_GAINED_FOR_BETRAYING = -50
POINTS_GAINED_PER_SUICIDE = -30


-- End of configuration

api_version = "1.9.0.0"
ctf_globals = nil

GAME_STATE = nil

function OnError(Message)
    local aliases_new = io.open("arcadeerrors.txt","a")
    if(aliases_new ~= nil) then
        aliases_new:write(Message .. "\n")
        io.close(aliases_new)
    end
end

function InitializeGameState()
    GAME_STATE = {}
    GAME_STATE.player_scores = {}
    GAME_STATE.team_scores = {["red"] = INITIAL_SCORE, ["blue"] = INITIAL_SCORE}
    GAME_STATE.most_players = 0
    GAME_STATE.global_loss_timer = 0
    GAME_STATE.contest_distance = CONTEST_DISTANCE_OVERRIDE[get_var(1,"$map")]
    if(GAME_STATE.contest_distance == nil) then GAME_STATE.contest_distance = CONTEST_DISTANCE_DEFAULT end

    register_callback(cb['EVENT_DIE'],"OnDie")
    register_callback(cb['EVENT_ALIVE'],"OnAlive")
    register_callback(cb['EVENT_JOIN'],"OnJoin")
    register_callback(cb['EVENT_LEAVE'],"OnLeave")
    register_callback(cb['EVENT_SCORE'],"OnScore")
    timer(1000,"GameRefresh")
end


function DestroyGameState()
    GAME_STATE = nil

    unregister_callback(cb['EVENT_DIE'])
    unregister_callback(cb['EVENT_ALIVE'])
    unregister_callback(cb['EVENT_LEAVE'])
    unregister_callback(cb['EVENT_JOIN'])
    unregister_callback(cb['EVENT_TICK'])
end

function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
    register_callback(cb['EVENT_GAME_END'],"OnGameEnd")

    local ctf_globals_pointer = sig_scan("8B3C85????????3BF9741FE8????????8B8E2C0200008B4610") + 3
    if(ctf_globals_pointer == 3) then return end
    ctf_globals = read_dword(ctf_globals_pointer)

    OnGameStart()
end

function OnScriptUnload() end
function OnGameEnd() 
    DestroyGameState() 
end

function GameRefresh()
    if(GAME_STATE ~= nil) then
        GAME_STATE.global_loss_timer = GAME_STATE.global_loss_timer + 1
        if(GAME_STATE.global_loss_timer == 60) then
            GAME_STATE.global_loss_timer = 0
            IncreaseTeamScore("red",POINTS_LOST_PER_MINUTE * -1)
            IncreaseTeamScore("blue",POINTS_LOST_PER_MINUTE * -1)
        end

        local old_score_red = read_dword(ctf_globals + 0x10)
        local old_score_blue = read_dword(ctf_globals + 0x10 + 4)

        GAME_STATE.old_player_scores = {}

        for i=1,16 do
            if(GAME_STATE.player_scores[i] ~= nil and player_present(i) == true) then
                write_short(get_player(i) + 0xC8,GAME_STATE.player_scores[i].score)
                GAME_STATE.old_player_scores[i] = GAME_STATE.player_scores[i].score
            end
        end
        GAME_STATE.old_team_scores = {["red"] = old_score_red, ["blue"] = old_score_blue}


        write_dword(ctf_globals + 0x10, GAME_STATE.team_scores.red)
        write_dword(ctf_globals + 0x10 + 4,GAME_STATE.team_scores.blue)
        if(GAME_STATE.team_scores.red == 0 or GAME_STATE.team_scores.blue == 0) then
            execute_command("sv_map_next")
        end
        return true
    end
    return false
end

function OnGameStart()
    if(get_var(1,"$mode") == "Arcade CTF" and get_var(1,"$gt") == "ctf") then
        InitializeGameState()
        for i=1,16 do
            if(player_present(i)) then OnJoin(i) end
        end
    end
end

function MultiplierOfPlayer(PlayerIndex)
    PlayerIndex = tonumber(PlayerIndex)
    if(player_present(PlayerIndex) == false) then return 1.00 end
    local highest_score = GAME_STATE.player_scores[PlayerIndex].score
    local player_team = get_var(PlayerIndex,"$team")
    for i=1,16 do
        if(GAME_STATE.player_scores[i] ~= nil and get_var(i,"$team") == player_team and GAME_STATE.player_scores[i].score > highest_score) then
            return 1.00
        end
    end
    return MVP_BONUS
end

function OnAlive(PlayerIndex)
    if(PlayerIndex == nil or GAME_STATE == nil or GAME_STATE.player_scores == nil) then return end
    local team = get_var(PlayerIndex,"$team")
    local fx = 0
    local fy = 0
    local fz = 0
    local enemy_team = nil
    if(team == "red") then
        enemy_team = "blue"
        fx,fy,fz = read_vector3d(read_dword(ctf_globals + 4))
    elseif(team == "blue") then
        enemy_team = "red"
        fx,fy,fz = read_vector3d(read_dword(ctf_globals))
    end
    local player_object = get_dynamic_player(PlayerIndex)
    local x,y,z = read_vector3d(player_object + 0xA0)
    local distance_from_base = DistanceFormula(x,y,z,fx,fy,fz)
    if(distance_from_base < GAME_STATE.contest_distance) then
        IncreasePlayerScore(PlayerIndex,POINTS_GAINED_FOR_CONTESTING)
        IncreaseTeamScore(enemy_team,POINTS_LOST_PER_SECOND_PER_PLAYER_BASE_CONTESTED * MultiplierOfPlayer(PlayerIndex) * -1)
        if(GAME_STATE.player_scores[PlayerIndex].is_contesting == false) then
            GAME_STATE.player_scores[PlayerIndex].is_contesting = true
            --rprint(PlayerIndex,MESSAGE_BASE_CONTESTED)
        end
    else
        GAME_STATE.player_scores[PlayerIndex].is_contesting = false
    end
end

function OnJoin(PlayerIndex)
    if(GAME_STATE == nil or GAME_STATE.old_player_scores == nil) then return end
    local player_count = tonumber(get_var(PlayerIndex,"$pn"))
    if(player_count > GAME_STATE.most_players) then
        for i=GAME_STATE.most_players+1,player_count do
            if(i % 4 == 0) then
                IncreaseTeamScore("red",POINTS_INCREASED_EVERY_FOUR_PLAYERS)
                IncreaseTeamScore("blue",POINTS_INCREASED_EVERY_FOUR_PLAYERS)
            end
        end
        GAME_STATE.most_players = player_count
    end
    GAME_STATE.old_player_scores[PlayerIndex] = nil
    GAME_STATE.player_scores[PlayerIndex] = {
        ["score"] = 0,
        ["is_contesting"] = false
    }
end

function OnDie(VictimIndex,KillerIndex)
    KillerIndex = tonumber(KillerIndex)
    if(KillerIndex > 0) then
        if(KillerIndex == VictimIndex) then
            IncreasePlayerScore(KillerIndex,POINTS_GAINED_PER_SUICIDE)
        elseif(get_var(KillerIndex,"$team") == get_var(VictimIndex,"$team")) then
            IncreasePlayerScore(KillerIndex,POINTS_GAINED_FOR_BETRAYING)
        else
            IncreasePlayerScore(KillerIndex,POINTS_GAINED_PER_KILL)
            IncreaseTeamScore(get_var(VictimIndex,"$team"),POINTS_LOST_PER_KILLED_PLAYER * MultiplierOfPlayer(KillerIndex) * -1)
            --rprint(KillerIndex,"Kill: +" .. POINTS_GAINED_PER_KILL .. " - Total: " .. GAME_STATE.player_scores[KillerIndex].score)
        end
    end
end

function OnScore(PlayerIndex)
    IncreasePlayerScore(PlayerIndex,POINTS_GAINED_PER_CAP)
    IncreaseTeamScore(get_var(PlayerIndex,"$oteam"),POINTS_LOST_PER_FLAG_CAPPED_BY_ENEMY * MultiplierOfPlayer(PlayerIndex) * -1)
    say_all(get_var(PlayerIndex,"$name") .. " captured the flag. " .. get_var(PlayerIndex,"$oteam") .. " team lost " .. POINTS_LOST_PER_FLAG_CAPPED_BY_ENEMY * MultiplierOfPlayer(PlayerIndex) .. " points.")
    --rprint(PlayerIndex,"Flag Cap: +" .. POINTS_GAINED_PER_CAP .. " points. Total: " .. GAME_STATE.player_scores[PlayerIndex].score)
end

function OnLeave(PlayerIndex)
    GAME_STATE.player_scores[PlayerIndex] = nil
end


function DistanceFormula(x1,y1,z1,x2,y2,z2)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function IncreaseTeamScore(TeamName,Delta)
    if(Delta > 0) then
        Delta = math.floor(Delta)
    else
        Delta = math.ceil(Delta)
    end
    GAME_STATE.team_scores[TeamName] = GAME_STATE.team_scores[TeamName] + Delta
    if(GAME_STATE.team_scores[TeamName] >= read_dword(ctf_globals + 0x18)) then
        GAME_STATE.team_scores[TeamName] = read_dword(ctf_globals + 0x18) - 1
    end
    if(GAME_STATE.team_scores[TeamName] < 0) then
        GAME_STATE.team_scores[TeamName] = 0
    end
end
function IncreasePlayerScore(PlayerIndex,Delta)
    if(Delta > 0) then
        Delta = math.floor(Delta)
    else
        Delta = math.ceil(Delta)
    end
    PlayerIndex = tonumber(PlayerIndex)
    GAME_STATE.player_scores[PlayerIndex].score = GAME_STATE.player_scores[PlayerIndex].score + Delta
    if(GAME_STATE.player_scores[PlayerIndex].score > 32767) then
        GAME_STATE.player_scores[PlayerIndex].score = 32767
    end
    if(player_present(PlayerIndex)) then
        local sign = "+"
        if(Delta < 0) then sign = "" end
        rprint(PlayerIndex,"|rScore: " .. GAME_STATE.player_scores[PlayerIndex].score .. " (" .. sign .. Delta .. ")")
    end
end
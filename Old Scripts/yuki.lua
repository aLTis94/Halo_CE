-- Team-based Bipeds 1.1 by 002
-- Tunned by {BK}Charly
-- Configuration

cyborg = "ecd\\characters\\ecd_cyborg\\ecd_cyborg_mp"
female = "ecd\\characters\\ecd_female\\ecd_female_mp"
elite = "ecd\\characters\\ecd_elite\\ecd_elite_mp"
cwheat = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cwheat"
cair = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cair"
cemerald = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cemerald"
colive = "ecd\\characters\\ecd_cyborg\\colors\\ecd_colive"
ccherry = "ecd\\characters\\ecd_cyborg\\colors\\ecd_ccherry"
cstarting = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cstarting"
cstandard = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cstandard"
cadvanced = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cadvanced"
cexpert = "ecd\\characters\\ecd_cyborg\\colors\\ecd_cexpert"
csupreme = "ecd\\characters\\ecd_cyborg\\colors\\ecd_csupreme"
ewheat = "ecd\\characters\\ecd_elite\\colors\\ecd_ewheat"
eair = "ecd\\characters\\ecd_elite\\colors\\ecd_eair"
eemerald = "ecd\\characters\\ecd_elite\\colors\\ecd_eemerald"
eolive = "ecd\\characters\\ecd_elite\\colors\\ecd_eolive"
echerry = "ecd\\characters\\ecd_elite\\colors\\ecd_echerry"
estarting = "ecd\\characters\\ecd_elite\\colors\\ecd_estarting"
estandard = "ecd\\characters\\ecd_elite\\colors\\ecd_estandard"
eadvanced = "ecd\\characters\\ecd_elite\\colors\\ecd_eadvanced"
eexpert = "ecd\\characters\\ecd_elite\\colors\\ecd_eexpert"
esupreme = "ecd\\characters\\ecd_elite\\colors\\ecd_esupreme"
fwheat = "ecd\\characters\\ecd_female\\colors\\ecd_fwheat"
fair = "ecd\\characters\\ecd_female\\colors\\ecd_fair"
femerald = "ecd\\characters\\ecd_female\\colors\\ecd_femerald"
folive = "ecd\\characters\\ecd_female\\colors\\ecd_folive"
fcherry = "ecd\\characters\\ecd_female\\colors\\ecd_fcherry"
fstarting = "ecd\\characters\\ecd_female\\colors\\ecd_fstarting"
fstandard = "ecd\\characters\\ecd_female\\colors\\ecd_fstandard"
fadvanced = "ecd\\characters\\ecd_female\\colors\\ecd_fadvanced"
fexpert = "ecd\\characters\\ecd_female\\colors\\ecd_fexpert"
fsupreme = "ecd\\characters\\ecd_female\\colors\\ecd_fsupreme"

-- End of Configuration

api_version = "1.7.0.0"

local gmatch, lower = string.gmatch, string.lower

local players
local game_started

DEFAULT_BIPED = nil
cyborg2 = nil
female2 = nil
elite2 = nil
cwheat = nil
cair = nil
cemerald = nil
colive = nil
ccherry = nil
cstarting = nil
cstandard = nil
cadvanced = nil
cexpert = nil
csupreme = nil
ewheat = nil
eair = nil
eemerald = nil
eolive = nil
echerry = nil
estarting = nil
estandard = nil
eadvanced2 = nil
eexpert2 = nil
esupreme2 = nil
fwheat = nil
fair = nil
femerald = nil
folive = nil
fcherry = nil
fstarting = nil
fstandard = nil
fadvanced2 = nil
fexpert2 = nil
fsupreme2 = nil

function OnScriptLoad()

    game_started = false
	
	OnGameStart()
	
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_JOIN"], "OnPlayerConnect")
    register_callback(cb["EVENT_LEAVE"], "OnPlayerDisconnect")
    register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	register_callback(cb["EVENT_COMMAND"], "ChatCommand")
    register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
end

function OnScriptUnload() 
    DEFAULT_BIPED = nil
    cyborg = nil
    female = nil
    elite = nil
    cwheat = nil
    cair = nil
    cemerald = nil
    colive = nil
    ccherry = nil
    cstarting = nil
    cstandard = nil
    cadvanced = nil
    cexpert = nil
    csupreme = nil
    ewheat = nil
    eair = nil
    eemerald = nil
    eolive = nil
    echerry = nil
    estarting = nil
    estandard = nil
    eadvanced = nil
    eexpert = nil
    esupreme = nil
    fwheat = nil
    fair = nil
    femerald = nil
    folive = nil
    fcherry = nil
    fstarting = nil
    fstandard = nil
    fadvanced2 = nil
    fexpert2 = nil
    fsupreme2 = nil
end

local function InitPlayer(Ply, Reset)
    if (not Reset) then
        players[Ply] = { char = "men" }
    else
        players[Ply] = nil
    end
end

function OnGameStart()
    players = { }
    if (get_var(0, "$gt") ~= "n/a") then

        game_started = true

        for i = 1, 16 do
            if player_present(i) then
                InitPlayer(i, false)
            end
        end
    end
end

function OnPlayerConnect(Ply)
    InitPlayer(Ply, false)
end

function OnPlayerDisconnect(Ply)
    InitPlayer(Ply, true)
end

function FindBipedTag(TagName)
    local tag_array = read_dword(0x40440000)
    for i=0,read_word(0x4044000C)-1 do
        local tag = tag_array + i * 0x20
        if(read_dword(tag) == 1651077220 and read_string(read_dword(tag + 0x10)) == TagName) then
            return read_dword(tag + 0xC)
        end
    end
end

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)
    if(player_present(PlayerIndex) == false) then return true end
    if(DEFAULT_BIPED == nil) then
        local tag_array = read_dword(0x40440000)
        for i=0,read_word(0x4044000C)-1 do
            local tag = tag_array + i * 0x20
            if(read_dword(tag) == 1835103335 and read_string(read_dword(tag + 0x10)) == "globals\\globals") then
                local tag_data = read_dword(tag + 0x14)
                local mp_info = read_dword(tag_data + 0x164 + 4)
                for j=0,read_dword(tag_data + 0x164)-1 do
                    DEFAULT_BIPED = read_dword(mp_info + j * 160 + 0x10 + 0xC)
                end
            end
        end
    end
    if(MapID == DEFAULT_BIPED) then
        if(cyborg2 == nil) then cyborg2 = FindBipedTag(cyborg) end
        if(female2 == nil) then female2 = FindBipedTag(female) end
        if(elite2 == nil) then elite2 = FindBipedTag(elite) end
        if(cwheat == nil) then cwheat = FindBipedTag(cwheat) end
        if(cair == nil) then cair = FindBipedTag(cair) end
        if(cemerald == nil) then cemerald = FindBipedTag(cemerald) end
        if(colive == nil) then colive = FindBipedTag(colive) end
        if(ccherry == nil) then ccherry = FindBipedTag(ccherry) end
        if(cstarting == nil) then cstarting = FindBipedTag(cstarting) end
        if(cstandard == nil) then cstandard = FindBipedTag(cstandard) end
        if(cadvanced == nil) then cadvanced = FindBipedTag(cadvanced) end
        if(cexpert == nil) then cexpert = FindBipedTag(cexpert) end
        if(csupreme == nil) then csupreme = FindBipedTag(csupreme) end
        if(ewheat == nil) then ewheat = FindBipedTag(ewheat) end
        if(eair == nil) then eair = FindBipedTag(eair) end
        if(eemerald == nil) then eemerald = FindBipedTag(eemerald) end
        if(eolive == nil) then eolive = FindBipedTag(eolive) end
        if(echerry == nil) then echerry = FindBipedTag(echerry) end
        if(estarting == nil) then estarting = FindBipedTag(estarting) end
        if(estandard == nil) then estandard = FindBipedTag(estandard) end
        if(eadvanced2 == nil) then eadvanced2 = FindBipedTag(eadvanced) end
        if(eexpert2 == nil) then eexpert2 = FindBipedTag(eexpert) end
        if(esupreme2 == nil) then esupreme2 = FindBipedTag(esupreme) end
        if(fwheat == nil) then fwheat = FindBipedTag(fwheat) end
        if(fair == nil) then fair = FindBipedTag(fair) end
        if(femerald == nil) then femerald = FindBipedTag(femerald) end
        if(folive == nil) then folive = FindBipedTag(folive) end
        if(fcherry == nil) then fcherry = FindBipedTag(fcherry) end
        if(fstarting == nil) then fstarting = FindBipedTag(fstarting) end
        if(fstandard == nil) then fstandard = FindBipedTag(fstandard) end
        if(fadvanced2 == nil) then fadvanced2 = FindBipedTag(fadvanced) end
        if(fexpert2 == nil) then fexpert2 = FindBipedTag(fexpert) end
        if(fsupreme2 == nil) then fsupreme2 = FindBipedTag(fsupreme) end

        cprint(players[PlayerIndex].char)

        BIPED_TO_USE = cyborg
        if(players[PlayerIndex].char == "cyborg") then
            BIPED_TO_USE = cyborg2
			say_all("man spawned!")
        elseif(players[PlayerIndex].char == "female") then
            BIPED_TO_USE = female2
            cprint("woman spawn")
        elseif(players[PlayerIndex].char == "elite") then
            BIPED_TO_USE = elite2
            cprint("elite spawn")
        elseif(players[PlayerIndex].char == "cwheat") then
            BIPED_TO_USE = cwheat
            cprint("cwheat spawn")
        elseif(players[PlayerIndex].char == "cair") then
            BIPED_TO_USE = cair
            cprint("cair spawn")
        elseif(players[PlayerIndex].char == "cemerald") then
            BIPED_TO_USE = cemerald
            cprint("cemerald spawn")
        elseif(players[PlayerIndex].char == "colive") then
            BIPED_TO_USE = colive
            cprint("colive spawn")
        elseif(players[PlayerIndex].char == "ccherry") then
            BIPED_TO_USE = ccherry
            cprint("ccherry spawn")
        elseif(players[PlayerIndex].char == "cstarting") then
            BIPED_TO_USE = cstarting
            cprint("cstarting spawn")
        elseif(players[PlayerIndex].char == "cstandard") then
            BIPED_TO_USE = cstandard
            cprint("cstandard spawn")
        elseif(players[PlayerIndex].char == "cadvanced") then
            BIPED_TO_USE = cadvanced
            cprint("cadvanced spawn")
        elseif(players[PlayerIndex].char == "cexpert") then
            BIPED_TO_USE = cexpert
            cprint("cexpert spawn")
        elseif(players[PlayerIndex].char == "csupreme") then
            BIPED_TO_USE = csupreme
            cprint("csupreme spawn")
        elseif(players[PlayerIndex].char == "ewheat") then
            BIPED_TO_USE = ewheat
            cprint("ewheat spawn")
        elseif(players[PlayerIndex].char == "eair") then
            BIPED_TO_USE = eair
            cprint("eair spawn")
        elseif(players[PlayerIndex].char == "eemerald") then
            BIPED_TO_USE = eemerald
            cprint("eemerald spawn")
        elseif(players[PlayerIndex].char == "eolive") then
            BIPED_TO_USE = eolive
            cprint("eolive spawn")
        elseif(players[PlayerIndex].char == "echerry") then
            BIPED_TO_USE = echerry
            cprint("echerry spawn")
        elseif(players[PlayerIndex].char == "estarting") then
            BIPED_TO_USE = estarting
            cprint("estarting spawn")
        elseif(players[PlayerIndex].char == "estandard") then
            BIPED_TO_USE = estandard
            cprint("estandard spawn")
        elseif(players[PlayerIndex].char == "eadvanced") then
            BIPED_TO_USE = eadvanced2
            cprint("eadvanced spawn")
        elseif(players[PlayerIndex].char == "eexpert") then
            BIPED_TO_USE = eexpert2
            cprint("eexpert spawn")
        elseif(players[PlayerIndex].char == "esupreme") then
            BIPED_TO_USE = esupreme2
            cprint("esupreme spawn")
        elseif(players[PlayerIndex].char == "fwheat") then
            BIPED_TO_USE = fwheat
            cprint("fwheat spawn")
        elseif(players[PlayerIndex].char == "fair") then
            BIPED_TO_USE = fair
            cprint("fair spawn")
        elseif(players[PlayerIndex].char == "femerald") then
            BIPED_TO_USE = femerald
            cprint("femerald spawn")
        elseif(players[PlayerIndex].char == "folive") then
            BIPED_TO_USE = folive
            cprint("folive spawn")
        elseif(players[PlayerIndex].char == "fcherry") then
            BIPED_TO_USE = fcherry
            cprint("fcherry spawn")
        elseif(players[PlayerIndex].char == "fstarting") then
            BIPED_TO_USE = fstarting
            cprint("fstarting spawn")
        elseif(players[PlayerIndex].char == "fstandard") then
            BIPED_TO_USE = fstandard
            cprint("fstandard spawn")
        elseif(players[PlayerIndex].char == "fadvanced") then
            BIPED_TO_USE = fadvanced2
            cprint("fadvanced spawn")
        elseif(players[PlayerIndex].char == "fexpert") then
            BIPED_TO_USE = fexpert2
            cprint("fexpert spawn")
        elseif(players[PlayerIndex].char == "fsupreme") then
            BIPED_TO_USE = fsupreme2
            cprint("fsupreme spawn")
        end

        return true,BIPED_TO_USE
    end
    return true
end

local function Split(cmd)
    local Args = { }
    for Params in gmatch(cmd, "([^%s]+)") do
        Args[#Args + 1] = lower(Params)
    end
    return Args
end

local function IsAdmin(Ply, level)
    return (tonumber(get_var(Ply, "$lvl")) >= level) or (Ply == 0)
end

function ItsMe(Admin, Ply)
    if Admin == Ply then
		return true
	else
		return false
	end
end

function ChatCommand(Ply, MSG, _, _)
    local Args = Split(MSG)
    if(Args) then
        if(Args[1] == "char") then
            if(Args[2] == "cyborg" or Args[2] == "men") then
                players[Ply].char = "cyborg"
                cprint("set men")
            elseif(Args[2] == "female" or Args[2] == "girl") then
                players[Ply].char = "female"
                cprint("set female")
            elseif(Args[2] == "elite") then
                players[Ply].char = "elite"
                cprint("set elite")
            elseif(Args[2] == "cwheat") then
                players[Ply].char = "cwheat"
                cprint("set cwheat")
            elseif(Args[2] == "cair") then
                players[Ply].char = "cair"
                cprint("set cair")
            elseif(Args[2] == "cemerald") then
                players[Ply].char = "cemerald"
                cprint("set cemerald")
            elseif(Args[2] == "colive") then
                players[Ply].char = "colive"
                cprint("set colive")
            elseif(Args[2] == "ccherry") then
                players[Ply].char = "ccherry"
                cprint("set ccherry")
            elseif(Args[2] == "cstarting") then
                players[Ply].char = "cstarting"
                cprint("set cstarting")
            elseif(Args[2] == "cstandard") then
                players[Ply].char = "cstandard"
                cprint("set cstandard")
            elseif(Args[2] == "cadvanced") then
                players[Ply].char = "cadvanced"
                cprint("set cadvanced")
            elseif(Args[2] == "cexpert") then
                players[Ply].char = "cexpert"
                cprint("set cexpert")
            elseif(Args[2] == "csupreme") then
                players[Ply].char = "csupreme"
                cprint("set csupreme")
            elseif(Args[2] == "ewheat") then
                players[Ply].char = "ewheat"
                cprint("set ewheat")
            elseif(Args[2] == "eair") then
                players[Ply].char = "eair"
                cprint("set eair")
            elseif(Args[2] == "eemerald") then
                players[Ply].char = "eemerald"
                cprint("set eemerald")
            elseif(Args[2] == "eolive") then
                players[Ply].char = "eolive"
                cprint("set eolive")
            elseif(Args[2] == "echerry") then
                players[Ply].char = "echerry"
                cprint("set echerry")
            elseif(Args[2] == "estarting") then
                players[Ply].char = "estarting"
                cprint("set estarting")
            elseif(Args[2] == "estandard") then
                players[Ply].char = "estandard"
                cprint("set estandard")
            elseif(Args[2] == "eadvanced") then
                players[Ply].char = "eadvanced"
                cprint("set eadvanced")
            elseif(Args[2] == "eexpert") then
                players[Ply].char = "eexpert"
                cprint("set eexpert")
            elseif(Args[2] == "esupreme") then
                players[Ply].char = "esupreme"
                cprint("set esupreme")
            elseif(Args[2] == "fwheat") then
                players[Ply].char = "fwheat"
                cprint("set fwheat")
            elseif(Args[2] == "fair") then
                players[Ply].char = "fair"
                cprint("set fair")
            elseif(Args[2] == "femerald") then
                players[Ply].char = "femerald"
                cprint("set femerald")
            elseif(Args[2] == "folive") then
                players[Ply].char = "folive"
                cprint("set folive")
            elseif(Args[2] == "fcherry") then
                players[Ply].char = "fcherry"
                cprint("set fcherry")
            elseif(Args[2] == "fstarting") then
                players[Ply].char = "fstarting"
                cprint("set fstarting")
            elseif(Args[2] == "fstandard") then
                players[Ply].char = "fstandard"
                cprint("set fstandard")
            elseif(Args[2] == "fadvanced") then
                players[Ply].char = "fadvanced"
                cprint("set fadvanced")
            elseif(Args[2] == "fexpert") then
                players[Ply].char = "fexpert"
                cprint("set fexpert")
            elseif(Args[2] == "fsupreme") then
                players[Ply].char = "fsupreme"
                cprint("set fsupreme")
            end
            rprint(Ply, "char set "..players[Ply].char)
            return false
        elseif Args[1] == "colors" then
            rprint(Ply, "-[-[-[ COLORS ]-]-]-");
            rprint(Ply, "wheat");
            rprint(Ply, "air");
            rprint(Ply, "olive");
            rprint(Ply, "emerald");
            rprint(Ply, "cherry");
            rprint(Ply, "starting");
            rprint(Ply, "standard");
            rprint(Ply, "advanced");
            rprint(Ply, "expert");
            rprint(Ply, "supreme");
            rprint(Ply, "-[-[-[ COLORS ]-]-]-");
            return false
        end
    end
end

function OnGameEnd()
    DEFAULT_BIPED = nil
    cyborg2 = nil
    female2 = nil
    elite2 = nil
    cwheat = nil
    cair = nil
    cemerald = nil
    colive = nil
    ccherry = nil
    cstarting = nil
    cstandard = nil
    cadvanced = nil
    cexpert = nil
    csupreme = nil
    ewheat = nil
    eair = nil
    eemerald = nil
    eolive = nil
    echerry = nil
    estarting = nil
    estandard = nil
    eadvanced2 = nil
    eexpert2 = nil
    esupreme2 = nil
    fwheat = nil
    fair = nil
    femerald = nil
    folive = nil
    fcherry = nil
    fstarting = nil
    fstandard = nil
    fadvanced2 = nil
    fexpert2 = nil
    fsupreme2 = nil
end
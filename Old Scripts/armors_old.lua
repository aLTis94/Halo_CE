-- Custom Bipeds by 002, custom made for King
-- Configuration

-- Use lowercase ["key"], only. The ["key"] is what you enter with the /armor command.
-- ["key"] = "tag", (surround with commas)
BIPEDS = {
    ["marine"] = "bourrin\\halo reach\\marine-to-spartan\\mp test",
    ["female"] = "bourrin\\halo reach\\spartan\\female\\female",
    ["117"] = "bourrin\\halo reach\\spartan\\male\\117",
    ["haunted"] = "bourrin\\halo reach\\spartan\\male\\haunted",
    ["default"] = "bourrin\\halo reach\\spartan\\male\\mp masterchief",
    ["odst"] = "bourrin\\halo reach\\spartan\\male\\odst",
}

-- End of Configuration

api_version = "1.7.0.0"

BIPED_IDS = {}
CHOSEN_BIPEDS = {}
DEFAULT_BIPED = nil

function OnScriptLoad()
    register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
    register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
    register_callback(cb['EVENT_COMMAND'],"OnCommand")
end

function OnScriptUnload()
    BIPED_IDS = {}
    DEFAULT_BIPED = nil
end

function OnCommand(PlayerIndex,Command,Environment,Password)
    if(player_present(PlayerIndex)) then
        Command = string.lower(Command)
        commandargs = {}
        for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
        if(commandargs[1] == "armor") then
            if(#commandargs == 1) then
                say(PlayerIndex,"Use /armor followed by the armor you wanted")
            elseif(#commandargs > 1) then
                armorwanted = Command:sub(commandargs[1]:len() + 2)
                if(BIPEDS[armorwanted] == nil) then
                    say(PlayerIndex,"Armor " .. armorwanted .. " does not exist.")
                else
                    CHOSEN_BIPEDS[get_var(PlayerIndex,"$hash")] = armorwanted
                    say(PlayerIndex,"You will respawn with " .. armorwanted .. " armor.")
                end
            end
            return false
        end
    end
    return true
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
    local hash = get_var(PlayerIndex,"$hash")
    if(MapID == DEFAULT_BIPED and CHOSEN_BIPEDS[hash]) then
        for key,value in pairs(BIPEDS) do
            if(BIPED_IDS[key] == nil) then
                BIPED_IDS[key] = FindBipedTag(BIPEDS[key])
            end
        end
        return true,BIPED_IDS[CHOSEN_BIPEDS[hash]]
    end
    return true
end

OnGameEnd = OnScriptUnload
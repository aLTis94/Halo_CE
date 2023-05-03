-- Disable Vehicle Damage by 002

api_version = "1.6.0.0"

function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
    OnGameStart()
end
function OnScriptUnload() end
function OnGameStart()
    local tag_array = read_dword(0x40440000)
    local tag_count = read_dword(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + 0x20 * i
        if(read_dword(tag) == 1835103335 and read_string(read_dword(tag + 0x10)) == "globals\\globals") then
            local tag_data = read_dword(tag + 0x14)
            local falling_damage_count = read_dword(tag_data + 0x188)
            local falling_damage = read_dword(tag_data + 0x188 + 4)
            for j=0,falling_damage_count-1 do
                local item = falling_damage + j * 152
                write_dword(item + 0x5C + 0xC,0xFFFFFFFF)
                write_dword(item + 0x5C + 0x4,0x0)
                write_dword(item + 0x5C + 0x0,0x0)
            end
        end
    end
end
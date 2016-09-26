-- Remove Empty Weapons by 002

api_version = "1.9.0.0"

function OnScriptLoad()
    object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
    if(object_table_ptr == 0) then
        cprint("Garbage Collection: object_table_ptr sig not found! Aborting")
        return
    end
    register_callback(cb['EVENT_TICK'],"GarbageCollection")
end

function OnScriptUnload()

end

function GarbageCollection()
    local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if(object ~= 0 and object ~= 0xFFFFFFFF) then
            local remove_this_object = false
            if(read_word(object + 0xB4) == 2 and read_bit(object + 0x1F4,0) == 0) then
                local tag_data = read_dword(lookup_tag(read_dword(object)) + 0x14)
                local tag_path = read_string(read_dword(lookup_tag(read_dword(object)) + 0x10))
                -- Don't remove the flag or oddball!
                if(read_bit(tag_data + 0x308,3) == 0) then
                    -- Check if battery-powered.
                    if(read_bit(tag_data + 0x308 + 1, 3) == 1) then
                        remove_this_object = read_float(object + 0x240) >= 1.0
                    -- Check if object uses a magazine. Some objects might not (e.g. Energy Sword)
                    elseif(read_dword(tag_data + 0x4F0) > 0) then
                        local primary_empty = read_word(object + 0x2B6) == 0 and read_word(object + 0x2B8) == 0
                        local secondary_empty = read_word(object + 0x2C6) == 0 and read_word(object + 0x2C8) == 0
                        remove_this_object = primary_empty and secondary_empty
                    end
                end
            end
            if(remove_this_object) then
                local object_id = read_word(first_object + i * 0xC) * 0x10000 + i
                destroy_object(object_id)
            end
        end
    end
end

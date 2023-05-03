-- Reverse Splatter by Kavawuvi ^v^

-- Upon running over someone, that person should not be killed?
DO_NOT_KILL_VICTIM = true


api_version = "1.10.0.0"
function OnScriptLoad()
    register_callback(cb['EVENT_GAME_START'],"oimateurgayXDDDDDDDdddd")
    oimateurgayXDDDDDDDdddd()
end
function OnScriptUnload() end

function oimateurgayXDDDDDDDdddd()
    local killed_unit_addr = lookup_tag("jpt!","globals\\vehicle_killed_unit")
    if killed_unit_addr == 0 then return end
    local killed_unit = read_dword(killed_unit_addr + 0x14)
    write_word(killed_unit + 0x1C4, 03)-- birbs are nice and cool but you are not
	write_float(killed_unit + 0x1D0, 100)
	write_float(killed_unit + 0x1D4, 100)
	write_float(killed_unit + 0x1D8, 100)
	write_float(killed_unit + 0x254, 0) -- don't watch that youtube video about ducks having sex it's distrurbing

	-- :-DDDDDDDDDD
    local collision_addr = lookup_tag("jpt!","globals\\vehicle_collision")
    if DO_NOT_KILL_VICTIM and collision_addr ~= 0 then
        local collision = read_dword(collision_addr + 0x14)
        write_float(collision + 0x1D0, 0)
        write_float(collision + 0x1D4, 0)
        write_float(collision + 0x1D8, 0)
		--Goose sucks big clean aubergines
    end
end

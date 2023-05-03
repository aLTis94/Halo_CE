-- Next Game by 002 v1.1

-- These are settings for the script's built-in command handler.
DISABLE_COMMAND_HANDLER = false
ADMIN_LEVEL_NEEDED = 4

-- End of configuration.

api_version = "1.9.0.0"
timer_seconds_address = nil
timer_seconds_address_2 = nil
game_over_state_address = nil

function OnScriptLoad()
    local timer_seconds_address_sig = sig_scan("C3D905????????D864240CD915????????D81D")
    if(timer_seconds_address_sig == 0) then return end

    local timer_seconds_address_2_sig = sig_scan("74??D905????????D864240CD915????????D81D")
    if(timer_seconds_address_2_sig == 0) then return end

    local game_over_state_address_sig = sig_scan("C705????????03??????75??C6")
    if(game_over_state_address_sig == 0) then return end

    timer_seconds_address = read_dword(timer_seconds_address_sig + 3)
    timer_seconds_address_2 = read_dword(timer_seconds_address_2_sig + 4)
    game_over_state_address = read_dword(game_over_state_address_sig + 2)

    if(DISABLE_COMMAND_HANDLER == false) then register_callback(cb['EVENT_COMMAND'],"OnCommand") end
end
function OnScriptUnload() end

function EditTimerOne()
    write_float(timer_seconds_address, -1.0)
    timer(100,"EditTimerTwo")
    return false
end

function EditTimerTwo()
    write_float(timer_seconds_address_2, -1.0)
    return false
end

function NextGameNow(PlayerIndex)
    if(read_dword(game_over_state_address) == 1) then
		execute_command("sv_map_next")
		write_float(timer_seconds_address, -1.0)
		timer(100,"EditTimerOne")
	else
		--say(PlayerIndex, "Invalid map or gametype!")
	end
end

function OnCommand(PlayerIndex,Command,Environment)
    if(Environment == 0 or tonumber(get_var(PlayerIndex,"$lvl")) >= ADMIN_LEVEL_NEEDED) then
	
		Command = string.lower(Command)
		MESSAGE = {}
		for word in string.gmatch(Command, "([^".." ".."]+)") do 
			table.insert(MESSAGE, word)
		end
		
		if MESSAGE[1] == "mf" and #MESSAGE > 2 then
			local map_name = MESSAGE[2]
			local gametype = MESSAGE[#MESSAGE]
			
			if #MESSAGE > 3 then
				for i=3,#MESSAGE-1 do
					map_name = map_name.." "..MESSAGE[i]
				end
			end
			
			say(PlayerIndex, "Loading map \""..map_name.."\" on gametype "..gametype)
			execute_command("map \""..map_name.."\" "..gametype)
			NextGameNow(PlayerIndex)
			return false
		end
    end
end

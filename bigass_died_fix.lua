--	Test

api_version = "1.9.0.0"

function OnScriptLoad()
	safe_read(false)
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnTick()
	for PlayerIndex = 1,16 do
        if(player_alive(PlayerIndex) == true) then
			local biped = get_dynamic_player(PlayerIndex)
			local vehicle_objectid = read_dword(biped + 0x11C)
			if(tonumber(vehicle_objectid) ~= 0xFFFFFFFF) then
				local vehicle_object = get_object_memory(vehicle_objectid)
				local damage_causer_id = read_dword(vehicle_object + 0x438)
				if(damage_causer_id ~= nil) then
					damage_causer = get_object_memory(damage_causer_id)
					if(damage_causer ~= 0) then
						rprint(1, damage_causer)
						write_dword(biped + 0x438, damage_causer)
						rprint(1, "|r"..read_dword(biped + 0x438))
					end
				end
			end
		end
	end
end

function OnScriptUnload()
end
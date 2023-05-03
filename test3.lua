
api_version = "1.12.0.0"


function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnScriptUnload() 
end

function OnTick()
	local player = get_dynamic_player(1)
	if player ~= 0 then
		cprint(read_float(player + 0x5C))
		--write_dword(player + 0x4, 2)
	end
end
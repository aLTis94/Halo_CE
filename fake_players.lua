api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnScriptUnload()
end

function OnTick()
	local m_player = get_player(1)
	if m_player ~= 0 then
		for i=0,0x200 do
			write_byte(m_player + 0x200 + i, read_byte(m_player + 0x200 + i))
		end
	end
end
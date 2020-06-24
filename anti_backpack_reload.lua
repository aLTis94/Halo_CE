-- by aLTis

api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnScriptUnload()
end

function OnTick()
	for i=1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 then
			for j=0,3 do
				local weapon_object_id = read_dword(player + 0x2F8 + j*4)
				local object = get_object_memory(weapon_object_id)
				if object ~= 0 then
					local weapon_active = read_bit(object + 0x10, 0)
					if weapon_active == 1 then
						write_word(object + 0x2B2, 255)
					end
				end
			end
		end
	end
end

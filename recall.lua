-- Recall script by aLTis
-- Wait a few seconds without moving or getting damaged to respawn

--CONFIG

	recall_command = "recall"
	recall_time = 8 -- seconds

--END OF CONFIG

api_version = "1.9.0.0"

WANTS_TO_SWITCH = {}

function OnScriptLoad()
	for i=1,16 do
		WANTS_TO_SWITCH[i] = -1
	end
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
end

function OnScriptUnload() end

function OnTick()
	for i=1,16 do
		if player_alive(i) == true then
			local player = get_player(i)
			local player_object = get_dynamic_player(i)
			local unit_forward = read_float(player_object + 0x278)
			local unit_left = read_float(player_object + 0x27C)
			local shooting = read_float(player_object + 0x490)
			local vehicle = get_object_memory(read_dword(player_object + 0x11C))
			local flag = read_dword(read_dword(read_dword(lookup_tag("matg","globals\\globals") + 0x14) + 0x164 + 4) + 0x0 + 0xC)
			local ball = read_dword(read_dword(read_dword(lookup_tag("matg","globals\\globals") + 0x14) + 0x164 + 4) + 0x4C + 0xC)
			local held_obj_id = read_dword(player_object + 0x118)
			local weapon_metaid = nil
			if held_obj_id ~= 0xFFFFFFFF then
				local held_weapon = get_object_memory(held_obj_id)
				weapon_metaid = read_dword(held_weapon)
			end
			
			if WANTS_TO_SWITCH[i] > 0 then
				WANTS_TO_SWITCH[i] = WANTS_TO_SWITCH[i] - 1
				if unit_forward ~= 0 or unit_left ~= 0 then
					WANTS_TO_SWITCH[i] = -1
					say(i, "You moved! Respawn cancelled")
				elseif shooting == 1 then
					WANTS_TO_SWITCH[i] = -1
					say(i, "You shot! Respawn cancelled")
				elseif vehicle ~= 0 then
					WANTS_TO_SWITCH[i] = -1
					say(i, "You can't recall in a vehicle")
				elseif weapon_metaid == flag then
					WANTS_TO_SWITCH[i] = -1
					say(i, "You can't recall while holding a flag")
				elseif weapon_metaid == ball then
					WANTS_TO_SWITCH[i] = -1
					say(i, "You can't recall while holding the oddball")
				end
			elseif
				WANTS_TO_SWITCH[i] == 0 then
				WANTS_TO_SWITCH[i] = -1
				local object = read_dword(player + 0x34)
				if object ~= 0 then
					destroy_object(object)
				end
			end
		else
			WANTS_TO_SWITCH[i] = -1
		end
	end
end

function OnDamage(PlayerIndex)
	if WANTS_TO_SWITCH[PlayerIndex] > 0 then
		say(PlayerIndex, "You were damaged! Respawn cancelled")
		WANTS_TO_SWITCH[PlayerIndex] = -1
	end
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	if Command == recall_command then
		say(PlayerIndex, "Wait "..recall_time.." seconds without moving to respawn")
		WANTS_TO_SWITCH[PlayerIndex] = recall_time * 30
		return false
	end
	return true
end
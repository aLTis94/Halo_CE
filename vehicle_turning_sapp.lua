api_version = "1.12.0.0"

-- CONFIG
	
	local turn_rate_multiplier = 1
	local turn_amount_multiplier = 1
	
	local decrease_desync = true -- improves vehicle sync but makes them look more jittery
	local vehicle_update_rate = 5 -- lower means better sync but more jittery
	
--END OF CONFIG

local VEHICLES = nil

function OnScriptLoad()
	object_table = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_GAME_START'],"OnMapLoad")
	register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
	for i=1,16 do
		SendConsoleMessages(i)
	end
end

function OnMapLoad()
	VEHICLES = nil
end

function OnScriptUnload()
	local object_count = read_word(object_table + 0x2E)
	if object_count ~= 0 then --IF SAPP WAS RELOADED
		for tag, info in pairs (VEHICLES) do
			local turn_rate = read_float(info.tag_data + 0x314)
			if turn_rate == 0 then
				write_float(info.tag_data + 0x314, info.turn_rate)
			end
		end
	end
	ChangeSync(false)
end

function OnPlayerJoin(i)
	timer(1000, "SendConsoleMessages", i)
end

function OnTick()
	if VEHICLES == nil then
		VEHICLES = {}
		FindVehiTags()
	end
	
	for i=1,16 do
		local m_unit = get_dynamic_player(i)
		if m_unit ~= 0 then
			local vehicle = get_object_memory(read_dword(m_unit + 0x11C))
			if vehicle ~= 0 then
				local tag_id = read_dword(vehicle)
				if VEHICLES[tag_id] ~= nil then
					local forward = read_float(vehicle + 0x278)
					local left = read_float(vehicle + 0x27C)
					local turn = read_float(vehicle + 0x4DC)
					left = left + left*math.abs(forward)/2 -- makes it more consistant when driving forwards or backwards
					
					local turn_rate = math.rad(VEHICLES[tag_id].turn_rate)/30*turn_rate_multiplier
					
					if left ~= 0 then
						turn = turn + left*turn_rate
					elseif turn > 0 then
						turn = turn - turn_rate
						if turn < 0 then
							turn = 0
						end
					elseif turn < 0 then
						turn = turn + turn_rate
						if turn > 0 then
							turn = 0
						end
					end
					
					if turn < -VEHICLES[tag_id].max_turn then
						turn = -VEHICLES[tag_id].max_turn
					elseif turn > VEHICLES[tag_id].max_turn then
						turn = VEHICLES[tag_id].max_turn
					end
					
					write_float(vehicle + 0x4DC, turn)
				end
			end
		end
	end
end

function SendConsoleMessages(i)
	i = tonumber(i)
	rprint(i, "You must have keyboard vehicle turning lua script for this to work!|ncFC0303")
	rprint(i, "Turning~"..turn_rate_multiplier.."~"..turn_amount_multiplier)
end

function FindVehiTags()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		if tag_class == 0x76656869 then
			local tag_id = read_dword(tag + 0xC)
			if VEHICLES[tag_id] == nil then
				local tag_data = read_dword(tag + 0x14)
				local vehicle_type = read_byte(tag_data + 0x2F4)
				if vehicle_type == 0 or vehicle_type == 1 then
					local turn_rate = read_float(tag_data + 0x314)
					local max_turn = read_float(tag_data + 0x308)
					if turn_rate == 0 then
						turn_rate = 90
					end
					if max_turn == 0 then
						max_turn = 8
					end
					VEHICLES[tag_id] = {}
					VEHICLES[tag_id].max_turn = math.rad(max_turn)*turn_amount_multiplier
					VEHICLES[tag_id].turn_rate = turn_rate
					VEHICLES[tag_id].tag_data = tag_data
					write_float(tag_data + 0x314, 0)
				end
			end
		end
	end
	
	for tag_id, info in pairs (VEHICLES) do
		ChangeSync(true)
		break
	end
	
	return nil
end

function ChangeSync(enable)
	if decrease_desync then
		if enable then
			execute_command("use_new_vehicle_update_scheme false")
			execute_command("vehicle_incremental_rate 10")
		else
			execute_command("use_new_vehicle_update_scheme true")
			execute_command("vehicle_incremental_rate "..vehicle_update_rate)
		end
	end
end

function ClearConsole()
	for j=0,25 do
		rprint(1, " ")
	end
end
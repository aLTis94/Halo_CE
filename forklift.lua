
api_version = "1.12.0.0"

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
end

FORKS = {}
timer = 10
HAY = nil

function OnScriptUnload()
	for i=1,16 do
		if FORKS[i] ~= nil then
			local fork_object = get_object_memory(FORKS[i])
			if fork_object ~= 0 then
				destroy_object(FORKS[i])
			end
		end
	end
end

function OnGameStart()
	HAY = nil
	FORKS = {}
end

function FindForklift()
	timer = timer - 1
	if timer < 1 then
		timer = 100
	else
		return true
	end
	
	HAY = {}
	
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = get_object_memory(ID)
		if object ~= 0 and read_word(object + 0xB4) == 1 then
			local name = GetName(object)
			if name == "altis\\scenery\\hay\\hay" then
				HAY[object] = 1
			end
		end
	end
	return true
end

function OnTick()
	if HAY == nil and FindForklift() then
		return false
	end
	
	for hay_object,TYPE in pairs (HAY) do 
		write_word(hay_object + 0x5AC, 65535)
	end
	
	for i = 1,16 do
		local player = get_dynamic_player(i)
		local has_fork = false
		if player ~= 0 then
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 and GetName(vehicle) == "altis\\vehicles\\forklift\\forklift" then
				has_fork = true
				if FORKS[i] ~= nil and get_object_memory(FORKS[i]) ~= 0 then
					local fork_object = get_object_memory(FORKS[i])
					--local function4 = read_float(vehicle + 0x140)
					
					local player_id = read_dword(stats_globals + to_real_index(i)*48 + 0x4)
					write_dword(fork_object + 0xC0, player_id)
					write_dword(fork_object + 0xC4, read_dword(get_player(i) + 0x34))
					write_bit(fork_object + 0x10, 5, 0)
					
					write_float(fork_object + 0x5C, read_float(vehicle + 0x5C0 + 0x34 * 6 + 0x28) + read_float(vehicle + 0x68))
					write_float(fork_object + 0x60, read_float(vehicle + 0x5C0 + 0x34 * 6 + 0x2C) + read_float(vehicle + 0x6C))
					write_float(fork_object + 0x64, read_float(vehicle + 0x5C0 + 0x34 * 6 + 0x30) + read_float(vehicle + 0x70))
					
					--write_float(fork_object + 0x5C, read_float(vehicle + 0x5C))
					--write_float(fork_object + 0x60, read_float(vehicle + 0x60))
					--write_float(fork_object + 0x64, read_float(vehicle + 0x64) + function4*0.83 - 0.38)
					
					write_float(fork_object + 0x68, read_float(vehicle + 0x68))
					write_float(fork_object + 0x6C, read_float(vehicle + 0x6C))
					write_float(fork_object + 0x70, read_float(vehicle + 0x70))
					
					write_float(fork_object + 0x74, read_float(vehicle + 0x74))
					write_float(fork_object + 0x78, read_float(vehicle + 0x78))
					write_float(fork_object + 0x7C, read_float(vehicle + 0x7C))
					
					write_float(fork_object + 0x80, read_float(vehicle + 0x80))
					write_float(fork_object + 0x84, read_float(vehicle + 0x84))
					write_float(fork_object + 0x88, read_float(vehicle + 0x88))
					
					write_float(fork_object + 0x8C, read_float(vehicle + 0x8C))
					write_float(fork_object + 0x90, read_float(vehicle + 0x90))
					write_float(fork_object + 0x94, read_float(vehicle + 0x94))
				else
					FORKS[i] = spawn_object("vehi", "altis\\vehicles\\forklift\\fork\\fork", 0, 0, 20)
					--rprint(1, "spawned")
				end
			end
		end
		
		if has_fork == false then
			if FORKS[i] ~= nil then
				--rprint(1, "destroyed")
				if get_object_memory(FORKS[i]) ~= 0 then
					destroy_object(FORKS[i])
				end
				FORKS[i] = nil
			end
		end
	end
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end
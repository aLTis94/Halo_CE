-- Vehicle Health script by aLTis. Version 1.1.0
-- Makes vehicles like Falcon destructible, shows their health on hud, plays a warning sound on low health (only if player has chimera)
api_version = "1.12.0.0"

-- CONFIG
	
	--(WARNING!!! This feature requires damage_module.dll)
	-- This will try to fix "died" message when player gets killed in a vehicle
	died_fix = true
	
	vehicle_respawn_time = 30 -- seconds
	vehicle_part_lifetime = 29 -- seconds
	vehicle_explosion_delay = 20--66 -- ticks
	
	sound_timer = 27 --How often the warning sound plays (only for players with chimera)
	
	-- Vehicles and their destroyed variants
	VEHICLE_TAGS = {
		["vehicles\\falcon\\falcon"] = {"vehicles\\falcon_destroyed\\falcon_destroyed", 0x1, 2, 0.001, 0},
		["halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\military truck"] = {"altis\\vehicles\\truck_destroyed\\truck_destroyed", 0, 0, 0.04, 0},
		["altis\\vehicles\\scorpion\\scorpion"] = {"altis\\vehicles\\scorpion_destroyed\\scorpion_destroyed", 0, 0, 0.007, 0},
	}
	
	vehicle_parts_effect_tag = "vehicles\\falcon_destroyed\\spawn_parts"
	
	DESTROYED_VEHICLE_PARTS = {
		"vehicles\\falcon_destroyed\\left_wing\\left_wing",
		"vehicles\\falcon_destroyed\\right_wing\\right_wing",
		"vehicles\\falcon_destroyed\\tail\\tail",
		"altis\\vehicles\\truck_destroyed\\wheel\\wheel",
	}
	
	smoke_tag = "altis\\weapons\\smoke\\smoke"
	
	script_room_x = -111
	script_room_y = -192
	script_room_z = -108

-- END_OF_CONFIG

VEHICLES = {}
VEHICLE_TAG_IDS = {}
DESTROYED_VEHICLE_PARTS_IDS = {}
DESTROYED_VEHICLE_PARTS_OBJECTS = {}

function GetDamageModule()
	ffi = require("ffi")
	ffi.cdef [[
		void damage_object(float amount, uint32_t receiver, int8_t causer);
		void damage_player(float amount, uint8_t receiver, int8_t causer);
	]]
	damage_module = ffi.load("damage_module")
	damage_object = damage_module.damage_object
	damage_player = damage_module.damage_player
end

function OnScriptLoad()
	
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	
	Initialize()
	if died_fix then
		GetDamageModule()
	end
end

function OnGameStart()
	VEHICLES = {}
	VEHICLE_TAG_IDS = {}
	DESTROYED_VEHICLE_PARTS_IDS = {}
	DESTROYED_VEHICLE_PARTS_OBJECTS = {}
	Initialize()
end

function GetTime()
	return tonumber(get_var(0, "$ticks"))
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	if VEHICLE_TAG_IDS[MetaID] ~= nil then
		VEHICLES[ID] = {}
		VEHICLES[ID].name = VEHICLE_TAG_IDS[MetaID]
		VEHICLES[ID].destroyed = false
		VEHICLES[ID].respawning = 0
	elseif DESTROYED_VEHICLE_PARTS_IDS[MetaID] ~= nil then
		DESTROYED_VEHICLE_PARTS_OBJECTS[ID] = GetTime()
	end
end

function RemoveVehicle(ID)
	ID = tonumber(ID)
	if get_object_memory(ID) ~= 0 then
		destroy_object(ID)
	end
	DESTROYED_VEHICLE_PARTS_OBJECTS[ID] = nil
end

function OnTick()
	SetUIStuff()
	
	local ticks = GetTime()
	
	--VEHICLE PARTS
	for ID,spawn_time in pairs (DESTROYED_VEHICLE_PARTS_OBJECTS) do
		local object = get_object_memory(ID)
		if object then
			local lifetime = (ticks - spawn_time)/30
			if lifetime > vehicle_part_lifetime then
				RemoveVehicle(ID)
			end
		else
			DESTROYED_VEHICLE_PARTS_OBJECTS[ID] = nil
		end
	end
	
	--VEHICLES
	for ID,info in pairs (VEHICLES) do 
		if VEHICLES[ID].damage_timer ~= nil then
			if ticks - VEHICLES[ID].damage_timer > 400 then
				VEHICLES[ID].damage_timer = nil
				VEHICLES[ID].damager = nil
				--rprint(1, "removed")
			end
		end
		local object = get_object_memory(ID)
		if object ~= 0 then
			local x = read_float(object + 0x5C)
			local y = read_float(object + 0x60)
			local z = read_float(object + 0x64)
			if VEHICLES[ID].respawning > 0 then
				write_float(object + 0x68, 0)
				write_float(object + 0x6C, 0)
				write_float(object + 0x70, 0)
				write_float(object + 0x8C, 0)
				write_float(object + 0x90, 0)
				write_float(object + 0x94, 0)
				VEHICLES[ID].respawning = VEHICLES[ID].respawning - 1
			end
			if info.destroyed == false then
				--Getting damager
				GetDamager(ID)
				if VEHICLES[ID].smoke ~= nil and get_object_memory(VEHICLES[ID].smoke) ~= 0 then
					destroy_object(VEHICLES[ID].smoke)
				end
				VEHICLES[ID].smoke = nil
				local shields = read_float(object + 0xE4)
				if shields < 0.4 then
					if shields == 0 then
						KillPassengers(ID)
					else
						if VEHICLES[ID].smoke == nil then
							--x = x + read_float(object + 0x5C0 + VEHICLE_TAGS[VEHICLES[ID].name][3]*0x34)
							--y = y + read_float(object + 0x5C4 + VEHICLE_TAGS[VEHICLES[ID].name][3]*0x34)
							--z = z + read_float(object + 0x5C8 + VEHICLE_TAGS[VEHICLES[ID].name][3]*0x34)
							VEHICLES[ID].smoke = spawn_object("weap", smoke_tag, x, y, z)
						elseif get_object_memory(VEHICLES[ID].smoke) ~= 0 then
							destroy_object(VEHICLES[ID].smoke)
							VEHICLES[ID].smoke = nil
						end
					end
				end
				
			--DESTROYED VEHICLES
			elseif VEHICLES[ID].destroyed_vehicle ~= nil then
				write_float(object + 0xE4, 1)
				VEHICLES[ID].respawning = 5
				
				local lifetime = (ticks - VEHICLES[ID].destroyed_time)/30
				if lifetime > vehicle_respawn_time - 1 then
					if get_object_memory(VEHICLES[ID].destroyed_vehicle) ~= 0 then
						destroy_object(VEHICLES[ID].destroyed_vehicle)
					end
					VEHICLES[ID].destroyed_vehicle = nil
					VEHICLES[ID].destroyed = false
				end
			end
		else
			--Vehicle is gone but not destroyed!
			VEHICLES[ID] = nil
		end
	end
end

function GetDamager(ID)
	local object = get_object_memory(ID)
	if object == 0 then return end
	
	local damager = read_word(object + 0x43C+2)
	if damager ~= 0xFFFF then
		local ticks = GetTime()
		local damage_time = read_dword(object + 0x430)
		if ticks - damage_time < 1 then
			for i=1,16 do
				local m_player = get_player(i)
				if m_player ~= 0 then
					local player_id = read_word(m_player)
					if damager == player_id then
						VEHICLES[ID].damager = i
						VEHICLES[ID].damage_timer = damage_time
						break
					end
				end
			end
		end
	end
end

function DestroyVehicle(ID)
	ID = tonumber(ID)
	
	if VEHICLES[ID].destroyed == true then return false end
	
	local object = get_object_memory(ID)
	if object == 0 then
		say_all("Error destroying a vehicle!")
		return false
	end
	
	-- make sure no players entered the vehicle as it's being DESTROYED
	if CheckPassengers(ID) > 0 then
		return true
	end
	
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	
	--set respawn time
	write_dword(object + 0x5AC, (GetTime() - (60 - vehicle_respawn_time)*30))
	
	VEHICLES[ID].destroyed_time = GetTime()
	VEHICLES[ID].destroyed = true
	MoveToScriptRoom(ID)
	timer(1, "SpawnDeadVehicle", ID, x, y, z)
	
	return false
end

function SpawnDeadVehicle(ID, x, y, z)
	ID = tonumber(ID)
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)
	
	VEHICLES[ID].destroyed_vehicle = spawn_object("vehi", VEHICLE_TAGS[VEHICLES[ID].name][1], x, y, z)
	
	local destroyed_object = get_object_memory(VEHICLES[ID].destroyed_vehicle)
	local object = get_object_memory(ID)
	if destroyed_object ~= 0 then
		write_float(destroyed_object + 0x5C, x)
		write_float(destroyed_object + 0x60, y)
		write_float(destroyed_object + 0x64, z)
		write_float(destroyed_object + 0x68, read_float(object + 0x68))
		write_float(destroyed_object + 0x6C, read_float(object + 0x6C))
		write_float(destroyed_object + 0x70, read_float(object + 0x70) + 0.02)
		write_float(destroyed_object + 0x74, read_float(object + 0x74))
		write_float(destroyed_object + 0x78, read_float(object + 0x78))
		write_float(destroyed_object + 0x7C, read_float(object + 0x7C))
		write_float(destroyed_object + 0x80, read_float(object + 0x80))
		write_float(destroyed_object + 0x84, read_float(object + 0x84))
		write_float(destroyed_object + 0x88, read_float(object + 0x88))
	end
	return false
end

function CheckPassengers(ID)
	local passengers = 0
	for i = 1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local vehicle = read_dword(player + 0x11C)
			if vehicle == ID then
				passengers = passengers + 1
				if died_fix and VEHICLES[ID].damager ~= nil and damage_module ~= nil then
					--Dealing damage to player
					damage_player(10000, to_real_index(i), to_real_index(VEHICLES[ID].damager))
					--say_all("player "..get_var(i, "$name").." was killed by "..get_var(VEHICLES[ID].damager, "$name"))
				else
					kill(i)
				end
			end
		end
	end
	return passengers
end

function KillPassengers(ID)
	local object = get_object_memory(ID)
	if object == 0 then
		say_all("Error killing passengers")
		return false
	end
	
	if died_fix then
		GetDamager(ID)
	end
	
	if CheckPassengers(ID) == 0 then
		timer(vehicle_explosion_delay, "DestroyVehicle", ID)
	end
end

function Initialize()
	local vehicle_parts_effect = lookup_tag("effe", vehicle_parts_effect_tag)
	if vehicle_parts_effect == 0 then 
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
		return false 
	end
	
	-- set up falcon parts effect
	local tag_data = read_dword(vehicle_parts_effect + 0x14)
	local events_struct = read_dword(tag_data + 0x34 + 4)
	write_float(events_struct + 0x08, 0.09)
	write_float(events_struct + 0x0C, 0.09)
	
	-- reduce rider damage fraction
	for vehicle_tag,info in pairs (VEHICLE_TAGS) do
		local vehicle_tag = lookup_tag("vehi", vehicle_tag)
		if vehicle_tag ~= 0 then
			vehicle_tag = read_dword(vehicle_tag + 0x14)
			write_float(vehicle_tag + 0x184, info[4])
			local collision_tag = read_dword(vehicle_tag + 0x70 + 0xC)
			collision_tag = lookup_tag(collision_tag)
			if collision_tag ~= 0 then
				collision_tag = read_dword(collision_tag + 0x14)
				write_bit(collision_tag, 3, info[5])
			end
		end
	end
	
	
	register_callback(cb['EVENT_OBJECT_SPAWN'], "OnObjectSpawn")
	
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = get_object_memory(ID)
		if object ~= 0 and read_word(object + 0xB4) == 1 then
			local name = GetName(object)
			if VEHICLE_TAGS[name] ~= nil then
				VEHICLES[ID] = {}
				VEHICLES[ID].name = name
				VEHICLES[ID].destroyed = false
				VEHICLES[ID].respawning = 0
			end
		end
	end
	
	VEHICLE_TAG_IDS = {}
	DESTROYED_VEHICLE_PARTS_IDS = {}
	for name,info in pairs (VEHICLE_TAGS) do 
		local MetaID = GetMetaID("vehi", name)
		if MetaID ~= nil then
			VEHICLE_TAG_IDS[MetaID] = name
		end
	end
	for id,name in pairs (DESTROYED_VEHICLE_PARTS) do 
		local MetaID = GetMetaID("vehi", name)
		if MetaID ~= nil then
			DESTROYED_VEHICLE_PARTS_IDS[MetaID] = 1
		end
	end
end

function MoveToScriptRoom(ID)
	local object = get_object_memory(ID)
	if object ~= 0 then
		write_bit(object + 0x10, 5, 0)
		write_float(object + 0x5C, script_room_x)
		write_float(object + 0x60, script_room_y)
		write_float(object + 0x64, script_room_z)
	end
end

function SetUIStuff()
	sound_timer = sound_timer - 1
	if sound_timer == 0 then
		sound_timer = 27
	end

	for i=1,16 do
		if player_alive(i) then
			local player_object = get_dynamic_player(i)
			local vehicle_objectid = read_dword(player_object + 0x11C)		--			Check in which vehicle player is
			local vehicle_object = get_object_memory(vehicle_objectid)
			
			if vehicle_object ~= 0 then
				local vehicle_name = GetName(vehicle_object)
				
				for name, info in pairs(VEHICLE_TAGS) do
					if vehicle_name == name then			--							Check if vehicle is in the VEHICLES list
						local weapon = read_dword(vehicle_object + 0x2F8)	--			Get vehicle's weapon
						local weapon_object = get_object_memory(weapon)
						if weapon_object ~= 0 then
							local armor = read_float(vehicle_object + 0xE4)	--		Get vehicle's shield value (vehicles use shields, not actual health)
							if armor < 0.4 and sound_timer == 1 then
								PlaySound(i, "transition")
							end
							armor = math.floor(armor * 85 + 0.5)			--		Multiply armor value by 85 so it would display correctly on hud meter
							write_word(weapon_object + 0x2B6 + info[2]*0xC, armor)	--	Change ammo in halo's memory
						end
					end
				end
			end
		end
	end
end

function PlaySound(i, sound)
	if get_var(i, "$has_chimera") == "1" then
		rprint(i, "play_chimera_sound~"..sound)
	end
end

function OnScriptUnload()
	for ID,info in pairs (VEHICLES) do 
		if info.destroyed == true then
			if VEHICLES[ID].destroyed_vehicle ~= nil and get_object_memory(VEHICLES[ID].destroyed_vehicle) ~= 0 then
				destroy_object(VEHICLES[ID].destroyed_vehicle)
			end
		end
		if VEHICLES[ID].smoke ~= nil and get_object_memory(VEHICLES[ID].smoke) ~= 0 then
			destroy_object(VEHICLES[ID].smoke)
		end
	end
	for ID,info in pairs (DESTROYED_VEHICLE_PARTS_OBJECTS) do 
		if get_object_memory(ID) ~= 0 then
			destroy_object(ID)
		end
	end
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= 0) then
		return read_dword(address + 0xC)
	end
	return nil
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Finds distance between two coordinates (from 002)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function OnError(Message)
	say_all("Error! "..Message)
end
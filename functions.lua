

api_version = "1.9.0.0"

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D") -- used for FindAllObjects()
	stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3) -- used for SetOwnerID()
end

function OnScriptUnload()
end

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function DistanceBetweenObjects(ID1, ID2)-- Finds distance between 2 objects, returns -1 if can't find it (requires DistanceFormula)
	local object1 = get_object_memory(ID1)
	local object2 = get_object_memory(ID1)
	if object1 ~= 0 and object2 ~= 0 then
		local x1, y1, z1 = read_vector3d(object1 + 0x5C)
		local x2, y2, z2 = read_vector3d(object2 + 0x5C)
		return DistanceFormula(x1,y1,z1,x2,y2,z2)
	else
		return -1, -1, -1
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Finds distance between two coordinates (from 002)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function MoveObject(ID, x, y, z)-- Moves object to given coordinates
	local object = get_object_memory(ID)
	if object ~= 0 and x ~= nil and y ~= nil and z ~= nil then
		write_bit(object + 0x10, 5, 0)-- makes object not static
		write_vector3d(object + 0x5C, x, y, z)
	end
end

function SetVelocity(ID, x_vel, y_vel, z_vel)-- Sets object velocity
	local object = get_object_memory(ID)
	if object ~= 0 and x_vel ~= nil and y_vel ~= nil and z_vel ~= nil then
		write_bit(object + 0x10, 5, 0)-- makes object not static
		write_vector3d(object + 0x68, x_vel, y_vel, z_vel)
	end
end

function GetMetaID(object_type, object_dir)-- Finds MetaID of a tag
	local address = lookup_tag(object_type,object_dir)
	if address ~= 0 then
		return read_dword(address + 0xC)
	end
	return nil
end

function GetName(DynamicObject)--	Gets directory of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function GetDamagerID(ID)-- Checks which player damaged the biped (from 002)
	local biped_object = get_object_memory(ID)
	local damage_causer = nil
	if biped_object ~= 0 then
		for k=0,3 do
			local struct = biped_object + 0x430 + 0x10 * k
			local damager_pid = read_word(struct + 0xC)
			if(damager_pid ~= 0xFFFF) then
				damage_causer = tonumber(to_player_index(damager_pid))
			end
		end
	end
	return damage_causer
end

function SetOwnerID(ID, i)-- Sets objects owner to be a player
	local object = get_object_memory(ID)
	if object ~= 0 then
		local player_id = read_dword(stats_globals + to_real_index(i)*48 + 0x4)
		write_dword(object + 0xC0, player_id)
		write_dword(object + 0xC4, read_dword(get_player(i) + 0x34))
	end
end

function GetPlayerAimLocation(i)--	Finds coordinates at which player is looking (from giraffe)
	local player = get_dynamic_player(i)
	local px, py, pz = read_vector3d(player + 0x5c)
    local vx, vy, vz = read_vector3d(player + 0x230)
    local cs = read_float(player + 0x50C)
    local h = 0.62 - (cs * (0.62 - 0.35))
    pz = pz + h
	local hit, x, y , z = intersect(px, py, pz, 10000*vx, 10000*vy, 10000*vz, read_dword(get_player(i) + 0x34))
	local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - 0.1
	return intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(i) + 0x34))
end

function FindAllObjects()-- Goes through all objects that currently exist on the map
	local object_table = read_u32(read_u32(0x401192 + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
        local object = read_dword(first_object + i * 0xC + 0x8)
        if object ~= 0 and object ~= 0xFFFFFFFF then
			local object_type = read_word(object + 0xB4)
			-- do something with object here
		end
	end
end

function SyncAmmo(i)-- Synchronizes ammo for all weapons for this player
	i = tonumber(i)
	if player_alive(i) then
		local player = get_dynamic_player(i)
		for j = 0,3 do
			local currentWeapon = read_dword(player + 0x2F8 + j*0x4)
			if get_object_memory(currentWeapon) ~= 0 then
				sync_ammo(currentWeapon, 1)
			end
		end
	end
end
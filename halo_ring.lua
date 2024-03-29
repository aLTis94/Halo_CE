
--CONFIG
	local min_velocity = 0.001
	local bipd_z_offset = -0.2
--END OF CONFIG

api_version = "1.12.0.0"

local gravity_vel = 0.003565 * 1
local script_active = false

local find = string.find
local abs = math.abs
local sqrt = math.sqrt
local floor = math.floor

local ITEMS = {}
local WEAPONS = {}
local PLAYER_POSITIONS = {}
local VEHICLES = {}
local GRENADES = {}

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_GAME_START'],"OnMapLoad")
	CheckMap()
end

function OnScriptUnload()
end

function EditTags()
	
	GRENADES = {}
	GRENADES[read_dword(lookup_tag("proj", "weapons\\frag grenade\\frag grenade") + 0xC)] = true
	GRENADES[read_dword(lookup_tag("proj", "weapons\\plasma grenade\\plasma grenade") + 0xC)] = true
	
	WEAPONS = {}
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
		if tag_class == 0x77656170 then --weap
			local tag_id = read_dword(tag + 0xC)
			local name = read_string(read_dword(tag + 0x10))
			local tag_data = read_dword(tag + 0x14)
			
			write_float(tag_data + 0x20, 0) -- acceleration scale
			
			local model_tag = lookup_tag(read_dword(tag_data + 0x28 + 0xC))
			if model_tag ~= 0 then
				local model_tag_data = read_dword(model_tag + 0x14)
				WEAPONS[tag_id] = read_dword(model_tag_data + 0xB8) -- get node count
			end
			
			write_float(tag_data + 0x3E4, 0)--auto aim angle
			write_float(tag_data + 0x3F4, 0)--deviation angle
		
		elseif tag_class == 0x65716970 then --eqip
			local tag_data = read_dword(tag + 0x14)
			
			write_float(tag_data + 0x20, 0) -- acceleration scale
			
		elseif tag_class == 0x70726f6a then --proj
			local tag_data = read_dword(tag + 0x14)
			local range = read_float(tag_data + 0x1C8)
			
			--Increase projectile range
			if (range < 120 and range > 25) or range == 0 then
				write_float(tag_data + 0x1C8, 128)
			end
		elseif tag_class == 0x62697064 then -- bipd
			local tag_data = read_dword(tag + 0x14)
			--write_bit(tag_data + 0x2F4, 31-30, 1)
		end
	end
end

function CheckMap()
	ITEMS = {}
	VEHICLES = {}
	if lookup_tag("senv", "altis\\levels\\halo\\shaders\\halo outer ring bsp") ~= 0 then
		script_active = true
		EditTags()
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		return true
	else
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
		script_active = false
		return false
	end
end

function OnMapLoad()
	CheckMap()
end

function OnObjectSpawn(i, MetaID, ParentID, ObjectID)
	if GRENADES[MetaID] ~= nil then
		timer(33, "GrenadeCheck", ObjectID,i)
	end
end

function GrenadeCheck(ObjectID,i)
	ObjectID = tonumber(ObjectID)
	i = tonumber(i)
	local object = get_object_memory(ObjectID)
	if object ~= 0 then
		local parent = read_dword(object + 0x11C)
		if parent == 0xFFFFFFFF then
			local player = get_dynamic_player(i)
			if player ~= 0 then
				local parent2 = read_dword(player + 0x11C)
				if parent2 == 0xFFFFFFFF then
					local x,y,z = read_vector3d(player + 0x5C)
					local distance = sqrt(x*x + z*z)
					local rot_x = x / distance
					local rot_z = z / distance
					local cs = read_float(player + 0x50C)
					local h = 0.42 - (cs * (0.27))
					local x_aim,y_aim,z_aim = read_vector3d(player + 0x224)
					local m = 0.3
					write_vector3d(object + 0x5C, x - h*rot_x + x_aim*m, y + y_aim*m, z - h*rot_z + z_aim*m)
				end
			end
		else
			return true
			--timer(33, "GrenadeCheck", ObjectID,i)
		end
	end
	return false
end

function WeaponPickup(ID,object,x,y,z)
	for j=1,16 do
		local m_player = get_player(j)
		local player = get_dynamic_player(j)
		if m_player ~= 0 and player ~= 0 then
			local x2,y2,z2 = read_vector3d(player + 0x5C)
			local distance = GetDistance(x,y,z,x2,y2,z2)
			local interaction_type = read_word(m_player + 0x28)
			if distance < 1 and interaction_type ~= 8 then
				local has_weapons = false
				local name = GetName(object)
				local tag_id = read_dword(object)
				local already_has_this = false
				local weap_slot = read_word(player + 0x2F2)
				if find(name, "flag") == nil and find(name, "ball") == nil then
					for k=0,3 do
						local weapon = get_object_memory(read_dword(player + 0x2F8 + k*4))
						if weapon ~= 0 and weap_slot ~= k then
							has_weapons = true
							if read_dword(weapon) == tag_id then
								already_has_this = true
							end
						end
					end
				end
				
				if already_has_this == false then
					-- check weapon that player is already trying to interact with
					local closer = true
					local object = get_object_memory(read_dword(m_player + 0x24))
					if object ~= 0 then
						local x3,y3,z3 = read_vector3d(object + 0x5C)
						local distance2 = GetDistance(x2,y2,z2,x3,y3,z3)
						if distance2 < distance then
							closer = false
						end
					end
					
					if closer then
						write_dword(m_player + 0x24, ID)
						if has_weapons then
							write_word(m_player + 0x28, 6)
						else
							write_word(m_player + 0x28, 7)
						end
					end
				end
			end
		end
	end
end

function VehicleEnter(ID,object,x,y,z)
	
	if VEHICLES[ID] == nil then
		VEHICLES[ID] = {}
	end
	
	-- this fixes vehicle rotation when it respawns
	if VEHICLES[ID].x == nil or GetDistance(x,y,z,VEHICLES[ID].x,VEHICLES[ID].y,VEHICLES[ID].z) > 0.5 then
		local distance = sqrt(x*x + z*z)
		local rot_x = x / distance
		local rot_z = z / distance
		local a = GetAnglesFrom3DVector(rot_x,rot_z,0)*-1
		if VEHICLES[ID].x ~= nil then
			a=a*2
		end
		local x1,y1,z1 = read_vector3d(object + 0x74)
		write_vector3d(object + 0x74,  RotateVectorOnY(x1,y1,z1,a))
		--rprint(1, x.."  angle "..math.deg(a))
		write_vector3d(object + 0x80,  0, 0, 1)
	end
	VEHICLES[ID].x,VEHICLES[ID].y,VEHICLES[ID].z = x,y,z
	
	local name = GetName(object)
	
	for i=1,16 do
		local m_player = get_player(i)
		local player = get_dynamic_player(i)
		if m_player ~= 0 and player ~= 0 then
			local x2,y2,z2 = read_vector3d(player + 0x5C)
			local distance = GetDistance(x,y,z,x2,y2,z2)
			if distance < 1.8 and find(name, "warthog") ~= nil then
				local x2,y2,z2 = read_vector3d(object + 0x5C0 + 0*0x34 + 0x28)
				local x3,y3,z3 = read_vector3d(object + 0x5C0 + 13*0x34 + 0x28)
				local dist_hull = sqrt(x2*x2 + z2*z2)
				local dist_barrels = sqrt(x3*x3 + z3*z3)
				if dist_hull < dist_barrels then
					write_dword(m_player + 0x24, ID)
					write_word(m_player + 0x28, 11)
				else
					write_dword(m_player + 0x24, ID)
					write_word(m_player + 0x28, 8)
					local seat = 0
					local x,y,z = read_vector3d(player + 0x5C)
					local closest_seat = 10
					local closest_distance = 1000
					for j=10,12 do
						local x2,y2,z2 = read_vector3d(object + 0x5C0 + j*0x34 + 0x28)
						local distance = GetDistance(x,y,z,x2,y2,z2)
						if j == 11 then
							distance = distance + 0.4
						end
						if distance < closest_distance then
							closest_distance = distance
							closest_seat = j
						end
					end
					if closest_seat == 10 then
						seat = 0
					elseif closest_seat == 11 then
						seat = 2
					elseif closest_seat == 12 then
						seat = 1
					end
					
					write_word(m_player + 0x2A, seat)
				end
			end
		end
	end
end

function ObjectCleanup()
	for ID,info in pairs (ITEMS) do
		if get_object_memory(ID) == 0 then
			ITEMS[ID] = nil
		end
	end
	for ID,info in pairs (VEHICLES) do
		if get_object_memory(ID) == 0 then
			VEHICLES[ID] = nil
		end
	end
end

function PreventSliding()
	for i=1,16 do
		
		-- Prevent player from slowly sliding
		local player = get_dynamic_player(i)
		if player ~= 0 and get_object_memory(read_dword(player + 0x11C)) == 0 and read_bit(player + 0x10, 5) == 1 then
			if PLAYER_POSITIONS[i] == nil then
				PLAYER_POSITIONS[i] = {}
			else
				write_vector3d(player + 0x5C, PLAYER_POSITIONS[i].x, PLAYER_POSITIONS[i].y, PLAYER_POSITIONS[i].z)
			end
			PLAYER_POSITIONS[i].x, PLAYER_POSITIONS[i].y, PLAYER_POSITIONS[i].z = read_vector3d(player + 0x5C)
		else
			PLAYER_POSITIONS[i] = nil
		end
	end
end

function KillBoundary()
	for i=1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local x,y,z = read_vector3d(player + 0x5C)
			local parent = get_object_memory(read_dword(player + 0x11C))
			if parent ~= 0 then
				x,y,z = read_vector3d(parent + 0x5C)
			end
			local distance = sqrt(x*x + z*z)
			if distance > 50 then
				kill(i)
			end
		end
	end	
end

function OnTick()
	if script_active == false then
		return false 
	end
	
	execute_command("rider_ejection 0")

	ObjectCleanup()
	PreventSliding()
	KillBoundary()
	
	--gametype_base = 0x5F5478
	--gametype_vehicle_respawn_time = read_dword(gametype_base + 0x68) -- Confirmed. (1 sec = 30 ticks)
	--write_dword(gametype_base + 0x68, 30)
	
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			local stationary = read_bit(object + 0x10, 5)
			local on_ground = read_bit(object + 0x10, 1)
			local ignore_gravity = read_bit(object + 0x10, 2)
			local parent = get_object_memory(read_dword(object + 0x11C))
			local x,y,z = read_vector3d(object + 0x5C)
			local distance = sqrt(x*x + z*z)
			local x_vel, y_vel, z_vel = read_vector3d(object + 0x68)
			local velocity = abs(x_vel) + abs(y_vel) + abs(z_vel)
			local item = (object_type == 2 or object_type == 3)
			
			if parent == 0 and (abs(z_vel) > 0.0005 or item) and object_type ~= 1 and (object_type ~= 5 or find(GetName(object), "grenade") ~= nil or find(GetName(object), "plasma_cannon") ~= nil) then
				if object_type == 0 then
					if read_dword(object + 0x4D8) == 0xFFFFFFFF then
						z_vel = z_vel + gravity_vel
						write_float(object + 0x70, z_vel)
					end
				else
					write_bit(object + 0x10, 5, 0)
					z_vel = z_vel + gravity_vel
					write_float(object + 0x70, z_vel)
				end
			end
			
			if parent == 0 and object_type ~= 1 and object_type ~= 6 then
				-- stop objects from slowly sliding (doesn't work??)
				if velocity < min_velocity then
					write_vector3d(object + 0x68, 0, 0, 0)
					write_bit(object + 0x10, 5, 1)
				end
			end
			
			if object_type == 1 then
				VehicleEnter(ID,object,x,y,z)
			end
			
			--rotate the biped
			if object_type == 0 then
				local x,y,z = x,y,z
				if parent ~= 0 then
					x,y,z = read_vector3d(parent + 0x5C)
				end
				local rot_x = -x / distance
				local rot_z = -z / distance
				
				--rprint(1, read_float(object + 0x74))
				--write_vector3d(object + 0x74, 0, 0, 1)
				write_vector3d(object + 0x514, rot_x, 0, rot_z)
				
				if parent == 0 then
					OffsetBiped(object, rot_x, rot_z)
					local health = read_float(object + 0xE0)
					if health > 0 then
						write_vector3d(object + 0x80, rot_x, 0, rot_z)
					else
						-- do something with dead bodies
						write_bit(object + 0x4CC, 0, 0)
					end
				end
			elseif item and parent == 0 then
				
				if parent == 0 and read_bit(object + 0x1F4, 0) == 0 then
					if ITEMS[ID] == nil then
						ITEMS[ID] = {}
						ITEMS[ID].x = x
						ITEMS[ID].y = y
						ITEMS[ID].z = z
						local rot_x = (-x / distance)*0.001
						local rot_z = (-z / distance)*0.001
						write_vector3d(object + 0x68, rot_x, 0, rot_z)
						write_bit(object + 0x10, 5, 0)
					else
						local offset = 0x340
						--if object is equipment
						if object_type == 3 then
							offset = 0x294
						end
						local x,y,z = read_vector3d(object + offset + 0x28)
						if stationary == 0 then
							local distance = GetDistance(x,y,z,ITEMS[ID].x,ITEMS[ID].y,ITEMS[ID].z)
							
							if distance < 0.001 then
								--rprint(1, GetName(object).." stopped moving")
								write_vector3d(object + 0x218, x - 0.2, y - 0.2, z - 0.2)
								write_vector3d(object + 0x68, 0, 0, 0)
								write_bit(object + 0x10, 5, 1)
								write_bit(object + 0x10, 1, 1)
								--write_bit(object + 0x1F4, 3, 1)
								velocity = 0
							end
						else
							write_bit(object + 0x10, 1, 1)
							write_bit(object + 0x1F4, 3, 1)
							write_vector3d(object + 0x8C, 0, 0, 0)
							write_float(object + 0x224, 0)
							write_float(object + 0x228, 1)
						end
						
						ITEMS[ID].x = x
						ITEMS[ID].y = y
						ITEMS[ID].z = z
						
						WeaponPickup(ID,object,x,y,z)
					end
				end
				
				local rot_x = -x / distance
				local rot_z = -z / distance
				
				write_vector3d(object + 0x74, 0, 1, 0)
				write_vector3d(object + 0x80, rot_x, 0, rot_z)
				write_vector3d(object + 0x218, 0, 0, 0)
			end
			
			if (stationary == 0 or on_ground == 0) and parent == 0 and ignore_gravity == 0 then
				
				local nade_check = true
				if object_type == 5 then
					local name = GetName(object)
					if find(name, "grenade") == nil and find(name, "plasma_cannon") == nil then
						nade_check = false
					end
				end
				
				if (velocity > min_velocity or (on_ground == 0 and item == false)) and nade_check then
					
					write_bit(object + 0x10, 5, 0)

					local rot_x = x / distance
					local rot_z = z / distance
					rot_x = rot_x * gravity_vel
					rot_z = rot_z * gravity_vel
					
					--rprint(1, GetName(object).." "..velocity)
					write_vector3d(object + 0x68, x_vel + rot_x, y_vel, z_vel + rot_z)
				end
			end
		end
	end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return floor(num * mult + 0.5) / mult
end

function OffsetBiped(object, rot_x, rot_z)
	local x2,y2,z2 = read_vector3d(object + 0x5C)
	for i=0,18 do
		local offset = object + 0x550 + 0x34*i + 0x28
		local x,y,z = read_vector3d(offset)
		write_vector3d(offset, x + rot_x*bipd_z_offset, y, z + rot_z*bipd_z_offset)
	end
	
	--offset weapon
	local weapon_slot = read_byte(object + 0x2F4)
	local weapon_id = read_dword(object + 0x2F8 + weapon_slot * 4)
	local object = get_object_memory(weapon_id)
	if object ~= 0 then
		OffsetWeapon(object, rot_x, rot_z)
	end
end

function OffsetWeapon(object, rot_x, rot_z)
	local tag_id = read_dword(object)
	if WEAPONS[tag_id] ~= nil then
		local node_count = WEAPONS[tag_id]
		for j = 0,node_count do
			local offset = object + 0x340 + 0x28 + 0x34*j
			local x,y,z = read_vector3d(offset)
			write_vector3d(offset, x + rot_x*bipd_z_offset, y, z + rot_z*bipd_z_offset)
		end
	end
end

function GetDistance(x,y,z,x2,y2,z2)
	local x_dist = x2-x
	local y_dist = y2-y
	local z_dist = z2-z
	return sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function RotateVectorOnY(x,y,z,a)
	local x2 = x*math.cos(a) + z*math.sin(a)
	local z2 = -x*math.sin(a) + z*math.cos(a)
	return x2,y,z2
end

function GetAnglesFrom3DVector(x,y,z)
	local pitch = math.asin(z)
	local yaw = math.atan(x,-y) - math.pi/2
	return yaw, pitch
end

function OnError(Message)
	say_all("Error!"..Message)
end
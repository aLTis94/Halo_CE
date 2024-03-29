--	Red dot by aLTis (some stuff copied from giraffe's script)
--	This script will create a red dot when a player charges spartan  laser

--	CONFIG

debug_mode = false

spartan_laser = "halo reach\\objects\\weapons\\support_high\\spartan_laser\\spartan laser"
red_dot_effect = "altis\\effects\\red_dot"

-- values can be found in player's biped tag under 'camera, collision, and autoaim'.
STANDING_CAMERA_HEIGHT = 0.62
CROUCHING_CAMERA_HEIGHT = 0.35

DISTANCE = 10000
DISTANCE_FROM_COLLISION = 0.01

--	END OF CONFIG

api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function DeleteWeapon(ID)
	ID = tonumber(ID)
	if get_object_memory(ID) ~= 0 then
		destroy_object(ID)
	end
end

function OnTick()
	for i=1,16 do
		if(player_alive(i)) then
			local player = get_dynamic_player(i)
			local currentWeapon = read_dword(player + 0x118)
			local WeaponObj = get_object_memory(currentWeapon)
			if(WeaponObj ~= nil and WeaponObj ~= 0) then
				local name = read_string(read_dword(read_word(WeaponObj) * 32 + 0x40440038))
				if(name == spartan_laser) then
					local weap_charge = read_byte(WeaponObj + 0x261)
					if(weap_charge == 2) then
						if(debug_mode) then rprint(1, "Weapon is charging") end
						
						local px, py, pz = read_vector3d(player + 0x5c)
                        local vx, vy, vz = read_vector3d(player + 0x230)
                        local cs = read_float(player + 0x50C)
                        local h = STANDING_CAMERA_HEIGHT - (cs * (STANDING_CAMERA_HEIGHT - CROUCHING_CAMERA_HEIGHT))
                         pz = pz + h
                        local hit, x, y , z = intersect(px, py, pz, DISTANCE*vx, DISTANCE*vy, DISTANCE*vz, read_dword(get_player(i) + 0x34))
                        local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - DISTANCE_FROM_COLLISION
                        hit, x, y , z = intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(i) + 0x34))
						
						local EffectObj = spawn_object("weap", red_dot_effect, x, y, z)
						timer(33, "DeleteWeapon", EffectObj)
					end
				end
			end
		end
	end
end

function OnScriptUnload() end
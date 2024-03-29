--	Armor Ability script by aLTis (altis94@gmail.com)
--	Will only work in maps like BigassV3
--	You should only edit the spawn locations unless you know what you're doing
--	FIX COORDINATE READING WHEN IN VEHICLES AAAAAAA

--CONFIG	
	SPAWN_LOCATIONS = {
		{"Bubble Shield", -60.9152, -24.2141, -3.500},
		{"Bubble Shield", 145.221, -16.0017, 20.200},
		{"Hologram", -75.3733, -15.9569, 1.500},
		{"Hologram", 151.726, -24.0957, 20.000},
		{"EMP", -61.7809, -14.9578, 2.222},
		{"EMP", 134.799, 12.0433, 24.300},
		{"Regen", -75.1649, -19.3963, 13.250},
		{"Regen", 154.47, 7.11953, 23.8128},
	}
	
	COOLDOWNS = {	--	How long you need to wait after activating an ability
		["Bubble Shield"] = 30 * 30,
		["Hologram"] = 		15 * 30,
		["Regen"] = 		30 * 30,
		["EMP"] = 			15 * 30,
	}
	
	x_delay = 10 -- how much frames to wait after E was pressed until X gets pressed again to activate ability
	pick_up_range = 1.0 --	distance from where you can pick up armor abilities
	health_regen_rate = 0.02
	health_regen_range = 1.5
	hologram_lifetime = 15 * 30
	emp_range = 2.5
	
	--tag locations
	bubble_shield_pickup = "armor_abilities\\pickups\\bubble"
	bubble_shield_deployed = "armor_abilities\\bubble_shield\\deployed\\bubble_shield"
	hologram_pickup = "armor_abilities\\pickups\\hologram"
	hologram_deployed = "armor_abilities\\hologram\\hologram_"
	hologram_deployed_idle = "armor_abilities\\hologram\\hologram_idle_"
	health_regen_pickup = "armor_abilities\\pickups\\regen"
	health_regen_deployed = "armor_abilities\\health_regen\\health_regen"
	emp_pickup = "armor_abilities\\pickups\\emp"
	emp_deployed = "armor_abilities\\emp\\emp"
--END OF CONFIG


api_version = "1.9.0.0"

PLAYERS = {}
PICKUPS = {}
REGENS = {}
HOLO = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	--register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	for i=1,16 do
		PLAYERS[i] = {}
		PLAYERS[i]["ACTION"] = 0
		PLAYERS[i]["STATE"] = 0
		PLAYERS[i]["ABILITY"] = nil
		PLAYERS[i]["COOLDOWN"] = 0
		PLAYERS[i]["test"] = 0
		PLAYERS[i]["test2"] = 0
	end
	
	bubble_tag = GetMetaID("weap", bubble_shield_pickup)
	emp_tag = GetMetaID("weap", emp_pickup)
	health_regen_tag = GetMetaID("weap", health_regen_pickup)
	hologram_tag = GetMetaID("weap", hologram_pickup)
	
	execute_command("disable_object \""..bubble_shield_pickup.."\"")
	execute_command("disable_object "..emp_pickup)
	execute_command("disable_object "..health_regen_pickup)
	execute_command("disable_object "..hologram_pickup)
	
	timer(1000, "RespawnArmorAbilities")
end

function RespawnArmorAbilities()
	for k,v in pairs (SPAWN_LOCATIONS) do
		PICKUPS[spawn_object("weap", "armor_abilities\\pickups\\"..string.lower(v[1]), v[2], v[3], v[4])] = v[1]
	end
	timer(30000, "RespawnArmorAbilities")
end

function OnPlayerSpawn(PlayerIndex)
	PLAYERS[PlayerIndex]["ABILITY"] = nil
	PLAYERS[PlayerIndex]["COOLDOWN"] = 0
end

function OnPlayerDeath(i)
	if PLAYERS[i]["ABILITY"] ~= nil then
		PICKUPS[spawn_object("weap", "armor_abilities\\pickups\\"..PLAYERS[i]["ABILITY"], PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] + 0.1)] = PLAYERS[i]["ABILITY"]
	end
end

function OnTick()
	--	Remove despawned pickups
	for ID,TYPE in pairs (PICKUPS) do
		if get_object_memory(ID) == 0 then
			PICKUPS[ID] = nil
		end
	end
	
	--	Get players positions and set weapon ammo to sync cooldown meter
	for i=1,16 do
		if player_alive(i) then
			local player = get_dynamic_player(i)
			PLAYERS[i]["x"], PLAYERS[i]["y"], PLAYERS[i]["z"] = read_vector3d(player + 0x5C)
			for j = 0,2 do
				local currentWeapon = read_dword(player + 0x2F8 + j*0x4)
				local WeaponObj = get_object_memory(currentWeapon)
				if WeaponObj ~= 0 then
					--rprint(i, "loaded "..read_word(WeaponObj + 0x2C2))
					--rprint(i, "cooldown "..PLAYERS[i]["COOLDOWN"])
					local ammo = 0
					if PLAYERS[i]["ABILITY"] ~= nil then
						ammo = math.floor( (COOLDOWNS[PLAYERS[i]["ABILITY"]] - PLAYERS[i]["COOLDOWN"])/ COOLDOWNS[PLAYERS[i]["ABILITY"]] * 85)
					end
					if ammo < 0 then
						ammo = 0
					end
					--rprint(i, "ammo "..ammo)
					write_word(WeaponObj + 0x2C2, ammo)
				end
			end
		end
	end
	
	for i=1,16 do
		if player_alive(i) then
			local player = get_dynamic_player(i)
			local x, y, z = read_vector3d(player + 0x5C)
			--	Health regen stuff
				for ID,TYPE in pairs (REGENS) do 
					if get_object_memory(ID) == 0 then
						PICKUPS[ID] = nil
					else
						local x1, y1, z1 = read_vector3d(get_object_memory(ID) + 0x5C)
						local vehicle = get_object_memory(read_dword(player + 0x11C))
						if vehicle ~= 0 then
							x, y, z = read_vector3d(vehicle + 0x5C)
						end
						local player_health = read_float(player + 0xE0)
						if DistanceFormula(x1,y1,z1,x,y,z) < health_regen_range and player_health < 1.0 then
							write_float(player + 0xE0, player_health + health_regen_rate)
						end
					end
				end
			
			if read_dword(player + 0x11C) == 4294967295 then
				local network_struct = read_dword(sig_scan("F3ABA1????????BA????????C740??????????E8????????668B0D") + 3)
				local client_machineinfo_struct = network_struct + 0x3B8+0x40 + to_real_index(i) * 0xEC
				local action_key_all = read_bit(player + 0x209, 6)
				local action_key_only = read_bit(client_machineinfo_struct + 0x24, 6)
				local test_shit = read_bit(player + 0x47A, 6)
			
			PLAYERS[i]["ACTION"] = 0
			
			if action_key_all == 1 then
				if PLAYERS[i]["test2"] == 0 and PLAYERS[i]["test"] == 0 and test_shit == 0 then
					--say(i, "X")
					PLAYERS[i]["ACTION"] = 1
				end
				PLAYERS[i]["test"] = 1
			else
				PLAYERS[i]["test"] = 0
			end
			
			if PLAYERS[i]["test2"] > 0 then
				PLAYERS[i]["test2"] = PLAYERS[i]["test2"] - 1
			end
			
			if test_shit == 1 then
				PLAYERS[i]["test2"] = x_delay
			end
				
				--	Check if player is picking up an AA
				if action_key_all == 1 then
					if PLAYERS[i]["STATE"] == 1 then
						PLAYERS[i]["STATE"] = 0
						local picked = false
						for ID,TYPE in pairs (PICKUPS) do
							if picked == false then
								local x1, y1, z1 = read_vector3d(get_object_memory(ID) + 0x5C)
								if DistanceFormula(x1,y1,z1,x,y,z) < pick_up_range then
									if PLAYERS[i]["ABILITY"] ~= TYPE then
										if PLAYERS[i]["ABILITY"] ~= nil then
											PICKUPS[spawn_object("weap", "armor_abilities\\pickups\\"..PLAYERS[i]["ABILITY"], x, y, z + 0.1)] = PLAYERS[i]["ABILITY"]
										end
										PLAYERS[i]["ABILITY"] = TYPE
										rprint(i, "|cPicked up "..TYPE)
										destroy_object(ID)
										PICKUPS[ID] = nil
										picked = true
									end
								end
							end
						end
					end
				else
					PLAYERS[i]["STATE"] = 1
				end
				
				--	Check if player is activating an AA
				if PLAYERS[i]["ACTION"] == 1 then
					--	AA happens here
					if PLAYERS[i]["COOLDOWN"] == 0 then
					--BUBBLE
						if PLAYERS[i]["ABILITY"] == "Bubble Shield" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Bubble Shield"]
							local ID = spawn_object("eqip", bubble_shield_deployed, x, y, z + 0.01)
							timer(15000, "destroy_object", ID)
					--HOLOGRAM
						elseif PLAYERS[i]["ABILITY"] == "Hologram" then
							local player_yaw = read_float(client_machineinfo_struct + 0x28)
							--local yaw = read_float(player + 0x78)
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Hologram"]
							local team = get_var(i, "$team")
							local hologram_object = spawn_object("vehi", hologram_deployed..team, x, y, z, player_yaw)
							local object = get_object_memory(hologram_object)
							if object ~= 0 then
								local pitch, yaw, roll = read_vector3d(object + 0x550)
								pitch = pitch/13
								yaw = yaw/13
								write_bit(object + 0x10, 5, 0)
								write_vector3d(object + 0x68, pitch, yaw, 0)
								HOLO[hologram_object] = {}
								HOLO[hologram_object].timer = hologram_lifetime
								HOLO[hologram_object].player_yaw = player_yaw
								HOLO[hologram_object].yaw = yaw
								HOLO[hologram_object].pitch = pitch
								HOLO[hologram_object].team = team
								HOLO[hologram_object].x, HOLO[hologram_object].y, HOLO[hologram_object].z = read_vector3d(object + 0x5C)
							end
					--REGEN
						elseif PLAYERS[i]["ABILITY"] == "Regen" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["Regen"]
							local ID = spawn_object("eqip", health_regen_deployed, x, y, z + 0.01)
							REGENS[ID] = 1
							timer(15000, "destroy_object", ID)
					--EMP
						elseif PLAYERS[i]["ABILITY"] == "EMP" then
							PLAYERS[i]["COOLDOWN"] = COOLDOWNS["EMP"]
							local emp = spawn_object("proj", emp_deployed, x, y, z + 0.05)
							
							local player_team = get_var(i, "$team")
							
							for j=1,16 do
								if player_alive(j) and get_var(j, "$team") ~= player_team then
									local enemy = get_dynamic_player(j)
									local x1, y1, z1 = read_vector3d(enemy + 0x5C)
									local vehicle = get_object_memory(read_dword(enemy + 0x11C))
									if vehicle ~= 0 then
										x1, y1, z1 = read_vector3d(vehicle + 0x5C)
									end
									if DistanceFormula(x1,y1,z1,x,y,z) < emp_range then
											shields = 0
										write_float(enemy + 0xE4, 0)
									end
								end
							end
						else
							--rprint(i, "|cYou have no AA")
						end
					else
						--rprint(i, "|c"..math.floor(PLAYERS[i]["COOLDOWN"]/30).."s left")
					end
				end
			end
			
			
			--	Cooldown
			if PLAYERS[i]["COOLDOWN"] > 0 then
				PLAYERS[i]["COOLDOWN"] = PLAYERS[i]["COOLDOWN"] - 1
				if PLAYERS[i]["COOLDOWN"] == 0 then
					--rprint(i, "|cAbility ready!")
				end
			end
		end
	end
	
	for ID, value in pairs (HOLO) do
		if value.timer > 0 then
			value.timer = value.timer - 1
			if value.idle == nil then
				local object = get_object_memory(ID)
				if object ~= 0 then
					local x, y, z = read_vector3d(object + 0x5C)
					local distance = DistanceFormula(x, y, z, value.x, value.y, value.z)
					if distance > 0.06 or distance == 0 then
						value.x = x
						value.y = y
						value.z = z
						write_bit(object + 0x10, 5, 0)
						local x_vel, y_vel, z_vel = read_vector3d(object + 0x68)
						write_vector3d(object + 0x68, value.pitch, value.yaw, z_vel)
					else
						--add idle vehicle
						new_ID = spawn_object("vehi", hologram_deployed_idle..value.team, value.x, value.y, value.z - 0.19, value.player_yaw)
						HOLO[new_ID] = {}
						HOLO[new_ID].timer = value.timer
						HOLO[new_ID].idle = 1
						destroy_object(ID)
						HOLO[ID] = nil
					end
				else
					HOLO[ID] = nil
				end
			end
		else
			destroy_object(ID)
			HOLO[ID] = nil
		end
	end
end

function OnObjectSpawn(PlayerIndex, MetaID, ParentID, ID)
	if MetaID == bubble_tag then
		PICKUPS[ID] = "Bubble Shield"
	elseif MetaID == emp_tag then
		PICKUPS[ID] = "EMP"
	elseif MetaID == health_regen_tag then
		PICKUPS[ID] = "Regen"
	elseif MetaID == hologram_tag then
		PICKUPS[ID] = "Hologram"
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= 0) then
		--cprint(object_dir..": "..address.."     "..read_dword(address + 0xC))
		return read_dword(address + 0xC)
	end
	return nil
end

function OnScriptUnload() 
	for ID,TYPE in pairs (PICKUPS) do
		destroy_object(ID)
	end
	for ID, value in pairs (HOLO) do
		destroy_object(ID)
	end
end
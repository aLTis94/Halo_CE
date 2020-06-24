
--CONFIG
	
	debug_mode = false
	
	-- GAMETYPE
		gametype = "monster"
		minimum_player_count = 2
		start_delay = 5 -- seconds
	
	
	-- HUNTERS
		--(0 = white) (1 = black) (2 = red) (3 = blue) (4 = gray) (5 = yellow) (6 = green) (7 = pink) (8 = purple) (9 = cyan) (10 = cobalt) (11 = orange) (12 = teal) (13 = sage) (14 = brown) (15 = tan) (16 = maroon) (17 = salmon)
		color_hunter = 13
		speed_hunter = 1
		skull_limit = 3 -- how many skulls to spawn with a strong weapon
		skull_weapon = "weapons\\rocket launcher\\rocket launcher"
	
	-- MONSTER
		color_monster = 11
		speed_monster = 1.2
		max_health = 1900
		skull_health_restore_amount = 0.043
		skull_pickup_range = 0.4
		
		enable_flames = true
		flaming_rate = 7 -- how often should the flame projectile spawn under the feet
		flame_distance = 0.15 -- how far away from player
		
		frag_recharge_time = 1000
		plasma_recharge_time = 500
		nuke_recharge_time = 2700
		timer_multiplier_pn = 0.19 -- how much quicker abilities recharge based on player count (higher means faster)
		dmg_multiplier_pn = 0.056 -- how much less monster takes damage from enemies based on player count (higher means less)
	
	--WEAPON MOD
		fire_rate = 8	-- Projectiles per second
		projectiles_per_shot = 1 -- How many projectiles to fire in one shot
		error_from = 0.008	-- accuracy when started firing (0-1; 0-pi rad)
		error_to = 0.008	-- accuracy when firing (0-1; 0-pi rad)
		
		PROJECTILES = {
			[1]= "weapons\\rocket launcher\\rocket";
			[2]= "weapons\\needler\\needle";
			[3]= "weapons\\plasma rifle\\bolt";
			[4]= "weapons\\plasma_cannon\\plasma_cannon";
			[5]= "weapons\\plasma pistol\\bolt";
			[6]= "weapons\\plasma rifle\\charged bolt";
			[7]= "weapons\\sniper rifle\\sniper bullet";
			[8]= "vehicles\\c gun turret\\mp gun turret";
			[9]= "weapons\\plasma grenade\\plasma grenade";
			[10]= "weapons\\frag grenade\\frag grenade";
			[11]= "vehicles\\scorpion\\tank shell";
			[12]= "vehicles\\banshee\\mp_banshee fuel rod";
		}
		
		-- projectiles (uses tags listed above)
		modded_projectile = PROJECTILES[8]
		modded_frag = PROJECTILES[1]
		modded_plasma = PROJECTILES[12]
		nuke = PROJECTILES[11]
		
		gravity_rifle = "weapons\\gravity rifle\\gravity rifle"
		flamethrower_projectile = "weapons\\flamethrower\\flame"
		flamethrower = "weapons\\flamethrower\\flamethrower"
		flamethrower_replacement = "weapons\\shotgun\\shotgun"
		
		grenade_source_type_frag = "weapons\\frag grenade\\frag grenade"
		grenade_source_type_plasma = "weapons\\plasma grenade\\plasma grenade"
		
		HEADSHOT_DMGS = {
			[1] = "weapons\\pistol\\bullet";
			[2] = "weapons\\sniper rifle\\sniper bullet";
		}
	
	-- HUD COLORS
		color_default = "|nc7FB3D5"
		color_red = "|ncFC0303"
		
	
--END OF CONFIG

api_version = "1.9.0.0"

game_was_started = false

function OnScriptLoad()
	network_struct = read_dword(sig_scan("F3ABA1????????BA????????C740??????????E8????????668B0D") + 3)
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	timer(30, "Initialize")
end

function OnGameStart()
	game_over = false
	game_started = false
	monster = nil
	timer(30, "Initialize")
end

function OnScriptUnload()
	if game_was_started then
		EnableObjects()
	end
	if game_started then
		RemoveAllObjectsByID(oddball_id)
		for i=1,16 do
			ClearConsole(i)
		end
	end
end

function Initialize()
	if get_var(0, "$mode") == gametype and lookup_tag("weap", gravity_rifle) ~= 0 then
		
		game_was_started = true
		flamethrower_projectile_id = GetMetaID("proj", flamethrower_projectile)
		flamethrower_id = GetMetaID("weap", flamethrower)
		flamethrower_replacement_id = GetMetaID("weap", flamethrower_replacement)
		modded_projectile_id = GetMetaID("proj", modded_projectile)
		frag_id = GetMetaID("proj", grenade_source_type_frag)
		plasma_id = GetMetaID("proj", grenade_source_type_plasma)
		modded_frag_id = GetMetaID("proj", modded_frag)
		modded_plasma_id = GetMetaID("proj", modded_plasma)
		falling_dmg_id = GetMetaID("jpt!", "globals\\falling")
		vehicle_dmg_id = GetMetaID("jpt!", "globals\\vehicle_collision")
		oddball_id = GetMetaID("weap", "weapons\\ball\\ball")
		nuke_id = GetMetaID("proj", nuke)
		
		if flamethrower_projectile_id == nil or modded_projectile_id == nil or frag_id == nil or plasma_id == nil or oddball_id == nil then
			say_all("Monster script couldn't load due to missing tags")
			UnregisterCallbacks()
		else
			RegisterCallbacks()
		end
		
		location_store = sig_scan("741F8B482085C9750C")
		if(location_store == 0) then
			location_store = sig_scan("EB1F8B482085C9750C")
			if(location_store == 0) then
				cprint("Failed to find color assignment signature")
			end
		end
		safe_write(true)
		write_char(location_store,235)
		safe_write(false)
		
		SetupFlameTag()
		ModWeaponTag()
		RemoveHeadshots()
		DisableObjects()
		
		game_started = false
		game_over = false
	elseif game_was_started then
		UnregisterCallbacks()
		EnableObjects()
		if location_store ~= nil and location_store ~= 0  then
			safe_write(true)
			write_char(location_store,116)
			safe_write(false)
		end
	end
end

function RegisterCallbacks()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
	register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
	register_callback(cb['EVENT_PRESPAWN'],"OnPlayerPrepawn")
	register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
end

function UnregisterCallbacks()
	unregister_callback(cb["EVENT_TICK"])
	unregister_callback(cb['EVENT_JOIN'])
	unregister_callback(cb['EVENT_GAME_END'])
	unregister_callback(cb['EVENT_LEAVE'])
	unregister_callback(cb['EVENT_DIE'])
	unregister_callback(cb['EVENT_SPAWN'])
	unregister_callback(cb['EVENT_PRESPAWN'])
	unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
	unregister_callback(cb['EVENT_OBJECT_SPAWN'])
end

function EnableObjects()
	execute_command("block_tc 0")
	execute_command("disable_all_objects 0 0")
	execute_command("disable_all_vehicles 1 0")
	execute_command("enable_object \""..gravity_rifle.."\" 0")
	execute_command("enable_object weapons\\flamethrower\\flamethrower 0")
	execute_command("enable_object weapons\\ball\\ball 0")
	execute_command("enable_object \""..gravity_rifle.."\" 0")
end

function DisableObjects()
	execute_command("block_tc 1")
	execute_command("disable_all_objects 1 1")
	execute_command("disable_all_vehicles 1 1")
	execute_command("disable_object \""..gravity_rifle.."\" 1")
	execute_command("disable_object weapons\\flamethrower\\flamethrower 2")
	execute_command("disable_object weapons\\ball\\ball 2")
	execute_command("disable_object \""..gravity_rifle.."\" 2")
end

function CheckPlayerCount()
	if tonumber(get_var(0, "$pn")) >= minimum_player_count and game_over == false then
		if debug_mode == false then
			timer(start_delay*1000, "Begin")
		end
	end
end

function Begin()
	if game_started == false then
		
		PickRandomPlayer()
		
		PLAYER_HEAD_POSITION = {}
		PLAYER_SKULL_COUNT = {}
		SKULLS = {}
		
		for i=1,16 do
			PLAYER_SKULL_COUNT[i] = 0
			PLAYER_HEAD_POSITION[i] = {}
			PLAYER_HEAD_POSITION[i].x, PLAYER_HEAD_POSITION[i].y,PLAYER_HEAD_POSITION[i].z  = 0,0,0
			
			ChangePlayerColor(i)
		end
		
		timer(33, "AnnounceMonster")
		
		if debug_mode == false then
			for i=1,16 do
				DeletePlayer(i)
			end
			execute_command("sv_map_reset")
			execute_command("st * blue")
			execute_command("st "..monster.." red")
		end
		
		ResetMonsterStats()
		RemoveAllObjectsByID(oddball_id)
		RemoveAllObjectsByID(flamethrower_id)
		
		game_started = true
	end
end

function AnnounceMonster()
	if monster ~= nil and player_present(monster) then
		say_all("The game begins... "..get_var(monster, "$name").." is the monster!")
	end
end

function PickRandomPlayer()
	local PLAYERS = {}
	local pid = 1
	for i=1,16 do
		if player_present(i) and get_var(i, "$name") ~= previous_monster then
			PLAYERS[pid] = i
			pid = pid + 1
		end
	end
	math.randomseed(tonumber(get_var(0, "$ticks"))*tonumber(get_var(1, "$ping")))
	monster = PLAYERS[math.random(1,#PLAYERS)]
	if monster == nil then -- just to make sure :v
		monster = 1
	end
	previous_monster = get_var(monster, "$name")
end

function ResetMonsterStats()
	monster_flame_timer = flaming_rate
	frag_timer = 0
	plasma_timer = 0
	nuke_timer = 0
	monster_x_key = 0
	monster_previous_action = 0
	monster_hold_x = 0
	monster_delay = 0
	
	tip_monster_nuke = true
	tip_monster_health = true
end

function OnTick()
	if game_started and monster ~= nil then
		
		local timer_multiplier = 1 + timer_multiplier_pn*(tonumber(get_var(0, "$pn")) - 2)
		--rprint(1, timer_multiplier)
		
		for i=1,16 do
			local player = get_dynamic_player(i)
			if player ~= 0 then
				PLAYER_HEAD_POSITION[i].x, PLAYER_HEAD_POSITION[i].y, PLAYER_HEAD_POSITION[i].z = read_vector3d(player + 0x7C0 + 0x28)
				if i ~= monster then
					local x,y,z = read_vector3d(player + 0x5C)
					for ID,value in pairs (SKULLS) do
						local object = get_object_memory(ID)
						if object ~= 0 then
							local x2,y2,z2 = read_vector3d(object + 0x5C)
							if DistanceFormula(x,y,z,x2,y2,z2)<skull_pickup_range then
								PLAYER_SKULL_COUNT[i] = PLAYER_SKULL_COUNT[i] + 1
								if PLAYER_SKULL_COUNT[i] ~= skull_limit then
									say(i, "Skull collected!")
								else
									say(i, "You collected "..skull_limit.." skulls and you will spawn with a rocket launcher!")
								end
								RemoveObject(ID)
								SKULLS[ID] = nil
							end
						end
					end
				end
			end
		end
		
		local player = get_dynamic_player(monster)
		if player ~= 0 and player_alive(monster) then
			local x,y,z = read_vector3d(player + 0x5C)
			local x_facing,y_facing,z_facing = read_vector3d(player + 0x224)
			local x_aim,y_aim,z_aim = read_vector3d(player + 0x23C)
			local player_obj_id = read_dword(get_player(monster) + 0x34)
			local health = read_float(player + 0xE0)
		-- SPEED
			local m_player = get_player(monster)
			local speed = read_float(m_player + 0x6C)
			if math.abs(speed - speed_monster) > 0.01 then
				write_float(m_player + 0x6C, speed_monster)
			end
			
		-- GRENADES
			if frag_timer >= 0 and frag_timer < frag_recharge_time then
				frag_timer = frag_timer + timer_multiplier
			elseif frag_timer >= frag_recharge_time then
				write_byte(player + 0x31E, 1)
				frag_timer = -100
			end
			if plasma_timer >= 0 and plasma_timer < plasma_recharge_time then
				plasma_timer = plasma_timer + timer_multiplier
			elseif plasma_timer >= plasma_recharge_time then
				write_byte(player + 0x31F, 1)
				plasma_timer = -100
			end
			
			local frag_count = read_byte(player + 0x31E)
			local plasma_count = read_byte(player + 0x31F)
			if frag_count == 0 and frag_timer < 0 then
				frag_timer = 0
			end
			if plasma_count == 0 and plasma_timer < 0 then
				plasma_timer = 0
			end
			
		-- NUKE
			if nuke_timer < nuke_recharge_time then
				nuke_timer = nuke_timer + timer_multiplier
			end
			if nuke_timer >= nuke_recharge_time then
				if tip_monster_nuke then
					say(monster, "Nuke is ready. Press X to activate it!")
					tip_monster_nuke = false
				end
				if GetPlayerInput(monster) then
					spawn_projectile(nuke_id, player_obj_id, x+x_aim, y+y_aim, z+0.5,x_aim,y_aim,z_aim)
					spawn_projectile(nuke_id, player_obj_id, x+x_aim, y+y_aim, z+0.5,x_aim+0.2,y_aim+0.2,z_aim)
					spawn_projectile(nuke_id, player_obj_id, x+x_aim, y+y_aim, z+0.5,x_aim-0.2,y_aim-0.2,z_aim)
					spawn_projectile(nuke_id, player_obj_id, x+x_aim, y+y_aim, z+0.5,x_aim,y_aim,z_aim+0.15)
					spawn_projectile(nuke_id, player_obj_id, x+x_aim, y+y_aim, z+0.5,x_aim,y_aim,z_aim-0.15)
					nuke_timer = 0
				end
			end
			
		-- FLAMEY FEETIES
			monster_flame_timer = monster_flame_timer - 1
			if monster_flame_timer < 1 then
				if enable_flames then
					local proj = spawn_projectile(flamethrower_projectile_id, player_obj_id, x-x_facing*flame_distance, y-y_facing*flame_distance, z+0.05,0,0,-1)
					timer(0, "RemoveObject", proj)
				end
				local x_vel = read_float(player + 0x68)
				if math.abs(x_vel) > 0.001 then
					monster_flame_timer = flaming_rate
				else
					monster_flame_timer = flaming_rate*3
				end
				execute_command("mag "..monster.." 999")
				sync_ammo(monster)
			end
			
			
		-- SKULL PICKUP
			if health*max_health < max_health then
				if tip_monster_health and health*max_health*1.5 < max_health then
					say(monster, "Collect skulls of dead players to restore health!")
					tip_monster_health = false
				end
				for ID,value in pairs (SKULLS) do
					local object = get_object_memory(ID)
					if object ~= 0 then
						local x2,y2,z2 = read_vector3d(object + 0x5C)
						if DistanceFormula(x,y,z,x2,y2,z2)<skull_pickup_range then
							local new_health = health + skull_health_restore_amount
							if new_health > 1 then
								new_health = 1
							end
							RemoveObject(ID)
							SKULLS[ID] = nil
							
							powerup_interact(spawn_object("eqip", "powerups\\health pack", x, y, z), monster)
							write_float(player + 0xE0, new_health)
						end
					else
						SKULLS[ID] = nil
					end
				end
			end
		end
	else
		CheckPlayerCount()
	end
	
	HUD()
end

function OnPlayerJoin(i)
	if game_started then
		PLAYER_SKULL_COUNT[i] = 0
		ChangePlayerColor(i)
		timer(30, "DeletePlayer", i)
		if monster ~= nil then
			say(i, get_var(monster, "$name").." is the monster!")
		end
		if i ~= monster then
			execute_command("st "..i.." blue")
		end
	else
		say(i, "This is the monster gametype. It will begin when there are "..minimum_player_count.." players...")
	end
end

function OnPlayerLeave(i)
	if game_started then
		if i == monster then
			DeletePlayer(i)
			--if tonumber(get_var(0, "$pn")) >= 0 then
			--	PickRandomPlayer()
				--execute_command("st * blue")
				--execute_command("st "..monster.." red")
			--else
				game_started = false
				execute_command("sv_map_next")
			--end
		end
	end
end

function OnGameEnd()
	if game_started then
		if monster ~= nil then
			say_all("The monster has won...")
		end
		game_started = false
		game_over = true
		monster = nil
		ResetMonsterStats()
		for i=1,16 do
			ClearConsole(i)
		end
	end
	UnregisterCallbacks()
end

function OnPlayerDeath(i)
	if game_started then
		if i == monster then
			say_all("The monster has been defeated!")
			game_started = false
			monster = nil
			execute_command("sv_map_next")
		else
			local ID = spawn_object("weap", "ball", PLAYER_HEAD_POSITION[i].x, PLAYER_HEAD_POSITION[i].y, PLAYER_HEAD_POSITION[i].z, 0, oddball_id)
			SKULLS[ID] = true
		end
	end
end

function OnPlayerPrepawn(i)
	if game_started then
		ChangePlayerColor(i)
	end
end

function ChangePlayerColor(i)
	if player_present(i) then
		if i == monster then
			write_word(get_player(i) + 0x60, color_monster)
		else
			write_word(get_player(i) + 0x60, color_hunter)
		end
	end
end

function OnPlayerSpawn(i)
	if game_started then
		if i == monster then
			execute_command("wdel "..i)
			execute_command("spawn weap \""..gravity_rifle.."\" "..i.." 0")
			execute_command("wadd "..i)
			local player = get_dynamic_player(i)
			if player ~= 0 then
				write_float(player + 0xD8, max_health)
			end
		elseif PLAYER_SKULL_COUNT[i] >= skull_limit then
			execute_command("wdel "..i)
			execute_command("spawn weap \""..skull_weapon.."\" "..i.." 0")
			execute_command("wadd "..i)
			timer(1, "GiveAmmo", i, 4)
			PLAYER_SKULL_COUNT[i] = PLAYER_SKULL_COUNT[i] - skull_limit
			return
		end
		timer(1, "GiveAmmo", i, 999)
	end
end

function GiveAmmo(i, ammo_count)
	execute_command("ammo "..i.." "..ammo_count.." 5")
	execute_command("nades "..i.." 0")
end

function OnDamage(i, causer, tagID, damage, material, backtap)
	if game_started then
		--say_all(i.." "..causer.." "..damage.."   "..material.."   "..backtap)
		if i == monster then	
			if i == causer then
				return true, 0
			elseif tagID == falling_dmg_id then
				local player = get_dynamic_player(i)
				local touching_ground = read_bit(player + 0x10, 1)
				if touching_ground == 0 then
					return false
				else
					return true -- if player quit
				end
			elseif tagID == vehicle_dmg_id then
				return true, 40
			else
				execute_command("kills "..causer.." +"..damage)
				if backtap ~= 0 then
					local player = get_dynamic_player(monster)
					if player ~= 0 then
						local health = read_float(player + 0xE0)
						write_float(player + 0xE0, health - health*(40/max_health))
					end
					return false
				end
			end
			return true, damage * (1 - dmg_multiplier_pn * (tonumber(get_var(0, "$pn")) - 2))
		end
	end
end

function OnError(Message)
	say_all("Error!"..Message)
end

function RemoveObject(ID)
	ID = tonumber(ID)
	local object = get_object_memory(ID)
	if object ~= 0 then
		destroy_object(ID)
	end
end

function OnObjectSpawn(i, MetaID, ParentID, ID)
	if get_var(0, "$mode") == gametype and MetaID == flamethrower_id then
		return true, flamethrower_replacement_id
	elseif game_started then
		if i == monster then
			if MetaID == frag_id then
				return true, modded_frag_id
			elseif MetaID == plasma_id then
				return true, modded_plasma_id
			end
		end
	end
end

function SetupFlameTag()
	local flame_tag = lookup_tag("proj", flamethrower_projectile)
	if flame_tag ~= 0 then
		flame_tag = read_dword(flame_tag + 0x14)
		write_dword(flame_tag + 0x224 + 0xC, 0xFFFFFFFF)
		write_float(flame_tag + 0x1E4, 10)
		write_float(flame_tag + 0x1E8, 10)
		
		local mat_address = read_dword(flame_tag + 0x244)
		local cyborg_address = mat_address + 21*160
		write_word(cyborg_address + 0x02, 0)
		write_word(cyborg_address + 0x24, 0)
	end
end

function ModWeaponTag()
	local old_weapon = lookup_tag("weap", gravity_rifle)
	local old_data = read_dword(old_weapon + 0x14)
	local trigger_data = read_dword(old_data + 0x4FC + 4)
	
	--write_bit(trigger_data, 3, 1)--	Does not repeat automatically
	write_bit(trigger_data, 5, 1)--	Uses weapon origin
	--write_short(trigger_data + 0x22, 0)--			Rounds per shot; leave at 0 for infinite ammo
	write_float(trigger_data + 0x4, fire_rate)--	Rounds per second from
	write_float(trigger_data + 0x8, fire_rate)--	Rounds per second to
	write_short(trigger_data + 0x6E, projectiles_per_shot)--	Projectiles per shot
	write_float(trigger_data + 0x7C, error_from)--	Error from
	write_float(trigger_data + 0x80, error_to)--	Error to
	
	write_dword(trigger_data + 0x94 + 0xC, modded_projectile_id)
end

function HUD()
	for i=1,16 do
		if player_present(i) then
			if game_started then
				if player_alive(i) then
					if get_var(0, "$ticks")%5 == 1 then
						ClearConsole(i)
						local player_monster = get_dynamic_player(monster)
						if player_monster ~= 0 then
							local health = read_float(player_monster + 0xE0)*max_health
							if i == monster then
								rprint(i, "|r<"..PrintBar(nuke_timer, nuke_recharge_time, 20, "right").."> NUKE (x)"..color_red)
								rprint(i, "|r<"..PrintBar(frag_timer, frag_recharge_time, 20, "right").."> ROCKET "..color_red)
								rprint(i, "|r<"..PrintBar(plasma_timer, plasma_recharge_time, 20, "right").."> PLASMA "..color_red)
								rprint(i, "|cHEALTH"..color_red)
							else
								if PLAYER_SKULL_COUNT[i] > 0 then
									if PLAYER_SKULL_COUNT[i] > 1 then
										rprint(i, "|r"..PLAYER_SKULL_COUNT[i].." SKULLS"..color_red)
									else
										rprint(i, "|r"..PLAYER_SKULL_COUNT[i].." SKULL"..color_red)
									end
								end
								rprint(i, "|c"..string.upper(get_var(monster, "$name")).."'S HEALTH"..color_red)
							end
							rprint(i, "|c<"..PrintBar(health, max_health, 65, "left")..">"..color_red)
						end
					end
				else
					ClearConsole(i)
				end
			else
				-- if game has not started
			end
		end
	end
end

function PrintBar(val_min, val_max, length, side)
	if val_min == -100 then
		val_min = val_max
	end
	local bar = ""
	for i=1,length do
		if i > val_min/val_max*length then
			if side == "left" then
				bar = bar.."."
			else
				bar = "."..bar
			end
		else
			if side == "left" then
				bar = bar.."|"
			else
				bar = "|"..bar
			end
		end
	end
	return bar
end

function ClearConsole(i)
	for j=0,25 do
		rprint(i, " ")
	end
end

function RemoveHeadshots()
	for i=1,2 do
		local tag_data = read_dword(lookup_tag("jpt!", HEADSHOT_DMGS[i]) + 0x14)
		write_bit(tag_data + 0x1C8, 1, 0)
	end
end

function GetMetaID(object_type, object_dir)
	local address = lookup_tag(object_type,object_dir)
	if(address ~= 0) then
		return read_dword(address + 0xC)
	end
	return nil
end

function DeletePlayer(i)
	i = tonumber(i)
	if player_alive(i) then
		local m_player = get_player(i)
		local player_obj_id = read_dword(m_player + 0x34)
		local object = get_object_memory(player_obj_id)
		if object ~= 0 then
			destroy_object(player_obj_id)
		end
	end
end

function GetPlayerInput(i) -- checks if player is pressing X key
	local pressing_x_key = false
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local client_machineinfo_struct = network_struct + 0x3B8+0x40 + to_real_index(i) * 0xEC
		local action_key_all = read_bit(player + 0x209, 6)
		local action_key_only = read_bit(client_machineinfo_struct + 0x24, 6)
		local e_key = read_bit(player + 0x47A, 6)
		
		monster_x_key = 0
		
		if action_key_all == 1 then
			if monster_delay == 0 and monster_previous_action == 0 and e_key == 0 then
				pressing_x_key = true
				monster_x_key = 1
			end
			monster_previous_action = 1
		else
			monster_previous_action = 0
			monster_hold_x = 0
		end
		
		if monster_delay > 0 then
			monster_delay = monster_delay - 1
		end
		
		if e_key == 1 then
			monster_delay = 10
		end
		
		if monster_x_key == 1 then
			monster_hold_x = 1
		end
	end
	return pressing_x_key
end

function RemoveAllObjectsByID(object_id)
	if object_id ~= nil then
		local object_table = read_dword(read_dword(object_table_ptr + 2))
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		for i=0,object_count-1 do
			local ID = read_word(first_object + i*12)*0x10000 + i
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= 0 and object ~= 0xFFFFFFFF then
				if read_dword(object) == object_id then
					destroy_object(ID)
				end
			end
		end
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

function DistanceToDirection(x, y, z, vx, vy, vz)
	local hit, x_g, y_g , z_g, hit_id = intersect(x, y, z, vx, vy, vz)
	return DistanceFormula(x_g, y_g, z_g, x, y, z)
end

function SyncAmmo(i) -- sync ammo for all weapons for this player
	i = tonumber(i)
	if player_alive(i) then
		local player = get_dynamic_player(i)
		for j = 0,2 do
			local currentWeapon = read_dword(player + 0x2F8 + j*0x4)
			if get_object_memory(currentWeapon) ~= 0 then
				say_all("sync")
				sync_ammo(currentWeapon, 0)
			end
		end
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end
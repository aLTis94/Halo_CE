
--CONFIG
	
	local female_armor1 = "bourrin\\halo reach\\spartan\\female\\female"
	local female_armor2 = "bourrin\\halo reach\\marine-to-spartan\\mp female"
	local flood_biped = "characters\\floodcombat_human\\player\\flood player"
	
	local sprint_name = "altis\\weapons\\sprint\\sprint"
	local sprint_female_name = "altis\\weapons\\sprint\\sprint_female"
	local flag_name = "reach\\objects\\weapons\\multiplayer\\flag\\flag"
	local ball_name = "weapons\\ball\\ball"
	local ar_name = "bourrin\\weapons\\assault rifle"
	local br_name = "altis\\weapons\\br_spec_ops\\br_spec_ops"
	local shotgun_name = "cmt\\weapons\\human\\shotgun\\shotgun"
	local dmr_name = "bourrin\\weapons\\dmr\\dmr"
	local ma5k_name = "altis\\weapons\\br\\br"
	local spartan_laser_name = "halo reach\\objects\\weapons\\support_high\\spartan_laser\\spartan laser"
	local rl_name = "bourrin\\weapons\\badass rocket launcher\\bourrinrl"
	local gauss_name = "weapons\\gauss sniper\\gauss sniper"
	local sniper_name = "cmt\\weapons\\evolved\\human\\sniper_rifle\\sniper_rifle"
	local pistol_name = "reach\\objects\\weapons\\pistol\\magnum\\magnum"
	local odst_pistol_name = "halo3\\weapons\\odst pistol\\odst pistol"
	local binoculars_name = "altis\\weapons\\binoculars\\binoculars"
	local knife_name = "altis\\weapons\\knife\\knife"
	local armor_room_name = "altis\\scenery\\armor_room\\armor_room"
	local falcon_name = "vehicles\\falcon\\falcon"
	local scorpion_name = "altis\\vehicles\\scorpion\\scorpion"
	local turret_name = "halo 4\\objects\\vehicles\\human\\turrets\\storm_unsc_artillery\\unsc_artillery_mp"
	local forklift_name = "altis\\vehicles\\forklift\\forklift"
	local frag_name = "cmt\\weapons\\human\\frag_grenade\\frag grenade"
	
	-- 		{voice line = delay after this sound, chance of this sound playing}
	local DIALOG = {
		["scrn_plr_wrswpn"] = {45, 0.8},---0.8
		["chr_vcljmp"] = {55, 0.8},
		["chr_kllfoe"] = {55, 0.2},
		["chr_kllfoe_vclbmp"] = {90, 0.25},
		["dwn_wpn_snpr"] = {65, 0.4},
		["entervcl_drvr"] = {45, 0.15},
		["entervcl_gnr"] = {45, 0.2},
		["grt_intovcl_mine"] = {70, 0.15},
		["grt_plr_vcl"] = {65, 0.15},
		["grt"] = {25, 0.7},
		["scld_plr_hrt_blt"] = {60, 0.18},
		["scld_plr_vclcrazy"] = {70, 0.3},
		["strk_grnd"] = {50, 0.15},
		["strk_snpr"] = {45, 0.5},
		["thnk_plr_btrwpn"] = {55, 0.3},--0.3
		["pain_fall"] = {20, 2},
		["whn"] = {60, 0.08},
		["laugh"] = {50, 1.1},
	}
	
	local debug_mode = false -- makes the sounds play 100% of the time
--END OF CONFIG

api_version = "1.12.0.0"

local last_dialog_timer = 0

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	
	Initialize()
end

function OnGameStart()
	Initialize()
end

function OnScriptUnload()

end

function Initialize()
	if lookup_tag("proj", "altis\\effects\\distance_check") ~= 0 then
		--stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
		cprint("  Dialog script enabled")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_WEAPON_PICKUP'],"OnWeaponPickup")
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
		register_callback(cb['EVENT_VEHICLE_ENTER'],"OnVehicleEnter")
		
		frag_id = read_dword(lookup_tag("proj", frag_name) + 0xC)
		
		local gametype_base = 0x5F5478
		local weaps = read_byte(gametype_base + 0x5C)
		
		if weaps == 4 or weaps == 6 or weaps == 7 or weaps == 12 then
			heavy_weapons_gt = true
		else
			heavy_weapons_gt = false
		end
		
		PLAYERS = {}
		for i=1,16 do
			PLAYERS[i] = {}
		end
	else
		cprint("  Dialog script disabled")
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_WEAPON_PICKUP'])
		unregister_callback(cb['EVENT_JOIN'])
		unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
		unregister_callback(cb['EVENT_VEHICLE_ENTER'])
	end
end

function PlaySound(i, sound)
	i = tonumber(i)
	--rprint(1, "trying to play sound "..sound.." for player "..i)
	if PLAYERS[i] == nil or PLAYERS[i].name == nil or DIALOG[sound] == nil or PLAYERS[i].dead or PLAYERS[i].gender == "flood" then return end
	
	if PLAYERS[i].last_dialog_timer == 0 and last_dialog_timer == 0 then
		math.randomseed(tonumber(get_var(0, "$ticks")) * i + PLAYERS[i].x)
		if debug_mode or math.random() < DIALOG[sound][2] then
			PLAYERS[i].last_dialog_timer = DIALOG[sound][1]
			last_dialog_timer = math.floor(DIALOG[sound][1]/2)
			
			for j=0,15 do
				if player_present(j) and get_var(j, "$has_chimera") == "1" and (player_alive(j) == false or DistanceBetweenPlayers(i,j) < 19) then
					rprint(j, "voice~"..PLAYERS[i].name.."~"..PLAYERS[i].gender.."_"..sound)
				end
			end
		end
	end
end

function OnPlayerJoin(i)
	PLAYERS[i].last_dialog_timer = 100
end

function OnPlayerDeath(i, causer)
	PLAYERS[i].dead = true
	
	causer = tonumber(causer)
	
	if i == causer or PLAYERS[causer] == nil or PLAYERS[causer].team == PLAYERS[i].team then return end
	
	--if PLAYERS[causer].vehicle~=nil and PLAYERS[causer].vehicle_seat==0 and PLAYERS[causer].vehicle_name ~= falcon_name and PLAYERS[causer].vehicle_name ~= scorpion_name then
	--	if PLAYERS[causer].vehicle_name ~= armor_room_name then
			--timer(330, "PlaySound", causer, "chr_kllfoe_vclbmp")
	--	end
	--else
	if PLAYERS[i].weapon_name ~= nil and PLAYERS[i].weapon_name == sniper_name or PLAYERS[i].weapon_name == gauss_name then
		timer(350, "PlaySound", causer, "dwn_wpn_snpr")
	elseif PLAYERS[causer].weapon_name ~= nil and PLAYERS[causer].weapon_name == sniper_name and math.random() < 0.7 then
		timer(400, "PlaySound", causer, "strk_snpr")
	else
		timer(350, "PlaySound", causer, "chr_kllfoe")
	end
end

function OnTick()
	GetStats()
	
	if PLAYERS[1].last_dialog_timer ~= nil then
		--rprint(1, PLAYERS[1].last_dialog_timer)
	end
	
	Woohoo()
	VehicleCrash()
	GrenadeThrow()
	
	if last_dialog_timer > 0 then
		last_dialog_timer = last_dialog_timer - 1
	end
end

function GetStats()
	for i=1,16 do
		
		if PLAYERS[i].last_dialog_timer == nil then
			PLAYERS[i].last_dialog_timer = 0
		elseif PLAYERS[i].last_dialog_timer > 0 then
			PLAYERS[i].last_dialog_timer = PLAYERS[i].last_dialog_timer - 1
		end
		
		local player = get_dynamic_player(i)
		if player == 0 then
			PLAYERS[i].dead = true
		else
			PLAYERS[i].dead = false
			
			PLAYERS[i].m_player = get_player(i)
			local name = GetName(player)
			if name == female_armor1 or name == female_armor2 then
				PLAYERS[i].gender = "female"
			elseif name == flood_biped then
				PLAYERS[i].gender = "flood"
			else
				PLAYERS[i].gender = "male"
			end
			PLAYERS[i].object = player
			PLAYERS[i].name = read_wide_string(PLAYERS[i].m_player + 0x4, 12)
			PLAYERS[i].team = read_word(player + 0xB8)
			
			PLAYERS[i].health = read_float(player + 0xE0)
			PLAYERS[i].shields = read_float(player + 0xE4)
			
			PLAYERS[i].vehicle_id = read_dword(player + 0x11C)
			PLAYERS[i].vehicle = get_object_memory(PLAYERS[i].vehicle_id)
			if PLAYERS[i].vehicle ~= 0 then
				PLAYERS[i].vehicle_seat = read_word(player + 0x2F0)
				PLAYERS[i].vehicle_name = GetName(PLAYERS[i].vehicle)
				PLAYERS[i].vehicle_airborne = read_byte(PLAYERS[i].vehicle + 0x4D0) -- 0 to 255
				local x_vel, y_vel, z_vel = read_vector3d(PLAYERS[i].vehicle + 0x68)
				PLAYERS[i].vehicle_prev_vel = PLAYERS[i].vehicle_vel
				PLAYERS[i].vehicle_vel = math.abs(x_vel) + math.abs(y_vel) + math.abs(z_vel)
				PLAYERS[i].vehicle_collision_x = read_float(PLAYERS[i].vehicle + 0x508)
				PLAYERS[i].vehicle_collision_y = read_float(PLAYERS[i].vehicle + 0x50C)
				--ClearConsole(1)
				--rprint(1, PLAYERS[i].vehicle_prev_vel - PLAYERS[i].vehicle_vel)
			else
				PLAYERS[i].vehicle = nil
				PLAYERS[i].vehicle_vel = 0
			end
			
			PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z = read_vector3d(player + 0x550 + 0x28)
			
			local held_weapon = get_object_memory(read_dword(player + 0x118))
			if held_weapon ~= 0 and read_word(held_weapon + 0xB4) == 2 then
				PLAYERS[i].weapon = held_weapon
				PLAYERS[i].weapon_name = GetName(held_weapon)
			end
		end
	end
end

function Woohoo()
	for i=1,16 do
		if player_present(i) and PLAYERS[i].dead == false and PLAYERS[i].vehicle ~= nil and PLAYERS[i].vehicle_seat ~= 0 and PLAYERS[i].vehicle_name ~= falcon_name then
			if PLAYERS[i].vehicle_airborne == 40 and PLAYERS[i].vehicle_vel > 0.01 then
				PlaySound(i, "chr_vcljmp")
				break
			end
		end
	end
end

function VehicleCrash()
	local crahs_sens = 50
	for i=1,16 do
		if PLAYERS[i].vehicle ~= nil and PLAYERS[i].vehicle_seat ~= 0 then
			for j=1,16 do
				if i~=j and player_alive(j) and PLAYERS[j].vehicle ~= nil and PLAYERS[j].vehicle_seat == 0 then
					if (math.abs(PLAYERS[i].vehicle_collision_x) > crahs_sens or math.abs(PLAYERS[i].vehicle_collision_x) > crahs_sens) then
						timer(600, "PlaySound", i, "scld_plr_vclcrazy")
					elseif PLAYERS[i].vehicle_prev_vel ~= nil and PLAYERS[i].vehicle_prev_vel - PLAYERS[i].vehicle_vel > 0.12 then
						timer(100, "PlaySound", i, "scld_plr_vclcrazy")
					end
				end
			end
		end
	end
end

function GrenadeThrow()
	if get_var(0, "$ffa") == "1" then return end
	
	for i=1,16 do
		if player_alive(i) then
			local child_obj = get_object_memory(read_dword(PLAYERS[i].object + 0x118))
			if child_obj ~= 0 and read_word(child_obj + 0xB4) == 5 then
				if read_dword(child_obj) == frag_id then
					PlaySound(i, "strk_grnd")
					break
				end
			end
		end
	end
end

function OnVehicleEnter(i)
	-- should probably check if there are any allies/players around before doing this
	PLAYERS[i].vehicle_id = read_dword(PLAYERS[i].object + 0x11C)
	PLAYERS[i].vehicle = get_object_memory(PLAYERS[i].vehicle_id)
	if PLAYERS[i].vehicle ~= 0 then
		PLAYERS[i].vehicle_seat = read_word(PLAYERS[i].object + 0x2F0)
		PLAYERS[i].vehicle_name = GetName(PLAYERS[i].vehicle)
		
		if PLAYERS[i].vehicle_name == "taunts\\wave" then
			timer(400, "PlaySound", i, "grt")
			return
		elseif PLAYERS[i].vehicle_name == "taunts\\taunt" and PLAYERS[i].vehicle_seat == 5 then
			timer(450, "PlaySound", i, "laugh")
		end
		
		if PLAYERS[i].vehicle_name==armor_room_name or string.find(PLAYERS[i].vehicle_name, "taunt") ~= nil or PLAYERS[i].vehicle_name==turret_name or PLAYERS[i].vehicle_name==forklift_name then
			return
		end
		
		local gunner_talk = false
		
		if PLAYERS[i].vehicle_seat == 0 then
			PlaySound(i, "entervcl_drvr")
		elseif PLAYERS[i].vehicle_seat==2 and string.find(PLAYERS[i].vehicle_name, "warthog")~=nil then
			PlaySound(i, "entervcl_gnr")
			gunner_talk = true
		end
		
		if PLAYERS[i].vehicle_seat ~= 0 then
			for j=1,16 do
				if i~=j and player_alive(j) and PLAYERS[j].vehicle ~= nil and PLAYERS[j].vehicle_seat==0 and PLAYERS[i].vehicle_id == PLAYERS[j].vehicle_id then
					if gunner_talk then
						timer(2000, "NiceRide", i, j)
					else
						timer(400, "NiceRide", i, j)
					end
					break
				end
			end
		end
	end
end

function NiceRide(i, j)
	i,j = tonumber(i), tonumber(j)
	if player_alive(i) and player_alive(j) and PLAYERS[i].vehicle ~= nil and PLAYERS[j].vehicle ~= nil then
		PlaySound(i, "grt_plr_vcl")
		timer(1200, "WelcomeRider", i, j)
	end
end

function WelcomeRider(i, j)
	i,j = tonumber(i), tonumber(j)
	if player_alive(j) and PLAYERS[j].vehicle ~= nil and PLAYERS[i].vehicle ~= nil then
		PlaySound(j, "grt_intovcl_mine")
	end
end

function OnDamage(i, causer, meta_id)
	causer = tonumber(causer)
	
	if player_present(i) == false or player_present(causer) == false then return end
	
	local tag = lookup_tag(meta_id)
	if tag ~= 0 then
		local name = read_string(read_dword(tag + 0x10))
		if causer~=0 and PLAYERS[i].team == PLAYERS[causer].team then
			if i~=causer and player_alive(i) and player_alive(causer) == true then
				if string.find(name, "expl") == nil and string.find(name, "coll") == nil and string.find(name, "melee") == nil then
					local distance = DistanceBetweenPlayers(i, causer)
					if distance < 15 then
						PlaySound(i, "scld_plr_hrt_blt")
					end
				end
			end
		else
			if name == "globals\\falling" then
				PlaySound(i, "pain_fall")
			elseif name == "globals\\vehicle_collision" then
				timer(330, "PlaySound", causer, "chr_kllfoe_vclbmp")
			elseif PLAYERS[i].shields < 0.1 and PLAYERS[i].health < 0.9 and PLAYERS[i].vehicle == nil and i~=causer then
				PlaySound(i, "whn")
				--say_all(get_var(i, "$name").." is hurt by "..get_var(causer, "$name"))
			end
		end
	end
end

function CheckGun(i)
	i = tonumber(i)
	if PLAYERS ~= nil and PLAYERS[i] ~= nil then
		--say_all(PLAYERS[i].weapon_name)
		if PLAYERS[i].weapon ~= nil and PLAYERS[i].weapon_name ~= flag_name and PLAYERS[i].weapon_name ~= ball_name and PLAYERS[i].weapon_name ~= sprint_name and PLAYERS[i].weapon_name ~= sprint_female_name then
			local unloaded_ammo = read_word(PLAYERS[i].weapon + 0x2B6)
			local loaded_ammo = read_word(PLAYERS[i].weapon + 0x2B8)
			
			if unloaded_ammo == 0 and loaded_ammo == 0 then
				PlaySound(i, "scrn_plr_wrswpn")
			elseif PLAYERS[i].weapon_name == spartan_laser_name or PLAYERS[i].weapon_name == rl_name or PLAYERS[i].weapon_name == gauss_name then
				--say_all("thnk "..PLAYERS[i].weapon_name)
				PlaySound(i, "thnk_plr_btrwpn")
			end
		end
	end
end

function OnWeaponPickup(i, slot, wtype)
	--say_all("slot \""..slot.."\"")
	--say_all("wtype \""..wtype.."\"")
	if heavy_weapons_gt == false and tonumber(wtype) == 1 and tonumber(slot) < 3 then
		if PLAYERS[i].m_player ~= nil then
			timer(133, "CheckGun", i)
		end
	end
end

function GetName(DynamicObject)--	Gets directory + name of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

function DistanceBetweenPlayers(i,j)
	if PLAYERS[i].x ~= nil and PLAYERS[j].x ~= nil then
		return DistanceFormula(PLAYERS[i].x,PLAYERS[i].y,PLAYERS[i].z,PLAYERS[j].x,PLAYERS[j].y,PLAYERS[j].z)
	else
		return 1000
	end
end

function DistanceFormula(x1,y1,z1,x2,y2,z2)-- Made by 002
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function OnError(Message)
	say_all("Error!"..Message)
end

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end

function read_wide_string(address, length)
	local string = ""
	
	for i=0, length do
		local character = read_word(address + i*2)
		if character ~= 0 and character < 256 then
			string = string..read_string(address + i*2)
		end
	end
	
	return string
end
-- 	Custom Bipeds by 002, modified by giraffe and aLTis (altis94@gmail.com)

--																README!
--	This is a modified version of 002's/giraffe's biped swithcing script;
--	Players who join or enter command /armor will be spawned inside an "armor room" where they will be able to choose their armor;
--	They will also be able to choose weapon skins for their loadout weapons
--	There is an optional server message that will be displayed on player's console while he is choosing armor. The message can be customised;
--	This script also contains Chimera detection and other useful things;


-- todo: oddball might get removed if using /armor

api_version = "1.12.0.0"

-- Configuration
	
	-- enables emotes via chat commands or emote wheel. Might cause crashes
	emotes_enabled = true
	-- enabled voice callouts for chimera users
	voice_enabled = true
	-- enables assasinations like in newer halo games (WARNING!!! This feature requires damage_module.dll)
	assasinations_enabled = true
	
	-- armor switching is disabled on these gametypes
	BLACKLISTED_GAMETYPES = {
		["forkball"] = true,
		["survival"] = true,
		["flood"] = true,
		["zombies"] = true,
		["infection"] = true,
	}
	
	-- players on blue team spawn as flood on these gametypes
	FLOOD_GAMETYPES = {
		["flood"] = true,
		["zombies"] = true,
		["infection"] = true,
		["survival"] = true,
	}
	
	--	Show console messages while choosing armor (scroll down to ConsoleMessages in order to customize them)
	show_console_messages = true

	--	Let players choose armor right when they join the server
	choose_armor_on_join = 	true

	--	Let players choose armor after using a command
	choose_armor_on_command = true
	choose_armor_after_time = true
	switch_time = 3	--	Time player needs to stand still to die and choose armor and stuff
	switch_time_message = "Don't move for "..switch_time.." seconds to switch armor."
	switch_time_fail_message = "Armor switch cancelled!"
	switch_command = "armor" --	What is the command that players need to enter (must be lowercase)
	alt_switch_command = "armour" -- Same as above
	alt_switch_command_2 = "armadura" -- Again, same as above
	command_success = "You will be able to choose your armor next time you spawn."
	command_fail = "You are already choosing an armor you silly billy :P"

	-- Message spam. These are sent to player when he is dead
	spam_messages = false
	spam_message = "You can change your armor using /armor command"
	spam_frequency = 3 -- Lower means more frequent

	--	Force armor choice. Set it to true if you don't want your girlfriend to choose her clothes forever ^^
	force_armor_choice = false
	choice_time = 40 * 30 --	Time in ticks that player is allowed to spend in the armor room. Don't set this too high.
	kick_message = "You spent too much time choosing your armor."

	armor_room_vehicle = "altis\\scenery\\armor_room\\armor_room"
	
	--	Flood stuff. Blue team players will be switched to flood on flood_gametype
	flood_biped = "characters\\floodcombat_human\\player\\flood player"
	
	-- Enter only the bipeds that you want to use in your server. Don't forget to change both of these.
	BIPEDS = {
		["default"] = "bourrin\\halo reach\\spartan\\male\\mp masterchief",
		["female"] = "bourrin\\halo reach\\spartan\\female\\female",
		["marine"] = "bourrin\\halo reach\\marine-to-spartan\\mp test",
		["fmarine"] = "bourrin\\halo reach\\marine-to-spartan\\mp female",
		["odst"] = "bourrin\\halo reach\\spartan\\male\\odst",
		["specops"] = "bourrin\\halo reach\\spartan\\male\\spec_ops",
		["koslovik"] = "bourrin\\halo reach\\spartan\\male\\koslovik",
		["altis"] = "bourrin\\halo reach\\spartan\\male\\haunted",
		["sbb"] = "bourrin\\halo reach\\spartan\\male\\117",
		["linda"] = "bourrin\\halo reach\\spartan\\male\\linda",
	}
	-- I know that I could have merged these two but whatever :P
	BIPED_NUMBER = {
		[0] = "default", [1] = "linda", [2] = "female", [3] = "sbb", [4] = "marine", [5] = "fmarine", [6] = "specops", [7] = "koslovik", [8] = "altis", [9] = "odst",
	}

	VISOR_COLORS = {
		[0] = { ["red"] = 0.960784, ["green"] = 0.780392, ["blue"] = 0.396078 },	--default
		[1] = { ["red"] = 1, ["green"] = 0.894118, ["blue"] = 0.176471 },--yellow
		[2] = { ["red"] = 1, ["green"] = 0.55, ["blue"] = 0 },--bronze
		[3] = {	 ["red"] = 0.156863, ["green"] = 0.956863, ["blue"] = 1 },--cyan
		[4] = { ["red"] = 0.509804, ["green"] = 1, ["blue"] = 0.654902 },--salad
		[5] = { ["red"] = 0.2, ["green"] = 1, ["blue"] = 0.2 },--green
		[6] = {	 ["red"] = 0, ["green"] = 0.36, ["blue"] = 0.105 },--dark green
		[7] = { ["red"] = 0, ["green"] = 0, ["blue"] = 0 },--black
		[8] = { ["red"] = 0.5, ["green"] = 0.5, ["blue"] = 0.5 },--grey
		[9] = { ["red"] = 0.9, ["green"] = 0.9, ["blue"] = 0.9 },--white
		[10] = { ["red"] = 0.2, ["green"] = 0.2, ["blue"] = 1 },--blue alt
		[11] = { ["red"] = 0, ["green"] = 0, ["blue"] = 1 },--blue
		[12] = { ["red"] = 0.29, ["green"] = 0, ["blue"] = 0.788 },--purple
		[13] = { ["red"] = 0.75, ["green"] = 0, ["blue"] = 0 },--red
		[14] = { ["red"] = 1, ["green"] = 0.3, ["blue"] = 0.3 },--light red
		[15] = { ["red"] = 1, ["green"] = 0.4, ["blue"] = 0.81 },--pink
		[16] = { ["red"] = 0.65, ["green"] = 0.3, ["blue"] = 0.4 },--greyish red
		[17] = { ["red"] = 0.3, ["green"] = 0.5, ["blue"] = 0.65 },--greyish blue
		[18] = { ["red"] = 0.3, ["green"] = 0.65, ["blue"] = 0.65 },--greyish cyan
		[19] = { ["red"] = 0.3, ["green"] = 0.6, ["blue"] = 0.3 },--greyish green
		[20] = { ["red"] = 0.5, ["green"] = 0.6, ["blue"] = 0.3 },--greyish greenish yellow
		[21] = { ["red"] = 0.65, ["green"] = 0.5, ["blue"] = 0.3 },--brown
		[22] = { ["red"] = 0.3, ["green"] = 0.2, ["blue"] = 0.15 },--dark brown
		[23] = { ["red"] = 0.18, ["green"] = 0.3, ["blue"] = 0.15 },--dark green
		[24] = { ["red"] = 0.14, ["green"] = 0.3, ["blue"] = 0.3 },--dark cyan
		[25] = { ["red"] = 0.14, ["green"] = 0.22, ["blue"] = 0.35 },--dark blue
		[26] = { ["red"] = 0.14, ["green"] = 0.14, ["blue"] = 0.35 },--dark purple
		[27] = { ["red"] = 1, ["green"] = 0.7, ["blue"] = 0.7 },--bright red
		[28] = { ["red"] = 1, ["green"] = 0.7, ["blue"] = 1 },--bright purple
		[29] = { ["red"] = 0.7, ["green"] = 0.7, ["blue"] = 1 },--bright blue
		[30] = { ["red"] = 0.7, ["green"] = 0.85, ["blue"] = 1 },--bright cyan
		[31] = { ["red"] = 0.7, ["green"] = 1, ["blue"] = 1 },--bright cyan2
		[32] = { ["red"] = 0.7, ["green"] = 1, ["blue"] = 0.7 },--bright green
		[33] = { ["red"] = 1, ["green"] = 1, ["blue"] = 0.7 },--bright yellow
	}
	
	
	EMBLEMS = {
		["{XG}aLTis"] = 1, ["{XG}Mind"] = 1, ["amen"] = 1, ["Treeman"] = 2, ["(SBB) Storm"] = 3, ["tark"] = 4, ["Tark"] = 4, ["giraffe"] = 5, ["raffgie"] = 5,
		["Pacobell"] = 6, ["(SBB)Kawaii"] = 7, ["Fubih"] = 7, ["Gonzalus"] = 8, ["(SBB)Shaung"] = 9, ["Shaung"] = 9, ["VanilaNeko"] = 9, ["(SBB) Sean"] = 12, ["(SBB) Mega"] = 12,
		["Megasean"] = 12, ["MrChromed"] = 13, ["Sled"] = 13, ["Cono256"] = 13, ["Solink"] = 13, ["JerryBrick"] = 13, ["Ryon"] = 15, ["Madotsuki"] = 15, ["[1] Echo-77"] = 16,
		["[1]Echo-77"] = 16, ["multiclient"] = 18, ["Speed775"] = 19, ["Night"] = 20, ["Reus"] = 21, ["Antarctican"] = 22, ["PopeTX28"] = 23, ["Nickster"] = 24,
		["Bean"] = 25, ["tarikja"] = 30, ["Michelle"] = 31, ["Perla117"] = 32, ["Kinnet"] = 33, ["kinnet"] = 33, ["Lvl 1 crook"] = 33,
		[string.format("J%sv%s",string.char(170),string.char(170))] = 34,
		[string.format("J%sv%s",string.char(166),string.char(166))] = 34,
		["Crack2020"] = 35, ["Stick"] = 36, ["Rock Candy"] = 37, ["oove"] = 38, ["Hispanorum"] = 39,
		[string.format("L%sB%s",string.char(216),string.char(216))] = 41,
		[string.format("[LVS]L%sB%s",string.char(216),string.char(216))] = 41,
		["The Lobo"] = 41, ["ReconNinja"] = 42, ["ThRankaWolf"] = 43, ["silvernight47"] = 43, ["Tempus Lux"] = 44, ["GEMIS"] = 44, ["{BK}miriem"] = 45,
	}
	
	CLAN_EMBLEMS = {
		["{BK}"] = 10, ["(SBB)"] = 11, ["(SHM)"] = 13, ["[Key]"] = 14, ["El"] = 17, ["POQ"] = 40, ["PÕQ"] = 40,
	}
	
	--	Coordinates of the first armor room and stuff (don't touch these unless you know what you're doing!)
	x = -113
	y = -149
	z = -104
	rot = 0--math.pi
	distance_between_rooms = (-2.5)

	--	Delay before spawning room vehicle in ms (should not be changed)
	room_delay_command = 0
	room_delay_player_join = 0

	--	Console message delay (in ticks) - how often to refresh console messages
	console_delay = 15

	--	Player input delay (in ticks) - shorter delay means armors switch faster when pressing left or right
	input_delay_armor = 8
	-- Player input delay for skins and visor colors
	input_delay = 4

--	WEAPON SKINS
	
	--	All weapons must have "weapon" tag in their table, highest number is default skin
	SKINS = {
		["ar"] = {
			["weapon"] = "bourrin\\weapons\\assault rifle",
			["count"] = 8,
		},
		["br"] = {
			["weapon"] = "altis\\weapons\\br_spec_ops\\br_spec_ops",
			["count"] = 4,
		},
		["dmr"] = {
			["weapon"] = "bourrin\\weapons\\dmr\\dmr",
			["count"] = 4,
		},
		["shotgun"] = {
			["weapon"] = "cmt\\weapons\\human\\shotgun\\shotgun",
			["count"] = 4,
		},
		["pistol"] = {
			["weapon"] = "reach\\objects\\weapons\\pistol\\magnum\\magnum",
			["count"] = 8,
		},
		["ma5k"] = {
			["weapon"] = "altis\\weapons\\br\\br",
			["count"] = 4,
		},
		["odst"] = {
			["weapon"] = "halo3\\weapons\\odst pistol\\odst pistol",
			["count"] = 4,
		},
	}
	
	
	EMOTE_TIMERS = {
		["laugh"] = {123, 5},
		["upset"] = {230, 4},
		["thrust"] = {112, 3},
		["sit"] = {99999, 2},
		["flex"] = {336, 1},
		["wave"] = {85, 0},
		["shrug"] = {120, 9},
		["butt"] = {178, 8},
		["dance"] = {204, 7},
		["dab"] = {25, 6},
	}
	
	emote_delay_time = 2*30 -- how long player needs to wait to be able to use an emote again
	
	afk_emote = true		-- makes player read a newspaper if they are afk
	afk_emote_timer = 40*30	-- how long player has to be afk (in ticks)
	
	voice_lines_to_chat = true -- will send chat messages to teammates when using voice callouts
	
	-- these are the voice lines that will be sent as chat messages. comment out those that you don't want to use
	CHAT_MESSAGES = {
		["cvr"] = "Cover me!",
		["newordr_entervcl"] = "Get in!",
		["entervcl"] = "I need a ride!",
		["warn"] = "Watch out!",
		["newordr_advance"] = "Advance!",
		["join_stayback"] = "We should stay back!",
		["foundfoe"] = "This way!",
		["ok"] = "Okay!",
		["prs"] = "Good job!",
		["scrn"] = "Idiot!",
		["thnk"] = "Thanks!",
	}
	
--  MAP BOUNDARIES

	force_players_to_stay_in_map = true
	boundary_move_player_amount = 6
	map_boundary_x_min = -200
	map_boundary_x_max = 206.5
	map_boundary_y_min = -105
	map_boundary_y_max = 106
	
--	MELEE FOR VEHICLES

	-- (WARNING!!! This feature requires damage_module.dll)
	vehicle_melee_enable = true
	
--	INPUT
	local KEYBOARD_KEYS = {
		[17] = "1", [18] = "2", [19] = "3", [20] = "4", [21] = "5", [22] = "6", [23] = "7", [24] = "8", [25] = "9", [26] = "10", [27] = "Minus", [28] = "Equal",
		[30] = "Tab", [31] = "Q", [32] = "W", [33] = "E", [34] = "R", [35] = "T", [36] = "Y", [37] = "U", [38] = "I", [39] = "O", [40] = "P", [43] = "Backslash",
		[44] = "Caps Lock", [45] = "A", [46] = "S", [47] = "D", [48] = "F", [49] = "G", [50] = "H", [51] = "J", [52] = "K", [53] = "L", [56] = "Enter", [57] = "Shift",
		[58] = "Z", [59] = "X", [60] = "C", [61] = "V", [62] = "B", [63] = "N", [64] = "M", [69] = "Ctrl", [71] = "Alt",[72] = "Space",
	}
	
-- End of Configuration

if assasinations_enabled or vehicle_melee_enable then
	ffi = require("ffi")
	ffi.cdef [[
		void damage_object(float amount, uint32_t receiver, int8_t causer);
		void damage_player(float amount, uint8_t receiver, int8_t causer);
	]]
	damage_module = ffi.load("damage_module")
	damage_object = damage_module.damage_object
	damage_player = damage_module.damage_player
end

PLAYER_INPUT = {}--		used to check if a player released a key before pressing it again
BIPED_IDS = {}
CHOSEN_SKINS = {}
CHOSEN_BIPEDS = {}--	armor that player actually chose
CHOSEN_VISOR = {}
PREVIEW_SKINS = {}
ROOM_VEHICLES = {}--	ID of the armor room
CHOOSING_ARMOR = {}
BIPED_VEHICLES = {}--	ID of the armor that is being previewed
BIPED_WANTED = {}--		Which armor player is choosing
DELAY_COUNTER = {}--	Used to delay console messages
WANTS_TO_SWITCH = {}--	Changes to 1 if player used a command and to 2 if just joined and 3 if timer thing
PREVIOUS_FLASHLIGHT_STATE = {} -- Used to check if player is pressing Q
DEFAULT_BIPED = nil
EMOTES = {}
EMOTES.timers = {}
EMOTES.delay = {}
EMOTES.vehicles = {}
EMOTES.active = {}
MELEE_TIMERS = {}
POSITIONS = {} -- used for death sounds
AFK = {}
CUSTOM_KEYS = {}
HAY = {}
FORKS = {}
for i=1,16 do
	AFK[i] = {}
	AFK[i].timer = 0
end
game_ended = false
translation = false

function OnScriptLoad()
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	stats_globals = read_dword(sig_scan("33C0BF??????00F3AB881D") + 0x3)
	add_var("has_chimera", 4)
	for i=1,16 do
		set_var(i, "$has_chimera", 0)
	end
	
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
	
	if lookup_tag("vehi", armor_room_vehicle) ~= 0 then
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_PRESPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
		for i=1,16 do
			rprint(i, "|ndo_you_have_chimera?")
			
			CHOOSING_ARMOR[i] = false
			WANTS_TO_SWITCH[i] = 1
			PREVIEW_SKINS[i] = {}
			DELAY_COUNTER[i] = 1
			PLAYER_INPUT[i] = 0
			BIPED_WANTED[i] = 0
			CHOSEN_SKINS[i] = {}
			CHOSEN_VISOR[i] = 0
			EMOTES.timers[i] = 0
			EMOTES.delay[i] = 0
			EMOTES.vehicles[i] = nil
			EMOTES.active[i] = 0
			MELEE_TIMERS[i] = 0
			CUSTOM_KEYS[i] = {}
			CUSTOM_KEYS[i].aa = 60
			CUSTOM_KEYS[i].sprint = 57
			
			for key,value in pairs (SKINS) do
				CHOSEN_SKINS[i][key] = #value
			end
			
			if player_present(i) then
				LoadChoices(i)
			end
			
			timer(5000, "FindHay")
		end
	end
end

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,25 do
		rprint(i," ")
	end
end

function RemoveWeapons(PlayerIndex)--		Removes player's weapons. Used when player enters the room
	execute_command("wdel " .. PlayerIndex .. " 0")
	execute_command("nades " .. PlayerIndex .. " 0 0")
end

function ConsoleMessages(i) --				These are the messages that will be displayed while player is choosing his armor
	DELAY_COUNTER[i] = DELAY_COUNTER[i] + 1
	if(DELAY_COUNTER[i]%console_delay == 0) then
		if(DELAY_COUNTER[i] > choice_time) then
			DELAY_COUNTER[i] = 1
			if(force_armor_choice) then
				OnVehicleExit(i)
				say(i, kick_message)
			end
		end
		
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, "|cWelcome to the Official Bigass server!|nc7FB3D5")
		if get_var(i, "$has_chimera") == "1" then
			rprint(i, "|cYou have Chimera!|nc9DFF09")
		else
			rprint(i, "|cYou don't have Chimera! Please download Chimera -581 from Discord!|ncFF4B09")
		end
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		if translation then
			if get_var(i, "$language") == "en" then
				rprint(i, "|lYour language is set to English, press [flashlight] to change it|nc1F618D")
			else
				rprint(i, "|lYour language is set to Spanish, press [flashlight] to change it|ncD68910")
			end
		else
			rprint(i, " ")
		end
		rprint(i,"|l[left] and [right] to switch armors|nc7FB3D5")
		rprint(i, "|l[forward]/[backward] to switch primary/secondary weapon skins|nc7FB3D5")
		if get_var(i, "$has_chimera") == "1" then
			rprint(i, "|l[crouch] and [jump] to switch visor color|nc7FB3D5")
		else
			rprint(i, " ")
		end
		if(force_armor_choice) then
			rprint(i,"|l[action] to confirm your selection|rYou have "..math.floor((choice_time/30) - (DELAY_COUNTER[i]/30)).." seconds to choose.|nc7FB3D5")
		else
			rprint(i, "|l[action] to confirm your selection|nc7FB3D5")
		end
	end
end

function MessageSpam(PlayerIndex)
	if(rand(1,spam_frequency) == 1) then
		say(PlayerIndex, spam_message)
	end
end

function LoadChoices(i)
	local savefile = io.open("sapp\\bigass_armors\\"..get_var(i, "$name")..".txt", "r")
	if savefile ~= nil then
		CHOSEN_VISOR[i] = tonumber(savefile:read())
		BIPED_WANTED[i] = tonumber(savefile:read())
		for key,value in pairs (SKINS) do
			CHOSEN_SKINS[i][key] = tonumber(savefile:read())
		end
		local key_aa = savefile:read()
		if key_aa ~= nil then
			CUSTOM_KEYS[i].aa = tonumber(key_aa)
			local key_sprint = savefile:read()
			if key_sprint ~= nil then
				CUSTOM_KEYS[i].sprint = tonumber(key_sprint)
			end
		end
		savefile:close()
	end
	SendCustomKeys(i)
end

function SaveChoices(i)
	if BIPED_WANTED ~= nil and CHOSEN_SKINS[i] ~= nil and BIPED_WANTED[i] ~= nil and CHOSEN_VISOR[i] ~= nil then
		local savefile = io.open("sapp\\bigass_armors\\"..get_var(i, "$name")..".txt", "w")
		if savefile ~= nil then
			io.output(savefile)
			io.write(CHOSEN_VISOR[i].."\n")
			io.write(BIPED_WANTED[i].."\n")
			for key,value in pairs (SKINS) do
				io.write(CHOSEN_SKINS[i][key].."\n")
			end
			if CUSTOM_KEYS[i].aa ~= ni and CUSTOM_KEYS[i].sprint ~= nil then
				io.write(CUSTOM_KEYS[i].aa.."\n")
				io.write(CUSTOM_KEYS[i].sprint.."\n")
			end
			savefile:close()
		else
			os.execute("mkdir sapp\\bigass_armors")
		end
	end
end

function OnTick() --						Gets player input and stuff
	for i=1,16 do
		GetCustomKeys(i)
		AFKEmote(i)
		EmoteStuff(i)
		Forklift()
		VehicleMelee()
		
		local player = get_dynamic_player(i)
		
		if player ~= 0 and BIPED_WANTED ~= nil then
			POSITIONS[i] = {}
			POSITIONS[i].x, POSITIONS[i].y, POSITIONS[i].z = read_vector3d(player + 0x550 + 0x28)
			
			if(FLOOD_GAMETYPES[string.lower(get_var(0, "$mode"))] ~= nil and get_var(i, "$team") == "blue") then
				POSITIONS[i].sound = "flood"
			else
				if BIPED_WANTED[i] == 2 or BIPED_WANTED[i] == 5 then
					POSITIONS[i].sound = "female"
				elseif BIPED_WANTED[i] == 3 then
					POSITIONS[i].sound = "storm"
				else
					POSITIONS[i].sound = "male"
				end
			end
		end
		
		if ROOM_VEHICLES[i] == nil then
			ROOM_VEHICLES[i] = spawn_object("vehi", armor_room_vehicle, x, (y + distance_between_rooms * (i - 1)), (z + 0.05), rot)
			if get_object_memory(ROOM_VEHICLES[i]) == 0 then
				cprint("ERROR spawning "..i)
			end
		end
		
		if PREVIEW_SKINS == nil then return false end
		
		if player_alive(i) == true and CHOOSING_ARMOR[i] then
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 and GetName(vehicle) ~= armor_room_vehicle then
				CHOOSING_ARMOR[i] = false
			end
			
			if get_var(i, "$language") == "$language" then
				translation = false
			else	
				translation = true
			end
			
			if(show_console_messages) then
				ConsoleMessages(i)
			end
			
			-- WEAPON SKINS
			local primary_weapon, secondary_weapon = GetBipedWeapons(i)
			if primary_weapon ~= nil and PREVIEW_SKINS ~= nil and PREVIEW_SKINS[i] ~= nil then
				if PREVIEW_SKINS[i].primary == nil then
					PREVIEW_SKINS[i].primary = spawn_object("weap", primary_weapon.."_preview", (x - 0.1), (y + distance_between_rooms * (i - 1) - 0.45), z + 0.6, -math.pi/2)
					ChangeSkinOfWeapon(PREVIEW_SKINS[i].primary, i)
					local object = get_object_memory(PREVIEW_SKINS[i].primary)
					if object ~= 0 then
						write_dword(object + 0x204, 0xF000000)
					end
				end
				
				local primary_weapon_object = get_object_memory(PREVIEW_SKINS[i].primary)
				if(primary_weapon_object == 0) then
					PREVIEW_SKINS[i].primary = nil
				end
				
				if secondary_weapon ~= nil then
					if(PREVIEW_SKINS[i].secondary == nil) then
						PREVIEW_SKINS[i].secondary = spawn_object("weap", secondary_weapon.."_preview", (x - 0.1), (y + distance_between_rooms * (i - 1) - 0.4), z + 0.45, -math.pi/2)
						ChangeSkinOfWeapon(PREVIEW_SKINS[i].secondary, i)
						local object = get_object_memory(PREVIEW_SKINS[i].secondary)
						if object ~= 0 then
							write_dword(object + 0x204, 0xF000000)
						end
					end
					
					local secondary_weapon_object = get_object_memory(PREVIEW_SKINS[i].secondary)
					if(secondary_weapon_object == 0) then
						PREVIEW_SKINS[i].secondary = nil
					end
				end
			end
			
			local unit_forward = read_float(player + 0x278)
			local unit_left = read_float(player + 0x27C)
			local flashlight_state = read_bit(player + 0x208,4)
			local unit_crouch = read_bit(player + 0x208,0)
			local unit_jump = read_bit(player + 0x208,1)
			
			
			--	Change player's language if they are pressing Q
			if translation and flashlight_state ~= 0 then
				if get_var(i, "$language") == "en" then
					set_var(i, "$language", "es")
				else
					set_var(i, "$language", "en")
				end
			end
			
			--	Check if player is pressing left or right and switch their armor
			if(PLAYER_INPUT[i] == 0) then
				if unit_crouch == 1 then
					PlaySound(i, "bumper")
					PLAYER_INPUT[i] = input_delay
					CHOSEN_VISOR[i] = CHOSEN_VISOR[i] - 1
					if(CHOSEN_VISOR[i] < 0) then
						CHOSEN_VISOR[i] = #VISOR_COLORS
					end
					ChooseVisor(i, 1)
				elseif unit_jump == 1 then
					PlaySound(i, "bumper")
					PLAYER_INPUT[i] = input_delay
					CHOSEN_VISOR[i] = CHOSEN_VISOR[i] + 1
					if(CHOSEN_VISOR[i] > #VISOR_COLORS) then
						CHOSEN_VISOR[i] = 0
					end
					ChooseVisor(i, 1)
				elseif(unit_left == -1) then--		Right
					PlaySound(i, "b_button")
					PLAYER_INPUT[i] = input_delay_armor
					BIPED_WANTED[i] = BIPED_WANTED[i] + 1
					if(BIPED_WANTED[i] > #BIPED_NUMBER) then
						BIPED_WANTED[i] = 0
					end
					ChooseBiped(i, 0)
				elseif(unit_left == 1) then--	Left
					PlaySound(i, "b_button")
					PLAYER_INPUT[i] = input_delay_armor
					BIPED_WANTED[i] = BIPED_WANTED[i] - 1
					if(BIPED_WANTED[i] < 0) then
						BIPED_WANTED[i] = #BIPED_NUMBER
					end
					ChooseBiped(i, 0)
				elseif(unit_forward == 1) then
					PlaySound(i, "bumper")
					PLAYER_INPUT[i] = input_delay
					
					for key,value in pairs (SKINS) do
						if(value["weapon"] == primary_weapon) then
							CHOSEN_SKINS[i][key] = CHOSEN_SKINS[i][key] - 1
							if(CHOSEN_SKINS[i][key] < 1) then
								CHOSEN_SKINS[i][key] = value["count"]
							end
							if(PREVIEW_SKINS[i].primary ~= nil) then
								ChangeSkinOfWeapon(PREVIEW_SKINS[i].primary, i)
							end
						end
					end
				elseif(unit_forward == -1 and secondary_weapon ~= nil) then
					PlaySound(i, "bumper")
					PLAYER_INPUT[i] = input_delay
					
					for key,value in pairs (SKINS) do
						if(value["weapon"] == secondary_weapon) then
							CHOSEN_SKINS[i][key] = CHOSEN_SKINS[i][key] - 1
							if(CHOSEN_SKINS[i][key] < 1) then
								CHOSEN_SKINS[i][key] = value["count"]
							end
							if(PREVIEW_SKINS[i].secondary ~= nil) then
								ChangeSkinOfWeapon(PREVIEW_SKINS[i].secondary, i)
							end
						end
					end
				end
				
				local room_vehicle = get_object_memory(ROOM_VEHICLES[i])
				if room_vehicle == 0 then 
					say_all("Armor script: room vehicle didn't exist")
					ROOM_VEHICLES[i] = spawn_object("vehi", armor_room_vehicle, x, (y + distance_between_rooms * (i - 1)), (z + 0.05), rot)
					execute_command("vexit "..i)
					DestroyRoom(i)
					return
				end
				local room_x = read_float(room_vehicle + 0x5C)
				local room_y = read_float(room_vehicle + 0x60)
				local room_z = read_float(room_vehicle + 0x64)
				local x_dist = room_x - x
				local y_dist = room_y - y
				local z_dist = room_z - z
				local distance_from_map_room = math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
				if distance_from_map_room > 30 then
					execute_command("vexit "..i)
					DestroyRoom(i)
					RemoveObject(ROOM_VEHICLES[i])
					ROOM_VEHICLES[i] = nil
					--say_all("destroying room")
				end
				
			elseif(PLAYER_INPUT[i] > 0) then
				PLAYER_INPUT[i] = PLAYER_INPUT[i] - 1
			end
		elseif(player_alive(i) and WANTS_TO_SWITCH[i] == 3) then
			if player ~= 0 then
				local has_flag = false
				for i=0,3 do
					local weapon_id = read_dword(player + 0x2F8 + i*0x4)
					local weapon = get_object_memory(weapon_id)
					if weapon ~= 0 and GetName(weapon) == "reach\\objects\\weapons\\multiplayer\\flag\\flag" then
						has_flag = true
					end
				end
				local unit_forward = read_float(player + 0x278)
				local unit_left = read_float(player + 0x27C)
				local shooting = read_float(player + 0x490)
				local vehicle = get_object_memory(read_dword(player + 0x11C))
				if(unit_forward ~= 0 or unit_left ~= 0 or shooting == 1 or vehicle ~= 0 or has_flag) then
					say(i, switch_time_fail_message)
					WANTS_TO_SWITCH[i] = 2
					PlaySound(i, "error")
				end
			end
		end
	end
	
	Boundaries()
end

function PlaySound(i, sound)
	if get_var(i, "$has_chimera") == "1" then
		rprint(i, "play_chimera_sound~"..sound)
	end
end

function ChooseVisor(j, room)
	j = tonumber(j)
	if player_present(j) == false then return false end
	room = tonumber(room)
	
	if CHOSEN_VISOR[j] ~= nil and player_alive(j) then
		local player_info = get_player(j)
		local player_name = read_wide_string(player_info + 0x4, 12)
		local color = VISOR_COLORS[CHOSEN_VISOR[j]].red.."~"..VISOR_COLORS[CHOSEN_VISOR[j]].green.."~"..VISOR_COLORS[CHOSEN_VISOR[j]].blue
		if room == 1 then
			if get_var(j, "$has_chimera") == "0" then return false end
			if BIPED_NUMBER[BIPED_WANTED[j]] == "altis" then
				rprint(j, "visor_room~"..color.."~haunted")
			else
				rprint(j, "visor_room~"..color)
				if EMBLEMS[player_name] ~= nil then 
					rprint(j, string.format("logo~%s~%s", EMBLEMS[player_name], player_name))
				else
					for CLAN,emblem_id in pairs (CLAN_EMBLEMS) do
						if string.find(player_name, CLAN) then
							rprint(j, string.format("logo~%s~%s", emblem_id, player_name))
						end
					end
				end
			end
			return false
		end
		
		for i = 1,16 do
			if get_var(i, "$has_chimera") == "1" then
				if CHOSEN_BIPEDS[j] == "altis" then
					rprint(i, string.format("visor~%s~%s~haunted",color,player_name))
				else
					rprint(i, string.format("visor~%s~%s",color,player_name))
					if EMBLEMS[player_name] ~= nil then 
						rprint(i, string.format("logo~%s~%s", EMBLEMS[player_name], player_name))
						--say_all("setting emblem for "..player_name)
					else
						for CLAN,emblem_id in pairs (CLAN_EMBLEMS) do
							if string.find(player_name, CLAN) then
								rprint(j, string.format("logo~%s~%s", emblem_id, player_name))
								--say_all("setting clan emblem for "..player_name)
							end
						end
					end
				end
			end
		end
	end
end

function GetBipedWeapons(i)
	local gametype_weapons = read_byte(0x5F5478 + 0x5C)
	
	if gametype_weapons == 4 then
		return "cmt\\weapons\\evolved\\human\\sniper_rifle\\sniper_rifle", "reach\\objects\\weapons\\pistol\\magnum\\magnum"
	elseif gametype_weapons == 6 then
		return "bourrin\\weapons\\badass rocket launcher\\bourrinrl", nil
	elseif gametype_weapons == 7 then
		return "cmt\\weapons\\human\\shotgun\\shotgun", nil
	elseif(BIPED_VEHICLES[i] ~= nil) then
		local preview_biped_object = get_object_memory(BIPED_VEHICLES[i])
		if(preview_biped_object ~= 0) then 
			local biped_name = read_string(read_dword(read_word(preview_biped_object) * 32 + 0x40440038))
			--	this part is made by sehe, it finds what weapons biped has
			local biped_tag_table_entry = lookup_tag("bipd", biped_name)
			local biped_tag = read_dword(biped_tag_table_entry + 0x14)
			local first_weapon = read_dword(biped_tag + 0x2DC)
			local primary_weapon = read_string(read_dword(first_weapon + 4))
			local secondary_weapon = read_string(read_dword(first_weapon + 4 + 0x24))
			return primary_weapon, secondary_weapon
		end
	end
end

function ChooseBiped(PlayerIndex, entering)--			This only chooses preview biped inside the armor room
	if BIPED_VEHICLES[PlayerIndex] ~= nil and entering == 0 then
		timer(200, "RemoveObject", BIPED_VEHICLES[PlayerIndex])
	end
	BIPED_VEHICLES[PlayerIndex] = spawn_object("bipd ", BIPEDS[BIPED_NUMBER[BIPED_WANTED[PlayerIndex]]].."_preview", x, (y + distance_between_rooms * (PlayerIndex - 1)), (z-0.01), rot)
	
	if PREVIEW_SKINS[PlayerIndex] ~= nil then
		if PREVIEW_SKINS[PlayerIndex].primary ~= nil then
			RemoveObject(PREVIEW_SKINS[PlayerIndex].primary)
			PREVIEW_SKINS[PlayerIndex].primary = nil
		end
		if PREVIEW_SKINS[PlayerIndex].secondary ~= nil then
			RemoveObject(PREVIEW_SKINS[PlayerIndex].secondary)
			PREVIEW_SKINS[PlayerIndex].secondary = nil
		end
	end
	timer(245, "ChooseVisor", PlayerIndex, 1)
end

function RemoveObject(ID)
	ID = tonumber(ID)
	if ID ~= nil and get_object_memory(ID) ~= 0 then
		destroy_object(ID)
	--else
		--say_all("Armor script: couldn't remove an object!")
	end
end

function SpawnRoom(PlayerIndex)--			This makes the player enter the armor room
	PlayerIndex = tonumber(PlayerIndex)
	if player_alive(PlayerIndex)==false then 
		return false
	end
	
	RemoveWeapons(PlayerIndex)
	ChooseBiped(PlayerIndex, 1)
	CHOOSING_ARMOR[PlayerIndex] = true
	--if ROOM_VEHICLES[PlayerIndex] == nil then
		--ROOM_VEHICLES[PlayerIndex] = spawn_object("vehi", armor_room_vehicle, x, (y + distance_between_rooms * (PlayerIndex - 1)), (z + 0.05), rot)
	--end
	if ROOM_VEHICLES[PlayerIndex] ~= nil then
		enter_vehicle(ROOM_VEHICLES[PlayerIndex], PlayerIndex, 0)
	else
		say_all("ERROR! Couldn't enter armor room")
	end
end

function DestroyRoom(PlayerIndex)--			Destroys the room vehicle IF it exists
	
	PlayerIndex = tonumber(PlayerIndex)
	
	if CHOOSING_ARMOR[PlayerIndex] and player_alive(PlayerIndex) then
		local player_object_id = read_dword(get_player(PlayerIndex) + 0x34)
		RemoveObject(player_object_id)
	end
	if PREVIEW_SKINS[PlayerIndex] ~= nil then
		if(PREVIEW_SKINS[PlayerIndex].primary ~= nil) then
			RemoveObject(PREVIEW_SKINS[PlayerIndex].primary)
			PREVIEW_SKINS[PlayerIndex].primary = nil
		end
		if(PREVIEW_SKINS[PlayerIndex].secondary ~= nil) then
			RemoveObject(PREVIEW_SKINS[PlayerIndex].secondary)
			PREVIEW_SKINS[PlayerIndex].secondary = nil
		end
	end
	if(BIPED_VEHICLES[PlayerIndex] ~= nil) then
		RemoveObject(BIPED_VEHICLES[PlayerIndex])
		BIPED_VEHICLES[PlayerIndex] = nil
	end
	
	CHOOSING_ARMOR[PlayerIndex] = false
end

function OnPlayerJoin(PlayerIndex)--		Resets some values and calls SpawnRoom after a delay
	if lookup_tag("vehi", armor_room_vehicle) ~= 0 then
		set_var(PlayerIndex, "$has_chimera", 0)
		
		rprint(PlayerIndex, "|ndo_you_have_chimera?")
		
		if BLACKLISTED_GAMETYPES[string.lower(get_var(0, "$mode"))] == nil then
			if(choose_armor_on_join) then
				WANTS_TO_SWITCH[PlayerIndex] = 2
			end
		end
		CHOSEN_BIPEDS[tonumber(PlayerIndex)] = nil
		BIPED_WANTED[PlayerIndex] = 0
		CHOSEN_VISOR[PlayerIndex] = 0
		CUSTOM_KEYS[PlayerIndex].aa = 60
		CUSTOM_KEYS[PlayerIndex].sprint = 57
		LoadChoices(PlayerIndex)
		
		timer(5000, "CheckChimera", PlayerIndex)
	end
end

function OnPlayerLeave(PlayerIndex)--		Resets CHOSEN_BIPEDS and destroys room/biped vehicles if they exist
	PlayerIndex = tonumber(PlayerIndex)
    CHOSEN_BIPEDS[PlayerIndex] = nil
	WANTS_TO_SWITCH[PlayerIndex] = 0
	DestroyRoom(PlayerIndex)
	set_var(PlayerIndex, "$has_chimera", 0)
end

function OnPlayerDeath(PlayerIndex)--		If player died while inside the room, the room and biped vehicles are destroyed
	PlayerIndex = tonumber(PlayerIndex)
	DestroyRoom(PlayerIndex)
	if(spam_messages) then
		timer(1500, "MessageSpam", PlayerIndex)
	end
	
	if POSITIONS[PlayerIndex] ~= nil then
		local ID = spawn_object("weap", "altis\\effects\\death_sound\\"..POSITIONS[PlayerIndex].sound, POSITIONS[PlayerIndex].x, POSITIONS[PlayerIndex].y, POSITIONS[PlayerIndex].z)
		timer(4000, "RemoveObject", ID)
	end
end

function OnVehicleExit(PlayerIndex)--		If player leaves the armor room vehicle (confirms armor selection) then vehicles are destroyed and 
	--										actual CHOSEN_BIPEDS is changed to wanted armor
	if CHOOSING_ARMOR[PlayerIndex] then
		if(BIPED_VEHICLES[PlayerIndex]~=nil) then
			CHOSEN_BIPEDS[PlayerIndex] = BIPED_NUMBER[BIPED_WANTED[PlayerIndex]]
			if(show_console_messages) then
				ClearConsole(PlayerIndex)
				PlaySound(PlayerIndex, "spawn")
				SaveChoices(PlayerIndex)
			end
		end
		DestroyRoom(PlayerIndex)
	end
end

function OnGameStart()
    game_ended = false
	if lookup_tag("vehi", armor_room_vehicle) ~= 0 then
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
		register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
		register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
		register_callback(cb["EVENT_TICK"],"OnTick")
		register_callback(cb['EVENT_PRESPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamage")
		HAY = {}
		for i=1,16 do
			PREVIEW_SKINS[i] = {}
			DELAY_COUNTER[i] = 1
			PLAYER_INPUT[i] = 0
			BIPED_WANTED[i] = 0
			CUSTOM_KEYS[i] = {}
			CUSTOM_KEYS[i].aa = 60
			CUSTOM_KEYS[i].sprint = 57
			ROOM_VEHICLES = {}
			if(CHOSEN_SKINS[i] == nil) then
				CHOSEN_SKINS[i] = {}
				for key,value in pairs (SKINS) do
					CHOSEN_SKINS[i][key] = #value
				end
			end
		end
		if(choose_armor_on_command == false) then
			unregister_callback(cb['EVENT_COMMAND'])
		end
		timer(5000, "FindHay")
	else
		unregister_callback(cb['EVENT_OBJECT_SPAWN'])
		unregister_callback(cb['EVENT_GAME_END'])
		unregister_callback(cb['EVENT_LEAVE'])
		unregister_callback(cb['EVENT_DIE'])
		unregister_callback(cb['EVENT_VEHICLE_EXIT'])
		unregister_callback(cb["EVENT_TICK"])
		unregister_callback(cb['EVENT_PRESPAWN'])
		unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
		unregister_callback(cb['EVENT_ALIVE'])
	end
end

function OnGameEnd()--						Resets most of the values to prevent issues when the next game starts
    game_ended = true
    CHOSEN_BIPEDS = {}
    BIPED_IDS = {}
	ROOM_VEHICLES = {}
	BIPED_VEHICLES = {}
    DEFAULT_BIPED = nil
	PREVIEW_SKINS = {}
end

function OnCommand(PlayerIndex,Command,Environment,Password)
	
	if Environment == 1 then
		if Command == "i_have_chimera_lol" then
			--say(PlayerIndex, "Chimera detected!")
			set_var(PlayerIndex, "$has_chimera", 1)
			SendCustomKeys(PlayerIndex)
			return false
		elseif Command == "activate_aa" then
			execute_command("lua_call aa CustomKey ".. PlayerIndex)
			return false
		elseif Command == "start_sprinting" then
			execute_command("lua_call sprinting CheckSprint "..PlayerIndex.." start")
			return false
		elseif Command == "stop_sprinting" then
			execute_command("lua_call sprinting CheckSprint "..PlayerIndex.." stop")
			return false
		else
			MESSAGE = {}
			for word in string.gmatch(Command, "([^".."~".."]+)") do 
				table.insert(MESSAGE, word)
			end
			
			if MESSAGE[1] == "key" then
				GetCustomKeys(PlayerIndex, tonumber(MESSAGE[2]))
				return false
			end
			
			if MESSAGE[1] == "emote" then
				EmoteHotkey(PlayerIndex, tonumber(MESSAGE[2]))
				return false
			end
			
			if MESSAGE[1] == "voice" and MESSAGE[2] ~= nil then
				local player_info = get_player(PlayerIndex)
				local player_name = read_wide_string(player_info + 0x4, 12)
				for j=1,16 do
					if player_present(j) and get_var(j, "$has_chimera")=="1" and (player_alive(j)==false or DistanceBetweenPlayers(PlayerIndex,j)<19) then
						rprint(j, "voice~"..player_name.."~"..MESSAGE[2])
					end
				end
				
				VoiceLineToChat(PlayerIndex, player_name, MESSAGE[2])
				return false
			end
		end
    end
	
	Command = string.lower(Command)
	if choose_armor_on_command then --	Command that players will need to enter in order to choose armor the next time they spawn
		if(Command == switch_command or Command == alt_switch_command or Command == alt_switch_command_2) then
			if BLACKLISTED_GAMETYPES[string.lower(get_var(0, "$mode"))] == nil then
				if CHOOSING_ARMOR[PlayerIndex] == false then
					if(FLOOD_GAMETYPES[string.lower(get_var(0, "$mode"))] ~= nil and get_var(PlayerIndex, "$team") == "blue") then
						say(PlayerIndex, "You can't change your armor when you're a zombie!")
						return false
					end
					if(choose_armor_after_time and player_alive(PlayerIndex) and WANTS_TO_SWITCH[PlayerIndex] ~= 3) then
						say(PlayerIndex, switch_time_message)
						WANTS_TO_SWITCH[PlayerIndex] = 3
						timer(switch_time*1000, "KillPlayer", PlayerIndex)
						return false
					else
						say(PlayerIndex, command_success)
						WANTS_TO_SWITCH[PlayerIndex] = 2
						return false
					end
				else
					say(PlayerIndex, command_fail)
					return false
				end
			else
				say(PlayerIndex, "You are not allowed to switch armor on this gametype")
				return false
			end
		end
	end
	
	if Command == "nav" and player_alive(PlayerIndex) then
		local hit, x, y, z = GetPlayerAimLocation(PlayerIndex)
		local player_team = get_var(PlayerIndex, "$team")
		local player_team_real = 0
		if get_dynamic_player(PlayerIndex) ~= 0 then
			 player_team_real = read_word(get_dynamic_player(PlayerIndex) + 0xB8)
		end
		if x ~= 0 then
			for i=1,16 do
				if get_var(i, "$has_chimera") == "1" and player_team == get_var(i, "$team") then
					rprint(i, "nav~default_red~"..x.."~"..y.."~"..z+0.5 .."~"..player_team_real)
				end
			end
			say(PlayerIndex, "Navpoint set for "..player_team.." team with index "..player_team_real)
		else
			say(PlayerIndex, "Couldn't set navpoint")
		end
		return false
	elseif Command == "remove_nav" then
		local player_team = get_var(PlayerIndex, "$team")
		for i=1,16 do
			if get_var(i, "$has_chimera") == "1" and player_team == get_var(i, "$team") then
				rprint(i, "remove_nav")
			end
		end
		return false
	elseif Command == "check_chimera" then
		local everyone_has_chimera = true
		local no_chimera_players = {}
		for i=1,16 do
			if player_present(i) and get_var(i, "$has_chimera") == "0" then
				no_chimera_players[i] = get_var(i, "$name").."\n"
				everyone_has_chimera = false
			end
		end
		if everyone_has_chimera then
			rprint(PlayerIndex, "Everyone has chimera!")
		else
			rprint(PlayerIndex, "The following players don't have chimera:")
			for id,name in pairs (no_chimera_players) do
				rprint(PlayerIndex, name)
			end
		end
		return false
	elseif Command == "set_keys" or Command == "keys" then
		if get_var(PlayerIndex, "$has_chimera") == "1" then
			CUSTOM_KEYS[PlayerIndex] = {}
			rprint(PlayerIndex, "choose_keys")
			PlaySound(PlayerIndex, "b_button")
		else
			say(PlayerIndex, "You must have Chimera for this command to work!")
		end
		return false
	elseif Command == "taunts" or Command == "emotes" then
		if emotes_enabled then
			local message = "Available emotes: "
			for key,value in pairs (EMOTE_TIMERS) do
				message = message.."/"..key.." "
			end
			say(PlayerIndex, message)
		else
			say(PlayerIndex, "Emotes are currently disabled.")
		end
		return false
	else
		for key,value in pairs (EMOTE_TIMERS) do
			if Command == key then
				if emotes_enabled then
					SpawnEmote(PlayerIndex, key)
				else
					say(PlayerIndex, "Emotes are currently disabled.")
				end
				return false
			end
		end
	
	end
	
	return true
end

function GetCustomKeys(i, key)
	if CUSTOM_KEYS[i].sprint == nil and CHOOSING_ARMOR[i] == false then
		if key == nil then
			ClearConsole(i)
			if CUSTOM_KEYS[i].aa == nil then
				rprint(i, "|cPress a key for armor ability")
			else
				rprint(i, "|cPress a key for sprint")
			end
			rprint(i, "|cPress ESC to reset defaults")
		else
			if KEYBOARD_KEYS[key] ~= nil then
				if CUSTOM_KEYS[i].aa == nil then
					say(i, "Armor ability key set to "..KEYBOARD_KEYS[key])
					CUSTOM_KEYS[i].aa = key
					CUSTOM_KEYS[i].sprint = 57
					timer(500, "ResetInput", i)
					PlaySound(i, "a_button")
				elseif CUSTOM_KEYS[i].aa ~= key then
					ClearConsole(i)
					say(i, "Sprint key set to "..KEYBOARD_KEYS[key])
					CUSTOM_KEYS[i].sprint = key
					SendCustomKeys(i)
					SaveChoices(i)
					PlaySound(i, "advance")
				else
					say(i, "A key is already set to "..KEYBOARD_KEYS[key])
					rprint(i, "choose_keys")
					PlaySound(i, "Error")
				end
			elseif key == 0 then
				say(i, "Defaults set!")
				CUSTOM_KEYS[i].aa = 64
				CUSTOM_KEYS[i].sprint = 57
				SendCustomKeys(i)
			else
				say(i, "Invalid key, enter a different one! (key ID "..key..")")
				rprint(i, "choose_keys")
				PlaySound(i, "Error")
			end
		end
	end
end

function ResetInput(i)
	CUSTOM_KEYS[tonumber(i)].sprint = nil
	rprint(i, "choose_keys")
end

function SendCustomKeys(i)
	if get_var(i, "$has_chimera") == "1" and CUSTOM_KEYS[i].aa ~= nil and CUSTOM_KEYS[i].sprint ~= nil then
		local emotes = 0
		local voice = 0
		if emotes_enabled then emotes = 1 end
		if voice_enabled then voice = 1 end
		rprint(i, "custom_keys~"..CUSTOM_KEYS[i].aa.."~"..CUSTOM_KEYS[i].sprint.."~"..emotes.."~"..voice)
		execute_command("lua_call aa AddCustomKey ".. i .. " "..KEYBOARD_KEYS[CUSTOM_KEYS[i].aa])
		execute_command("lua_call sprinting AddCustomKey ".. i .. " "..KEYBOARD_KEYS[CUSTOM_KEYS[i].sprint])
	end
end

function VoiceLineToChat(i, name, message)
	if voice_lines_to_chat == false or get_var(0, "$ffa")=="1" or name == nil then return end
	
	message = string.gsub(message, "female_", "")
	message = string.gsub(message, "male_", "")
	
	if CHAT_MESSAGES[message] ~= nil then
		for j=1,16 do
			if get_var(j, "$team") == get_var(i, "$team") then
				say(j, "["..name.."]: "..CHAT_MESSAGES[message])
			end
		end
	end
end

function AFKEmote(i)
	if afk_emote == false then return end
	
	local player = get_dynamic_player(i)
	if player ~= 0 then 
		local name = GetName(player)
		local shooting = read_float(player + 0x490)
		local action = read_bit(player + 0x208, 6)
		local stationary = read_bit(player + 0x10, 5)
		local vehicle = get_object_memory(read_dword(player + 0x11C))
		local x_vel = read_float(player + 0x68)
		if stationary == 0 or shooting ~= 0 or vehicle ~= 0 or math.abs(x_vel) > 0.01 or action ~= 0 or name == flood_biped then
			AFK[i].timer = 0
		else
			AFK[i].timer = AFK[i].timer + 1
		end
	end
	
	if AFK[i].timer > afk_emote_timer then
		if AFK[i].weapon == nil and POSITIONS[i] ~= nil and player ~= 0 then
			local third_weapon = read_dword(player + 0x300)
			if third_weapon == 0xFFFFFFFF then
				execute_command("block_all_objects "..i.." 1")
				AFK[i].weapon = spawn_object("weap", "altis\\weapons\\newspaper\\newspaper", POSITIONS[i].x, POSITIONS[i].y, POSITIONS[i].z)
				assign_weapon(AFK[i].weapon, i)
			end
		elseif player == 0 and AFK[i].weapon ~= nil then
			execute_command("block_all_objects "..i.." 0")
			RemoveObject(AFK[i].weapon)
			AFK[i].weapon = nil
		end
	elseif AFK[i].weapon ~= nil then
		execute_command("block_all_objects "..i.." 0")
		RemoveObject(AFK[i].weapon)
		AFK[i].weapon = nil
	end
end

function EmoteStuff(i)
	if emotes_enabled == false then return end
	
	local player = get_dynamic_player(i)
	
	if EMOTES.timers[i] == nil then
		EMOTES.timers[i] = 0
		EMOTES.delay[i] = 0
		EMOTES.active[i] = 0
	end
	
	if EMOTES.delay[i] > 0 then
		EMOTES.delay[i] = EMOTES.delay[i] - 1
	end
	
	if EMOTES.timers[i] > 99999 - 113 then
		EMOTES.timers[i] = EMOTES.timers[i] - 1
		--rprint(1, EMOTES.timers[i] - 99999 - 111)
		goto skip_emote
	end
	
	if EMOTES.timers[i] > 0 and EMOTES.vehicles[i] ~= nil then
		EMOTES.timers[i] = EMOTES.timers[i] - 1
		if player ~= 0 then
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			if vehicle ~= 0 then
				EMOTES.active[i] = 1
				--write_bit(vehicle + 0x10, 24, 1)
				--write_vector3d(vehicle + 0x8C, 0, 0, 0)
				
				EMOTES.delay[i] = emote_delay_time
				local x_vel, y_vel, z_vel = read_vector3d(vehicle + 0x68)
				local x_rot_vel, y_rot_vel, z_rot_vel = read_vector3d(vehicle + 0x8C)
				local unit_forward, unit_left, shooting = read_float(player + 0x278), read_float(player + 0x27C), read_float(player + 0x490)
				if x_vel+y_vel+z_vel ~= 0 or x_rot_vel+y_rot_vel+z_rot_vel ~= 0 or unit_forward ~= 0 or unit_left ~= 0 or shooting ~= 0 then
					exit_vehicle(i)
					--say_all("exiting emote because of input")
					EMOTES.timers[i] = 0
				end
			else
				--say_all("player is not in a vehicle")
				EMOTES.timers[i] = 0
			end
		else
			--say_all("exiting emote because driver died")
			EMOTES.timers[i] = 0
		end
	elseif EMOTES.vehicles[i] ~= nil then
		if EMOTES.active[i] == 1 then
			EMOTES.active[i] = 2
			exit_vehicle(i)
		end
	end
	
	::skip_emote::
	
	if EMOTES.vehicles[i] ~= nil then
		local vehicle = get_object_memory(EMOTES.vehicles[i])
		if vehicle ~= 0 then
			local driver = read_dword(vehicle + 0x324)
			if driver == 0xFFFFFFFF then
				if EMOTES.active[i] > 0 then
					--say_all("Removing emote...")
					timer(200, "RemoveObject", EMOTES.vehicles[i])
				end
				EMOTES.active[i] = 0
				EMOTES.timers[i] = 0
				EMOTES.vehicles[i] = nil
			end
		else
			EMOTES.vehicles[i] = nil
		end
	end
end

function EmoteHotkey(i, emote_id)
	if emotes_enabled == false then return end
	for key,value in pairs (EMOTE_TIMERS) do
		if value[2] == emote_id then
			SpawnEmote(i, key)
		end
	end
end

function SpawnEmote(i, type)
	if FLOOD_GAMETYPES[string.lower(get_var(0, "$mode"))] ~= nil then
		say(i, "You can't emote on this gametype.")
		return
	end
	
	local player = get_dynamic_player(i)
	
	if player == 0 then
		say(i, "You must be alive to use an emote.")
		return
	end
	
	if EMOTES.timers[i] ~= 0 then
		say(i, "You are already using an emote.")
		return
	end
	
	if EMOTES.delay[i] ~= 0 then
		say(i, "You must to wait "..math.ceil(EMOTES.delay[i]/30) .." seconds to use an emote again!")
		return
	end
	
	if EMOTES.vehicles[i] ~= nil then
		say(i, "You are already using an emote.")
		return
	end
	
	local airborne = read_bit(player + 0x4CC, 0)
	local x_vel,y_vel,z_vel = read_vector3d(player + 0x68)
	if math.abs(x_vel) > 0.01 or math.abs(z_vel) > 0.01 or airborne == 1 then
		say(i, "You can't emote while moving.")
		return
	end
	
	if type == "sit" then
		local touched_obj = get_object_memory(read_dword(player + 0x4FC))
		if touched_obj ~= 0 then
			local time_since_touch = read_char(player + 0x500)
			local touched_obj_type = read_word(touched_obj + 0xB4)
			if (touched_obj_type == 1 or touched_obj_type == 0) and time_since_touch < 0 then
				say(i, "Can't sit here.")
				return
			end
		end
	end
	
	local vehicle = get_object_memory(read_dword(player + 0x11C))
	local unit = read_byte(player + 0x2A0)
	if vehicle == 0 and unit == 4 and GetName(player) ~= flood_biped then
		local x,y,z = read_vector3d(player + 0x5C)
		local yaw = read_float(player + 0x224)
		local pitch = read_float(player + 0x228)
		execute_command("m "..i.." 0 0 0.20") -- fixes an issue where player is stuck in the ground
		ID = spawn_object("vehi", "taunts\\"..type, x, y, z, GetYaw(yaw, pitch))
		timer(33, "EnterEmote", i, ID, type)
	else
		say(i, "You can't use an emote now!")
	end
end

function EnterEmote(i, ID, type)
	i=tonumber(i)
	ID=tonumber(ID)
	if get_object_memory(ID) ~= 0 then
		EMOTES.vehicles[i] = ID
		enter_vehicle(EMOTES.vehicles[i], i, 0)
		EMOTES.active[i] = 1
		EMOTES.timers[i] = EMOTE_TIMERS[type][1]
	else
		say_all("Emote object doesn't exist!")
	end
end

function EnterVehicle(ID, i)
	ID = tonumber(ID)
	i = tonumber(i)
	if get_object_memory(ID) ~= 0 then
		enter_vehicle(ID, i, 0)
	end
end

function Boundaries()
	if force_players_to_stay_in_map then
		for i=1,16 do
			local player = get_dynamic_player(i)
			if player ~= 0 and read_dword(player + 0x11C) == 0xFFFFFFFF then
				local x,y,z = read_vector3d(player + 0x5C)
				
				if x < map_boundary_x_min then
					write_vector3d(player + 0x5C, x+boundary_move_player_amount,y,z+1)
				elseif x > map_boundary_x_max then
					write_vector3d(player + 0x5C, x-boundary_move_player_amount,y,z+1)
				end
				
				if y < map_boundary_y_min then
					write_vector3d(player + 0x5C, x,y+boundary_move_player_amount,z+1)
				elseif y > map_boundary_y_max then
					write_vector3d(player + 0x5C, x,y-boundary_move_player_amount,z+1)
				end
			end
		end
	end
end

function KillPlayer(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	if player_present(PlayerIndex) and player_alive(PlayerIndex) and WANTS_TO_SWITCH[PlayerIndex] == 3 then
		RemoveWeapons(PlayerIndex)
		timer(room_delay_command, "SpawnRoom", PlayerIndex)
		WANTS_TO_SWITCH[PlayerIndex] = 0
		say_all(get_var(PlayerIndex, "$name").." is switching their armor. Type /"..switch_command.." to switch yours")
		PlaySound(PlayerIndex, "advance")
	end
end

function RespawnPlayerInstantly(PlayerIndex)
	if(player_present(PlayerIndex)) then
		local player = get_player(PlayerIndex)
		write_dword(player + 0x2C, 0)
	end
end

function OnDamage(i, causer, meta_id, dmg, mat, backtap)
	causer = tonumber(causer)
	if(WANTS_TO_SWITCH[i] == 3) then
		say(i, switch_time_fail_message)
		WANTS_TO_SWITCH[i] = 2
	end
	
	if assasinations_enabled and backtap == 1 and get_var(i, "$team") ~= get_var(causer, "$team")then
		local player = get_dynamic_player(i)
		if player ~= 0 and read_bit(player + 0x4CC, 0) == 0 and GetName(player) ~= flood_biped then
			local x, y, z = read_vector3d(player + 0x5C)
			local yaw = read_float(player + 0x224)
			local pitch = read_float(player + 0x228)
			ID = spawn_object("vehi", "taunts\\assasination", x, y, z, GetYaw(yaw, pitch))
			timer(33, "EnterAss", ID, i, causer)
			return false
		end
	end
end

function EnterAss(ID, i, causer)
	ID = tonumber(ID)
	i = tonumber(i)
	causer = tonumber(causer)
	if get_object_memory(ID) ~= 0 then
		local player = get_dynamic_player(i)
		local player2 = get_dynamic_player(causer)
		if player ~= 0 and player2 ~= 0 then
			enter_vehicle(ID, i, 0)
			enter_vehicle(ID, causer, 1)
		end
	end
	
	timer(100/3*76, "ExitAss", ID, i, causer)
	timer(100/3*55, "DamagePlayer", 1000, i, causer)
	return false
end

function ExitAss(ID, i, causer)
	ID = tonumber(ID)
	i = tonumber(i)
	causer = tonumber(causer)
	if get_object_memory(ID) ~= 0 then
		exit_vehicle(causer)
		timer(200, "RemoveObject", ID)
	end
end

function DamagePlayer(dmg, i, causer)
	dmg = tonumber(dmg)
	i = tonumber(i)
	causer = tonumber(causer)
	if player_alive(i) then
		damage_player(dmg, i, causer)
	end
end

function FindBipedTag(TagName)
    local tag_array = read_dword(0x40440000)
    for i=0,read_word(0x4044000C)-1 do
        local tag = tag_array + i * 0x20
        if(read_dword(tag) == 1651077220 and read_string(read_dword(tag + 0x10)) == TagName) then
            return read_dword(tag + 0xC)
        end
    end
end

function OnPlayerSpawn(PlayerIndex)-- Used to detect when player has spawned and if he wants to switch armor
	if(FLOOD_GAMETYPES[string.lower(get_var(0, "$mode"))] ~= nil and get_var(PlayerIndex, "$team") == "blue") then
		execute_command("nades " .. PlayerIndex .. " 0 0")
		return true
	end
	
	-- on snipers only gt, armors that should spawn with odst pistol spawn with no secondary weapon. this will fix that
	local gametype_weapons = read_byte(0x5F5478 + 0x5C)
	if gametype_weapons == 4 then
		local player = get_dynamic_player(PlayerIndex)
		if player ~= 0 then
			if read_dword(player + 0x2FC) == 0xFFFFFFFF then
				local pistol_id = spawn_object("weap", "reach\\objects\\weapons\\pistol\\magnum\\magnum", x, y, z)
				if assign_weapon(pistol_id, PlayerIndex) == false then
					say_all("Error assigning weapon!")
				end
			end
		end
	end
	
	timer(33, "ChangeSkin", PlayerIndex)
	DELAY_COUNTER[PlayerIndex] = 1
	if(WANTS_TO_SWITCH[PlayerIndex] == 3) then
		WANTS_TO_SWITCH[PlayerIndex] = 1
	end
	if(WANTS_TO_SWITCH[PlayerIndex] == 1) then
		RemoveWeapons(PlayerIndex)
		timer(room_delay_command, "SpawnRoom", PlayerIndex)
		WANTS_TO_SWITCH[PlayerIndex] = 0
		return true
	end
	if(WANTS_TO_SWITCH[PlayerIndex] == 2) then
		RemoveWeapons(PlayerIndex)
		timer(room_delay_player_join, "SpawnRoom", PlayerIndex)
		WANTS_TO_SWITCH[PlayerIndex] = 0
	end
end

function ChangeSkin(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	if player_present(PlayerIndex) then
		timer(100, "ChooseVisor", PlayerIndex, 0)
		local player = get_dynamic_player(PlayerIndex)
		if player ~= 0 then
			for i = 0,1 do
				local currentWeapon = read_dword(player + 0x2F8 + i*0x4)
				ChangeSkinOfWeapon(currentWeapon, PlayerIndex)
			end
		end
	end
end

function ChangeSkinOfWeapon(currentWeapon, PlayerIndex)
	local WeaponObj = get_object_memory(currentWeapon)
	if(WeaponObj ~= 0) then
		local name = read_string(read_dword(read_word(WeaponObj) * 32 + 0x40440038))
		for key,value in pairs (SKINS) do
			if(value["weapon"] == name or value["weapon"].."_preview" == name) then
				local ammo_required = CHOSEN_SKINS[PlayerIndex][key]
				local current_ammo = read_word(WeaponObj + 0x2C4)
				
				if(current_ammo ~= ammo_required and ammo_required ~= nil) then
					write_word(WeaponObj + 0x2C4, ammo_required)	
					sync_ammo(currentWeapon, 1)
				end
			end
		end
	end
end

function FindHay()
	local object_table = read_dword(read_dword(object_table_ptr + 2))
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
		local object = get_object_memory(ID)
		if object ~= 0 and read_word(object + 0xB4) == 1 then
			local name = GetName(object)
			if name == "altis\\scenery\\hay\\hay" then
				HAY[ID] = 1
			end
		end
	end
end

function Forklift()
	for ID,TYPE in pairs (HAY) do
		local object = get_object_memory(ID)
		if object ~= 0 then
			write_word(object + 0x5AC, 65535)
		else
			HAY[ID] = nil
		end
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
					local player_id = read_dword(stats_globals + to_real_index(i)*48 + 0x4)
					write_dword(fork_object + 0xC0, player_id)
					write_dword(fork_object + 0xC4, read_dword(get_player(i) + 0x34))
					write_bit(fork_object + 0x10, 5, 0)
					
					write_float(fork_object + 0x5C, read_float(vehicle + 0x5C0 + 0x34 * 6 + 0x28) + read_float(vehicle + 0x68))
					write_float(fork_object + 0x60, read_float(vehicle + 0x5C0 + 0x34 * 6 + 0x2C) + read_float(vehicle + 0x6C))
					write_float(fork_object + 0x64, read_float(vehicle + 0x5C0 + 0x34 * 6 + 0x30) + read_float(vehicle + 0x70))
					
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
				end
			end
		end
		
		if has_fork == false then
			if FORKS[i] ~= nil then
				if get_object_memory(FORKS[i]) ~= 0 then
					destroy_object(FORKS[i])
				end
				FORKS[i] = nil
			end
		end
	end
end

function VehicleMelee()
	if vehicle_melee_enable == false then return end
	
	for i=1,16 do
		local player = get_dynamic_player(i)
		if player ~= 0 then
			local melee = read_byte(player + 0x505)
			if MELEE_TIMERS[i]==0 and melee~=0 then
				local hit, x, y, z, target_id = GetPlayerAimLocation(i)
				if target_id ~= nil and target_id ~= 0xFFFFFFFF then
					local object = get_object_memory(target_id)
					if object ~= 0 and read_dword(object + 0x11C) ~= 0xFFFFFFFF then
						for j=1,16 do
							local m_player = get_player(j)
							if i~=j and m_player~=0 and read_dword(m_player+0x34)==target_id and get_var(i,"$team")~=get_var(j,"$team") then
								local x,y,z = read_vector3d(player + 0x5C)
								local x2,y2,z2 = read_vector3d(object + 0x550 + 0x28)
								local distance = DistanceFormula(x, y, z, x2,y2,z2)
								if distance < 1 then
									damage_player(50, j, i)
								end
							end
						end
					end
				end
			end
			MELEE_TIMERS[i] = melee
		end
	end
end

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)--			nerd shit (this changes player's biped when it spawns)
    if(player_present(PlayerIndex) == false) then return true end
    if(DEFAULT_BIPED == nil) then
        local tag_array = read_dword(0x40440000)
        for i=0,read_word(0x4044000C)-1 do
            local tag = tag_array + i * 0x20
            if(read_dword(tag) == 1835103335 and read_string(read_dword(tag + 0x10)) == "globals\\globals") then
                local tag_data = read_dword(tag + 0x14)
                local mp_info = read_dword(tag_data + 0x164 + 4)
                for j=0,read_dword(tag_data + 0x164)-1 do
                    DEFAULT_BIPED = read_dword(mp_info + j * 160 + 0x10 + 0xC)
                end
            end
        end
    end
	if(FLOOD_GAMETYPES[string.lower(get_var(0, "$mode"))] ~= nil and get_var(PlayerIndex, "$team") == "blue") then
		return true, FindBipedTag(flood_biped)
	end
	
    if(MapID == DEFAULT_BIPED and CHOSEN_BIPEDS[PlayerIndex]) then
        for key,value in pairs(BIPEDS) do
            if(BIPED_IDS[key] == nil) then
                BIPED_IDS[key] = FindBipedTag(BIPEDS[key])
            end
        end
        return true,BIPED_IDS[CHOSEN_BIPEDS[PlayerIndex]]
    end
    return true
end

function GetPlayerAimLocation(i)--	Finds coordinates at which player is looking (from giraffe)
	local player = get_dynamic_player(i)
	if player ~= 0 then
		local px, py, pz = read_vector3d(player + 0x5c)
		local vehicle = read_dword(player + 0x11C)
		if vehicle ~= 0xFFFFFFFF then
			local vehicle = get_object_memory(vehicle)
			if vehicle ~= 0 then
				px, py, pz = read_vector3d(vehicle + 0x5c)
			end
		end
		local vx, vy, vz = read_vector3d(player + 0x230)
		local cs = read_float(player + 0x50C)
		local h = 0.62 - (cs * (0.62 - 0.35))
		pz = pz + h
		--local hit, x, y , z = intersect(px, py, pz, 10000*vx, 10000*vy, 10000*vz, read_dword(get_player(i) + 0x34))
		--local distance = math.sqrt(((x-px)*(x-px)) + ((y-py)*(y-py)) + ((z-pz)*(z-pz)) ) - 0.1
		--return intersect(px, py, pz, distance*vx, distance*vy, distance*vz, read_dword(get_player(i) + 0x34))
		return intersect(px, py, pz, vx*1000, vy*1000, vz*1000, read_dword(get_player(i) + 0x34))
	else
		return 0, 0, 0
	end
end

function GetName(DynamicObject)--	Gets directory of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
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

function CheckChimera(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	if player_present(PlayerIndex) and get_var(PlayerIndex, "$has_chimera") ~= "1" and game_ended == false then
		say(PlayerIndex, "You don't have Chimera installed")
		say(PlayerIndex, "Get Chimera -572 for extra features!")
		rprint(PlayerIndex, "|ndo_you_have_chimera?")
	end
end

function GetYaw(yaw, pitch)
    local cos_b = math.acos(pitch)
    
    local finalAngle = cos_b
    
    if(yaw < 0) then finalAngle = finalAngle * -1 end
 
    finalAngle = finalAngle - math.pi / 2
 
    if(finalAngle < 0) then finalAngle = finalAngle + math.pi * 2 end
 
    return  (math.pi*2) - finalAngle
end

function DistanceBetweenPlayers(i,j)
	local player = get_dynamic_player(i)
	local player2 = get_dynamic_player(j)
	if player ~= nil and player2 ~= nil then
		local x,y,z = read_vector3d(player + 0x550 + 0x28)
		local x2,y2,z2 = read_vector3d(player2 + 0x550 + 0x28)
		return DistanceFormula(x,y,z, x2,y2,z2)
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

function OnScriptUnload()--		Destroys armor and biped vehicles when script is unloaded to prevent duplicates and players staying inside the script room
	for i=1, 16 do
		rprint(i, "|nbgreload")
		
		if(PREVIEW_SKINS[i] ~= nil) then
			if(PREVIEW_SKINS[i].primary ~= nil) then
				RemoveObject(PREVIEW_SKINS[i].primary)
			end
			if(PREVIEW_SKINS[i].secondary ~= nil) then
				RemoveObject(PREVIEW_SKINS[i].secondary)
			end
		end
		if(BIPED_VEHICLES[i]~=nil) then
			RemoveObject(BIPED_VEHICLES[i])
		end
		if(ROOM_VEHICLES[i]~=nil) then
			RemoveObject(ROOM_VEHICLES[i])
		end
		
		if AFK[i].weapon ~= nil then
			RemoveObject(AFK[i].weapon)
		end
		
		if emotes_enabled and EMOTES ~= nil and EMOTES.vehicles ~= nil then
			RemoveObject(EMOTES.vehicles[i])
		end
		
		if FORKS[i] ~= nil then
			RemoveObject(FORKS[i])
		end
	end
 end
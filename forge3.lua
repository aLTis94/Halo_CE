local DEBUG = false
----------------------------------------------------------------------------
--------------------------		SAPP FORGE		----------------------------
----------------------------------------------------------------------------
------------ LUA Script by Girrafe								------------
------------ Modifications by Kirby_422							------------
----------------------------------------------------------------------------
------------ Version: 		0.8.0								------------
------------ Last Modified:	April 7th 2016						------------
----------------------------------------------------------------------------
--------------------------	COMMANDS:			----------------------------
------------ /forge refresh										------------
------------ /forge spawn <object>								------------
------------ /forge place [<name>]								------------
------------ /forge pickup										------------
------------ /forge cancel										------------
------------ /forge rot[ate] <yaw> [<pitch>] [<roll>]			------------
------------ /forge yaw <yaw>									------------
------------ /forge pitch <pitch>								------------
------------ /forge roll <roll>									------------
------------ /forge push <distance>								------------
------------ /forge raise <distance>							------------
------------ /forge undo										------------
------------ /forge remove <name>								------------
------------ /forge help										------------
------------ /forge remove_nearest								------------
------------ /forge save <filename> [<IP:Port>]					------------
------------ /forge load <filename> [<IP:Port>]					------------
------------ /forge list saves [<IP:Port>]						------------
------------	-- ~ Server Console only ~	--					------------
------------ /forge permission ban name <name or playerNum>		------------
------------ /forge permission ban ip <ip or playerNum>			------------
------------ /forge permission unban name <name or playerNum>	------------
------------ /forge permission unban ip <ip or playerNum>		------------
------------ /forge permission auth name <name or playerNum>	------------
------------ /forge permission auth ip <ip or playerNum>		------------
------------ /forge permission unauth name <name or playerNum>	------------
------------ /forge permission unauth ip <ip or playerNum>		------------
------------ /forge actionlevel quit [<level>]					------------
------------ /forge actionlevel ban [<level>]					------------
------------ /forge actionlevel game end [<level>]				------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
--------------------------	Changelog:			----------------------------
----------------------------------------------------------------------------
--------	Date UNKNOWN	Girrafe
-- Made entire LUA script
-- Added z-offset variable to FORGE_OBJECTS.
-- Added /refresh and /undo commands.
-- Added forge command to unload loaded saves:
--	/forge unload <name>
--------
--------	Aug 17 2015	Kirby_422
-- Added /pickup
-- Added /remove_nearest
-- Added variables TELEPORTER_PAIRS, TELEPORTER_PAIRS_INCOMPLETE, PLAYER_LAST_TELEPORTER_USED, PLAYER_FORGE_OBJECT_NEXT_PAIR
-- Added function test_teleportation, teleport, cancel_place_teleporter, change_teleporters_incomplete
-- Updated function clear
--------
--------	Aug 18 2015	Kirby_422
-- Seperated similar code unto functions; ie get_obj_location
-- Cleaned up code and indentation
-- Updated save/load to save teleporters
-- Updated pickup to include LOADED_FORGE_OBJECTS
--------
--------	Aug 20 2015	Kirby_422
-- Seperated a great deal of code from OnCommand for reuse purposes
-- Added /forge help
-- Added /forge list saves
--------
--------	Aug 22 2015	Kirby_422
-- Cleaned up help and list saves, and set them up as RCON responses rather than server messages.
-- Allowed the server to save/load games
--------
--------	Oct 25 2015	Kirby_422
-- Moved almost all code to seperate functions rather than in the onCommand dialog.
-- Setup /forge <command> for all commands, rather than /<command>
-- Setup server permissions; banned players, authorized players, and the permission levels that decides who can use forge (server only, auth only, non-banned, anyone including banned)
-- Setup responses to game end, being banned, disconnecting; can autosave all structures, delete them, transfer ownership to the server (127.0.0.1), etc.
-- 		If autosaved as server on game end, reload automatically next round.
-- Autoload forge file available.
--------
--------	April 24 2016 aLTis
-- forge will now work if the script was loaded while the game is running
-- added all objects to the menu
----------------------------------------------------------------------------
----------------------------------------------------------------------------


-- ["FORGE_NAME"] = { "tag_name", distance-from-player-in-world-units, z-offset }
FORGE_OBJECTS = {
	["arch_brace"] = { "arch_brace", 6, 1 },
	["arena_window"] = { "arena_window", 13, 2 },
	["base_round"] = { "base_round", 13, 1 },
	["brace"] = { "brace", 4, 1 },
	["bridge_diag"] = { "bridge_diag", 8, 0.3 },
	["bridge2x2"] = { "bridge2x2", 4, 0.3 },
	["bunker"] = { "bunker", 5, 0.5 },
	["bunker_stair"] = { "bunker_stair", 8, 2 },
	["c_shield"] = { "c_shield", 4, 0.5 },
	["cylinder_big"] = { "cylinder_big", 10, 3 },
	["cylinder_small"] = { "cylinder_small", 8, 3 },
	["column"] = { "column", 3, 0.3 },
	["crenel_full"] = { "crenel_full", 4, 0.3 },
	["dish"] = { "dish", 10, 0.5 },
	["dish_door"] = { "dish_door", 10, 0.5 },
	["dish_antenna"] = { "dish_antenna", 8, 0.5 },
	["door"] = { "door", 4, 1 },
	["ladder"] = { "ladder", 4, 1 },
	["plate_y"] = { "plate_y", 4, 0.3 },
	["plate_y_large"] = { "plate_y_large", 6, 0.3 },
	["plate2x2_45"] = { "plate2x2_45", 4, 0.3 },
	["plate3x4"] = { "plate3x4", 6, 0.3 },
	["plate4x6"] = { "plate4x6", 8, 0.3 },
	["plate5x5"] = { "plate5x5", 8, 0.3 },
	["railing1"] = { "railing1", 4, 0.3 },
	["ramp_circle_small"] = { "ramp_circle_small", 6, 1 },
	["ramp_enclosed"] = { "ramp_enclosed", 6, 1.5 },
	["ramp_plate"] = { "ramp_plate", 6, 1 },
	["ramp4"] = { "ramp4", 6, 1 },
	["rock_arch"] = { "rock_arch", 8, 2 },
	["rock_flat"] = { "rock_flat", 8, 1 },
	["rock_med_a"] = { "rock_med_a", 8, 1 },
	["rock_med_b"] = { "rock_med_b", 8, 1 },
	["rock_sea_stack"] = { "rock_sea_stack", 10, 2 },
	["rock_small"] = { "rock_small", 4, 0.3 },
	["rock_spire_a"] = { "rock_spire_a", 8, 1 },
	["rock_spire_b"] = { "rock_spire_b", 8, 1 },
	["staircase"] = { "staircase", 8, 1 },
	["stunt_ramp"] = { "stunt_ramp", 6, 0.5 },
	["teleporter_receiver"] = { "teleporter_receiver", 3, 0.3 },
	["teleporter_sender"] = { "teleporter_sender", 3, 0.3 },
	["tent"] = { "tent", 6, 1 },
	["tower"] = { "tower", 8, 2 },
	["tower_tall"] = { "tower_tall", 8, 3 },
	["tree_large"] = { "tree_large", 6, 1 },
	["tree_small"] = { "tree_small", 4, 1 },
	
	--["spawnpoint"] = { "spawnpoint", 2, 1 },
	--["spawnpoint_red"] = { "spawnpoint", 2, 1 },
	["warthog"] = {"warthog", 4, 1},
	["ghost"] = {"ghost", 4, 1},
}
FORGE_OBJECT_SPAWN_OVERRIDE = {
	["warthog"] = "vehicles\\warthog\\mp_warthog",
	["ghost"] = "vehicles\\ghost\\ghost_mp",
}
-- Use lowercase ["key"], only. The ["key"] is what you enter with the /armor command.
-- ["key"] = "tag", (surround with commas)
BIPEDS = {
    ["default"] = "characters\\cyborg_mp\\cyborg_mp",
    ["mexican"] = "characters\\cyborg_mp\\mexican",
    ["monitor"] = "characters\\monitor\\monitor"
}
BIPED_IDS = {}
CHOSEN_BIPEDS = {}
DEFAULT_BIPED = nil
PREVIOUS_DATA = {} -- 0 = location, 1 = rotation, 2 = shield, 3 = health, 4 = ToMonitor [bool]
PLAYER_INPUT_VALUES = {}
PLAYER_KEYMAP = {}
FORGE_MENU = {
	["1"] = {
		["name"]="Construction", 
		["1"]={
			["name"]="Building Blocks",
			["_1"]={"Block 3x4", "plate3x4", "INSERT-DESCRIPTION"},
			["_2"]={"Block 5x5 Flat", "plate5x5", "INSERT-DESCRIPTION"},
		}, 
		["2"]={
			["name"]="Bridges and Platforms",
			["_1"]={"Bridge 2x2", "bridge2x2", "INSERT-DESCRIPTION"},
			["_2"]={"Corner 2x2", "plate2x2_45", "INSERT-DESCRIPTION"},
			["_3"]={"Bridge Diagonal", "bridge_diag", "INSERT-DESCRIPTION"},
			["_4"]={"Dish", "dish", "INSERT-DESCRIPTION"},
			["_5"]={"Dish Open", "dish_door", "INSERT-DESCRIPTION"},
			["_6"]={"Landing Pad", "plate4x6", "INSERT-DESCRIPTION"},
			["_7"]={"Platform XL", "cylinder_small", "INSERT-DESCRIPTION"},
			["_8"]={"Platform XXL", "cylinder_big", "INSERT-DESCRIPTION"},
			["_9"]={"Plate Y", "plate_y", "INSERT-DESCRIPTION"},
			["_10"]={"Plate Y Large", "plate_y_large", "INSERT-DESCRIPTION"},
			["_11"]={"Staircase", "staircase", "INSERT-DESCRIPTION"},
			
		}, 
		["3"]={
			["name"]="Buildings",
			["_1"]={"Bunker", "bunker", "INSERT-DESCRIPTION"},
			["_2"]={"Bunker Round", "base_round", "INSERT-DESCRIPTION"},
			["_3"]={"Bunker Stair", "bunker_stair", "INSERT-DESCRIPTION"},
			["_4"]={"Tower", "tower", "INSERT-DESCRIPTION"},
			["_5"]={"Tower Tall", "tower_tall", "INSERT-DESCRIPTION"},
		}, 
		["4"]={
			["name"]="Decorative",
			["_1"]={"Antenna, Satellite", "dish_antenna", "INSERT-DESCRIPTION"},
			["_2"]={"Brace", "brace", "INSERT-DESCRIPTION"},
			["_3"]={"Brace Tunnel", "arch_brace", "INSERT-DESCRIPTION"},
			["_4"]={"Column", "column", "INSERT-DESCRIPTION"},
			["_5"]={"Cover", "crenel_full", "INSERT-DESCRIPTION"},
			["_6"]={"Covenant Shield", "c_shield", "INSERT-DESCRIPTION"},
			["_7"]={"Railing", "railing1", "INSERT-DESCRIPTION"},
			["_8"]={"Ladder", "ladder", "INSERT-DESCRIPTION"},
			["_9"]={"Tent", "tent", "INSERT-DESCRIPTION"},
		}, 
		["5"]={
			["name"]="Ramps",
			["_1"]={"Small Circular Ramp", "ramp_circle_small", "INSERT-DESCRIPTION"},
			["_2"]={"Enclosed Ramp", "ramp_enclosed", "INSERT-DESCRIPTION"},
			["_3"]={"Plated Ramp", "ramp_plate", "INSERT-DESCRIPTION"},
			["_4"]={"Ramp", "ramp4", "INSERT-DESCRIPTION"},
			["_5"]={"Stunt Ramp", "stunt_ramp", "INSERT-DESCRIPTION"},
		}, 
		["6"]={
			["name"]="Doors and Windows",
			["_1"]={"Door", "door", "INSERT-DESCRIPTION"},
			["_2"]={"Window Coliseum", "arena_window", "INSERT-DESCRIPTION"},
		}, 
	},
	["2"] = {
		["name"]="Nature",
		["1"]={
			["name"]="Rocks",
			["_1"] = {"Rock Arch", "rock_arch","INSERT-DESCRIPTION" },
			["_2"] = {"Flat Rock", "rock_flat","INSERT-DESCRIPTION" },
			["_3"] = {"Medium Rock, TypeA", "rock_med_a", "INSERT-DESCRIPTION" },
			["_4"] = {"Medium Rock, TypeB", "rock_med_b", "INSERT-DESCRIPTION" },
			["_5"] = {"Sea Rock", "rock_sea_stack", "INSERT-DESCRIPTION" },
			["_6"] = {"Small Rock", "rock_small", "INSERT-DESCRIPTION" },
			["_7"] = {"Rock Spire, TypeA", "rock_spire_a", "INSERT-DESCRIPTION" },
			["_8"] = {"Rock Spire, TypeB", "rock_spire_b", "INSERT-DESCRIPTION" },
		},
		["2"]={
			["name"]="Trees",
			["_1"] = {"Small Tree", "tree_small", "INSERT-DESCRIPTION" },
			["_2"] = {"Large Tree", "tree_large", "INSERT-DESCRIPTION" },
		},
	},
	["3"] = {
		["name"]="Vehicles",
		["1"]={
			["name"]="Human",
			["_1"]={"Warthog (Chaingun)","warthog","A 3 seat jeep equiped with a chaingun"},
			["_2"]={"Warthog (Guass)","gwarthog","A 3 seat jeep equiped with a guass cannon"},
			["_3"]={"Warthog (Rocket)","rwarthog","A 3 seat jeep equiped with a rocket launcher"},
			["_4"]={"Scorpion","scorpion_mp","A tank, with six treads, and enough seats for an army"},
			["_5"]={"Sparrow Hawk","sparrow","A swift fighter jet"},
			["_6"]={"Hornet","hornet","A switft fighter jet"},
			["_7"]={"Pelican","pelican","A fleet transport ship"},
			["_8"]={"Mongoose","mongoose","A two man ATV"},
			["_9"]={"Chaingun Turret","laag_turret","A ground-mounted chaingun"},
			["_10"]={"Rocket Turret","rocket_turret","A ground-mounted Rocket Launcher"},
		},
		["2"]={
			["name"]="Covenant",
			["_1"]={"Ghost","ghost","A fast single person hovercraft with twin plasma"},
			["_2"]={"Wraith","wraith_mp","A alien tank, equiped with mortor launcher"},
			["_3"]={"Spectre","spectre","An alien light transport, equiped with a rear mounted plasma launcher"},
			["_4"]={"Shadow","creep","A large alien transport, with automated plasma turrets"},
			["_5"]={"Banshee","banshee_mp","A alien fighter jet, equiped with two types of plasma"},
			["_6"]={"Plasma Turret","cov_turret","A ground-mounted plasma launcher"},
			["_6"]={"Gun Turret","","A Creepy crawly turret"},
		},
	},
	["4"] = {
		["name"]="Weapons",
		["1"]={
			["name"]="Human",
			["_1"]={"Assault Rifle","assault rifle","INSERT-DESCRIPTION"},
			["_2"]={"SMG","smg","a light weight Sub-Machine Gun"},
			["_3"]={"Pistol","pistol","A semi-automatic Magnum"},
			["_4"]={"Battle Rifle","battle_rifle","A burst fire rifle"},
			["_5"]={"Shotgun","shotgun","A semi-automatic shotgun"},
			["_6"]={"Sniper","sniper rifle","A sniper rifle"},
			["_7"]={"Rocket Launcher","rocket launcher","INSERT-DESCRIPTION"},
			["_8"]={"Fragmentation Grenade","frag grenade","A simple grenade, that explodes into shrapenal"},
		},
		["2"]={
			["name"]="Covenant",
			["_1"]={"Plasma Rifle","plasma rifle",""},
			["_2"]={"Brute Plasma Rifle","brute_plasma_rifle",""},
			["_3"]={"Plasma Pistol","plasma pistol",""},
			["_4"]={"Brute Plasma Pistol","brute_plasma_pistol",""},
			["_5"]={"Plasma Repeater","plasma_repeater",""},
			["_6"]={"Needler","needler_mp",""},
			["_7"]={"Carbine","carbine",""},
			["_8"]={"Beam Rifle","beam_rifle",""},
			["_9"]={"Spiker","spiker",""},
			["_10"]={"Mauler","mauler",""},
			["_11"]={"Plasma Grenade","plasma grenade",""},
		},
		["3"]={
			["name"]="Forrunner",
			["_1"]={"Sentinel Beam","sent_beam",""},
			["_2"]={"","",""},
		},
	},
	["5"] = {
		["name"]="Spawn Points",
		["_1"]={"Spawn Point (All Gametypes - RED Team)","$spawn",""},
		["_2"]={"Spawn Point (All Gametypes - BLUE Team)","$spawn",""},
		["_3"]={"Spawn Point (Slayer)","$spawn",""},
		["_4"]={"Spawn Point (KoTH)","$spawn",""},
		["_5"]={"Spawn Point (Race)","$spawn",""},
		["_6"]={"Spawn Point (Oddball)","$spawn",""},
		["_7"]={"Spawn Point (CTF - RED Team)","$spawn",""},
		["_8"]={"Spawn Point (CTF - BLUE Team)","$spawn",""},
	},
	["6"] = {
		["name"]="Netgame Flags",
		["_1"]={"Teleporter (1-way)","$tele_1",""},
		["_2"]={"Teleporter (2-way)","$tele_2",""},
		["_3"]={"Race Point","$net_race",""},
		["_4"]={"King Of the Hill","$net_koth",""},
		["_5"]={"Oddball","$net_odd",""},
	}
}
FORGE_MENU_SELECTED_PLYR = {}
FORGE_MENU_ANIM_TIME = 0
FORGE_MENU_ANIM_KEY = 25
FORGE_MENU_ANIM_TOTAL = FORGE_MENU_ANIM_KEY + FORGE_MENU_ANIM_KEY

NETGAME_SPAWNPOINT = {}
NETGAME_EQUIPMENT = {}
NETGAME_FLAG = {}
NETGAME_COUNTS = {}
SPLATTER_MASTER = nil

PREFIX = "forge\\"
PREVIEW_PREFIX = "forge\\preview\\"

-- The amount of world units above the player an object will be when player camera is looking completely up
FORGE_OBJECT_Z = 1.5 + 1.5

-- True or false, whether or not you want object to be 0 world units away from player when player camera is looking completely down
FORGE_OBJECT_CLOSE = false

-- Objects don't spawn if the origin is outside of the map. Nothing I can do about that.
-- You could change the z origin offset in the fake vehicle and scenery tag. If you were to change it to -50 then you change this variable to 50.
-- Changing z origin offset in tags seems very buggy for clients.
-- Best option, but time consuming is modifying gbxmodel and collision geometry by making them lowering then they should be, then modifying bounding offset and this variable accordingly.
Z_OFFSET = 0

-- Forge Permission levels
-- 0 : Only the server can run forge commands
-- 1 : Only authorized users can run commands
-- 2 : Anyone who isn't banned can place a set number of objects
-- 3 : Anyone who isn't banned can run forge commands
-- 4 : Everyone including the banned can run forge commands
-- /forge permission level [<level>]
FORGE_PERMISSION_LEVEL = 4
-- Auth and ban lists as dual lists; Index 1 is IPs, while Index 2 is display name
-- /forge permission auth <type> <value>
-- /forge permission ban <type> <value>
-- Valid types: IP, Name, PlayerIndex (IP Bans)
FORGE_PERMISSION_AUTH = {{},{}}
FORGE_PERMISSION_BAN = {{},{}}
-- On ban, do what with objects?
-- 0 : delete objects
-- 1 : save and delete
-- 2 : transfer ownership to server (127.0.0.1:2303)
-- 3 : ignore
FORGE_ON_BAN_ACTION = 0
-- On player disconnect, do what with objects?
-- 0 : delete objects
-- 1 : save and delete
-- 2 : transfer ownership to server (127.0.0.1:2303)
-- 3 : ignore
FORGE_ON_DISCONNECT_ACTION = 3
-- When the game ends, do what with objects?
-- 0 : save as server, reload next match
-- 1 : save as clients
-- 2 : ignore
FORGE_ON_GAME_END_ACTION = 0
-- When resuming save on next round, delete it?
DELETE_SERVER_AUTOSAV_ON_LOAD = false

FORGE_OBJECT_COUNT_PER_PLAYER = 50
FORGE_OBJECT_COUNT_SERVER = 500


-- End of config

PLAYER_FORGE_OBJECT = {}
PLAYER_FORGE_OBJECT_NEXT_PAIR = {}
PLAYER_FORGE_OBJECT_Z = {}
PLAYER_FORGE_OBJECT_ROT = {}
PLAYER_FORGE_OBJECT_DIS = {}
PLAYER_FORGE_OBJECT_TYPE = {} --NEW --OBJ,SPAWN,NETGAME-FLAG,EQIUPMENT,VEHICLE
PLAYER_FORGE_OBJECT_MOVEMENT_STYLE = {	0,0,0,0,0,0,0,0,
										0,0,0,0,0,0,0,0} --NEW --0:collideNone,1:collideBSP,2:collideALL
SPAWNED_FORGE_VEHICLES = {} --ObjectID, tagName, gametype, placedByID, x,y,z,rot0,rot1,rot2,rot3,rot4,rot5
SPAWNED_FORGE_EQUIPMENT = {} --respawnTime, tagName, gametype, placedByID, x,y,z,rot0
SPAWNED_FORGE_OBJECTS = {}
LOADED_FORGE_OBJECTS = {}

FORGE_PLAYER_PLACED_COUNT = {}
LOADED_SAVES = {}
KNOWN_SAVES = {}
KNOWN_SAVES_DIR_LOADED = {}

PLAYER_LAST_TELEPORTER_USED = {{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999},{-9999,-9999,-9999}}
TELEPORTER_PAIRS = {}
TELEPORTER_PAIRS_INCOMPLETE = {}

ADDITIONAL_REMOVAL = {0.0,0.0,0.0}
FORGE_NEW_OBJ_SPAWN_DATA = {nil,nil} --Gametype, ownerIP

GAME_ENDED = false

api_version = "1.7.0.0"
 
function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
	register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
	register_callback(cb['EVENT_TICK'],"OnTick")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	
    register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
	
	for i = 1,16 do
		if(player_alive(i) == true) then 
			OnPlayerJoin(i)
		end
	end
	OnGameStart()
end
function clear_console_prints(PlayerIndex)
	for i=1,30 do
		rprint(PlayerIndex, " ")
	end
	return false
end

function display_help(PlayerIndex, page_number)
  --clear_console_prints(PlayerIndex)
	
    for i=1,30 do
		rprint(PlayerIndex, " ")
	end
	if (page_number == "1") then
		rprint(PlayerIndex, "/forge >          ")
		rprint(PlayerIndex, "   -When used as Spartan, switches to Monitor")
		rprint(PlayerIndex, "   -When monitor, and holding an object, places it")
		rprint(PlayerIndex, "   -When monitor, and not in the creation menu, opens menu")
		rprint(PlayerIndex, "   -When in creation menu, and submenu selected, enters menu")
		rprint(PlayerIndex, "   -When in creation menu, and spawnable item selected, spawns")
		rprint(PlayerIndex, "/forge <         ")
		rprint(PlayerIndex, "   -When used as Monitor without item, switches to Spartan")
		rprint(PlayerIndex, "   -When used as Monitor with held item, removes it")
		rprint(PlayerIndex, "   -When in creation menu, and no submenus, closes menu")
		rprint(PlayerIndex, "   -When in creation menu, and a submenu, returns to previous menu")
		rprint(PlayerIndex, "/forge ^         ")
		rprint(PlayerIndex, "   -If in creation menu, selects next menu item up")
		rprint(PlayerIndex, "/forge v         ")
		rprint(PlayerIndex, "   -If in creation menu, selects next menu item down")
		rprint(PlayerIndex, "/forge ? [<PAGE NUMBER>]")
		rprint(PlayerIndex, "   -Displays this help menu, on selected page")
		rprint(PlayerIndex, "		-------FORGE HELP PAGE 1 OF 3-------")
    elseif (page_number == "2") then
		rprint(PlayerIndex, "/forge save <save-name>			")
		rprint(PlayerIndex, "   -Saves all objects you’ve placed for future use")
		rprint(PlayerIndex, "/forge load <save-name>			")
		rprint(PlayerIndex, "   -Loads a previous save file")
		rprint(PlayerIndex, "/forge unload <save-name>		  ")
		rprint(PlayerIndex, "   -Clears objects from a loaded save file")
		rprint(PlayerIndex, "/forge help [<PAGE>]			   ")
		rprint(PlayerIndex, "   -This screen; info about commands")
		rprint(PlayerIndex, "/forge list saves [<IP>:<PORT>]	")
		rprint(PlayerIndex, "   -Shows saves for your IP, or another IP")
		rprint(PlayerIndex, "/forge spawn <object>					")
		rprint(PlayerIndex, "   -Starts object creation process; use /forge place to finalize")
		rprint(PlayerIndex, "/forge place [<name>]					")
		rprint(PlayerIndex, "   -Places held object, optionally with a name")
		rprint(PlayerIndex, "		-------FORGE HELP PAGE 2 OF 3-------")
	else
		rprint(PlayerIndex, "/forge pickup							")
		rprint(PlayerIndex, "   -Picks up an object you’re aiming at")
		rprint(PlayerIndex, "/forge cancel							")
		rprint(PlayerIndex, "   -Deletes held object")
		rprint(PlayerIndex, "/forge remove_nearest					")
		rprint(PlayerIndex, "   -Removes an object you’re looking at")
		rprint(PlayerIndex, "/forge rot <degrees>					 ")
		rprint(PlayerIndex, "   -Changes object’s Yaw (z angle rotation)")
		rprint(PlayerIndex, "/forge yaw <degrees>					 ")
		rprint(PlayerIndex, "   -Changes object’s Yaw (z angle rotation)")
		rprint(PlayerIndex, "/forge pitch <degrees>				   ")
		rprint(PlayerIndex, "   -Changes object’s Pitch (x angle rotation)")
		rprint(PlayerIndex, "/forge roll <degrees>					")
		rprint(PlayerIndex, "   -Changes object’s Roll (y angle rotation")
		rprint(PlayerIndex, "		-------FORGE HELP PAGE 3 OF 3-------")
    end
    return false
end
-- function display_help_(PlayerIndex, testing_this_out)
	-- if (testing_this_out == "1") then
		-- say(PlayerIndex, "/forge save <save-name>			-Saves all objects you've placed for future use")
		-- say(PlayerIndex, "/forge load <save-name>			-Loads a previous save file")
		-- say(PlayerIndex, "/forge unload <save-name>		  -Clears objects from a loaded save file")
		-- say(PlayerIndex, "/forge help [<PAGE>]			   -This screen; info about commands")
		-- say(PlayerIndex, "/forge list saves [<IP>:<PORT>]	-Shows saves for your IP, or another IP")
		-- say(PlayerIndex, "--FORGE HELP PAGE 1 OF 3--")
	-- elseif (testing_this_out == "2") then
-- --say(PlayerIndex, "/forge list commands			   -Identical as /forge help")
-- --
		-- say(PlayerIndex, "/spawn <object>					-Starts object creation process; use /place to finalize")
		-- say(PlayerIndex, "/place [<name>]					-Places held object, optionally with a name")
		-- say(PlayerIndex, "/pickup							-Picks up an object you're aiming at")
		-- say(PlayerIndex, "/cancel							-Deletes held object")
		-- say(PlayerIndex, "/remove_nearest					-Removes an object you're looking at")
		-- say(PlayerIndex, "--FORGE HELP PAGE 2 OF 3--")
-- --
	-- else
		-- say(PlayerIndex, "/rot <degrees>					 -Changes object's Yaw (z angle rotation)")
		-- say(PlayerIndex, "/yaw <degrees>					 -Changes object's Yaw (z angle rotation)")
		-- say(PlayerIndex, "/pitch <degrees>				   -Changes object's Pitch (x angle rotation)")
		-- say(PlayerIndex, "/roll <degrees>					-Changes object's Roll (y angle rotation)")
		-- say(PlayerIndex, "--FORGE HELP PAGE 3 OF 3--")
	-- end
	-- return false
-- end

function test_collision(sourceX,sourceY,sourceZ,destinationX,destinationY,destinationZ,ignoreID,acceptObjCollision)
	local result = {intersect(sourceX,sourceY,sourceZ,destinationX,destinationY,destinationZ, ignoreID)}
	--print(result)
	if(result[1]) then
		if(result[5]==0xFFFFFFFF or acceptObjCollision) then
			return {result[2],result[3],result[4]}
		else
			return test_collision(result[2],result[3],result[4],destinationX,destinationY,destinationZ,result[5],acceptObjCollision)
		end
	else
		return {destinationX,destinationY,destinationZ}
	end
end
function discover_equipment()
    local tag_array = read_dword( 0x40440000 )
    local scenario_tag_index = read_word( 0x40440004 )
    local scenario_tag = tag_array + scenario_tag_index * 0x20
    local scenario_tag_data = read_dword(scenario_tag + 0x14)
	
	local equip_reflexive = scenario_tag_data + 0x354
    local equip_count = read_dword(equip_reflexive)
    local equip_address = read_dword(equip_reflexive + 0x4)
	NETGAME_COUNTS["equip"] = equip_count + 1
    for i=0,equip_count do
        local equip = equip_address + 144 * i
		local x,y,z = read_vector3d(equip + 0x40)
		local rotation = read_float(equip + 0x4C)
		local spawntime = read_word(equip + 0x0E)
		local gamemode = read_word(equip + 0x04)
		local tag_meta = read_dword(equip+0x50)
		NETGAME_EQUIPMENT[i+1] = {equip,x,y,z,rotation,spawntime,gamemode,tag_meta}
    end
end

function discover_flags()
    local tag_array = read_dword( 0x40440000 )
    local scenario_tag_index = read_word( 0x40440004 )
    local scenario_tag = tag_array + scenario_tag_index * 0x20
    local scenario_tag_data = read_dword(scenario_tag + 0x14)
	
	local flag_reflexive = scenario_tag_data + 0x354
    local flag_count = read_dword(flag_reflexive)
    local flag_address = read_dword(flag_reflexive + 0x4)
	NETGAME_COUNTS["flag"] = flag_count + 1
    for i=0,flag_count do
        local flag = flag_address + 148 * i
		local x,y,z = read_vector3d(flag)
		local rotation = read_float(flag + 0x0C)
		local flag_type = read_word(flag + 0x10)
		local team = read_word(flag + 0x12)
		NETGAME_FLAG[i+1] = {flag,x,y,z,rotation,team,flag_type}
    end
end

function discover_spawnpoints()
    local tag_array = read_dword( 0x40440000 )
    local scenario_tag_index = read_word( 0x40440004 )
    local scenario_tag = tag_array + scenario_tag_index * 0x20
    local scenario_tag_data = read_dword(scenario_tag + 0x14)

    local starting_location_reflexive = scenario_tag_data + 0x354
    local starting_location_count = read_dword(starting_location_reflexive)
    local starting_location_address = read_dword(starting_location_reflexive + 0x4)
	NETGAME_COUNTS["spawn"] = starting_location_count + 1
    for i=0,starting_location_count do
        local starting_location = starting_location_address + 52 * i
		local x,y,z = read_vector3d(starting_location)
		local rotation = read_float(starting_location + 0xC)
		local team = read_word(starting_location + 0x10)
		local gamemode = read_word(starting_location + 0x14)
		if (DEBUG) then
			print("")
			print("SPAWN POINT: " .. i .. " X Y Z: " .. x .. " " .. y .. " " .. z .. " Team: " .. team)
			print("DEBUG 1 of 4 :: ".. read_word(starting_location + 0x14))	--Gametype 00
			print("DEBUG 2 of 4 :: ".. read_word(starting_location + 0x16)) --Gametype 01
			print("DEBUG 3 of 4 :: ".. read_word(starting_location + 0x18)) --Gametype 02
			print("DEBUG 4 of 4 :: ".. read_word(starting_location + 0x1A)) --Gametype 03
			if (i ~= 0) then write_word(starting_location + 0x14, 0) write_word(starting_location + 0x16, 0) end --Disable all spawn points, other than the first one.
			gamemode = 0;
		end
		NETGAME_SPAWNPOINT[i+1] = {starting_location,x,y,z,rotation,team,gamemode}
    end
end
function place_spawnpoint(x,y,z,rotation,team,gamemode)
	for i=1,NETGAME_COUNTS["spawn"] do
		if(NETGAME_SPAWNPOINT[i][7]==0) then
			update_spawnpoint(i,x,y,z,rotation,team,gamemode)
			--i=NETGAME_SPA--WNPOINT_COUNT + 1
			return true
		end
	end
	return false
end
function update_spawnpoint(index,x,y,z,rotation,team,gamemode)
	if(NETGAME_SPAWNPOINT[index]~=nil)then
		if (x ~= nil) then
			NETGAME_SPAWNPOINT[index][2]=x
			NETGAME_SPAWNPOINT[index][3]=y
			NETGAME_SPAWNPOINT[index][4]=z
			NETGAME_SPAWNPOINT[index][5]=rotation
			write_vector3d(NETGAME_SPAWNPOINT[index][1], x,y,z)
			write_float(NETGAME_SPAWNPOINT[index][1] + 0xC, rotation)
		end
		if (team ~= nil) then
			NETGAME_SPAWNPOINT[index][6]=team
			write_word(NETGAME_SPAWNPOINT[index][1] + 0x10, team)
		end
		if (gamemode ~= nil) then
			NETGAME_SPAWNPOINT[index][7]=gamemode
			write_word(NETGAME_SPAWNPOINT[index][1] + 0x14, gamemode)
		else
			NETGAME_SPAWNPOINT[index][7]=0
			write_word(NETGAME_SPAWNPOINT[index][1] + 0x14, 0)
		end
	end
end
function display_spawnpoints()
	for _,v in pairs(NETGAME_SPAWNPOINT) do
		if(v[7]~=0)then
			local spawn_item = ""
			if (v[6] == 0) then
				spawn_item = PREFIX .. "spawnpoint_red"
			else
				spawn_item = PREFIX .. "spawnpoint"
			end
			local id = spawn_object("vehi", spawn_item, v[2], v[3], v[4]+0.05, 0)
			local object = get_object_memory(id)
			if(object ~= nil) then
				local rot = convert(v[5],0,0)
				write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
				write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
				timer(534, "destroy", id)
			end
		end
	end
end
function forge_carry_spawn(PlayerIndex, gamemode, team)
				local spawn_item = ""
				if (team == 0) then
					spawn_item = "spawnpoint_red"
				else
					spawn_item = "spawnpoint"
				end
				local x,y,z = read_vector3d(get_dynamic_player(PlayerIndex) + 0x5c)
				vehicle = spawn_object("vehi", PREVIEW_PREFIX .. spawn_item, x, y, z, 0)
				PLAYER_FORGE_OBJECT[PlayerIndex] = {spawn_item, vehicle, gamemode, team}
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = 0
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = 0
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = 0
				PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]=1
end
function count_placed_spawns()
	local count = 0
	for _,v in pairs(NETGAME_SPAWNPOINT) do
		if(v[7]~=0) then count = count + 1 end
	end
	return count
end
function count_unplaced_spawns()
	local count = 0
	for _,v in pairs(NETGAME_SPAWNPOINT) do
		if(v[7]==0) then count = count + 1 end
	end
	return count
end


function nearest_spawnpoint(x,y,z)
	local loc_x = -1
	local loc_y = -1
	local loc_z = -1
	local loc_index = -1
	local x_diff = 9999
	local y_diff = 9999
	local z_diff = 9999
	local x_diffb = 0
	local y_diffb = 0
	local z_diffb = 0
	for i=1,#NETGAME_SPAWNPOINT do
		if(NETGAME_SPAWNPOINT[i][7]~=0) then
			x_diffb = x - NETGAME_SPAWNPOINT[i][2]
			y_diffb = y - NETGAME_SPAWNPOINT[i][3]
			z_diffb = z - NETGAME_SPAWNPOINT[i][4]
			if (x_diffb < 0) then
				x_diffb = x_diffb * -1
			end
			if (y_diffb < 0) then
				y_diffb = y_diffb * -1
			end
			if (z_diffb < 0) then
				z_diffb = z_diffb * -1
			end
			if ((x_diff + y_diff +z_diff) > (x_diffb + y_diffb + z_diffb)) then
				x_diff = x_diffb
				y_diff = y_diffb
				z_diff = z_diffb
				loc_index = i
			end
		end
	end
	if(loc_index == -1) then return nil end
	return {loc_index, NETGAME_SPAWNPOINT[loc_index][2],NETGAME_SPAWNPOINT[loc_index][3],NETGAME_SPAWNPOINT[loc_index][4], x_diff,y_diff,z_diff}
end
function nearest_vehicle(x,y,z)
	local loc_x = -1
	local loc_y = -1
	local loc_z = -1
	local loc_index = -1
	local x_diff = 999999
	local y_diff = 999999
	local z_diff = 999999
	local x_diffb = 0
	local y_diffb = 0
	local z_diffb = 0
	for _,v in pairs(SPAWNED_FORGE_VEHICLES) do
		m_vehicle = get_object_memory(v[1])
		loc_x,loc_y,loc_z = read_vector3d(m_vehicle + 0x5c)
		x_diffb = x - loc_x
		y_diffb = y - loc_y
		z_diffb = z - loc_z
		if (x_diffb < 0) then
			x_diffb = x_diffb * -1
		end
		if (y_diffb < 0) then
			y_diffb = y_diffb * -1
		end
		if (z_diffb < 0) then
			z_diffb = z_diffb * -1
		end
		if ((x_diff + y_diff +z_diff) > (x_diffb + y_diffb + z_diffb)) then
			x_diff = x_diffb
			y_diff = y_diffb
			z_diff = z_diffb
			loc_index = v[1]
		end
	end
	return {loc_index, loc_x,loc_y,loc_z, x_diff,y_diff,z_diff}
end
function determine_closest_type(x,y,z, object_data, spawn_data, netgame_data, weapon_data, vehicle_data) --0:Obj, 1:Spawn, 2:Netgame, 3:Weapon,4:Vehicle
	local current_nearest = -1
	local x_diff = 999999
	local y_diff = 999999
	local z_diff = 999999
	local x_diff_2 = 999999
	local y_diff_2 = 999999
	local z_diff_2 = 999999
	if (object_data ~=nil) then
		current_nearest = 0
		x_diff = object_data[2]
		y_diff = object_data[3]
		z_diff = object_data[4]
		-- if (object_data[5] == 1) then
			-- x_diff = x - SPAWNED_FORGE_OBJECTS[object_data[1]][3]
			-- y_diff = y - SPAWNED_FORGE_OBJECTS[object_data[1]][4]
			-- z_diff = z - SPAWNED_FORGE_OBJECTS[object_data[1]][5]
		-- else
			-- x_diff = x - LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][3-object_data[8]]
			-- y_diff = y - LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][4-object_data[8]]
			-- z_diff = z - LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][5-object_data[8]]
		----local rot = {LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][6-object_data[8]], LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][7-object_data[8]], LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][8-object_data[8]], LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][9-object_data[8]], LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][10-object_data[8]], LOADED_FORGE_OBJECTS[object_data[1]][object_data[6]][2][object_data[7]][11-object_data[8]]}
		-- end
		-- if (x_diff < 0) then
			-- x_diff = x_diff * -1
		-- end
		-- if (y_diff < 0) then
			-- y_diff = y_diff * -1
		-- end
		-- if (z_diff < 0) then
			-- z_diff = z_diff * -1
		-- end
	end

	if (spawn_data ~= nil) then
		if(current_nearest == -1) then
			x_diff = spawn_data[5]
			y_diff = spawn_data[6]
			z_diff = spawn_data[7]
			current_nearest = 1
		else
			x_diff_2 = spawn_data[5]
			y_diff_2 = spawn_data[6]
			z_diff_2 = spawn_data[7]
			-- if (x_diff_2 < 0) then
				-- x_diff_2 = x_diff_2 * -1
			-- end
			-- if (y_diff_2 < 0) then
				-- y_diff_2 = y_diff_2 * -1
			-- end
			-- if (z_diff_2 < 0) then
				-- z_diff_2 = z_diff_2 * -1
			-- end
			if ((x_diff + y_diff +z_diff) > (x_diff_2 + y_diff_2 + z_diff_2)) then
				x_diff = x_diff_2
				y_diff = y_diff_2
				z_diff = z_diff_2
				current_nearest = 1
			end
		end
	end
	if (netgame_data ~= nil) then
		if(current_nearest == -1) then
			x_diff = netgame_data[5]
			y_diff = netgame_data[6]
			z_diff = netgame_data[7]
			current_nearest = 2
		else
			x_diff_2 = netgame_data[5]
			y_diff_2 = netgame_data[6]
			z_diff_2 = netgame_data[7]
			if ((x_diff + y_diff +z_diff) > (x_diff_2 + y_diff_2 + z_diff_2)) then
				x_diff = x_diff_2
				y_diff = y_diff_2
				z_diff = z_diff_2
				current_nearest = 2
			end
		end
	end
	if (weapon_data ~= nil) then
		if(current_nearest == -1) then
			x_diff = weapon_data[5]
			y_diff = weapon_data[6]
			z_diff = weapon_data[7]
			current_nearest = 3
		else
			x_diff_2 = weapon_data[5]
			y_diff_2 = weapon_data[6]
			z_diff_2 = weapon_data[7]
			if ((x_diff + y_diff +z_diff) > (x_diff_2 + y_diff_2 + z_diff_2)) then
				x_diff = x_diff_2
				y_diff = y_diff_2
				z_diff = z_diff_2
				current_nearest = 3
			end
		end
	end
	if (vehicle_data ~= nil) then
		if(current_nearest == -1) then
			x_diff = vehicle_data[5]
			y_diff = vehicle_data[6]
			z_diff = vehicle_data[7]
			current_nearest = 4
		else
			x_diff_2 = vehicle_data[5]
			y_diff_2 = vehicle_data[6]
			z_diff_2 = vehicle_data[7]
			if ((x_diff + y_diff +z_diff) > (x_diff_2 + y_diff_2 + z_diff_2)) then
				x_diff = x_diff_2
				y_diff = y_diff_2
				z_diff = z_diff_2
				current_nearest = 4
			end
		end
	end
	return current_nearest
end
function forge_menu_left(PlayerIndex)
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex] == nil) then
		FORGE_MENU_SELECTED_PLYR[PlayerIndex] = {}
	end
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] == nil) then
		if ((not forge_cancel_place(PlayerIndex)) and isMonitor(PlayerIndex)) then
			forge_change(PlayerIndex,false)
		end
	else
		pos = 1
		for i=1,5 do
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] == nil) then
				if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos] ~= nil) then FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos] = nil end
				break;
			end
			pos = i
		end
	end
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] == nil) then clear_console_prints(PlayerIndex) end
end

function forge_menu_right(PlayerIndex)
	if (isMonitor(PlayerIndex))then
		if (PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
			forge_place_obj(PlayerIndex)
		else
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex] == nil) then
				FORGE_MENU_SELECTED_PLYR[PlayerIndex] = {}
			end
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] == nil) then
				FORGE_MENU_SELECTED_PLYR[PlayerIndex] = {} --shouldnt be needed, but for some reason, is.
				FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] = "1"
			else
				pos = 0
				tmp = FORGE_MENU
				for i=1,20 do
					if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] == nil) then
						if (tmp["1"] ~= nil) then													-- If submenu is a Menu of Menus, proceed as menu of menus.
							FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]="1"
						elseif (tmp["_1"] ~= nil) then
							FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]="_1"
						end
						break;
					else
						if (tmp ~= nil and FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] ~= nil) then
						if(tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]] ~= nil) then	--and FORGE_MENU[PlayerIndex][i+1] ~= nil
							if (tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["1"] ~= nil or tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["_1"] ~= nil) then
								tmp = tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]
							end
						end
						end
						if (string.find(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i], "_") ~= nil) then 	--If at a spawnable item, spawn it.
							if(string.find(tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]][2], "%$") == nil) then
								forge_spawn_obj(PlayerIndex, tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]][2])
							elseif (string.find(tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]][2],"%$spawn")~=nil)then
								local team = 0
								local gametype = 0
								if(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_1") then
									gametype = 12
								elseif(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_2") then
									gametype = 12
									team = 1
								elseif(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_3") then
									gametype = 2
								elseif(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_4") then
									gametype = 4
								elseif(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_5") then
									gametype = 5
								elseif(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_6") then
									gametype = 3
								elseif(FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] =="_7") then
									gametype = 1
								else
									team = 1
									gametype =1
								end
								forge_carry_spawn(PlayerIndex, gametype, team)
							end
							FORGE_MENU_SELECTED_PLYR[PlayerIndex] = nil
							clear_console_prints(PlayerIndex)
							break;
						end
					end
				end
			end
		end
	else
		forge_change(PlayerIndex,true)
	end
end
function forge_menu_down(PlayerIndex)
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex] == nil) then
		FORGE_MENU_SELECTED_PLYR[PlayerIndex] = {}
	end
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] == nil) then
		--FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] = "1"
	else
		pos = 0
		tmp = FORGE_MENU
		for i=1,20 do
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] == nil) then
				--pos = i - 1
				break;
			else
				if (tmp ~= nil and FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] ~= nil) then
				if(tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]] ~= nil) then	--and FORGE_MENU[PlayerIndex][i+1] ~= nil
					if (tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["1"] ~= nil or tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["_1"] ~= nil) then
						if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i+1] ~= nil) then
						tmp = tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]
						pos = i
						end
					end
				end
				end
			end
		end
		
		if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] ~= nil) then
			_type = false
			_tstr = ""
			index = -1
			if (tonumber(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1]) == nil) then
				_type = true
				_tstr = "_"
				index = tonumber(string.sub(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1], 2))
			else
				index = tonumber(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1])
			end
			if (index == nil) then index = 1 end
			
				real_size = 0
				for i=1,20 do
					if (tmp[_tstr .. i] ~= nil) then
						real_size = i
					else
						i = 20
					end
				end
					
			if (index + 1 <= real_size) then
				if (_type) then
					FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] = "_" .. (index + 1)
				else
					FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] = "" .. (index + 1)
				end
			--else
				--say_all("result past list; ".. (index+1) .. " : "..real_size)
			end
		end
	end
end
function forge_menu_up(PlayerIndex)
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex] == nil) then
		FORGE_MENU_SELECTED_PLYR[PlayerIndex] = {}
	end
	if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] == nil) then
		--FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] = "1"
	else
		pos = 0
		tmp = FORGE_MENU
		for i=1,20 do
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] == nil) then
				--pos = i - 1
				break;
			else
				if (tmp ~= nil and FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] ~= nil) then
				if(tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]] ~= nil) then	--and FORGE_MENU[PlayerIndex][i+1] ~= nil
					if (tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["1"] ~= nil or tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["_1"] ~= nil) then
						if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i+1] ~= nil) then
						tmp = tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]
						pos = i
						end
					end
				end
				end
			end
		end
		
		if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] ~= nil) then
			_type = false
			index = -1
			if (tonumber(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1]) == nil) then
				_type = true
				index = tonumber(string.sub(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1], 2))
			else
				index = tonumber(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1])
			end
			if (index == nil) then 
				index = 1 
				--say_all("index was null")
			--else	
				--say_all(index.."")
			end
			if (index - 1 > 0) then
				if (_type) then
					FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] = "_" .. (index - 1)
				else
					FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] = "" .. (index - 1)
				end
			--else
				--say_all("already top")
			end
		end
	end
end

function forge_menu_display()
	for PlayerIndex=1,16 do
		tmp = nil
		if(player_present(PlayerIndex)) then
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex] == nil) then
				FORGE_MENU_SELECTED_PLYR[PlayerIndex] = {}
			end	
			if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][1] ~= nil) then
				--say_all("k")
				clear_console_prints(PlayerIndex)
				pos = 0
				tmp = FORGE_MENU
				for i=1,20 do
					if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] == nil) then
						--pos = i - 1
						break;
					else
						if (tmp ~= nil and FORGE_MENU_SELECTED_PLYR[PlayerIndex][i] ~= nil) then
						if(tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]] ~= nil) then	--and FORGE_MENU[PlayerIndex][i+1] ~= nil
							if (tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["1"] ~= nil or tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]["_1"] ~= nil) then
								if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][i+1] ~= nil) then
								tmp = tmp[FORGE_MENU_SELECTED_PLYR[PlayerIndex][i]]
								pos = i
								end
							end
						end
						end
					end
				end
				--say_all(pos .. " MENU")
				if (FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1] ~= nil) then
				
					_type = false
					index = -1
					_tstr = ""
					if (tonumber(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1]) == nil) then
						_type = true
						_tstr = "_"
						index = tonumber(string.sub(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1], 2))
						--say_all("_ type" .. index)
					else
						index = tonumber(FORGE_MENU_SELECTED_PLYR[PlayerIndex][pos+1])
						--say_all("number " .. index)
					end
					--say_all("k")
					if (index == nil) then index = 1 end
					real_size = 0
					for i=1,20 do
						if (tmp[_tstr .. i] ~= nil) then
							real_size = i
						else
							i = 20
						end
					end
					for i=1,real_size do
						if (i == index) then
							str = " >>  "
							if (FORGE_MENU_ANIM_TIME < FORGE_MENU_ANIM_KEY) then str = "  >> " end
							name_val = "name"
							if (tmp[_tstr .. i]["name"] == nil) then name_val = 1 end
							rprint(PlayerIndex, str .. tmp[_tstr .. i][name_val])
							--say_all(str .. tmp[ _tstr .. i]["name"])
						else
							name_val = "name"
							if (tmp[_tstr .. i]["name"] == nil) then name_val = 1 end
							rprint(PlayerIndex, "     " .. tmp[ _tstr .. i][name_val])
							--say_all("     " .. tmp[_tstr .. i]["name"])
						end
					end
				end
			end
		end
	end
end
function forge_obj_cleanup(IP, Action)
-- 0 : delete objects
-- 1 : save and delete
-- 2 : transfer ownership to server (127.0.0.1:2303)
-- 3 : ignore
	local splitIP = IP:split(":")
	if (Action < 3) then
		if (Action == 2) then
			for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
				if(v[7] == IP) then
					v[7] = "127.0.0.1:2303"
				end
			end
		elseif (Action == 0) then
			local count = 0
			for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
				count = count + 1
				if(v[7] == IP) then
					table.remove(SPAWNED_FORGE_OBJECTS, count)
				end
			end
		else
			local dir = "sapp\\forge\\" .. splitIP[1] .. "\\" .. splitIP[2] .. "\\"
			--os.execute("mkdir " .. dir)
			--os.execute("date /T > sapp\\forge\\" .. splitIP[1] .. "\\autosav.helper")
			--local date_info = io.open("sapp\\forge\\" .. splitIP[1] .. "\\autosav.helper", "r")
			--local line = directory_info:read():split(" ")
			--line = string.gsub(line[1], "/", "-")
			--directory_info:close()
			local line = os.date("%b-%d-%Y_%I-%M%p")
			forge_save(-1, splitIP[1], splitIP[2], "autosave_"..line, nil)
			--timer(1000, "forge_unload", IP, "autosave_"..line)
			forge_unload(splitIP[1], "autosave_"..line, nil)
		end
	end
	return false
end
function get_obj_location(DynPlayer, dist)
	if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
		destroy_object(PLAYER_FORGE_OBJECT[PlayerIndex][2])
		PLAYER_FORGE_OBJECT[PlayerIndex] = nil
	end

	local x, y, z = read_vector3d(DynPlayer + 0x5c)
	local yaw = get_yaw(DynPlayer)
	local pitch = read_float(DynPlayer + 0x238)

	local distance = dist

	if(pitch >= 0) then
		z = z + (FORGE_OBJECT_Z * pitch)
	else
		pitch = pitch*-1
		if(not FORGE_OBJECT_CLOSE) then 
			z = z - (distance * pitch)
		end
	end
	distance = distance - (distance * pitch)

	if(yaw >= 0 and yaw <= 90) then
		yaw = yaw / 90
		x = x + (distance*(1-yaw))
		y = y + (-distance*yaw)
	elseif(yaw >= 90 and yaw <= 180) then
		yaw = yaw - 90
		yaw = yaw / 90
		y = y + (-distance*(1-yaw))
		x = x + (-distance*yaw)
	elseif(yaw >= 180 and yaw <= 270) then
		yaw = yaw - 180
		yaw = yaw / 90
		x = x + (-distance*(1-yaw))
		y = y + (distance*yaw)
	elseif(yaw >= 270 and yaw <= 360) then
		yaw = yaw - 270
		yaw = yaw / 90
		y = y + (distance*(1-yaw))
		x = x + (distance*yaw)
	end
	return {x,y,z}
end
function teleport(PlayerIndex, x,y,z)
	local DynPlayer = get_dynamic_player(PlayerIndex)
	if DynPlayer ~= 0 then
		write_vector3d(DynPlayer + 0x5c, x,y,z)
	end
	return false
end
function test_teleportation(PlayerIndex)
	local DynPlayer = get_dynamic_player(PlayerIndex)
	if DynPlayer ~= 0 then
		local x,y,z = read_vector3d(DynPlayer + 0x5c)
		--say_all(string.format("%f::%f::%f",math.abs(PLAYER_LAST_TELEPORTER_USED[PlayerIndex][1] - x), math.abs(PLAYER_LAST_TELEPORTER_USED[PlayerIndex][2] - y), math.abs( PLAYER_LAST_TELEPORTER_USED[PlayerIndex][3] - z)))
		--say_all(string.format("%f::%f::%f",PLAYER_LAST_TELEPORTER_USED[PlayerIndex][1] - x, PLAYER_LAST_TELEPORTER_USED[PlayerIndex][2] - y, PLAYER_LAST_TELEPORTER_USED[PlayerIndex][3] - z))
		if (math.abs(PLAYER_LAST_TELEPORTER_USED[PlayerIndex][1] - x) + math.abs(PLAYER_LAST_TELEPORTER_USED[PlayerIndex][2] - y) + math.abs( PLAYER_LAST_TELEPORTER_USED[PlayerIndex][3] - z) > 1.5) then
			PLAYER_LAST_TELEPORTER_USED[PlayerIndex] = {-9999, -9999, -9999}
			for _,v in pairs(TELEPORTER_PAIRS) do
				if (math.abs(v[1][3]- x) + math.abs(v[1][4] - y) + math.abs(v[1][5] - z) < 0.8 and string.find(v[1][2], "teleporter_sender") ~= nil) then
					PLAYER_LAST_TELEPORTER_USED[PlayerIndex] = {v[2][3], v[2][4], v[2][5]}
					teleport(PlayerIndex, v[2][3], v[2][4], v[2][5])
				elseif (math.abs(v[2][3]- x) + math.abs(v[2][4] - y) + math.abs(v[2][5] - z) < 0.8 and string.find(v[2][2], "teleporter_sender") ~= nil) then
					PLAYER_LAST_TELEPORTER_USED[PlayerIndex] = {v[1][3], v[1][4], v[1][5]}
					teleport(PlayerIndex, v[1][3], v[1][4], v[1][5])
				end
			end
		end
	end
	return false
end
function cancel_place_teleporter(index)
  if (PLAYER_FORGE_OBJECT[index] ~= nil) then
	if (string.find(PLAYER_FORGE_OBJECT[index][1], "teleporter_") ~= nil) then
		if (TELEPORTER_PAIRS_INCOMPLETE[index][1] ~= nil) then remove_object(TELEPORTER_PAIRS_INCOMPLETE[index][1][3], TELEPORTER_PAIRS_INCOMPLETE[index][1][4], TELEPORTER_PAIRS_INCOMPLETE[index][1][5]) end
		if (TELEPORTER_PAIRS_INCOMPLETE[index][2] ~= nil) then remove_object(TELEPORTER_PAIRS_INCOMPLETE[index][2][3], TELEPORTER_PAIRS_INCOMPLETE[index][2][4], TELEPORTER_PAIRS_INCOMPLETE[index][2][5]) end
		TELEPORTER_PAIRS_INCOMPLETE[index] = nil
		PLAYER_FORGE_OBJECT_NEXT_PAIR[index] = nil
	end
  end
  return false
end
function change_teleporters_incomplete(PlayerIndex, ObjIndex, index_type, _w, _y, _i)
	if (TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] == nil) then TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {nil, nil} end
	local count = 0
	--say_all("Attempt breakdown")
	for _,v in pairs(TELEPORTER_PAIRS) do
		count = count + 1
		if (index_type == 1) then
			--say_all(string.format("%f::%f::%f",v[1][3],v[1][4],v[1][5]))
			--say_all(string.format("%f::%f::%f",SPAWNED_FORGE_OBJECTS[ObjIndex][3],SPAWNED_FORGE_OBJECTS[ObjIndex][4],SPAWNED_FORGE_OBJECTS[ObjIndex][5]))
			--say_all(string.format("Obj1::%f - %f, %f - %f, %f - %f", v[1][3], SPAWNED_FORGE_OBJECTS[ObjIndex][3], v[1][4], SPAWNED_FORGE_OBJECTS[ObjIndex][4], v[1][5], SPAWNED_FORGE_OBJECTS[ObjIndex][5]))
			if(v[1][3] == SPAWNED_FORGE_OBJECTS[ObjIndex][3] and v[1][4] == SPAWNED_FORGE_OBJECTS[ObjIndex][4] and v[1][5] == SPAWNED_FORGE_OBJECTS[ObjIndex][5]) then
				TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {nil, v[2]}
				table.remove(TELEPORTER_PAIRS, count)
				--say_all("Broke down")
				break
			end
			--say_all(string.format("Obj2::%f - %f, %f - %f, %f - %f", v[2][3], SPAWNED_FORGE_OBJECTS[ObjIndex][3], v[2][4], SPAWNED_FORGE_OBJECTS[ObjIndex][4], v[2][5], SPAWNED_FORGE_OBJECTS[ObjIndex][5]))
			if(v[2][3] == SPAWNED_FORGE_OBJECTS[ObjIndex][3] and v[2][4] == SPAWNED_FORGE_OBJECTS[ObjIndex][4] and v[2][5] == SPAWNED_FORGE_OBJECTS[ObjIndex][5]) then
				TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {v[1], nil}
				table.remove(TELEPORTER_PAIRS, count)
				--say_all("Broke down")
				break
			end
		else
			if(v[1][3] == LOADED_FORGE_OBJECTS[ObjIndex][_w][2][_y][3 - _i] and v[1][4] == LOADED_FORGE_OBJECTS[ObjIndex][_w][2][_y][4 - _i] and v[1][5] == LOADED_FORGE_OBJECTS[ObjIndex][_w][2][_y][5 - _i]) then
				TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {nil, v[2]}
				table.remove(TELEPORTER_PAIRS, count)
				--say_all("Broke down")
				break
			end
			--say_all(string.format("Obj2::%f - %f, %f - %f, %f - %f", v[2][3], LOADED_FORGE_OBJECTS[ObjIndex][_w][_y][3], v[2][4], LOADED_FORGE_OBJECTS[ObjIndex][_w][_y][4], v[2][5], LOADED_FORGE_OBJECTS[ObjIndex][_w][_y][5]))
			if(v[2][3] == LOADED_FORGE_OBJECTS[ObjIndex][_w][2][_y][3 - _i] and v[2][4] == LOADED_FORGE_OBJECTS[ObjIndex][_w][2][_y][4 - _i] and v[2][5] == LOADED_FORGE_OBJECTS[ObjIndex][_w][2][_y][5 - _i]) then
				TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {v[1], nil}
				table.remove(TELEPORTER_PAIRS, count)
				--say_all("Broke down")
				break
			end
		end
	end
	return false
end

function forge_game_start()
	forge_load(-1, "127.0.0.1", "2303", "autoload", "autoload") 	-- Automatically load a set level if exists.
	forge_load(-1, "127.0.0.1", "2303", "autosav", "autoload")		-- Automatically load previous round, if exists.
	if (DELETE_SERVER_AUTOSAV_ON_LOAD) then
		os.execute("DEL sapp\\forge\\autoload\\autosav.txt > nul 2>&1")		-- Delete autosave on load
	end

end
function forge_game_end()
	if (FORGE_ON_GAME_END_ACTION < 2) then
		if (FORGE_ON_GAME_END_ACTION == 0) then
			for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
				v[7] = "127.0.0.1:2303"
			end
			forge_save(-1, "127.0.0.1", "2303", "autosav", "autoload")
		else
			local date_str = os.date("%b-%d-%Y_%I-%M%p")
			for i=1,16 do
				if(player_present(i)) then
					local IP = get_var(PlayerIndex,"$ip"):split(":")
					forge_save(i, IP[1], IP[2], "autosave_"..date_str, nil)
				end
			end
		end
	end
	return false
end
function forge_save(PlayerIndex, ip, port, save_name, directory_overload)
	local full_IP = string.format("%s:%s",ip,port)
	local dir = "sapp\\forge\\" .. ip .. "\\" .. port .. "\\"
	if (directory_overload ~= nil) then dir = "sapp\\forge\\" .. directory_overload .. "\\" end

	os.execute("mkdir " .. dir .. " > nul 2>&1")
	local savefile = io.open(dir .. save_name .. ".txt", "w")

	local count = 1
	local objects = {}
	local remove = {}
	for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
		if(v[7] == full_IP) then
			table.insert(remove, count)
			table.insert(objects, {v[1], v[2], v[3], v[4], v[5], v[6][1], v[6][2], v[6][3], v[6][4], v[6][5], v[6][6]})
			savefile:write(v[1] .. "," .. v[2] .. "," .. v[3] .. "," .. v[4] .. "," .. v[5] .. "," .. v[6][1] .. "," .. v[6][2] .. "," .. v[6][3] .. "," .. v[6][4] .. "," .. v[6][5] .. "," .. v[6][6] .. "\n")
		else
			count = count + 1
		end
	end
	count = 0
	for o = #remove,1,-1 do
		table.remove(SPAWNED_FORGE_OBJECTS, remove[o])
	end

	if(LOADED_FORGE_OBJECTS[ip] ~= nil) then
		for _,v in pairs(LOADED_FORGE_OBJECTS[ip]) do
			for _,w in pairs(v[2]) do
				local i = 0
				if(#w == 10) then
					savefile:write(",")
					i = 1
				else
					savefile:write(w[1] .. ",")
				end
				
				savefile:write(w[2-i] .. "," .. w[3-i] .. "," .. w[4-i] .. "," .. w[5-i] .. "," .. w[6-i] .. "," .. w[7-i] .. "," .. w[8-i] .. "," .. w[9-i] .. "," .. w[10-i] .. "," .. w[11-i] .. "\n")
			end
		end
	end
	savefile:close()
	local tele_savefile = io.open(dir .. save_name .. "_tele.txt", "w")
	for _,v in pairs(TELEPORTER_PAIRS) do
		if ((v[1][7] == full_IP) or (v[2][7] == full_IP)) then
			if (v[1][1] == nil) then 
				v[1][1] = "teleporter_pairs"
				v[2][1] = "teleporter_pairs"
			end
			tele_savefile:write(v[1][1] .. "," .. v[1][2] .. "," .. v[1][3] .. "," .. v[1][4] .. "," .. v[1][5] .. "," .. v[1][6][1] .. "," .. v[1][6][2] .. "," .. v[1][6][3] .. "," .. v[1][6][4] .. "," .. v[1][6][5] .. "," .. v[1][6][6] .. "\n")
			tele_savefile:write(v[2][1] .. "," .. v[2][2] .. "," .. v[2][3] .. "," .. v[2][4] .. "," .. v[2][5] .. "," .. v[2][6][1] .. "," .. v[2][6][2] .. "," .. v[2][6][3] .. "," .. v[2][6][4] .. "," .. v[2][6][5] .. "," .. v[2][6][6] .. "\n")
		end
	end
	tele_savefile:close()

	if(LOADED_SAVES[ip] == nil) then
		LOADED_SAVES[ip] = {}
	end

	if(objects[1] == nil) then return false end

	if(LOADED_FORGE_OBJECTS[ip] == nil) then LOADED_FORGE_OBJECTS[ip] = {} end

	table.insert(LOADED_FORGE_OBJECTS[ip], {save_name, objects, ip})
	table.insert(LOADED_SAVES[ip], {save_name, dir})

	timer(500, "refresh")
	return false
end

function forge_load(PlayerIndex, ip, port, save_name, directory_overload)
	local full_IP = string.format("%s:%s",ip,port)
	local dir = "sapp\\forge\\" .. ip .. "\\" .. port .. "\\"
	if (directory_overload ~= nil) then dir = "sapp\\forge\\" .. directory_overload .. "\\" end

	local savefile = io.open(dir .. save_name .. ".txt", "r")
	local tele_savefile = io.open(dir .. save_name .. "_tele.txt", "r")
	if(savefile ~= nil) then

		local loaded = false

		if(LOADED_SAVES[ip] == nil) then
			LOADED_SAVES[ip] = {}
		else
			for _,v in pairs(LOADED_SAVES[ip]) do
				if(v == save_name) then
					loaded = true
					break
				end
			end
		end

		if(not loaded) then
			local line = savefile:read()
			local objects = {}
			while(line ~= nil) do
				local array = {}
							
				for w in line:gmatch("([^,]+)") do
					local n = #array + 1
					if(n > 2) then
						array[n] = tonumber(w)
					else
						array[n] = w
					end
				end
			table.insert(objects, array)
			line = savefile:read()
		end

		if(objects[1] == nil) then return false end

		if(LOADED_FORGE_OBJECTS[ip] == nil) then LOADED_FORGE_OBJECTS[ip] = {} end

		table.insert(LOADED_FORGE_OBJECTS[ip], {save_name, objects, ip})
		table.insert(LOADED_SAVES[ip], {save_name, dir})
		if (tele_savefile ~= nil) then
			line = tele_savefile:read()
			while(line ~= nil) do
				local array_a = {}
				local array_b = {}
							
				for w in line:gmatch("([^,]+)") do
					local n = #array_a + 1
					if(n > 2) then
						array_a[n] = tonumber(w)
					else
						array_a[n] = w
					end
				end
				line = tele_savefile:read()
				for w in line:gmatch("([^,]+)") do
					local n = #array_b + 1
					if(n > 2) then
						array_b[n] = tonumber(w)
					else
						array_b[n] = w
					end
				end
				table.insert(
					TELEPORTER_PAIRS, 
					{
						{array_a[1], array_a[2], array_a[3], array_a[4], array_a[5], {array_a[6], array_a[7], array_a[8], array_a[9], array_a[10], array_a[11]}, ip},
						{array_b[1], array_b[2], array_b[3], array_b[4], array_b[5], {array_b[6], array_b[7], array_b[8], array_b[9], array_b[10], array_b[11]}, ip}
					}
				)
				line = tele_savefile:read()
			end
		end
		--say_all(string.format("After load, %s -- %i", IP[1], #LOADED_FORGE_OBJECTS))
		--say_all(string.format("After load, %i", #LOADED_FORGE_OBJECTS[IP[1]]))
		timer(500, "refresh")
		end
	end
	return false
end
function forge_unload(ip, save_name, dir)
	local count = 1
	local search_index = 1
	local search_content = save_name
	if (dir ~= nil) then
	  search_index = 2
	  search_content = dir
	end
	print(ip)
	if (LOADED_SAVES[ip] == nil) then print("WTF?") else
	for _,v in pairs(LOADED_SAVES[ip]) do
		if(v[search_index] == search_content) then
			table.remove(LOADED_FORGE_OBJECTS[ip], count)
			table.remove(LOADED_SAVES[ip], count)
			timer(500, "refresh")
			break
		end
		count = count + 1
	end
	end
	return false
end
function list_saves(PlayerIndex, ip, port, page, directory_overload)
	if (KNOWN_SAVES[ip] == nil or directory_overload ~= nil) then
		if (KNOWN_SAVES[ip] == nil) then KNOWN_SAVES[ip] = {} end
		local dir = "sapp\\forge\\" .. ip .. "\\" .. port .. "\\"
		local override = false
		if (directory_overload ~= nil) then 
			dir = "sapp\\forge\\" .. directory_overload .. "\\" 
			override = true
		end
		local not_loaded = true
		if (directory_overload ~= nil) then
			if (KNOWN_SAVES_DIR_LOADED[ip] == nil) then 
				KNOWN_SAVES_DIR_LOADED[ip] = {}
			end
			for _,v in pairs(KNOWN_SAVES_DIR_LOADED[ip]) do 
				if (v == directory_overload) then
					not_loaded = false
					break
				end
			end
			table.insert(KNOWN_SAVES_DIR_LOADED[ip], directory_overload)
		end
		if (not_loaded) then
			os.execute("mkdir " .. dir .. " > nul 2>&1")
			os.execute("dir " .. dir .. "> " .. dir .. ".directory")
			local directory_info = io.open(dir .. ".directory", "r")
			local line = directory_info:read()
			--local total_save_count = 0
			while(line ~= nil) do
				local chunk = line:split(" ")--string.format("([^%s]+)", " ")
				--say_all(#chunk)
				local highest_nonnull = -1
				for i=1,#chunk+1 do
					if (chunk[i] ~= nil) then highest_nonnull = i end
				end
				if (highest_nonnull ~= -1) then
					if(string.find(chunk[#chunk], ".txt") ~= nil and string.find(chunk[#chunk], "_tele.txt") == nil) then 
						table.insert(KNOWN_SAVES[ip], {string.gsub(chunk[highest_nonnull], ".txt", ""), string.format("%s %s %s", chunk[1],chunk[2], chunk[3]), override})
						--if (string.find(chunk[#chunk], ".directory") == nil) then
						--say(PlayerIndex, string.format("%s %s %s", chunk[1],chunk[2], chunk[3]))
						--say(PlayerIndex, string.gsub(chunk[highest_nonnull], ".txt", ""))--line)
						--total_save_count = total_save_count + 1
					end
				end
				line = directory_info:read()
			end
			--say(PlayerIndex, string.format("There are %i saves available for the IP %s:%s",total_save_count, IP[1], IP[2]))
			directory_info:close()
			--os.remove(dir .. ".directory")
		end
	end
	clear_console_prints(PlayerIndex)
	local max_page = math.ceil(#KNOWN_SAVES[ip] / 13)
	if (max_page == 0) then
		rprint(PlayerIndex, "	   ------ NO SAVE FILES DETECTED, PAGE 0 OF 0 ------ ")
	else
		local actual_page = page
		if (max_page < page) then actual_page = max_page end
		if (page < 0) then actual_page = 1 end
		actual_page = actual_page - 1
		for i=1,13 do
			if (KNOWN_SAVES[ip][i+(actual_page*13)] ~= nil) then
				if (KNOWN_SAVES[ip][i+(actual_page*13)][1] ~= true) then
					rprint(PlayerIndex, string.format("	%s	Date Modified: %s", KNOWN_SAVES[ip][i+(actual_page*13)][1], KNOWN_SAVES[ip][i+(actual_page*13)][2]))
				else
					rprint(PlayerIndex, string.format("	%s	Date Modified: %s, ALT LOCATION", KNOWN_SAVES[ip][i+(actual_page*13)][1], KNOWN_SAVES[ip][i+(actual_page*13)][2]))
				end
			end
		end
		rprint(PlayerIndex,string.format("	   ------ SAVES FOR %s, PAGE %i OF %i ------ ", ip, actual_page + 1, max_page))
		rprint(PlayerIndex, "")
	end
	return false
end
function forge_spawn_obj(PlayerIndex, object)
	if(object ~= nil and FORGE_OBJECTS[object] ~= nil) then
	--say_all("TESTING: " .. object)
		local DynPlayer = get_dynamic_player(PlayerIndex)
		if DynPlayer ~= 0 then
			cancel_place_teleporter()
			if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
				destroy_object(PLAYER_FORGE_OBJECT[PlayerIndex][2])
				PLAYER_FORGE_OBJECT[PlayerIndex] = nil
				PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex] = nil
			end

			local loc = get_obj_location(DynPlayer, FORGE_OBJECTS[object][2])
			--say_all(FORGE_OBJECTS[object][1])
			vehicle = spawn_object("vehi", PREVIEW_PREFIX .. FORGE_OBJECTS[object][1], loc[1], loc[2], loc[3] + Z_OFFSET, 0)
			PLAYER_FORGE_OBJECT_TYPE[PlayerIndex] = 0
			PLAYER_FORGE_OBJECT[PlayerIndex] = {object, vehicle}
			if(string.find(object, "teleporter_") ~= nil) then 
				PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex] = "teleporter_sender"
				TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {nil, nil}
			end
		end
	end
	return false
end
function forge_pickup_obj(PlayerIndex)
	local DynPlayer = get_dynamic_player(PlayerIndex)
	if DynPlayer ~= 0 then
		local dbg_distance = 3.0
		if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
			destroy(PLAYER_FORGE_OBJECT[PlayerIndex][2])
			PLAYER_FORGE_OBJECT[PlayerIndex] = nil
		end
		local loc = get_obj_location(DynPlayer, 4.0)
		local near_data = get_nearest(loc[1], loc[2], loc[3])
		local near_spawn = nearest_spawnpoint(loc[1],loc[2],loc[3])
		local near_vehicle = nearest_vehicle(loc[1],loc[2],loc[3])
		local near_flag = nil
		local near_equip = nil
		--say_all(string.format("%i:%f:%f:%f",near_data[1],near_data[2],near_data[3],near_data[4]))
		local near_type = determine_closest_type(loc[1],loc[2],loc[3],near_data,near_spawn,near_flag,near_equip,near_vehicle)
		if(near_type == 0) then --Object
			if (near_data[2] < dbg_distance and near_data[3] < dbg_distance and near_data[4] < dbg_distance) then
				if(near_data[1] ~= nil) then
					--say_all(SPAWNED_FORGE_OBJECTS[near_data[1]][2])
				
					--say_all(string.format("Picking up Index %i",near_data[1]))
					--say_all(SPAWNED_FORGE_OBJECTS[near_data[1]][2])
					if (near_data[5] == 1) then
						if (string.find(SPAWNED_FORGE_OBJECTS[near_data[1]][2], "teleporter_") ~= nil) then change_teleporters_incomplete(PlayerIndex, near_data[1], near_data[5], nil, nil, nil) end
						vehicle = spawn_object("vehi", PREVIEW_PREFIX .. SPAWNED_FORGE_OBJECTS[near_data[1]][2], SPAWNED_FORGE_OBJECTS[near_data[1]][3], SPAWNED_FORGE_OBJECTS[near_data[1]][4], SPAWNED_FORGE_OBJECTS[near_data[1]][5], 0)
						PLAYER_FORGE_OBJECT[PlayerIndex] = {SPAWNED_FORGE_OBJECTS[near_data[1]][2], vehicle}
						local rot = SPAWNED_FORGE_OBJECTS[near_data[1]][6]
						--say_all(string.format("%d:%d:%d:%d:%d:%d",rot[1],rot[2],rot[3],rot[4],rot[5],rot[6]))
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = math.deg(math.asin(rot[2])) --yaw
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = math.deg(math.asin(rot[3])) --pitch
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = math.deg(math.asin(-rot[5])) --roll
						ADDITIONAL_REMOVAL[1] = SPAWNED_FORGE_OBJECTS[near_data[1]][3]
						ADDITIONAL_REMOVAL[2] = SPAWNED_FORGE_OBJECTS[near_data[1]][4]
						ADDITIONAL_REMOVAL[3] = SPAWNED_FORGE_OBJECTS[near_data[1]][5]
						table.remove(SPAWNED_FORGE_OBJECTS, near_data[1])
					else
						if (string.find(LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][2 - near_data[8]], "teleporter_") ~= nil) then 
							change_teleporters_incomplete(PlayerIndex, near_data[1], near_data[5], near_data[6], near_data[7], near_data[8]) 
						end
						vehicle = spawn_object("vehi", PREVIEW_PREFIX .. LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][2-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][3-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][4-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][5-near_data[8]], 0)
						PLAYER_FORGE_OBJECT[PlayerIndex] = {LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][2-near_data[8]], vehicle}
						local rot = {LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][6-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][7-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][8-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][9-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][10-near_data[8]], LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][11-near_data[8]]}
						--say_all(string.format("%d:%d:%d:%d:%d:%d",rot[1],rot[2],rot[3],rot[4],rot[5],rot[6]))
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = math.deg(math.asin(rot[2])) --yaw
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = math.deg(math.asin(rot[3])) --pitch
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = math.deg(math.asin(-rot[5])) --roll

						ADDITIONAL_REMOVAL[1] = LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][3-near_data[8]]
						ADDITIONAL_REMOVAL[2] = LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][4-near_data[8]]
						ADDITIONAL_REMOVAL[3] = LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]][2][near_data[7]][5-near_data[8]]
						--table.remove(LOADED_FORGE_OBJECTS[near_data[1]][near_data[6]], near_data[7])
						table.remove(LOADED_FORGE_OBJECTS[near_data[1]], near_data[6])
					end
					PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]=0
					timer(500, "refresh")
				end
			end
		elseif(near_type == 1) then --Spawn point
			if (near_spawn[5] < dbg_distance and near_spawn[6] < dbg_distance and near_spawn[7] < dbg_distance) then
				update_spawnpoint(near_spawn[1],nil,nil,nil,nil,nil,0)
				local spawn_data = NETGAME_SPAWNPOINT[near_spawn[1]]
				local spawn_item = ""
				if (spawn_data[6] == 0) then
					spawn_item = "spawnpoint_red"
				else
					spawn_item = "spawnpoint"
				end
				
				vehicle = spawn_object("vehi", PREVIEW_PREFIX .. spawn_item, spawn_data[2], spawn_data[3], spawn_data[4]+0.25, 0)
				PLAYER_FORGE_OBJECT[PlayerIndex] = {spawn_item, vehicle, spawn_data[7], spawn_data[6]}
				--local rot = SPAWNED_FORGE_OBJECTS[near_data[1]][6]
				--say_all(string.format("%d:%d:%d:%d:%d:%d",rot[1],rot[2],rot[3],rot[4],rot[5],rot[6]))
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = math.deg(math.asin(spawn_data[5]))--rot[2])) --yaw
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = 0--math.deg(math.asin(rot[3])) --pitch
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = 0--math.deg(math.asin(-rot[5])) --roll
				PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]=1
				timer(500, "refresh")
			end
		elseif(near_type == 2) then --netgame flag
		
		elseif(near_type == 3) then --equipment/Weapon
		
		elseif(near_type == 4) then --vehicle
		--SPAWNED_FORGE_VEHICLES[newobjectid]={newobjectid, name, obj_gametype, ownerIP, x,y,z,yaw,pitch,roll}
			local vehicle_data = SPAWNED_FORGE_VEHICLES[near_vehicle[1]]
			m_vehicle = get_object_memory(near_vehicle[1])
			local yaw,pitch,roll = read_vector3d(m_vehicle + 0x74)
			write_bit(m_vehicle + 0x10, 1,1)
			write_bit(m_vehicle + 0x10, 2,1)
			write_bit(m_vehicle + 0x10, 5,1)
			--vehicle = spawn_object("vehi", PREVIEW_PREFIX .. vehcile_data[2], spawn_data[2], spawn_data[3], spawn_data[4]+0.25, 0)
			say_all(vehicle_data[2] .."::".. vehicle_data[1] .."::".. vehicle_data[3])
			PLAYER_FORGE_OBJECT[PlayerIndex] = {vehicle_data[2], vehicle_data[1], vehicle_data[3]}
			--local rot = SPAWNED_FORGE_OBJECTS[near_data[1]][6]
			--say_all(string.format("%d:%d:%d:%d:%d:%d",rot[1],rot[2],rot[3],rot[4],rot[5],rot[6]))
			PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = yaw--math.deg(math.asin(yaw))--rot[2])) --yaw
			PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = pitch--math.deg(math.asin(pitch))--math.deg(math.asin(rot[3])) --pitch
			PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = roll--math.deg(math.asin(roll))--math.deg(math.asin(-rot[5])) --roll
			PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]=4
		end
	end
 
	return false
end
function forge_place_obj(PlayerIndex, name)
	if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
		local id = PLAYER_FORGE_OBJECT[PlayerIndex][2]
		local object = get_object_memory(id)

		local x, y, z = read_vector3d(object + 0x5c)
		if(PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]==0) then
			local override = false
			local tag_path = PREFIX .. PLAYER_FORGE_OBJECT[PlayerIndex][1]
			if(FORGE_OBJECT_SPAWN_OVERRIDE[PLAYER_FORGE_OBJECT[PlayerIndex][1]]~=nil) then 
				tag_path = FORGE_OBJECT_SPAWN_OVERRIDE[PLAYER_FORGE_OBJECT[PlayerIndex][1]] 
				override = true 
			end
			local newobjectid = spawn_object("vehi", tag_path, x, y, z, 0)
			local newobject = get_object_memory(newobjectid)
			write_vector3d(newobject + 0x5c, x, y, z)


			local rot = convert(PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1], PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2], PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3])
			write_vector3d(newobject + 0x74, rot[1], rot[2], rot[3])
			write_vector3d(newobject + 0x80, rot[4], rot[5], rot[6])

			if(name == nil) then name = "" end
			timer(534, "destroy", id)
			if(not(override))then
				timer(534, "destroy", newobjectid)
				table.insert(SPAWNED_FORGE_OBJECTS, { name, PLAYER_FORGE_OBJECT[PlayerIndex][1], x, y, z, rot, get_var(PlayerIndex,"$ip")})
			else
				--print("00")
				m_vehicle = get_object_memory(newobjectid)--get_object_memory(read_dword(get_object_memory(newobjectid) + 0x11C))
				--if(m_vehicle == nil) then print("NIL") else print(m_vehicle) end
				--print("01")
				local xx,yy,zz = read_vector3d(m_vehicle + 0x5c)
				--print("02")
				local yaw,pitch,roll = read_vector3d(m_vehicle + 0x74)
				--print("03")
				--local rx,ry,rz = read_vector3d(m_vehicle + 0x584)
				--print("04")
				--print("Object " .. name .. rx .. "  ::  " .. ry .. "  ::  " .. rz)
				--print("            " ..  xx .. "  ::  " .. yy .. "  ::  " .. zz)
				write_vector3d(m_vehicle + 0x584,xx,yy,zz)
				local ownerIP = get_var(PlayerIndex,"$ip")--"127.0.0.1:2303"
				local obj_gametype = 1
				if(FORGE_NEW_OBJ_SPAWN_DATA[1]~=nil) then
					obj_gametype = FORGE_NEW_OBJ_SPAWN_DATA[1]
					ownerIP = FORGE_NEW_OBJ_SPAWN_DATA[2]
				end
				FORGE_NEW_OBJ_SPAWN_DATA = {nil,nil}
				SPAWNED_FORGE_VEHICLES[newobjectid]={newobjectid, PLAYER_FORGE_OBJECT[PlayerIndex][1], obj_gametype, ownerIP, x,y,z,yaw,pitch,roll}
				say_all(SPAWNED_FORGE_VEHICLES[newobjectid][2] .. "::" ..PLAYER_FORGE_OBJECT[PlayerIndex][1])
				--write_word(m_vehicle + 0x5B0, 600) --DEBUG, TESTING
			end


			if(string.find(PLAYER_FORGE_OBJECT[PlayerIndex][1], "teleporter_") ~= nil) then 
				if (TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] == nil) then TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = {nil, nil} end
				if (TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1] == nil) then 
					TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1] =  {commandargs[2], PLAYER_FORGE_OBJECT[PlayerIndex][1], x, y, z, rot, get_var(PlayerIndex,"$ip") }
					--say_all(string.format("%f::%f::%f",TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1][3],TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1][4],TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1][5]))
					if (PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex] ~= nil) then
						vehicle = spawn_object("vehi", PREVIEW_PREFIX .. FORGE_OBJECTS[PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex]][1], x,y,z + Z_OFFSET, 0)
						PLAYER_FORGE_OBJECT[PlayerIndex] = {PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex], vehicle}
						PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex] = nil
					else
						PLAYER_FORGE_OBJECT[PlayerIndex] = nil
						PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
						PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
					end
				else
					TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][2] = { commandargs[2], PLAYER_FORGE_OBJECT[PlayerIndex][1], x, y, z, rot, get_var(PlayerIndex,"$ip") }
					--say_all(string.format("%f::%f::%f",TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][2][3],TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][2][4],TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][2][5]))
				end
				if (TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1] ~= nil and TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][2] ~= nil) then
					table.insert(TELEPORTER_PAIRS, {TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][1],TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex][2]})
					TELEPORTER_PAIRS_INCOMPLETE[PlayerIndex] = nil
					PLAYER_FORGE_OBJECT[PlayerIndex] = nil
					PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
					PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
					PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
					PLAYER_FORGE_OBJECT_NEXT_PAIR[PlayerIndex] = nil
				end
			else
				PLAYER_FORGE_OBJECT[PlayerIndex] = nil
				PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
				PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
				PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
			end
			PLAYER_FORGE_OBJECT_TYPE[PlayerIndex] = nil
		elseif(PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]==1) then
			local team = 0
			local gameMode = 1
			if(PLAYER_FORGE_OBJECT[PlayerIndex][3]~=nil) then
				gameMode = PLAYER_FORGE_OBJECT[PlayerIndex][3]
			end
			if(PLAYER_FORGE_OBJECT[PlayerIndex][4]~=nil) then
				team = PLAYER_FORGE_OBJECT[PlayerIndex][4]
			else
				if(string.find(PLAYER_FORGE_OBJECT[PlayerIndex][1], "red") ~= nil) then
					team = 0
				else
					team = 1
				end
			end
			place_spawnpoint(x,y,z,PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1],team,gameMode)
			timer(534, "destroy", id)
			PLAYER_FORGE_OBJECT[PlayerIndex] = nil
			PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
			PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
			PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
			PLAYER_FORGE_OBJECT_TYPE[PlayerIndex] = nil
			timer(500, "refresh")
		elseif(PLAYER_FORGE_OBJECT_TYPE[PlayerIndex]==4) then
			m_vehicle = get_object_memory(PLAYER_FORGE_OBJECT[PlayerIndex][2])
			write_bit(m_vehicle + 0x10, 2,0)
			write_bit(m_vehicle + 0x10, 1,0)
			write_bit(m_vehicle + 0x10, 5,0)
			PLAYER_FORGE_OBJECT[PlayerIndex] = nil
			PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
			PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
			PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
			PLAYER_FORGE_OBJECT_TYPE[PlayerIndex] = nil
		end
	end
	return false
end
function forge_remove(PlayerIndex, name)
	local count = 0
	for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
		count = count + 1
		if(get_var(PlayerIndex,"$ip") == v[7] and v[1] == commandargs[2]) then
			ADDITIONAL_REMOVAL[1] = v[3]
			ADDITIONAL_REMOVAL[2] = v[4]
			ADDITIONAL_REMOVAL[3] = v[5]
			table.remove(SPAWNED_FORGE_OBJECTS, count)
			timer(500, "refresh")
			break
		end
	end
	return false
end
function forge_cancel_place(PlayerIndex)
	--rprint(PlayerIndex,"Attempting to remove")
	if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
		--rprint(PlayerIndex,"Removed")
		cancel_place_teleporter(PlayerIndex)
		destroy(PLAYER_FORGE_OBJECT[PlayerIndex][2])
		PLAYER_FORGE_OBJECT[PlayerIndex] = nil
		PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
		PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
		PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
		PLAYER_FORGE_OBJECT_TYPE[PlayerIndex] = nil
		return true
	end
	return false
end
function forge_get_permission(PlayerIndex)
	if(player_present(PlayerIndex)) then
		if (FORGE_PERMISSION_LEVEL == 0) then
			return false
		elseif (FORGE_PERMISSION_LEVEL == 4) then
			return true
		elseif (FORGE_PERMISSION_LEVEL == 1) then
			local IP = get_var(PlayerIndex,"$ip"):split(":")
			if (FORGE_PERMISSION_AUTH[1][IP[1]] ~= nil) then
				return true
			end if (FORGE_PERMISSION_AUTH[2][get_var(PlayerIndex, "$name")] ~= nil) then
				return true
			end
		elseif (FORGE_PERMISSION_LEVEL == 2) then
	   		local IP = get_var(PlayerIndex,"$ip"):split(":")
			if (FORGE_PERMISSION_BAN[1][IP[1]] ~= nil) then
				return false
			end if (FORGE_PERMISSION_BAN[2][get_var(PlayerIndex, "$name")] ~= nil) then
				return false
			end
			return true
			--Will check for max spawned objects on obj spawn.
		elseif (FORGE_PERMISSION_LEVEL == 3) then
	   		local IP = get_var(PlayerIndex,"$ip"):split(":")
			if (FORGE_PERMISSION_BAN[1][IP[1]] ~= nil) then
				return false
			end if (FORGE_PERMISSION_BAN[2][get_var(PlayerIndex, "$name")] ~= nil) then
				return false
			end
			return true
		end
	end
	return false
end
function forge_set_auth(data, isIP, give)
	if (give) then
		if (isIP) then
			FORGE_PERMISSION_AUTH[1][data] = data
		else
			FORGE_PERMISSION_AUTH[2][data] = data
		end
	else
		if (isIP) then
			FORGE_PERMISSION_AUTH[1][data] = nil
		else
			FORGE_PERMISSION_AUTH[2][data] = nil
		end
	end

	local dir = "sapp\\forge\\settings\\"
	os.execute("mkdir " .. dir .. " > nul 2>&1")
	local savefile = io.open(dir .. "authorized_ips.txt", "w")
	for _,v in pairs(FORGE_PERMISSION_AUTH[1]) do
			if (v ~= nil) then
		   		savefile:write(v .. "\n")
			end
	end
	savefile:close()
	local savefile = io.open(dir .. "authorized_names.txt", "w")
	for _,v in pairs(FORGE_PERMISSION_AUTH[2]) do
			if (v ~= nil) then
		   		savefile:write(v .. "\n")
			end
	end
	savefile:close()

end
function forge_set_ban(data, isIP, give)
	if (give) then
		if (isIP) then
			FORGE_PERMISSION_BAN[1][data] = data
			forge_obj_cleanup(data .. ":2303", FORGE_ON_BAN_ACTION)
		else
			FORGE_PERMISSION_BAN[2][data] = data
		end
		--forge_obj_cleanup(get_var(PlayerIndex,"$ip"), FORGE_ON_BAN_ACTION)
	else
		if (isIP) then
			FORGE_PERMISSION_BAN[1][data] = nil
		else
			FORGE_PERMISSION_BAN[2][data] = nil
		end
	end

	local dir = "sapp\\forge\\settings\\"
	os.execute("mkdir " .. dir .. " > nul 2>&1")
	local savefile = io.open(dir .. "banned_ips.txt", "w")
	for _,v in pairs(FORGE_PERMISSION_BAN[1]) do
			if (v ~= nil) then
		   		savefile:write(v .. "\n")
			end
	end
	savefile:close()
	local savefile = io.open(dir .. "banned_names.txt", "w")
	for _,v in pairs(FORGE_PERMISSION_BAN[2]) do
			if (v ~= nil) then
		   		savefile:write(v .. "\n")
			end
	end
	savefile:close()
end
function forge_set_permission(level)
	if (level == FORGE_PERMISSION_LEVEL) then
		return false
	end
	local curr_mode = ""
	local change_mode = ""
	if (FORGE_PERMISSION_LEVEL == 0) then
		curr_mode = "Server-Only"
	elseif (FORGE_PERMISSION_LEVEL == 1) then
		curr_mode = "Authenticated-Only"
	elseif (FORGE_PERMISSION_LEVEL == 2) then
		curr_mode = "Limited-Public"
	elseif (FORGE_PERMISSION_LEVEL == 3) then
		curr_mode = "Public"
	else
		curr_mode = "Unrestricted"
	end
	if (level == 0) then
		change_mode = "Server-Only"
	elseif (level == 1) then
		change_mode = "Authenticated-Only"
	elseif (level == 2) then
		change_mode = "Limited-Public"
	elseif (level == 3) then
		change_mode = "Public"
	else
		change_mode = "Unrestricted"
	end
	say_all(string.format("Forge Mode was %s and is now %s", curr_mode, change_mode))
	FORGE_PERMISSION_LEVEL = level
	for i=1,16 do
		--say_all("rawr")
		--say_all(string.format("Index:%i Permisson:%s", i, forge_get_permission(i)))
		if (not forge_get_permission(i)) then
			--say_all("rawr2")
			forge_cancel_place(i)
		end
	end
	return false
end
function isMonitor(PlayerIndex)
	local IP = get_var(PlayerIndex,"$ip")
	if (PREVIOUS_DATA[IP] == nil) then
		--rprint(PlayerIndex, "NULL: Not Monitor")
		return false
	end
	if (PREVIOUS_DATA[IP][3] == -1 and PREVIOUS_DATA[IP][4])then
		--rprint(PlayerIndex, "Has already changed, and IS monitor")
		return true
	else
		--rprint(PlayerIndex, "Other: Not Monitor")
		return false
	end

end
function forge_change(PlayerIndex, toMonitor)
	if(player_present(PlayerIndex) and player_alive(PlayerIndex)) then
		if (toMonitor == nil) then
			toMonitor = not isMonitor(PlayerIndex)
		end
		--CHOSEN_BIPEDS[get_var(PlayerIndex,"$hash")] = "monitor"
		local IP = get_var(PlayerIndex,"$ip")
		--local IP = get_var(PlayerIndex,"$ip")
		PREVIOUS_DATA[IP] = {}
		local DynPlayer = get_dynamic_player(PlayerIndex)
		local x, y, z = read_vector3d(DynPlayer + 0x5c)
		local value1 = read_float(DynPlayer + 0x224)
		local value2 = read_float(DynPlayer + 0x228)
		local pitch = read_float(DynPlayer + 0x238)
		--local tmp = GetDefaultHealthShieldOfPlayer(PlayerIndex)
		PREVIOUS_DATA[IP][0] = {}
		PREVIOUS_DATA[IP][0][0]=x
		PREVIOUS_DATA[IP][0][1]=y
		PREVIOUS_DATA[IP][0][2]=z
		PREVIOUS_DATA[IP][1] = {}
		PREVIOUS_DATA[IP][1][0] = value1
		PREVIOUS_DATA[IP][1][1] = value2
		PREVIOUS_DATA[IP][1][2] = pitch
		PREVIOUS_DATA[IP][2] = getHealth(PlayerIndex)--tmp["health"]
		PREVIOUS_DATA[IP][3] = getShield(PlayerIndex)--tmp["shield"]
		PREVIOUS_DATA[IP][4] = toMonitor
		--say(PlayerIndex, "DBG::" .. getHealth(PlayerIndex) .. "::" .. getShield(PlayerIndex))
		
		--kill(PlayerIndex)
		destroy_object(read_dword(get_player(PlayerIndex) + 0x34))
		--local player = get_player(PlayerIndex)
		--write_dword(player + 0xAE,read_dword(player + 0xAE) - 1) -- reduce deaths by 1
		--write_dword(player + 0x2C,0) -- set respawn timer to respawn in 0 ticks (instant)
	end
end

function OnCommand(PlayerIndex, Command, Environment, Password)
	--say_all(os.date("%b-%d-%Y_%I-%M%p"))
	if (Environment ~= 0) then if (not forge_get_permission(PlayerIndex)) then return true end end
	if(player_present(PlayerIndex)) then
		Command = string.lower(Command)
		commandargs = {}
		for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
		if(commandargs[1] == "monitor" and not GAME_ENDED) then
			forge_change(PlayerIndex,true)
			return false
		end
		if(commandargs[1] == "spartan" and not GAME_ENDED) then
			forge_change(PlayerIndex,false)
			return false
		end
		if(commandargs[1] == "forge") then
		
			if(commandargs[2] == "<") then
				forge_menu_left(PlayerIndex)
			elseif(commandargs[2] == ">") then
				forge_menu_right(PlayerIndex)
				--rprint(PlayerIndex, "name is: " .. FORGE_MENU["1"]["name"])
			elseif(commandargs[2] == "^") then
				forge_menu_up(PlayerIndex)
			elseif(commandargs[2] == "v") then
				forge_menu_down(PlayerIndex)
			elseif(commandargs[2] == "?") then
				forge_menu_down(PlayerIndex)
				if (commandargs[3] == nil) then
					display_help(PlayerIndex, "1") 
				else
					display_help(PlayerIndex,commandargs[3])
				end
			end
			
			if(commandargs[2] == "change")then
				if(commandars[3] ~= nil)then
					if(commandargs[3] == "monitor") then
						forge_change(PlayerIndex,true)
					else
						forge_change(PlayerIndex,false)
					end
				else
					forge_change(PlayerIndex,not isMonitor(PlayerIndex))
				end
			end
			
			
			if(commandargs[2] == "save" and commandargs[3] ~= nil) then
				local IP = get_var(PlayerIndex,"$ip"):split(":")
				forge_save(PlayerIndex, IP[1], IP[2], commandargs[3], nil)
			elseif(commandargs[2] == "load" and commandargs[3] ~= nil) then
				local IP = get_var(PlayerIndex,"$ip"):split(":")
				forge_load(PlayerIndex, IP[1], IP[2], commandargs[3], nil)
			elseif(commandargs[2] == "unload" and commandargs[3] ~= nil) then
				local IP = get_var(PlayerIndex,"$ip"):split(":")
				forge_unload(IP[1], commandargs[3], nil)
			elseif (commandargs[2] == "help") then
				if (commandargs[3] == nil) then
					display_help(PlayerIndex, "1") 
				else
					display_help(PlayerIndex,commandargs[3])
				end
			elseif(commandargs[2] == "list") then
				if (commandargs[3] == "saves") then
					local IP = get_var(PlayerIndex,"$ip"):split(":")
					local page = 1
					if (commandargs[4] ~= nil) then page = tonumber(commandargs[4]) end
					if (commandargs[5] ~= nil) then IP = commandargs[5]:split(":") end
					if (IP[2] == nil) then IP[2] = 2303 end
					list_saves(PlayerIndex, IP[1], IP[2], page, nil)
				elseif (commandargs[3] == "commands") then
					if (commandargs[4] == nil) then
						display_help(PlayerIndex, "1") 
					else
						display_help(PlayerIndex,commandargs[4])
					end
				end
			elseif(commandargs[2] == "spawn" and not GAME_ENDED) then
				--if (commandargs[2] ~= nil) then
					--timer(500,"forge_spawn_obj", PlayerIndex, commandargs[2])
					forge_spawn_obj(PlayerIndex, commandargs[3])
					return false
				--end
			elseif(commandargs[2] == "place" and not GAME_ENDED) then
				if (commandargs[3] == nil) then commandargs[3] = "" end
				--timer(500,"forge_place_obj",PlayerIndex,commandargs[2])--
				forge_place_obj(PlayerIndex, commandargs[3])
				return false
			elseif(commandargs[2] == "remove" and not GAME_ENDED) then
				forge_remove(PlayerIndex, commandargs[3])
				return false
			elseif(commandargs[2] == "raise" and not GAME_ENDED) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil and tonumber(commandargs[3]) ~= nil) then
					if(PLAYER_FORGE_OBJECT_Z[PlayerIndex] ~= nil) then
						PLAYER_FORGE_OBJECT_Z[PlayerIndex] = PLAYER_FORGE_OBJECT_Z[PlayerIndex] + tonumber(commandargs[3])
					else
						PLAYER_FORGE_OBJECT_Z[PlayerIndex] = tonumber(commandargs[3])
					end
				end
				return false
			elseif(commandargs[2] == "push" and not GAME_ENDED) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil and tonumber(commandargs[3]) ~= nil) then
					if(PLAYER_FORGE_OBJECT_DIS[PlayerIndex] ~= nil) then
						PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = PLAYER_FORGE_OBJECT_DIS[PlayerIndex] + tonumber(commandargs[3])
					else
						PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = tonumber(commandargs[3])
					end
				end
				return false
			elseif((commandargs[2] == "rotate" or commandargs[2] == "rot") and not GAME_ENDED) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then

					if(commandargs[3] ~= nil and tonumber(commandargs[3]) ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] + tonumber(commandargs[3])
					end

					if(commandargs[3] ~= nil and tonumber(commandargs[4]) ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] + tonumber(commandargs[4])
					end

					if(commandargs[4] ~= nil and tonumber(commandargs[5]) ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] + tonumber(commandargs[5])
					end

				end
				return false
			elseif(commandargs[2] == "yaw" and not GAME_ENDED) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
					if(commandargs[3] ~= nil and tonumber(commandargs[3]) ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] + tonumber(commandargs[3])
					end
				end
				return false
			elseif(commandargs[2] == "pitch" and not GAME_ENDED) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
					if(commandargs[3] ~= nil and tonumber(commandargs[3]) ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] + tonumber(commandargs[3])
					end
				end
				return false
			elseif(commandargs[2] == "roll" and not GAME_ENDED) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
					if(commandargs[3] ~= nil and tonumber(commandargs[3]) ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][3] + tonumber(commandargs[3])
					end
				end
				return false
			elseif(commandargs[2] == "cancel") then
				forge_cancel_place(PlayerIndex)
				return false
			elseif(commandargs[2] == "refresh") then
				refresh()
				return false
			elseif(commandargs[2] == "undo") then
				local count = 0
				local object = nil
				for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
					count = count + 1
					if(get_var(PlayerIndex,"$ip") == v[7]) then
						--spawn_object("vehi", "forge\\destroy", v[3], v[4], v[5], 0)
						ADDITIONAL_REMOVAL[1] = v[3]
						ADDITIONAL_REMOVAL[2] = v[4]
						ADDITIONAL_REMOVAL[3] = v[5]
						object = count
					end
				end
				if(object ~= nil) then
					table.remove(SPAWNED_FORGE_OBJECTS, object)
					timer(500, "refresh")
				end
				return false
			elseif(commandargs[2] == "remove_nearest") then
				--say_all("KIRBYS HOPEFULLY DONE IT")
			local DynPlayer = get_dynamic_player(PlayerIndex)
				if DynPlayer ~= 0 then
					local loc = get_obj_location(DynPlayer, 2.0)
					--say_all(string.format("%i:%i:%i",loc[1],loc[2],(loc[3]+Z_OFFSET)))
					remove_object(loc[1], loc[2], loc[3] + Z_OFFSET)
				end
				return false
			elseif(commandargs[2] == "pickup" and not GAME_ENDED) then
				forge_pickup_obj(PlayerIndex)
				return false
			end
			return false
		end

		if(commandargs[1] == "p") then
			if(player_alive(PlayerIndex)) then
				cprint(get_dynamic_player(PlayerIndex))
			end
			return false
		end
	end
	if (PlayerIndex == 0 and Environment == 0) then
		--say_all("TEST")
		Command = string.lower(Command)
		commandargs = {}
		for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
		if(commandargs[1] == "forge") then
			if(commandargs[2] == "save" and commandargs[3] ~= nil) then
				local IP = {"127.0.0.1", "2303"}
				if (commandargs[4] ~= nil) then IP = commandargs[4]:split(":") end
				if (commandargs[5] == nil) then
					forge_save(PlayerIndex, IP[1], IP[2], commandargs[3], nil)
				else
					forge_save(PlayerIndex, IP[1], IP[2], commandargs[3], commandargs[5])
				end
			elseif(commandargs[2] == "load" and commandargs[3] ~= nil) then
				local IP = {"127.0.0.1", "2303"}
				if (commandargs[4] ~= nil) then IP = commandargs[4]:split(":") end
				if (commandargs[5] == nil) then
					forge_load(PlayerIndex, IP[1], IP[2], commandargs[3], nil)
				else
					forge_load(PlayerIndex, IP[1], IP[2], commandargs[3], commandargs[5])
				end
			elseif(commandargs[2] == "unload" and commandargs[3] ~= nil) then
				local IP = {"127.0.0.1", "2303"}
				if (commandargs[4] ~= nil) then IP = commandargs[4]:split(":") end
				if (commandargs[5] == nil) then
					forge_unload(IP[1], commandargs[3], nil)
				else
					forge_unload(IP[1], commandargs[3], commandargs[5])
				end
			elseif(commandargs[2] == "list") then
				if (commandargs[3] == "saves") then
					local IP = get_var(PlayerIndex,"$ip"):split(":")
					local page = 1
					if (commandargs[4] ~= nil) then page = tonumber(commandargs[4]) end
					if (commandargs[5] ~= nil) then IP = commandargs[5]:split(":") end
					if (IP[2] == nil) then IP[2] = 2303 end
					if (commandargs[6] == nil) then
						list_saves(PlayerIndex, IP[1], IP[2], page, nil)
					else
						list_saves(PlayerIndex, IP[1], IP[2], page, commandargs[6])
					end
				end
			elseif(commandargs[2] == "permission") then
				if (commandargs[3] == "level") then
					if (tonumber(commandargs[4]) ~= nil) then
						forge_set_permission(tonumber(commandargs[4]))
					else
						cprint(string.format("Current Forge Mode: %i", FORGE_PERMISSION_LEVEL), 6)
					end
				elseif (commandargs[3] ~= nil and commandargs[4] ~= nil and commandargs[5] ~=nil) then
					if (commandargs[3] == "auth" or commandargs[3] == "authorize") then
						if (commandargs[4] == "ip") then							
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									local IP = get_var(tonumber(commandargs[5]),"$ip"):split(":")
									forge_set_auth(IP[1], true, true)
								end
							else
								forge_set_auth(commandargs[5], true, true)
							end
						elseif( commandargs[4] == "name") then
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									forge_set_auth(get_var(tonumber(commandargs[5]), "$name"), false, true)
								end
							else
								forge_set_auth(commandargs[5], false, true)
							end
						end
					elseif (commandargs[3] == "unauth" or commandargs[3] == "unauthorize" or commandargs[3] == "deauth" or commandargs[3] =="deauthorize") then
						if (commandargs[4] == "ip") then
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									local IP = get_var(tonumber(commandargs[5]),"$ip"):split(":")
									forge_set_auth(IP[1], true, false)
								end
							else
								forge_set_auth(commandargs[5], true, false)
							end
						elseif( commandargs[4] == "name") then
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									forge_set_auth(get_var(tonumber(commandargs[5]), "$name"), false, false)
								end
							else
								forge_set_auth(commandargs[5], false, false)
							end
						end
					elseif (commandargs[3] == "ban") then
						if (commandargs[4] == "ip") then
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									local IP = get_var(tonumber(commandargs[5]),"$ip"):split(":")
									forge_set_ban(IP[1], true, true)
								end
							else
								forge_set_ban(commandargs[5], true, true)
							end
						elseif( commandargs[4] == "name") then							
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									forge_set_ban(get_var(tonumber(commandargs[5]), "$name"), false, true)
								end
							else
								forge_set_ban(commandargs[5], false, true)
							end
						end
					elseif (commandargs[3] == "unban") then
						if (commandargs[4] == "ip") then
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									local IP = get_var(tonumber(commandargs[5]),"$ip"):split(":")
									forge_set_ban(IP[1], true, false)
								end
							else
								forge_set_ban(commandargs[5], true, false)
							end
						elseif( commandargs[4] == "name") then
							if (tonumber(commandargs[5]) ~= nil) then
								if (tonumber(commandargs[5]) <= 16 and tonumber(commandargs[5]) > 0) then
									forge_set_ban(get_var(tonumber(commandargs[5]), "$name"), false, false)
								end
							else
								forge_set_ban(commandargs[5], false, false)
							end
						end
					end
				end
			elseif (commandargs[2] == "refresh")then
				refresh()
			elseif (commandargs[2] == "actionlevel") then
				if (commandargs[3] ~= nil) then
					if (commandargs[3] == "ban" or commandargs[3] == "onban") then
						if (commandargs[4] == nil) then
							print(string.format("\nCurrent Ban Action: %i", FORGE_ON_BAN_ACTION))
						else
							if (tonumber(commandargs[4]) ~= nil) then
								FORGE_ON_BAN_ACTION = tonumber(commandargs[4])
							end
						end
					elseif (commandargs[3] == "quit" or commandargs[3] == "disconnect" or commandargs[3] == "onquit" or commandargs[3] =="ondisconnect") then
						if (commandargs[4] == nil) then
							print(string.format("\nCurrent Disconnect Action: %i", FORGE_ON_DISCONNECT_ACTION))
						else
							if (tonumber(commandargs[4]) ~= nil) then
								FORGE_ON_DISCONNECT_ACTION = tonumber(commandargs[4])
							end
						end
					elseif (commandargs[3] == "gameend" or commandargs[3] == "game_end") then
						if (commandargs[4] == nil) then
							print(string.format("\nCurrent Game End Action: %i", FORGE_ON_GAME_END_ACTION))
						else
							if (tonumber(commandargs[4]) ~= nil) then
								FORGE_ON_GAME_END_ACTION = tonumber(commandargs[4])
							end
						end
					elseif (commandargs[3] == "game" or commandargs[4] == "end") then
						if (commandargs[5] == nil) then
							print(string.format("\nCurrent Game End Action: %i", FORGE_ON_GAME_END_ACTION))
						else
							if (tonumber(commandargs[5]) ~= nil) then
								FORGE_ON_GAME_END_ACTION = tonumber(commandargs[5])
							end
						end
					end
				end
			end
			return false
		end
	end
	return true
end

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function destroy(ObjectID)
	if(SPAWNED_FORGE_VEHICLES[ObjectID]~=nil) then SPAWNED_FORGE_VEHICLES[ObjectID] = nil end
	destroy_object(tonumber(ObjectID))
	return false
end
function get_nearest(x,y,z)
	local index_type = 1
	local _w = -1
	local _y = -1
	local _i = -1
	local nearest_index = nil
	local curr_index = 0
	local x_diff = 9999
	local y_diff = 9999
	local z_diff = 9999
	local x_diffb = 0
	local y_diffb = 0
	local z_diffb = 0
	for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
		curr_index = curr_index + 1
		x_diffb = x - v[3]
		y_diffb = y - v[4]
		z_diffb = z - v[5]
		if (x_diffb < 0) then
			x_diffb = x_diffb * -1
		end
		if (y_diffb < 0) then
			y_diffb = y_diffb * -1
		end
		if (z_diffb < 0) then
			z_diffb = z_diffb * -1
		end
		--say_all(string.format("Testing Index%i :: %i:%i:%i",curr_index,x_diffb,y_diffb,z_diffb))
		if ((x_diff + y_diff +z_diff) > (x_diffb + y_diffb + z_diffb)) then
			x_diff = x_diffb
			y_diff = y_diffb
			z_diff = z_diffb
			nearest_index = curr_index
		end
	end
	local i_1 = 0
	local i_2 = 0
	curr_index =0
	for _,v in pairs(LOADED_FORGE_OBJECTS) do
		i_1 = 0
		for _,w in pairs(v) do
			i_1 = i_1 + 1
			curr_index = w[3]--curr_index + 1
			if (curr_index ~= nil) then
				i_2 = 0
				for _,yy in pairs(w[2]) do
					i_2 = i_2 + 1

					local i = 0
					if(#yy == 10) then i = 1 end
					if(#yy == 10) then i = 1 end

					x_diffb = x - yy[3-i]
					y_diffb = y - yy[4-i]
					z_diffb = z - yy[5-i]
					if (x_diffb < 0) then
						x_diffb = x_diffb * -1
					end
					if (y_diffb < 0) then
						y_diffb = y_diffb * -1
					end
					if (z_diffb < 0) then
						z_diffb = z_diffb * -1
					end
					--say_all(string.format("Testing Index%i :: %i:%i:%i",curr_index,x_diffb,y_diffb,z_diffb))
					if ((x_diff + y_diff +z_diff) > (x_diffb + y_diffb + z_diffb)) then
						x_diff = x_diffb
						y_diff = y_diffb
						z_diff = z_diffb
						nearest_index = curr_index
						index_type = 2
						_w = i_1
						_y = i_2
						_i = i
					end
				end
			end
		end
	end
	return {nearest_index, x_diff, y_diff, z_diff, index_type, _w, _y, _i}
end
function remove_object(x, y, z)
	local dbg_distance = 3.0
	local results = get_nearest(x,y,z)
		--say_all(string.format("%i:%i:%i",results[2],results[3],results[4]))
	if (results[2] < dbg_distance and results[3] < dbg_distance and results[4] < dbg_distance) then
		if(results[1] ~= nil) then

			if (results[5] == 1) then
				--say_all(string.format("Removing Index %i",results[1]))
				ADDITIONAL_REMOVAL[1] = SPAWNED_FORGE_OBJECTS[results[1]][3]
				ADDITIONAL_REMOVAL[2] = SPAWNED_FORGE_OBJECTS[results[1]][4]
				ADDITIONAL_REMOVAL[3] = SPAWNED_FORGE_OBJECTS[results[1]][5]
				table.remove(SPAWNED_FORGE_OBJECTS, results[1])
				--refresh()
			else
				--say_all(string.format("Removing Index %i",results[1]))
				ADDITIONAL_REMOVAL[1] = LOADED_FORGE_OBJECTS[results[1]][results[6]][2][results[7]][3-results[8]]
				ADDITIONAL_REMOVAL[2] = LOADED_FORGE_OBJECTS[results[1]][results[6]][2][results[7]][4-results[8]]
				ADDITIONAL_REMOVAL[3] = LOADED_FORGE_OBJECTS[results[1]][results[6]][2][results[7]][5-results[8]]
				--table.remove(LOADED_FORGE_OBJECTS[results[1]][results[6]], results[7])
				table.remove(LOADED_FORGE_OBJECTS[results[1]], results[6])
				--refresh()
			end
			timer(500, "refresh")
		end
	end
end

function clear()
	--destroy_object(spawn_object("vehi", "forge\\destroy", 0, 0, 10, 0))
	--execute_command("object_create_anew_containing d")
	spawn_object("weap", "forge\\destroyer", ADDITIONAL_REMOVAL[1], ADDITIONAL_REMOVAL[2], ADDITIONAL_REMOVAL[3], 0) 
	for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
		spawn_object("weap", "forge\\destroyer", v[3], v[4], v[5], 0)
	end
	for _,v in pairs(LOADED_FORGE_OBJECTS) do
		for _,w in pairs(v) do
			for _,y in pairs(w[2]) do
				local i = 0
				if(#y == 10) then i = 1 end
				if(#y == 10) then i = 1 end
				--say_all(string.format("i:%iX:%sY:%sZ:%s",i, y[3-i], y[4-i], y[5-i]))
				spawn_object("weap", "forge\\destroyer", y[3-i], y[4-i], y[5-i], 0)
			end
		end
	end
	return false
end
function place_items()
	for _,v in pairs(SPAWNED_FORGE_OBJECTS) do
		local id = spawn_object("vehi", PREFIX .. v[2], v[3], v[4], v[5], 0)
		local object = get_object_memory(id)
		if(object ~= nil) then
			local rot = v[6]
			write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
			write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
			timer(534, "destroy", id)
		end
	end

	for _,v in pairs(LOADED_FORGE_OBJECTS) do
		for _,w in pairs(v) do
			for _,y in pairs(w[2]) do

				local i = 0
				if(#y == 10) then i = 1 end
				if(#y == 10) then i = 1 end
				
				local id = spawn_object("vehi", PREFIX .. y[2-i], y[3-i], y[4-i], y[5-i], 0)
				local object = get_object_memory(id)
				if(object ~= nil) then
					local rot = {y[6-i], y[7-i], y[8-i], y[9-i], y[10-i], y[11-i]}
					write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
					write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
					timer(534, "destroy", id)
				end
			end
		end
	end
	if (FORGE_PERMISSION_LEVEL > 0) then	--If ANY Players can run forge commands, display spawnpoints.
		display_spawnpoints()
	end
	return false
end

function destroy_splatter(ObjectID)
	destroy_object(ObjectID)
end

function spawn_splatter()
	SPLATTER_MASTER = spawn_object("vehi", "vehicles\\warthog\\mp_warthog", -174.998, -199.219, 24, 0)
	timer(33,"destroy_splatter", SPLATTER_MASTER)
end

function refresh()
	--timer(250,"clear")
	--if (SPLATTER_MASTER ~= nil) then
	--	destroy_object(SPLATTER_MASTER)
	--	SPLATTER_MASTER = nil
	--end
	timer(433,"spawn_splatter")
	timer(66,"place_items")
	----timer(433, "clear")
	return false
end
DIFF_TIME = 7
function forge_keymap_actions(PlayerIndex)
	if(isMonitor(PlayerIndex))then
		if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_modifier"]]["value"]>0.5) then
			--print("FORGE MODIFIER")
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_left"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_left"]]["repeat_timer"]==0) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] + 10
				end
			end
			
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_right"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_right"]]["repeat_timer"]==0) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][1] - 10
				end
			end
			
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_up"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_up"]]["repeat_timer"]==0) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] + 10
				end
			end
			
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_down"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_down"]]["repeat_timer"]==0) then
				if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
						PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] = PLAYER_FORGE_OBJECT_ROT[PlayerIndex][2] - 10
				end
			end
		else
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_left"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_left"]]["repeat_timer"]==0) then
				forge_menu_left(PlayerIndex)
			end
			
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_right"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_right"]]["repeat_timer"]==0) then
				forge_menu_right(PlayerIndex)
			end
			
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_up"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_up"]]["repeat_timer"]==0) then
				forge_menu_up(PlayerIndex)
			end
			
			if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_down"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_down"]]["repeat_timer"]==0) then
				forge_menu_down(PlayerIndex)
			end
		end
		if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_pickup"]]["value"]==1 and PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_pickup"]]["repeat_timer"]==0) then
			forge_pickup_obj(PlayerIndex)
		end
	else
		if(PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_monitor_key_1"]]["value"] + PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_monitor_key_2"]]["value"] > 1.5) then
			local diff = PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_monitor_key_1"]]["repeat_timer"] - PLAYER_INPUT_VALUES[PlayerIndex][PLAYER_KEYMAP[PlayerIndex]["forge_monitor_key_2"]]["repeat_timer"]
			if(diff<0) then diff = diff * -1 end
			if(diff<DIFF_TIME) then
				forge_change(PlayerIndex, true)
			end
		end
	end
end
function update_input(PlayerIndex)
	--print(PlayerIndex)
	local player = get_dynamic_player(PlayerIndex)
	PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["previous"]	=	PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["action"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["action"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["previous"]	=	PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["previous"]	=	PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["previous"]=	PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["front"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["front"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["back"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["back"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["left"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["left"]["value"]
	PLAYER_INPUT_VALUES[PlayerIndex]["right"]["previous"]		=	PLAYER_INPUT_VALUES[PlayerIndex]["right"]["value"]
	
	PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["value"] = read_bit(player + 0x208,4)
	PLAYER_INPUT_VALUES[PlayerIndex]["action"]["value"] = read_bit(player + 0x208,6)
	PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["value"] = read_bit(player + 0x208, 7) 

	PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["value"] = read_float(player + 0x490)

	local tmp = (read_byte(player + 0x2A4) == 5)
	if(tmp)then
		PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["value"] = 1
	else
		PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["value"] = 0
	end
	PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["value"] = read_bit(player + 0x208,0)
	PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["value"] = read_bit(player + 0x208,1)


	--current_nade_type = read_byte(player + 0x47E)
	--if(current_nade_type ~= previous_nade_type[PlayerIndex]) then
	--	PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"] = 1
	--else
	--	PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"] = 0
	--end
	--previous_nade_type[PlayerIndex] = current_nade_type

	--current_weapon_slot = read_byte(player + 0x47C)
	--if(current_weapon_slot ~= previous_weapon_slot[PlayerIndex]) then
	--	PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"] = 1
	--else
	--	PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"] = 0
	--end
	--previous_weapon_slot[PlayerIndex] = current_weapon_slot

	local current_anim_state = read_byte(player + 0x2A3)
	local unit_forward = read_float(player + 0x278)
    local unit_left = read_float(player + 0x27C)
	--if(current_anim_state ~= previous_anim_state[PlayerIndex]) then
	if(unit_forward > 0.1) then 
		PLAYER_INPUT_VALUES[PlayerIndex]["front"]["value"] = 1 
	else
		PLAYER_INPUT_VALUES[PlayerIndex]["front"]["value"] = 0
	end
	if(unit_forward < -0.1) then 
		PLAYER_INPUT_VALUES[PlayerIndex]["back"]["value"]= 1 
	else
		PLAYER_INPUT_VALUES[PlayerIndex]["back"]["value"] = 0
	end
	if(unit_left > 0.1) then 
		PLAYER_INPUT_VALUES[PlayerIndex]["left"]["value"] = 1 
	else
		PLAYER_INPUT_VALUES[PlayerIndex]["left"]["value"] = 0 
	end
	if(unit_left < -0.1) then 
		PLAYER_INPUT_VALUES[PlayerIndex]["right"]["value"] = 1 
	else
		PLAYER_INPUT_VALUES[PlayerIndex]["right"]["value"] = 0 
	end
	if(current_anim_state == 33) then 
		PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["value"] = 1 
	else
		PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["value"] = 0 
	end
	PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["value"] = read_word(player + 0x480)
	
	----------
	-- Update Ticks
	local timer_reset = 20
	 PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["repeat_timer"]		=	(PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["action"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["action"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["repeat_timer"]		=	(PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["repeat_timer"]		=	(PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["repeat_timer"]	=	(PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["repeat_timer"]	=	(PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["front"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["front"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["back"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["back"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["left"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["left"]["repeat_timer"]+1) % timer_reset
	 PLAYER_INPUT_VALUES[PlayerIndex]["right"]["repeat_timer"]			=	(PLAYER_INPUT_VALUES[PlayerIndex]["right"]["repeat_timer"]+1) % timer_reset
	
	----------
	-- Reset Ticks
	if(PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["previous"]	~=	PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["value"]		) then PLAYER_INPUT_VALUES[PlayerIndex]["flashlight"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["action"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["action"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["action"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["melee"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["value"]		) then PLAYER_INPUT_VALUES[PlayerIndex]["shooting"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["value"]		) then PLAYER_INPUT_VALUES[PlayerIndex]["grenade"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["crouch"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["previous"]			~=	PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["jump"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["reload"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["previous"]	~=	PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["value"]	) then PLAYER_INPUT_VALUES[PlayerIndex]["nade_switch"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["previous"]~=	PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["value"]	) then PLAYER_INPUT_VALUES[PlayerIndex]["weapon_switch"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["previous"]			~=	PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["zoom"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["front"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["front"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["front"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["back"]["previous"]			~=	PLAYER_INPUT_VALUES[PlayerIndex]["back"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["back"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["left"]["previous"]			~=	PLAYER_INPUT_VALUES[PlayerIndex]["left"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["left"]["repeat_timer"]=0 end
	if(PLAYER_INPUT_VALUES[PlayerIndex]["right"]["previous"]		~=	PLAYER_INPUT_VALUES[PlayerIndex]["right"]["value"]			) then PLAYER_INPUT_VALUES[PlayerIndex]["right"]["repeat_timer"]=0 end
	
	
end
function OnTick()
	for i=1,16 do
		if(player_present(i) and player_alive(i)) then
			update_input(i)
			forge_keymap_actions(i)
			if(PLAYER_FORGE_OBJECT[i] ~= nil) then
				object = get_object_memory(PLAYER_FORGE_OBJECT[i][2])
				if(object ~= 0) then
					local DynPlayer = get_dynamic_player(i)
					if DynPlayer ~= 0 then
						
						local distance = 2
						local raise = 1
						if(PLAYER_FORGE_OBJECT_TYPE[i]==0) then
							distance = FORGE_OBJECTS[PLAYER_FORGE_OBJECT[i][1]][2]
							raise = FORGE_OBJECTS[PLAYER_FORGE_OBJECT[i][1]][3]
						elseif(PLAYER_FORGE_OBJECT_TYPE[i]==1) then
							distance = 2
							raise = 1
						end
						if(PLAYER_FORGE_OBJECT_DIS[i] ~= nil) then
							distance = distance + PLAYER_FORGE_OBJECT_DIS[i]
						end

						local result = get_obj_location(DynPlayer, distance)

						if(PLAYER_FORGE_OBJECT_Z[i] ~= nil) then
							result[3] = result[3] + PLAYER_FORGE_OBJECT_Z[i] + Z_OFFSET + raise
						end
						write_vector3d(object + 0x5c, result[1], result[2] ,result[3])
						local rot = convert(PLAYER_FORGE_OBJECT_ROT[i][1], PLAYER_FORGE_OBJECT_ROT[i][2], PLAYER_FORGE_OBJECT_ROT[i][3])
						write_vector3d(object + 0x74, rot[1], rot[2], rot[3])
						write_vector3d(object + 0x80, rot[4], rot[5], rot[6])
					end
				else
					PLAYER_FORGE_OBJECT[i] = nil
				end
			end
			test_teleportation(i)
			local IP = get_var(i,"$ip")
			if (PREVIOUS_DATA[IP] ~= nil) then
				if (PREVIOUS_DATA[IP][2] ~= -1) then
					local DynPlayer = get_dynamic_player(i)
					write_vector3d(DynPlayer + 0x5c,PREVIOUS_DATA[IP][0][0],PREVIOUS_DATA[IP][0][1],PREVIOUS_DATA[IP][0][2])
					write_float(DynPlayer + 0x224,PREVIOUS_DATA[IP][1][0])
					write_float(DynPlayer + 0x228,PREVIOUS_DATA[IP][1][1])
					write_float(DynPlayer + 0x238, PREVIOUS_DATA[IP][1][2])
					
					--write_float(DynPlayer + 0xD8,PREVIOUS_DATA[IP][2])
					--write_float(DynPlayer + 0xDC,PREVIOUS_DATA[IP][3])
					setHealth(i,PREVIOUS_DATA[IP][2])
					setShield(i,PREVIOUS_DATA[IP][3])
					--SetDefaultHealthShieldOfPlayer(PlayerIndex,PREVIOUS_DATA[IP][2],PREVIOUS_DATA[IP][3])
					--PREVIOUS_DATA[IP] =nil
					PREVIOUS_DATA[IP][2] = -1
				end
			end
		end
	end
	forge_menu_display()
	FORGE_MENU_ANIM_TIME = (FORGE_MENU_ANIM_TIME + 1) % FORGE_MENU_ANIM_TOTAL
end

function rotate(X, Y, alpha)
	local c, s = math.cos(math.rad(alpha)), math.sin(math.rad(alpha))
	local t1, t2, t3 = X[1]*s, X[2]*s, X[3]*s
	X[1], X[2], X[3] = X[1]*c+Y[1]*s, X[2]*c+Y[2]*s, X[3]*c+Y[3]*s
	Y[1], Y[2], Y[3] = Y[1]*c-t1, Y[2]*c-t2, Y[3]*c-t3
end

function convert(Yaw, Pitch, Roll)
	local F, L, T = {1,0,0}, {0,1,0}, {0,0,1}
	rotate(F, L, Yaw)
	rotate(F, T, Pitch)
	rotate(T, L, Roll)
	return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}
end

function OnGameStart()
	safe_read(false)
	safe_write(false)
	SPAWNED_FORGE_OBJECTS = {}
	LOADED_FORGE_OBJECTS = {}
	LOADED_SAVES = {}

	GAME_ENDED = false

	local dir = "sapp\\forge\\settings\\"
	os.execute("mkdir " .. dir .. " > nul 2>&1")

	local savefile = io.open(dir .. "authorized_ips.txt", "r")
	if(savefile ~= nil) then
		local line = savefile:read()
		while(line ~= nil) do
			FORGE_PERMISSION_AUTH[1][line]=line
			line = savefile:read()
		end
		savefile:close()
	end
	local savefile = io.open(dir .. "authorized_names.txt", "r")
	if(savefile ~= nil) then
		local line = savefile:read()
		while(line ~= nil) do
			FORGE_PERMISSION_AUTH[2][line]=line
			line = savefile:read()
		end
		savefile:close()
	end

	local savefile = io.open(dir .. "banned_ips.txt", "r")
	if(savefile ~= nil) then
		local line = savefile:read()
		while(line ~= nil) do
			FORGE_PERMISSION_BAN[1][line]=line
			line = savefile:read()
		end
		savefile:close()
	end
	local savefile = io.open(dir .. "banned_names.txt", "r")
	if(savefile ~= nil) then
		local line = savefile:read()
		while(line ~= nil) do
			FORGE_PERMISSION_BAN[2][line]=line
			line = savefile:read()
		end
		savefile:close()
	end
	
	for i=1,16 do
		FORGE_MENU_SELECTED_PLYR[i] = "-1"
	end
	  
	discover_spawnpoints()
	discover_flags()
	discover_equipment()
	forge_game_start()
end

function OnGameEnd()
	GAME_ENDED = true
	
	forge_game_end()
	
	PLAYER_FORGE_OBJECT = {}
	PLAYER_FORGE_OBJECT_Z = {}
	PLAYER_FORGE_OBJECT_ROT = {}
	PLAYER_FORGE_OBJECT_DIS = {}
end

function OnPlayerJoin(PlayerIndex)
	PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
	PLAYER_INPUT_VALUES[PlayerIndex] = {
		["shooting"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["grenade"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["crouch"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["jump"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["flashlight"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["action"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["melee"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["reload"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["nade_switch"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["weapon_switch"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["zoom"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["front"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["back"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["left"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
		["right"] = {["value"]=0,["previous"]=0,["repeat_timer"]=0,},
	}
	PLAYER_KEYMAP[PlayerIndex] = {
		["forge_left"]="flashlight",
		["forge_right"]="action",
		["forge_down"]="crouch",
		["forge_up"]="jump",
		["forge_pickup"]="melee",
		["forge_modifier"]="shooting",
		["forge_spartan"]="zoom",
		["forge_monitor_key_1"]="melee",
		["forge_monitor_key_2"]="jump",
	}
	say(PlayerIndex,"Testing and Dev Server;")
	say(PlayerIndex,"type \\forge ?")
	timer(2500, "refresh")
end

function OnPlayerLeave(PlayerIndex)
	if(PLAYER_FORGE_OBJECT[PlayerIndex] ~= nil) then
		destroy_object(PLAYER_FORGE_OBJECT[PlayerIndex][2])
	end
	FORGE_MENU_SELECTED_PLYR[PlayerIndex] = nil
	PLAYER_FORGE_OBJECT[PlayerIndex] = nil
	PLAYER_FORGE_OBJECT_Z[PlayerIndex] = nil
	PLAYER_FORGE_OBJECT_ROT[PlayerIndex] = {0, 0, 0}
	PLAYER_FORGE_OBJECT_DIS[PlayerIndex] = nil
	
	forge_obj_cleanup(get_var(PlayerIndex,"$ip"), FORGE_ON_DISCONNECT_ACTION)
end

function get_yaw(m_object)
	local yaw = nil
		local value1 = read_float(m_object + 0x224)
		local value2 = read_float(m_object + 0x228)

		yaw = value1 * value2 * 90

		if(value2 <= 0 and value1 >= 0) then
			yaw = yaw * -1
			if(value2 < -0.7070707) then
				yaw = 90 - yaw
			end
		elseif(value2 <= 0 and value1 <= 0) then
			if(value2 > -0.7070707) then
				yaw = 180 - yaw
			else
				yaw = yaw + 90
			end
		elseif(value2 >= 0 and value1 <= 0) then
			yaw = yaw * -1
			if(value2 > 0.7070707) then
				yaw = 270 - yaw
			else
				yaw = yaw + 180
			end
		elseif(value2 >= 0 and value1 >= 0) then
			if(value2 < 0.7070707) then
				yaw = 360 - yaw
			else
				yaw = yaw + 270
			end
		end
	return yaw
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

function OnObjectSpawn(PlayerIndex, MapID, ParentID, ObjectID)
	--print()
	--local tmpp = "TRUE"
	--if(not(player_present(PlayerIndex))) then tmpp = "FALSE" end
	--print("\n\n\n\n" .. PlayerIndex .. " :: " .. MapID .. " : " .. ObjectID .. "\n" .. tmpp)
    if(player_present(PlayerIndex) == false) then
		local name, type = gettaginfo(MapID)
		if type == "vehi" then
			if(string.find(name,PREVIEW_PREFIX)==nil) then
				m_vehicle = get_object_memory(read_dword(get_object_memory(ObjectID) + 0x11C))
				local x,y,z = read_vector3d(m_vehicle + 0x5c)
				local yaw,pitch,roll = read_vector3d(m_vehicle + 0x74)
				local rx,ry,rz = read_vector3d(m_vehicle + 0x584)
				print("Object " .. name .. rx .. "  ::  " .. ry .. "  ::  " .. rz)
				print("            " ..  x .. "  ::  " .. y .. "  ::  " .. z)
				write_vector3d(m_vehicle + 0x584,x,y,z)
				local ownerIP = "127.0.0.1:2303"
				local obj_gametype = 1
				if(FORGE_NEW_OBJ_SPAWN_DATA[1]~=nil) then
					obj_gametype = FORGE_NEW_OBJ_SPAWN_DATA[1]
					ownerIP = FORGE_NEW_OBJ_SPAWN_DATA[2]
				end
				FORGE_NEW_OBJ_SPAWN_DATA = {nil,nil}
				SPAWNED_FORGE_VEHICLES[ObjectID]={ObjectID, name, obj_gametype, ownerIP, x,y,z,yaw,pitch,roll}
				say_all("TEST")
				write_word(m_vehicle + 0x5B0, 600) --DEBUG, TESTING
			end
		end
	else
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
		local hash = get_var(PlayerIndex,"$hash")
		local IP = get_var(PlayerIndex,"$ip")
		if (CHOSEN_BIPEDS[hash] == nil) then
			CHOSEN_BIPEDS[hash] = "default"
		end
		if(MapID == DEFAULT_BIPED) then
			for key,value in pairs(BIPEDS) do
				if(BIPED_IDS[key] == nil) then
					BIPED_IDS[key] = FindBipedTag(BIPEDS[key])
				end
			end
			if (PREVIOUS_DATA[IP] ~= nil) then
				--calc = (get_var(PlayerIndex, "$deaths") - 1)
				--str = "deaths " .. PlayerIndex .. " " .. calc
				--say_all(str .. "::" .. PlayerIndex)
				--WORKS--execute_command("deaths " .. PlayerIndex .. " -1", -1, true)
				--CHOSEN_BIPEDS[hash] = "default"
				if (PREVIOUS_DATA[IP][3] ~= -1)then
					PREVIOUS_DATA[IP][3] = -1
					if (PREVIOUS_DATA[IP][4]) then
						return true,BIPED_IDS["monitor"]
					else	
						return true,BIPED_IDS[CHOSEN_BIPEDS[hash]]
					end
				else 
					PREVIOUS_DATA[IP][4] = false
					return true,BIPED_IDS[CHOSEN_BIPEDS[hash]]
				end
			else
				return true,BIPED_IDS[CHOSEN_BIPEDS[hash]]
			end
		end
	end
    return true
end
function getHealth(PlayerIndex)
	return read_float(get_dynamic_player(PlayerIndex) + 0xE0)
end
function setHealth(PlayerIndex, newValue)
	write_float(get_dynamic_player(PlayerIndex) + 0xE0, newValue)
end
function getShield(PlayerIndex)
	return read_float(get_dynamic_player(PlayerIndex) + 0xE0 +0x4)
end
function setShield(PlayerIndex, newValue)
	write_float(get_dynamic_player(PlayerIndex) + 0xDC,newValue)--0xE0 + 0x4, newValue)
end

function OnScriptUnload() 
end
function gettaginfo(MapID)
	local tag = lookup_tag(MapID)
	return tag ~= 0 and read_string(read_dword(tag + 0x10)), read_string(tag)
end
-- 	Custom Bipeds by 002, modified by giraffe and aLTis

--	This is a modified version of 002's/giraffe's script;
--	Players who join or enter command /armor will be spawned inside an "armor room" where they will be able to choose their armor;
--	There also is an optional server message that will be displayed on player's console while he is choosing armor. The message can be customised;'
--	It is recommended to start a new game after the script has been loaded
--	Please read whole configuration if you want to change something and you have no idea what is lua;
--	The script should ONLY be used on BigassV3!


-- Configuration

--	Show console messages while choosing armor (scroll down to ConsoleMessages in order to customize them)
show_console_messages = true

--	Let players choose armor right when they join the server
choose_armor_on_join = 	true

--	Let players choose armor after using a command
choose_armor_on_command = true
switch_command = "armor" --	What is the command that players need to enter (must be lowercase)
command_success = "You will be able to choose your armor next time you spawn."
command_fail = "You are already choosing an armor you silly billy :P"

-- Message spam. These are sent to player when he is dead
spam_messages = true
spam_message = "You can change your armor using /armor command"
spam_frequency = 3 -- Lower means more frequent

--	Force armor choice. Set it to true if you don't want your girlfriend to choose her clothes forever ^^
force_armor_choice = false
choice_time = 600--	Time in ticks that player is allowed to spend in the armor room. Don't set this too high.
kick_message = "You spent too much time choosing your armor."



-- Enter only the bipeds that you want to use in your server. Don't forget to change both of these and biped_count.
BIPEDS = {
    ["default"] = "bourrin\\halo reach\\spartan\\male\\mp masterchief",
	["female"] = "bourrin\\halo reach\\spartan\\female\\female",
    ["marine"] = "bourrin\\halo reach\\marine-to-spartan\\mp test",
    ["odst"] = "bourrin\\halo reach\\spartan\\male\\odst",
	["specops"] = "bourrin\\halo reach\\spartan\\male\\spec_ops",
	["altis"] = "bourrin\\halo reach\\spartan\\male\\haunted",
    ["sbb"] = "bourrin\\halo reach\\spartan\\male\\117",
}
-- I know that I could have merged these two but whatever :P
BIPED_NUMBER = {
	[0] = "default",
	[1] = "female",
	[2] = "marine",
	[3] = "odst",
	[4] = "specops",
	[5] = "altis",
	[6] = "sbb",
}
biped_count = 7

--	Coordinates of the first armor room and stuff (don't touch these unless you know what you're doing!)
x = -107.275
y = -153.042
z = -111.217 + 0.285
rot = 0
distance_between_rooms = (-1.5)

--	Delay before spawning room vehicle in ms (should not be changed)
room_delay_command = 0
room_delay_player_join = 800

--	Console message delay (in ticks)
console_delay = 60

-- End of Configuration




api_version = "1.9.0.0"

BIPED_IDS = {}
CHOSEN_BIPEDS = {}--	armor that player actually chose
ROOM_VEHICLES = {}--	ID of the armor room
BIPED_VEHICLES = {}--	ID of the armor that is being previewed
BIPED_WANTED = {}--		Which armor player is choosing
DELAY_COUNTER = {}--	Used to delay console messages
WANTS_TO_SWITCH = {}--	Changes to 1 if player used a command and to 2 if just joined
DEFAULT_BIPED = nil
game_ended = false

function OnScriptLoad()
    register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
    register_callback(cb['EVENT_GAME_START'],"OnGameStart")
    register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
    register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
    register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	register_callback(cb['EVENT_VEHICLE_EXIT'], "OnVehicleExit")
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
	for i=1,16 do
		DELAY_COUNTER[i] = 1
	end
	if(choose_armor_on_command == false) then
		unregister_callback(cb['EVENT_COMMAND'])
	end
end

function ClearConsole(i)--					Clears player's console from any messages
	for j=1,30 do
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
				DestroyRoom(i)
				say(i, kick_message)
			end
		end
		
		ClearConsole(i)
		rprint(i, "                    Welcome to the Official Bigass server!")
		rprint(i, "                    Please don't leak betas e.e")
		rprint(i, "                    Have fun and stuff I guess")
		rprint(i, "                    VIVA LA MEXICO :V")
		rprint(i, "                    <insert server messages here>")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i,"                    Choose your armor using W and S keys")
		rprint(i,"                    Press E to confirm your selection")
		rprint(i, " ")
		rprint(i, " ")
		rprint(i, " ")
	end
end

function MessageSpam(PlayerIndex)
	if(rand(1,spam_frequency) == 1) then
		say(PlayerIndex, spam_message)
	end
end

function OnTick() --						This part checks when armor room has moved forward or backwards
	local coord
	
	for i=1,16 do
		if(ROOM_VEHICLES[i]~=nil and player_alive(i) == true) then
			if(show_console_messages) then
				ConsoleMessages(i)
			end
			
			
			coord = tonumber(get_var(i, "$x"))
			if(coord < (x - 0.005)) then--			Room moves back
				BIPED_WANTED[i] = BIPED_WANTED[i] + 1
				if(BIPED_WANTED[i] > (biped_count - 1)) then
					BIPED_WANTED[i] = 0
				end
				ChooseBiped(i)
				execute_command("t \""..i.."\" \"".. (x+0.004) .."\" \"".. (y + distance_between_rooms * (i - 1)) .."\" \"".. z .."\"")
			end
			
			if(coord > (x + 0.007)) then--			Room moves forward
				BIPED_WANTED[i] = BIPED_WANTED[i] - 1
				if(BIPED_WANTED[i] < 0) then
					BIPED_WANTED[i] = (biped_count - 1)
				end
				ChooseBiped(i)
				execute_command("t \""..i.."\" \"".. (x-0.003) .."\" \"".. (y + distance_between_rooms * (i - 1)) .."\" \"".. z .."\"")
			end
			
		end
	end
end

function ChooseBiped(PlayerIndex)--			This only chooses preview biped inside the armor room
	if(BIPED_VEHICLES[PlayerIndex]~=nil) then
		destroy_object(BIPED_VEHICLES[PlayerIndex])
	end
	BIPED_VEHICLES[PlayerIndex] = spawn_object("vehi ", BIPEDS[BIPED_NUMBER[BIPED_WANTED[PlayerIndex]]], (x-0.4), (y + distance_between_rooms * (PlayerIndex - 1)), (z-0.01), rot)
end

function SpawnRoom(PlayerIndex)--			This spawns the armor room vehicle and makes the player enter it
	PlayerIndex = tonumber(PlayerIndex)
	if(ROOM_VEHICLES[PlayerIndex]~=nil or player_alive(PlayerIndex)==false) then return false end
	NewVehiID = spawn_object("vehi", "altis\\scenery\\armor_room\\armor_room", x, (y + distance_between_rooms * (PlayerIndex - 1)), (z + 0.05), rot)
	if(NewVehiID == nil or NewVehiID == 4294967295) then return false end
	RemoveWeapons(PlayerIndex)
	ChooseBiped(PlayerIndex)
	ROOM_VEHICLES[PlayerIndex] = NewVehiID
	enter_vehicle(ROOM_VEHICLES[PlayerIndex], PlayerIndex, 0)
	execute_command("t \""..PlayerIndex.."\" \"".. x .."\" \"".. (y + distance_between_rooms * (PlayerIndex - 1)) .."\" \"".. z .."\"")
end

function DestroyRoom(PlayerIndex)--			Destroys the room vehicle IF it exists
	if(ROOM_VEHICLES[tonumber(PlayerIndex)] ~= nil)then
		destroy_object(ROOM_VEHICLES[tonumber(PlayerIndex)])
		ROOM_VEHICLES[tonumber(PlayerIndex)] = nil
	end
	if(BIPED_VEHICLES[PlayerIndex] ~= nil) then
		destroy_object(BIPED_VEHICLES[PlayerIndex])
		BIPED_VEHICLES[PlayerIndex] = nil
	end
end

function OnPlayerJoin(PlayerIndex)--		Resets some values and calls SpawnRoom after a delay
	if(choose_armor_on_join) then
		WANTS_TO_SWITCH[PlayerIndex] = 2
	end
	CHOSEN_BIPEDS[tonumber(PlayerIndex)] = nil
	BIPED_WANTED[PlayerIndex] = 0
end

function OnPlayerLeave(PlayerIndex)--		Resets CHOSEN_BIPEDS and destroys room/biped vehicles if they exist
	PlayerIndex = tonumber(PlayerIndex)
    CHOSEN_BIPEDS[PlayerIndex] = nil
	WANTS_TO_SWITCH[PlayerIndex] = 0
	DestroyRoom(PlayerIndex)
end

function OnPlayerDeath(PlayerIndex)--		If player died while inside the room, the room and biped vehicles are destroyed
	PlayerIndex = tonumber(PlayerIndex)
	DestroyRoom(PlayerIndex)
	if(spam_messages) then
		timer(1500, "MessageSpam", PlayerIndex)
	end
end

function OnVehicleExit(PlayerIndex)--		If player leaves the armor room vehicle (confirms armor selection) then vehicles are destroyed and 
	--										actual CHOSEN_BIPEDS is changed to wanted armor
	if(BIPED_VEHICLES[PlayerIndex]~=nil) then
		CHOSEN_BIPEDS[PlayerIndex] = BIPED_NUMBER[BIPED_WANTED[PlayerIndex]]
		if(show_console_messages) then
			ClearConsole(PlayerIndex)
		end
	end
	DestroyRoom(PlayerIndex)
end

function OnGameStart()
    game_ended = false
end

function OnGameEnd()--						Resets most of the values to prevent issues when the next game starts
    game_ended = true
    CHOSEN_BIPEDS = {}
    BIPED_IDS = {}
	ROOM_VEHICLES = {}
	BIPED_VEHICLES = {}
    DEFAULT_BIPED = nil
end

function OnCommand(PlayerIndex,Command)--	Command that players will need to enter in order to choose armor the next time they spawn
	if(choose_armor_on_command) then
		Command = string.lower(Command)
		if(Command == switch_command) then
			if(ROOM_VEHICLES[PlayerIndex] == nil) then
				say(PlayerIndex, command_success)
				WANTS_TO_SWITCH[PlayerIndex] = 1
				return false
			else
				say(PlayerIndex, command_fail)
				return false
			end
		end
	end
	return true
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
	DELAY_COUNTER[PlayerIndex] = 1
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

function OnScriptUnload()--		Destroys armor and biped vehicles when script is unloaded to prevent duplicates and players staying inside the script room
	for i=1, 16 do
		if(BIPED_VEHICLES[i]~=nil) then
			destroy_object(BIPED_VEHICLES[i])
		end
		if(ROOM_VEHICLES[i]~=nil) then
			destroy_object(ROOM_VEHICLES[i])
		end
	end
 end
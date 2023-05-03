-- Talk like yer port to starboard by Kavawuvi! ^v^

-- Edited by aLTis

pirate_command = "pirate" -- Admins can write this command and player index to make that player talk like a pirate
disable_command = "pirate_disable" -- Use this command and player index to remove pirate thing from that player
admin_level = 4 -- admin level required to execute those commands

DICTIONARY = {
    ["noob"] = "landlubber",
    ["noobs"] = "landlubbers",
    ["puto"] = "landlubber",
    ["putos"] = "landlubbers",
    ["ja"] = "arr",
    ["jaja"] = "yar har",
    ["jajaja"] = "yar har har",
    ["jajajaja"] = "argh! yar har har",
    ["ha"] = "arr",
    ["haha"] = "yar har",
    ["hahaha"] = "yar har har",
    ["hahahaha"] = "argh! yar har har",
    ["there"] = "thar",
    ["halomaps"] = "haloscourge",
    ["ns"] = "ye be fishin' for kills like a real sailor",
    ["nice"] = "ye be a good lad",
    ["help"] = "ABANDON SHIP!",
    ["wtf"] = "'tis a kraken approachin' from starboard",
    ["fuck"] = "SHIVER ME TIMBERS!",
    ["shit"] = "poopdeck",
    ["ass"] = "stern",
    ["nigger"] = "black matey",
    ["cracker"] = "white matey",
    ["beaner"] = "mexican matey",
    ["trash"] = "rubbish",
    ["kill"] = "kill",
    ["kills"] = "kills",
    ["death"] = "death",
    ["deaths"] = "deaths",
    ["warthog"] = "puma",
    ["banshee"] = "siren",
    ["scorpion"] = "kraken",
    ["tank"] = "kraken",
    ["ghost"] = "lil' siren",
    ["turret"] = "cannon",
    ["aimbot"] = "skulldugg'ry",
    ["wallhack"] = "skulldugg'ry",
    ["bot"] = "skulldugg'ry",
    ["cheat"] = "shifty",
    ["sniper"] = "marksman",
    ["rocket"] = "cannon",
    ["cheating"] = "hornswaggle",
    ["hello"] = "ahoy",
    ["left"] = "port",
    ["front"] = "bow",
    ["right"] = "starboard",
    ["back"] = "stern",
    ["from"] = "from",
    ["no"] = "nay",
    ["yes"] = "aye",
    ["nah"] = "nay",
    ["yeah"] = "aye",
    ["si"] = "aye",
    ["gg"] = "that be some smooth sailin' lads",
    ["change"] = "come about",
    ["team"] = "alliance",
    ["teams"] = "alliances",
    ["server"] = "ocean",
    ["good"] = "fine",
    ["game"] = "sailin'",
    ["rules"] = "pirate code",
    ["up"] = "sky",
    ["health"] = "essence",
    ["shield"] = "zapper",
    ["os"] = "overzapper",
    ["overshield"] = "overzapper",
    ["nade"] = "boom rock",
    ["nades"] = "boom rocks",
    ["pirate"] = "pirate",
    ["ban"] = "banish",
    ["banned"] = "banished",
    ["mute"] = "squelch",
    ["muted"] = "squelched",
    ["kick"] = "kick",
    ["kicked"] = "kicked",
    ["1v1"] = "duel",
    ["me"] = "me",
    ["you"] = "ye",
    ["kick"] = "kick",
    ["kicked"] = "kicked",
    ["kavawuvi"] = "scarlet sea bird",
    ["fucked"] = "rammed",
    ["bottle"] = "bottle",
    ["of"] = "o'",
    ["rum"] = "rum",
    ["sucks"] = "be a disgrace",
    ["suck"] = "be a disgrace",
    ["talk"] = "lingo",
    ["flag"] = "flag",
    ["base"] = "ship",
    ["red"] = "pirate",
    ["blue"] = "navy",
    ["cap"] = "plunder",
    ["get"] = "plunder",
    ["take"] = "plunder",
    ["the"] = "the",
    --["*"] = "yar"
}

PIRATES = {}

api_version = "1.10.0.0"
function OnScriptLoad()
    register_callback(cb['EVENT_CHAT'],"OnChat")
    register_callback(cb['EVENT_ECHO'],"OnEcho")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
end
temp = ""
function OnEcho(PlayerIndex,Message)
    temp = Message
end
function OnScriptUnload() end
function OnCommand(PlayerIndex,Command)
	if tonumber(get_var(PlayerIndex, "$lvl")) < admin_level then
		return true
	end
	Command = string.lower(Command)
	local WORDS = {}
	for word in string.gmatch(Command, "([^".." ".."]+)") do 
		table.insert(WORDS, word)
	end
	
	if WORDS[1] == pirate_command then
		local target_player_index = WORDS[2]
		if target_player_index ~= nil then
			target_player_index = tonumber(target_player_index)
			local target_player_name = get_var(target_player_index, "$name")
			if target_player_name ~= "" then
				PIRATES[target_player_name] = true
				say(PlayerIndex, target_player_name.." was turned into a pirate!")
				return false
			else
				say(PlayerIndex, "Player "..target_player_index.." not found")
				return false
			end
		else
			say(PlayerIndex, "Incorrect usage! Type \""..pirate_command.." player_index\"")
			return false
		end
	elseif WORDS[1] == disable_command then
		local target_player_index = WORDS[2]
		if target_player_index ~= nil then
			target_player_index = tonumber(target_player_index)
			local target_player_name = get_var(target_player_index, "$name")
			if target_player_name ~= "" then
				PIRATES[target_player_name] = nil
				say(PlayerIndex, target_player_name.." is no longer a pirate")
				return false
			else
				say(PlayerIndex, "Player "..target_player_index.." not found")
				return false
			end
		else
			say(PlayerIndex, "Incorrect usage! Type \""..pirate_command.." player_index\"")
			return false
		end
	end
	return true
end
function OnChat(PlayerIndex,Message,Channel)
	local name = get_var(PlayerIndex, "$name")
	if name ~= nil and PIRATES[name] == true then
		
		if Channel ~= 0 then return end
		local ml = Message:lower()
		local tm = ""
		if string.byte(ml) == 47 then return true end
		for word in string.gmatch(ml, "([^".." ".."]+)") do 
			local m = DICTIONARY[word]
			if m then tm = tm .. m .. " " else tm = tm .. word .. " " end
		end
		execute_command("msg_prefix",PlayerIndex,true)
		x = temp:sub(17)
		execute_command("msg_prefix \"\"",PlayerIndex,true)
		say_all(get_var(PlayerIndex,"$name") .. ": " .. tm)
		execute_command("msg_prefix \"" .. x .. "\"",PlayerIndex)
		return false
	end
end
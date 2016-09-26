--	Private Messages by aLTis (altis94@gmail.com)

--	This script lets players send private messages
--	By default, messages are sent via command /pm <name> <message>
--	Only a part of player's name may be entered
--	For example, /pm altis hi will be sent to {XG}aLTis
--	Recipients can quickly reply to senders
--	By default, /r <message> is used to reply

--	CONFIG

	--	Command used to send private messages
	pm_command = "pm"
	--	Command used to reply to PMs
	reply_command = "r"

	--	What will be written before the PM
	pm_prefix = "PM~"--<name>: <message>
	
--	END OF CONFIG

api_version = "1.9.0.0"

PLAYERS = {}

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
end

function OnScriptUnload()
end

function OnPlayerJoin(PlayerIndex)
	for i = 1,16 do
		if(PLAYERS[i] == PlayerIndex) then
			PLAYERS[i] = nil
		end
	end
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	commandargs = {}
	for w in Command:gmatch("%S+") do commandargs[#commandargs + 1] = w end
	
	if(commandargs[1] == pm_command) then
		if(commandargs[2] == nil or commandargs[3] == nil) then
			say(PlayerIndex, "Incorrect arguments! Command usage: /"..pm_command.." <player name> <string>")
			return false
		end
		
		local message = commandargs[3]
		for i = 4,30 do
			if(commandargs[i] == nil) then
				break
			end
			message = (message.." "..commandargs[i])
		end
		
		local name_wanted = string.lower(commandargs[2])
		for i = 1,16 do
			if(player_present(i) and i ~= PlayerIndex) then
				local player_name = string.lower(get_var(i, "$name"))
				if(string.find(player_name, name_wanted) ~= nil) then
					execute_command("msg_prefix \"\"")
					say(i, "Write /"..reply_command.." to reply!")
					say(i, pm_prefix..get_var(PlayerIndex, "$name")..": "..message)
					say(PlayerIndex, "PM sent to "..get_var(i, "$name"))
					PLAYERS[i] = PlayerIndex
					execute_command("msg_prefix \"** SAPP ** \"")
					return false
				end
			end
		end
		say(PlayerIndex, "Could not find player "..name_wanted)
		return false
	end
	
	if(commandargs[1] == reply_command) then
		local sender_id = PLAYERS[PlayerIndex]
		if(commandargs[2] == nil) then
			if(sender_id ~= nil and player_present(sender_id)) then
				say(PlayerIndex, "The last person to send you a PM was "..get_var(sender_id, "$name"))
			else
				say(PlayerIndex, "You have nobody to reply to")
			end
			return false
		end
		
		local message = commandargs[2]
		for i = 3,30 do
			if(commandargs[i] == nil) then
				break
			end
			message = (message.." "..commandargs[i])
		end
		
		if(sender_id ~= nil and player_present(sender_id)) then
			execute_command("msg_prefix \"\"")
			say(sender_id, "Write /"..reply_command.." to reply!")
			say(sender_id, pm_prefix..get_var(PlayerIndex, "$name").."> "..message)
			say(PlayerIndex, "PM sent to "..get_var(sender_id, "$name"))
			PLAYERS[sender_id] = PlayerIndex
			execute_command("msg_prefix \"** SAPP ** \"")
		else
			say(PlayerIndex, "You have nobody to reply to")
		end
		return false
	end
	return true
end
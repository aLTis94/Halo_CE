--	Weapon drop by aLTis (altis94@gmail.com)

	-- Command that will drop player's weapon
		weapon_drop_command = {"drop", "d","tirar","soltar"}
		
api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
end

function OnScriptUnload()
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	for i = 1,4 do	--	drop
		if(Command == weapon_drop_command[i]) then
			drop_weapon(PlayerIndex)
			return false
		end
	end
	return true
end
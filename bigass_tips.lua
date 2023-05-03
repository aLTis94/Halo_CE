-- Sends some tips for players
--CONFIG
	message_rate = 7 -- how often to send in minutes
--END OF CONFIG

api_version = "1.9.0.0"

timer = 0

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnScriptUnload() end

function OnTick()
	timer = timer + 1
	if timer > message_rate*1800 then
		timer = 0
		if string.find(get_var(0, "$map"), "bigass_") then
			execute_command("msg_prefix \"TIP: \"")
			local number = rand(1,9)
			if(number == 1) then
				say_all("You can press X to activate an armor ability!")
			elseif(number == 2) then
				say_all("You can press Q in Falcon to lock your height!")
			elseif(number == 3) then
				say_all("Type /armor if you want to change your armor and loadout!")
			elseif(number == 4) then
				say_all("Use /pm to send private messages to other players!")
			elseif(number == 5) then
				say_all("You can press X to activate an armor ability!")
			elseif(number == 6) then
				say_all("Tripmine colors change based on teams.")
			elseif(number == 7) then
				say_all("EMP ability only damages enemies.")
			elseif(number == 8) then
				say_all("Double tap W to sprint!")
			end
			execute_command("msg_prefix \"** SAPP ** \"")
		end
	end
end
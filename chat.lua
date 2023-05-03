--	Random chat bullshit

api_version = "1.12.0.0"

function OnScriptLoad()
	register_callback(cb["EVENT_CHAT"],"OnChat")
end

function OnScriptUnload() end

function OnGameStart()
end

function OnChat(PlayerIndex, message)
	message = string.lower(message)
	if(message == "uwu") then
		SayDelayed("DON'T UWU. $350 PENALTY")
	end
	if(string.find(message, "8ball ") ~= nil) then
		local number = rand(1,10)
		if(number == 1) then
			SayDelayed("Yes!")
		end
		if(number == 2) then
			SayDelayed("No.")
		end
		if(number == 3) then
			SayDelayed("My sources say yes")
		end
		if(number == 4) then
			SayDelayed("Maybe")
		end
		if(number == 5) then
			SayDelayed("Don't count on it")
		end
		if(number == 6) then
			SayDelayed("Sure buddy")
		end
		if(number == 7) then
			SayDelayed("For sure")
		end
		if(number == 8) then
			SayDelayed("Wouldn't think about it")
		end
		if(number == 9) then
			SayDelayed("That's a secret...")
		end
		if(number == 10) then
			SayDelayed("What is life?")
		end
	elseif(message == "neko") then
		SayDelayed(":3")
	elseif(message == "owo") then
		SayDelayed("What's this?")
	elseif(message == ">:u") then
		SayDelayed("RAGE MAPPING TEAM >:u")
	elseif(message == "o_0") then
		SayDelayed("0_o")
	elseif(string.find(message, "is this loss") ~= nil) then
		SayDelayed("Yes.")
	elseif(message == "give me your pants") then
		SayDelayed("Now give me your other pants!")
	elseif(string.find(message, "secret") ~= nil) then
		SayDelayed("Where? :o")
	elseif(string.find(message, "tits") ~= nil) then
		SayDelayed("( . Y . )")
	elseif(string.find(message, "crawling") ~= nil) then
		SayDelayed("THESE WOUNDS THEY WILL NOT HEAL")
	elseif(string.find(message, "fear is how i") ~= nil) then
		SayDelayed("CONFUSING WHAT IS REAL")
	elseif(string.find(message, "wake up") ~= nil) then
		SayDelayed("WAKE ME UP INSIDE")
	elseif(string.find(message, "wake me") ~= nil) then
		SayDelayed("CAN'T WAKE UP")
	elseif(string.find(message, "machine broke") ~= nil) then
		SayDelayed("Understandable have a nice day.")
	elseif(string.find(message, "anime") ~= nil) then
		SayDelayed("Anime is for nerds.")
	elseif(string.find(message, "just monika") ~= nil) then
		SayDelayed(":m3:")
		SayDelayed(":m2:")
		SayDelayed(":m1:")
	elseif(string.find(message, "nigger") ~= nil) then
		SayDelayed(":demonetized:DEMONETIZED!:demonetized:")
	end
	return true
end

function SayDelayed(message)
	timer(1, "say_all", message)
end
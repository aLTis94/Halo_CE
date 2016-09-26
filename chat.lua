--	Random chat bullshit

api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb["EVENT_CHAT"],"OnChat")
end

function OnGameStart()
end

function OnChat(PlayerIndex, message)
	message = string.lower(message)
	if(message == "uwu") then
		say_all("DON'T UWU. $350 PENALTY")
		if(PLAYERS[PlayerIndex]["score"] - 350 > 0) then
			PLAYERS[PlayerIndex]["score"] = PLAYERS[PlayerIndex]["score"] - 350
		else
			PLAYERS[PlayerIndex]["score"] = 0
		end
	end
	if(message == "neko") then
		say_all(":3")
	end
	if(message == "owo") then
		say_all("What's that?")
	end
	if(message == ">:u") then
		say_all("RAGE MAPPING TEAM >:u")
	end
	if(message == "o_0") then
		say_all("0_o")
	end
	if(message == "give me your pants") then
		say_all("Now give me your other pants!")
	end
	if(string.find(message, "secret") ~= nil) then
		say_all("Where? :o")
	end
	if(string.find(message, "girl") ~= nil) then
		say_all("aLTis is watching...")
	end
	if(string.find(message, "tits") ~= nil) then
		say_all("( . Y . )")
	end
	if(string.find(message, "8ball") ~= nil) then
		local number = rand(1,10)
		if(number == 1) then
			say_all("Yes!")
		end
		if(number == 2) then
			say_all("No.")
		end
		if(number == 3) then
			say_all("My sources say yes")
		end
		if(number == 4) then
			say_all("Maybe")
		end
		if(number == 5) then
			say_all("Don't count on it")
		end
		if(number == 6) then
			say_all("Sure buddy")
		end
		if(number == 7) then
			say_all("For sure")
		end
		if(number == 8) then
			say_all("Wouldn't think about it")
		end
		if(number == 9) then
			say_all("That's a secret...")
		end
		if(number == 10) then
			say_all("What is life?")
		end
	end
	if(string.find(message, "crawling") ~= nil) then
		say_all("THESE WOUNDS THEY WILL NOT HEAL")
	end
	if(string.find(message, "fear is how i") ~= nil) then
		say_all("CONFUSING WHAT IS REAL")
	end
	if(string.find(message, "wake up") ~= nil) then
		say_all("WAKE ME UP INSIDE")
	end
	if(string.find(message, "wake me") ~= nil) then
		say_all("CAN'T WAKE UP")
	end
	return true
end
--This script will show Star Wars intro thing in the console

--	config

initial_delay = 4500
delay = 500
half_delay = 250

--	end of config


api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
end

function Scroll(PlayerIndex)
	rprint(PlayerIndex, " ")
end

function OnCommand(PlayerIndex,Command)
	Command = string.lower(Command)
	if(Command == "starwars") then
		rprint(PlayerIndex, "                                       A long time ago in a galaxy far, far away....")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		rprint(PlayerIndex, "|n")
		timer(initial_delay, "one", PlayerIndex)
		return false
	else
		return true
	end
end

function one(PlayerIndex)
	rprint(PlayerIndex, "                                                                   STAR WARS")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	rprint(PlayerIndex, "|n")
	timer(initial_delay, "two", PlayerIndex)
end

function two(PlayerIndex)
	rprint(PlayerIndex, "                                                    It is a period of civil war.")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "three", PlayerIndex)
end

function three(PlayerIndex)
	rprint(PlayerIndex, "                                                    Rebel spaceships, striking")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "four", PlayerIndex)
end

function four(PlayerIndex)
	rprint(PlayerIndex, "                                                    from a hidden base, have")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "five", PlayerIndex)
end

function five(PlayerIndex)
	rprint(PlayerIndex, "                                                    won their first victory")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "six", PlayerIndex)
end

function six(PlayerIndex)
	rprint(PlayerIndex, "                                                    against the evil Galactic")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "seven", PlayerIndex)
end

function seven(PlayerIndex)
	rprint(PlayerIndex, "                                                    Empire")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "Scroll", PlayerIndex)
	timer(delay+half_delay, "eight", PlayerIndex)
end

function eight(PlayerIndex)
	rprint(PlayerIndex, "                                                    During the battle, Rebel")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "nine", PlayerIndex)
end

function nine(PlayerIndex)
	rprint(PlayerIndex, "                                                    spies managed to steal")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "ten", PlayerIndex)
end

function ten(PlayerIndex)
	rprint(PlayerIndex, "                                                    secret plans to the Empire's")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "eleven", PlayerIndex)
end

function eleven(PlayerIndex)
	rprint(PlayerIndex, "                                                    ultimate weapon, the")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "twelve", PlayerIndex)
end

function twelve(PlayerIndex)
	rprint(PlayerIndex, "                                                    DEATH STAR, an armored")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "thirteen", PlayerIndex)
end

function thirteen(PlayerIndex)
	rprint(PlayerIndex, "                                                    space station with enough")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "fourteen", PlayerIndex)
end

function fourteen(PlayerIndex)
	rprint(PlayerIndex, "                                                    power to destroy an entire")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "fifteen", PlayerIndex)
end

function fifteen(PlayerIndex)
	rprint(PlayerIndex, "                                                    planet.")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "Scroll", PlayerIndex)
	timer(delay+half_delay, "sixteen", PlayerIndex)
end

function sixteen(PlayerIndex)
	rprint(PlayerIndex, "                                                    Pursued by the Empire's")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "seventeen", PlayerIndex)
end

function seventeen(PlayerIndex)
	rprint(PlayerIndex, "                                                    sinister agents, Princess")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "eightteen", PlayerIndex)
end

function eightteen(PlayerIndex)
	rprint(PlayerIndex, "                                                    Leia races home aboard her")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "nineteen", PlayerIndex)
end

function nineteen(PlayerIndex)
	rprint(PlayerIndex, "                                                    starship, custodian of the")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "twenty", PlayerIndex)
end

function twenty(PlayerIndex)
	rprint(PlayerIndex, "                                                    stolen plans that can save")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "twentyone", PlayerIndex)
end

function twentyone(PlayerIndex)
	rprint(PlayerIndex, "                                                    her people and restore")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "twentytwo", PlayerIndex)
end

function twentytwo(PlayerIndex)
	rprint(PlayerIndex, "                                                    freedom to the galaxy....")
	timer(half_delay, "Scroll", PlayerIndex)
	timer(delay, "Scroll", PlayerIndex)
	timer(delay+half_delay, "Scroll", PlayerIndex)
	timer(delay+delay, "Scroll", PlayerIndex)
	timer(delay+delay+half_delay, "Scroll", PlayerIndex)
	timer(delay+delay+delay, "Scroll", PlayerIndex)
	timer(delay+delay+delay+half_delay, "Scroll", PlayerIndex)
	timer(delay+delay+delay+delay, "Scroll", PlayerIndex)
	timer(delay+delay+delay+delay+half_delay, "Scroll", PlayerIndex)
	timer(delay+delay+delay+delay+delay, "Scroll", PlayerIndex)
	timer(delay+delay+delay+delay+delay+half_delay, "Scroll", PlayerIndex)
end

function OnScriptUnload()	end
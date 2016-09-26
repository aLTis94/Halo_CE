--	This script will detect which weapon killed a player

--	Configuration

--	MetaIDs of damage effects
DAMAGES = {
	[0] = 3928885434,--	frag grenade
	[1] = 3927509157,-- trip mine
	[2] = 3874030965,--	falcon missile
	[3] = 3819831866,--	capsule
	[4] = 3923970159,-- rocket launcher
	[5] = 3874030965,--	rocket hog
	[6] = 3938847056,-- tank???
}

--	How long "LAST_DAMAGE" lasts in ms
damage_time = 200

--	End Of Configuration

LAST_DAMAGE = {}

api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	register_callback(cb['EVENT_DAMAGE_APPLICATION'], "OnDamage")
end

function OnPlayerDeath(PlayerIndex, KilledIndex)
	if(LAST_DAMAGE[PlayerIndex] ~= nil) then
		say_all("Got killed by an explosion!")
	end
end

function ResetDamage(PlayerIndex)
	LAST_DAMAGE[tonumber(PlayerIndex)] = nil
end

function OnDamage(PlayerIndex, Causer, MetaID)
	for i=0,6 do
		if(MetaID == DAMAGES[i]) then
			--say_all("EXPLOSIONS!")
			LAST_DAMAGE[PlayerIndex] = 1
			timer(damage_time, "ResetDamage", PlayerIndex)
		end
	end
end

function OnScriptUnload() end
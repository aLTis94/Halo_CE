-- Jetpack v0.13 By =GG=DLBon

-- How fast should a player fly up? Default = 0.19
flyspeed = 0.22

-- Do you want to inform players about jetpack on join? Default = true
informjetpack = true

-- Messages
informjetpack_msg = "Hold the spacebar to fly for a short moment!"
prepare_msg = "Jetpack is activating... Keep holding the spacebar."
fly_msg = "Jetpack activated! Keep holding the spacebar untill landed."

-- Do not change anything below

api_version = "1.9.0.0"

nofall = 0

ELSEACTION = {
	["else"] = 0,
}

nowfly = {}
lastfly = {}
activation = {}
invehicle = {}
nofall = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
	register_callback(cb['EVENT_JOIN'],"JoinMSGFly")
	register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamageApplication")
	register_callback(cb['EVENT_GAME_START'],"FallID")
end

function OnPlayerSpawn(PlayerIndex)
	nowfly[PlayerIndex] = 0
	lastfly[PlayerIndex] = 0
	activation[PlayerIndex] = 30
end

function JoinMSGFly(PlayerIndex)
	if(informjetpack == true) then
		rprint(PlayerIndex,"|c" .. informjetpack_msg)
	end
end

function OnTick()
	
	for i=1,16 do
		if(player_alive(i)) then
			local player = get_dynamic_player(i)

			invehicle[i] = read_bit(player + 0x11C,0)
			nowfly[i] = read_bit(player + 0x208,1)
			
			if(nowfly[i] == 1 and activation[i] == 30 and invehicle[i] == 1) then
				activation[i] = activation[i] - 1
			else
				ELSEACTION["else"] = 0
			end
			
			if(nowfly[i] == 1) then
			else
				activation[i] = 30
			end
			
			if(activation[i] ~= 30 and activation[i] ~= 0) then
			activation[i] = activation[i] - 1
			end
			
			if(activation[i] == 20) then
				rprint(i,"|c" .. prepare_msg)
			end
			
			if(activation[i] == 1) then
				rprint(i,"|c" .. fly_msg)
			end
			
			if(activation[i] == 0) then
				execute_command("m " .. i .. " 0 0 " .. flyspeed)
				nofall[i] = 1
			end
			-- Player
			
			lastfly[i] = nowfly[i]
			
			if(activation[i] ~= 0) then
				nofall[i] = 0
			end
	
		end
	end
end

function OnDamageApplication(PlayerIndex, CauserIndex, MetaID, Damage, HitString, Backtap)
	if MetaID == falling_damage then
		if(nofall[PlayerIndex] == 1) then
			return true, 0
		else
			return true, Damage
		end	
	elseif MetaID == distance_damage then
		if(nofall[PlayerIndex] == 1) then
			return true, 0
		else
			return true, Damage
		end	
	end
end		

function FallID()
	distance_damage = read_dword(lookup_tag("jpt!", "globals\\distance") + 12)
	falling_damage = read_dword(lookup_tag("jpt!", "globals\\falling") + 12)
end	

function OnScriptUnload() end
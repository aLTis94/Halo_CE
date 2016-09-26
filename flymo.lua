--	Vehicle Flymo v0.3 By =GG=DLBon

api_version = "1.9.0.0"

ELSEACTION = {
	["else"] = 0,
}

currentjump = {}
previousjump = {}
vid = {}
permi = {}
wantedpos = {}
nowpos = {}
tpam = {}
timy = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
end

function OnPlayerSpawn(PlayerIndex)
	currentjump[PlayerIndex] = 0
	previousjump[PlayerIndex] = 0
	timy[PlayerIndex] = 900
end

function OnTick()
	
	for i=1,16 do
		if(player_alive(i)) then
			local player = get_dynamic_player(i)

	
			vid[i] = read_bit(player + 0x11C,0)
			currentjump[i] = read_bit(player + 0x208,1)
			
			
			-- Player
			if(currentjump[i] ~= previousjump[i] and currentjump[i] == 1 and vid[i] ~= 1) then
				execute_command("cheat_jetpack true")
				local x,y,z = 0
				local vehicle_objectid = read_dword(player + 0x11C)
				local vehicle_object = get_object_memory(vehicle_objectid)
				local x,y,z = read_vector3d(vehicle_object + 0x5C)
                wantedpos[i] = z
				timy[i] = 0
			else
				ELSEACTION["else"] = 0
			end
			
			if(currentjump[i] == 1 and vid[i] ~= 1) then
				execute_command("cheat_jetpack true")
				
				wantedpos[i] = wantedpos[i] + 0.07
				
				local x,y,z = 0
				local vehicle_objectid = read_dword(player + 0x11C)
				local vehicle_object = get_object_memory(vehicle_objectid)
				local x,y,z = read_vector3d(vehicle_object + 0x5C)
                nowpos[i] = z
				
				tpam[i]= wantedpos[i] - nowpos[i]
				
				permi[i] = 1
			else
				ELSEACTION["else"] = 0
				permi[i] = 0
			end
			
			if(permi[i] == 1) then
				execute_command("m " .. i .. " 0 0 " .. tpam[i])
			else
				ELSEACTION["else"] = 0
			end
			
			if(currentjump[i] == previousjump[i] and currentjump[i] == 0 and vid[i] ~= 1 and timy[i] <= 20) then
				execute_command("cheat_jetpack true")
				execute_command("m " .. i .. " 0 0 0.06")
				timy[i] = timy[i] + 1
			else
				ELSEACTION["else"] = 0
			end
			-- Player
			
			
			previousjump[i] = currentjump[i]

			
			
		end
	end
end

function OnScriptUnload() end
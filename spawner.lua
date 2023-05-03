
api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnScriptUnload()
end

PLAYERS = {}
for i=1,16 do
	PLAYERS[i] = {}
end

function OnCommand(i,Command,Environment,Password)
	if Command == "bush" then
		if player_alive(i) then
			local x, y, z = read_vector3d(get_dynamic_player(i) + 0x5C)
			execute_command("lua_call fake_forge SpawnForgeObject 6 altis\\scenery\\bush\\bush "..x.." "..y.." "..z.." 0 0 0 0 0")
		end
		return false
	end
	return true
end

function OnTick()
	for i=1,16 do
		if player_alive(i) then
			PLAYERS[i].x, PLAYERS[i].y, PLAYERS[i].z = read_vector3d(get_dynamic_player(i) + 0x5C)
		end
	end
end

function OnPlayerDeath(i)
	if PLAYERS[i].x ~= nil then
		execute_command("lua_call fake_forge SpawnForgeObject 6 altis\\scenery\\tomato\\tomato "..PLAYERS[i].x.." "..PLAYERS[i].y.." "..PLAYERS[i].z.." 0 0 0 0 0")
	end
end

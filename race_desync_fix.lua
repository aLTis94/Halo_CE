--This script changes how vehicles are synchronized on race gametype.

--CONFIG

	update_rate = 13 -- how often vehicle position is updated. Lower values will sync vehicles better but look more jittery
	
--END OF CONFIG

api_version = "1.12.0.0"

local physics_were_changed = false

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	OnGameStart()
end

function OnScriptUnload()
	SetPhysics(false)
end

function OnGameStart()
	if get_var(0, "$gt") == "race" then
		SetPhysics(true)
	else
		SetPhysics(false)
	end
end

function SetPhysics(changed)
	if changed then
		--rprint(1, "changed")
		physics_were_changed = true
		execute_command("use_new_vehicle_update_scheme 0")
		execute_command("vehicle_incremental_rate "..update_rate)
	elseif physics_were_changed then
		--rprint(1, "default")
		physics_were_changed = false
		execute_command("use_new_vehicle_update_scheme 1")
		execute_command("vehicle_incremental_rate 4")
	end
end
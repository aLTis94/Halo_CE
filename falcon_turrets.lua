-- This script SHOULD give player a weapon when he enters a passenger seat

api_version = "1.9.0.0"

function OnScriptLoad()
    register_callback(cb['EVENT_VEHICLE_ENTER'], "OnVehicleEnter")
end

function OnVehicleEnter(PlayerIndex, SeatIndex)
	local weapon = spawn_object("weap bourrin\\weapons\\badass rocket launcher\\bourrinrl")
	assign_weapon(PlayerIndex, SeatIndex)
	sv_say("yo")
end

function OnScriptUnload() end
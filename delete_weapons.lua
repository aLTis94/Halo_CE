
api_version = "1.9.0.0"


function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnScriptUnload() 
end

function OnTick()
	for i=1,16 do
		execute_command("wdel "..i)
	end
end
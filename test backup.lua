--CONFIG
	ai_second_message_rate = 5 -- how often second message is sent (currently relies on the value below, too lazy to fix)
	ai_update_rate = 90 -- how often ai position gets updated
--END OF CONFIG

-- what if I synced the client side AI instead of the real biped? :thinking:



api_version = "1.9.0.0"

ai_timer = 0
AI = {}
object_table_ptr= nil

function OnScriptLoad()
	execute_command("ai_kill aaa")
	for i=1,5 do
		execute_command("ai_place aaa")
	end
	object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D")
	register_callback(cb['EVENT_TICK'],"OnTick")
end

function OnScriptUnload()
end

function OnTick()
	ai_timer = ai_timer + 1
	if ai_timer >= ai_update_rate then
		ai_timer = 0
	end
	local object_table = read_dword(read_dword(object_table_ptr + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
        local object = read_dword(first_object + i * 0xC + 0x8)
		
        if object ~= 0 and object ~= 0xFFFFFFFF then
			local object_type = read_word(object + 0xB4)
			if object_type == 0 then
				if read_dword(object + 0x218) == 0xFFFFFFFF and read_dword(object + 0x1F4) ~= 0xFFFFFFFF then
					if read_float(object + 0xE0) > 0 then
						if AI[object] == nil then
							AI[object] = {}
						end
						AI[object].x = read_float(object + 0x5C)
						AI[object].y = read_float(object + 0x60)
						AI[object].z = read_float(object + 0x64)
						AI[object].x_vel = read_float(object + 0x68)
						AI[object].y_vel = read_float(object + 0x6C)
						AI[object].z_vel = read_float(object + 0x70)
						AI[object].forward = read_float(object + 0x278)
						AI[object].left = read_float(object + 0x27C)
						AI[object].up = read_float(object + 0x280)
						AI[object].unit = read_byte(object + 0x2A0)
						AI[object].anim = read_word(object + 0xD0)
						AI[object].anim_timer = read_word(object + 0xD2)
						AI[object].x_aim = read_float(object + 0x23C)
						AI[object].y_aim = read_float(object + 0x240)
						AI[object].z_aim = read_float(object + 0x244)
						AI[object].rot1 = read_float(object + 0x74)
						AI[object].rot2 = read_float(object + 0x78)
						AI[object].rot3 = read_float(object + 0x7C)
						
						AI[object].firing = read_float(object + 0x490)
						AI[object].test2 = read_word(object + 0x388)
						AI[object].test3 = read_word(object + 0x38A)
						AI[object].test4 = read_word(object + 0x39E)
						AI[object].test5 = read_word(object + 0x390)
						
						AI[object].seat = read_word(object + 0x120)
						if read_dword(object + 0x11C) ~= 0xFFFFFFFF then
							AI[object].vehicle = 1
						else
							AI[object].vehicle = 0
						end
						
						--rprint(1, " ")
						--rprint(1, " ")
						--rprint(1, read_float(object + 0x224))
						--rprint(1, read_float(object + 0x23C))
						--rprint(1, read_float(object + 0x254))
						--rprint(1, read_float(object + 0x260))
						
						if ai_timer == 1 then
							rprint(1, string.format("ailoc %d %.4f %.4f %.4f", object, AI[object].x,AI[object].y,AI[object].z))
						end
						
						rprint(1, string.format("aiinfo %d %d %.4f %.4f %.4f %d %d %.3f %.3f %.3f %d",object,AI[object].unit,AI[object].x_vel,AI[object].y_vel,AI[object].z_vel, AI[object].anim, AI[object].anim_timer, AI[object].x_aim, AI[object].y_aim, AI[object].z_aim, AI[object].firing))
						
						if ai_timer%ai_second_message_rate == 0 then
							--rprint(1, "aiupd_timer "..ai_timer)
							rprint(1, string.format("aiupd %d %.3f %.3f %.3f %d %d",object, AI[object].rot1, AI[object].rot2, AI[object].rot3, AI[object].vehicle, AI[object].seat))
						end
						--rprint(1, "aiinfo "..object.." "..x.." "..y.." "..z)
						
						--rprint(1, "fw "..forward.." lft "..left)
					else
						if AI[object] ~= nil then
							AI[object] = nil
							rprint(1, "sending dead message")
							rprint(1, "aidead "..object)
						end
					end
				end
			end
		end
	end
end

function GetName(DynamicObject)--	Gets directory of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end
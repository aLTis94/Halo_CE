-- ai sync script (not finished)

--CONFIG
	ai_second_message_rate = 5 -- how often second message is sent (currently relies on the value below, too lazy to fix)
	ai_update_rate = 90 -- how often ai position gets updated
	
	-- The handshake will be this prefix followed by a random number.
	-- I recommend having your prefix start with |n so it won't display on clients that don't have Chimera.
	handshake_prefix = "|nbghandshake"
--END OF CONFIG

-- TODO:
-- split longer code in functions, like getting biped info and sending update messages etc

api_version = "1.9.0.0"

has_chimera = {}
attempts = {}

ai_timer = 0
game_started = 1
AI = {}
object_table_ptr= nil

function OnScriptLoad()
	add_var("has_chimera", 4)
	for i=1,16 do
		set_var(i, "$has_chimera", 0)
	end
	--execute_command("ai_kill aaa")
	--for i=1,5 do
	--	execute_command("ai_place aaa")
	--end
	--register_callback(cb['EVENT_TICK'],"OnTick")
	register_callback(cb['EVENT_GAME_START'],"OnGameStart")
	register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
	register_callback(cb['EVENT_COMMAND'],"OnCommand")
    register_callback(cb['EVENT_ALIVE'],"OnAlive")
    register_callback(cb['EVENT_LEAVE'],"OnLeave")
	register_callback(cb['EVENT_JOIN'],"OnJoin")
	rcon_password_expected = tostring(rand(0,99999999))
end

function OnScriptUnload()
	for i=1,16 do
		rprint(i, "|nbgreload")
	end
end

function OnGameStart()
	game_started = 1
	AI = {}
end

function OnGameEnd()
	game_started = 0
	AI = nil
end

function OnTick()
	if game_started == 0 then
		return
	end
	ai_timer = ai_timer + 1
	if ai_timer >= ai_update_rate then
		ai_timer = 0
	end
	local object_table = read_dword(read_dword(0x4011A2 + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
	
    for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
        local object = read_dword(first_object + i * 0xC + 0x8)
		
        if object ~= 0 and object ~= 0xFFFFFFFF then
			local object_type = read_word(object + 0xB4)
			if object_type == 0 then
				local name = GetName(object)
				if string.sub(name, 1,2) ~= "ai" and read_dword(object + 0x218) == 0xFFFFFFFF and read_dword(object + 0x1F4) ~= 0xFFFFFFFF then
					--rprint(1, read_float(object + 0xE0))
					if read_float(object + 0xE0) > 0 then
						if AI[ID] == nil then
							AI[ID] = {}
						end
						AI[ID].object = object
						AI[ID].name = GetName(object)
						AI[ID].damager = GetDamagerID(ID)
						AI[ID].x = read_float(object + 0x5C)
						AI[ID].y = read_float(object + 0x60)
						AI[ID].z = read_float(object + 0x64)
						AI[ID].x_vel = read_float(object + 0x68)
						AI[ID].y_vel = read_float(object + 0x6C)
						AI[ID].z_vel = read_float(object + 0x70)
						AI[ID].forward = read_float(object + 0x278)
						AI[ID].left = read_float(object + 0x27C)
						AI[ID].up = read_float(object + 0x280)
						AI[ID].unit = read_byte(object + 0x2A0)
						AI[ID].anim = read_word(object + 0xD0)
						AI[ID].anim_timer = read_word(object + 0xD2)
						AI[ID].x_aim = read_float(object + 0x23C)
						AI[ID].y_aim = read_float(object + 0x240)
						AI[ID].z_aim = read_float(object + 0x244)
						AI[ID].rot1 = read_float(object + 0x74)
						AI[ID].rot2 = read_float(object + 0x78)
						AI[ID].rot3 = read_float(object + 0x7C)
						
						AI[ID].firing = read_float(object + 0x490)
						AI[ID].test2 = read_word(object + 0x2B0)
						--if AI[ID].firing == 1 and AI[ID].test2 < 1 then
						--	AI[ID].firing = 1
						--else
						--	AI[ID].firing = 0
						--end
						
						local weapon_id = read_dword(object + 0x118)
						local weapon = get_object_memory(weapon_id)
						if weapon ~= 0 then
							AI[ID].test3 = read_float(weapon + 0x234)
							AI[ID].firing = 0
							if AI[ID].test3 > 0 then
								AI[ID].firing = 1
							end
							AI[ID].weapon_name = GetName(weapon)
							--rprint(1, AI[ID].firing)
						end
						
						AI[ID].seat = read_word(object + 0x120)
						if read_dword(object + 0x11C) ~= 0xFFFFFFFF then
							AI[ID].vehicle = 1
						else
							AI[ID].vehicle = 0
						end
						
						--rprint(1, " ")
						--rprint(1, " ")
						--rprint(1, read_float(object + 0x224))
						--rprint(1, read_float(object + 0x23C))
						--rprint(1, read_float(object + 0x254))
						--rprint(1, read_float(object + 0x260))
						
						SendUpdate(ID)
					end
				end
			end
		end
	end
	
	for ID,info in pairs (AI) do
		if get_object_memory(ID) == 0 or read_float(get_object_memory(ID) + 0xE0) < 0 then
			if AI[ID].damager == nil then
				AI[ID].damager = GetDamagerID(ID)
			end
			if AI[ID].damager ~= nil then
				local PlayerIndex = tonumber(AI[ID].damager)
				local name = nil
				for word in string.gmatch(AI[ID].name, "([^".."\\".."]+)") do 
					name = word
				end
				say(PlayerIndex, "You killed "..name)
				execute_command("kills "..PlayerIndex.." "..get_var(PlayerIndex, "$kills")+1)
			end
			AI[ID] = nil
			for i=1,16 do
				if has_chimera[i] then
					--rprint(1, "sending dead message, health "..read_float(get_object_memory(ID) + 0xE0))
					rprint(i, "aidead~"..ID)
				end
			end
		end
	end
end

function SendUpdate(ID)
	for i=1,16 do
		if has_chimera[i] then
			if ai_timer == 1 then
				if AI[ID].weapon_name ~= nil then
					rprint(i, string.format("ailoc~%d~%.4f~%.4f~%.4f~%s", ID, AI[ID].x,AI[ID].y,AI[ID].z, AI[ID].weapon_name))
				else
					rprint(i, string.format("ailoc~%d~%.4f~%.4f~%.4f", ID, AI[ID].x,AI[ID].y,AI[ID].z))
				end
			end
			
			rprint(i, string.format("aiinfo~%d~%d~%.4f~%.4f~%.4f~%d~%d~%.3f~%.3f~%.3f~%d",ID,AI[ID].unit,AI[ID].x_vel,AI[ID].y_vel,AI[ID].z_vel, AI[ID].anim, AI[ID].anim_timer, AI[ID].x_aim, AI[ID].y_aim, AI[ID].z_aim, AI[ID].firing))
			
			if ai_timer%ai_second_message_rate == 0 then
				--rprint(1, "aiupd_timer "..ai_timer)
				rprint(i, string.format("aiupd~%d~%.3f~%.3f~%.3f~%d~%d",ID, AI[ID].rot1, AI[ID].rot2, AI[ID].rot3, AI[ID].vehicle, AI[ID].seat))
			end
			--rprint(1, "aiinfo "..object.." "..x.." "..y.." "..z)
			
			--rprint(1, "fw "..forward.." lft "..left)
		end
	end
end

function GetDamagerID(ID)-- From 002; Checks which player killed the biped
	local biped_object = get_object_memory(ID)
	if biped_object ~= 0 then
		for k=0,3 do
			local struct = biped_object + 0x430 + 0x10 * k
			local damager_pid = read_word(struct + 0xC)
			if(damager_pid ~= 0xFFFF) then
				return to_player_index(damager_pid)
			end
		end
	end
end

function GetName(DynamicObject)--	Gets directory of the object
	return read_string(read_dword(read_word(DynamicObject) * 32 + 0x40440038))
end

-- Attempt to see if the player has Chimera installed, giving up after 4 times to avoid spamming.
function OnAlive(PlayerIndex)
    if has_chimera[PlayerIndex] ~= true then
        if attempts[PlayerIndex] == nil then
            attempts[PlayerIndex] = 0
        else
            attempts[PlayerIndex] = attempts[PlayerIndex] + 1
        end
        if attempts[PlayerIndex] < 4 then
            rprint(PlayerIndex,handshake_prefix .. rcon_password_expected)
        end
    end
end

function OnJoin(PlayerIndex)
	timer(5000, "CheckChimera", PlayerIndex)
end

function CheckChimera(PlayerIndex)
	PlayerIndex = tonumber(PlayerIndex)
	if has_chimera[PlayerIndex] ~= true then
		say(PlayerIndex, "You don't have Chimera installed")
		say(PlayerIndex, "Get latest version of Chimera for extra features!")
	end
end

function OnLeave(PlayerIndex)
    has_chimera[PlayerIndex] = nil
    attempts[PlayerIndex] = nil
	set_var(PlayerIndex, "$has_chimera", 0)
end

function OnCommand(PlayerIndex,Command,Environment,Password)
    if Environment == 1 and Password == rcon_password_expected then
        if Command == "acknowledged" then
            --rprint(PlayerIndex,handshake_prefix .. "you have chimera yay")
            has_chimera[PlayerIndex] = true
			set_var(PlayerIndex, "$has_chimera", 1)
        end
        return false
    end
end
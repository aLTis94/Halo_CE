--	This script should detect what keys player presses. Made by aLTis
--	The script itself only prints what you press in the console

api_version = "1.9.0.0"

ACTIONS = {
	["shooting"] = 0,
	["grenade"] = 0,
	["crouch"] = 0,
	["jump"] = 0,
	["flashlight"] = 0,
	["action"] = 0,
	["melee"] = 0,
	["reload"] = 0,
	["nade_switch"] = 0,
	["weapon_switch"] = 0,
	["zoom"] = 0,
	["front"] = 0,
	["back"] = 0,
	["left"] = 0,
	["right"] = 0,
}

previous_zoom_level = {}
previous_anim_state = {}
previous_crouch_state = {}
previous_jump_state = {}
previous_nade_type = {}
previous_weapon_slot = {}
previous_reload_state = {}
previous_shooting_state = {}
test_state = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
end

function OnPlayerSpawn(PlayerIndex)
	previous_zoom_level[PlayerIndex] = 65535
	previous_anim_state[PlayerIndex] = nil
	previous_crouch_state[PlayerIndex] = 0
	previous_jump_state[PlayerIndex] = 0
	previous_nade_type[PlayerIndex] = 0
	previous_weapon_slot[PlayerIndex] = 0
	previous_reload_state[PlayerIndex] = 0
	previous_shooting_state[PlayerIndex] = 0
end

function OnTick()
	local current_zoom_level
	local current_anim_state
	local current_crouch_state
	local current_jump_state
	local current_nade_type
	local current_weapon_slot
	local current_reload_state
	local current_shooting_state
	
	for i=1,16 do
		if(player_alive(i)) then
			local player = get_dynamic_player(i)
			
			ACTIONS["flashlight"] = read_bit(player + 0x208,4)
			ACTIONS["action"] = read_bit(player + 0x208,6)
			ACTIONS["melee"] = read_bit(player + 0x208, 7) 
			
			current_shooting_state = read_float(player + 0x490)
			if(current_shooting_state ~= previous_shooting_state[i] and current_shooting_state == 1) then
				ACTIONS["shooting"] = 1
			else
				ACTIONS["shooting"] = 0
			end
			previous_shooting_state[i] = current_shooting_state
			
			current_reload_state = read_byte(player + 0x2A4)
			if(previous_reload_state[i] ~= current_reload_state and current_reload_state == 5) then
				ACTIONS["reload"] = 1
			else
				ACTIONS["reload"] = 0
			end
			previous_reload_state[i] = current_reload_state
			
			current_crouch_state = read_bit(player + 0x208,0)
			if(current_crouch_state ~= previous_crouch_state[i] and current_crouch_state == 1) then
				ACTIONS["crouch"] = 1
			else
				ACTIONS["crouch"] = 0
			end
			previous_crouch_state[i] = current_crouch_state
			
			current_jump_state = read_bit(player + 0x208,1)
			if(current_jump_state ~= previous_jump_state[i] and current_jump_state == 1) then
				ACTIONS["jump"] = 1
			else
				ACTIONS["jump"] = 0
			end
			previous_jump_state[i] = current_jump_state
			
			current_nade_type = read_byte(player + 0x47E)
			if(current_nade_type ~= previous_nade_type[i]) then
				ACTIONS["nade_switch"] = 1
			else
				ACTIONS["nade_switch"] = 0
			end
			previous_nade_type[i] = current_nade_type
			
			current_weapon_slot = read_byte(player + 0x47C)
			if(current_weapon_slot ~= previous_weapon_slot[i]) then
				ACTIONS["weapon_switch"] = 1
			else
				ACTIONS["weapon_switch"] = 0
			end
			previous_weapon_slot[i] = current_weapon_slot
			
			local current_anim_state = read_byte(player + 0x2A3)
			if(current_anim_state ~= previous_anim_state[i]) then
				if(current_anim_state == 4) then ACTIONS["front"] = 1 end
				if(current_anim_state == 5) then ACTIONS["back"] = 1 end
				if(current_anim_state == 6) then ACTIONS["left"] = 1 end
				if(current_anim_state == 7) then ACTIONS["right"] = 1 end
				if(current_anim_state == 33) then ACTIONS["grenade"] = 1 end
			else
				ACTIONS["front"] = 0
				ACTIONS["back"] = 0
				ACTIONS["left"] = 0
				ACTIONS["right"] = 0
				ACTIONS["grenade"] = 0
			end
			previous_anim_state[i] = current_anim_state
			
			current_zoom_level = read_word(player + 0x480)
			if(current_zoom_level ~= previous_zoom_level[i]) then
				ACTIONS["zoom"] = 1
			else
				ACTIONS["zoom"] = 0
			end
			previous_zoom_level[i] = current_zoom_level

			
			
			for key,value in pairs(ACTIONS) do
				if(value ~= 0) then
					rprint(i, key) --	~CALL A FUNCTION OR SOMETHING HERE~
				end
			end
			
		end
	end
end

function VehicleTest(PlayerIndex)
	if(test_state[PlayerIndex] == 1) then
		test_state[PlayerIndex] = 0
		rprint(PlayerIndex, "off")
	else
		rprint(PlayerIndex, "on")
		local player_object = get_dynamic_player(PlayerIndex)
		local vehicle_objectid = read_dword(player_object + 0x11C)
		if(tonumber(vehicle_objectid) ~= 0xFFFFFFFF) then
			local vehicle_object = get_object_memory(vehicle_objectid)
			local driver = read_dword(vehicle_object + 0x324)
			rprint(PlayerIndex, driver)
			write_dword(vehicle_object + 0x324, 0xFFFFFFFF)
		end
		test_state[PlayerIndex] = 1
	end
end

function OnScriptUnload() end
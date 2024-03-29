--	Vehicle boosting script by aLTis (altis94@gmail.com)
--	Hold ctrl to boost while in a vehicle
--	Please, for the love of god, don't use this script on all vehicles on your crappy bigass servers. Thank you.

-- CONFIG
	boost_heat = 3 -- how fast it heats
	boost_overheat_treshold = 100	--	when heat reaches this level, it overheats
	boost_cooldown_treshold = 50	--	when overheated and heat reaches this level, it's no longer overheated
	
	show_boost_level = true -- show stuff on console
	
	--	vehicle tag and boost rate
	VEHICLES = {
		["vehicles\\warthog\\mp_warthog"] = 0.03,
		["vehicles\\rwarthog\\rwarthog"] = 0.03,
	}
	
	FLYING_VEHICLES = {
		["vehicles\\ghost\\ghost_mp"] = 0.022,
	}
--CONFIG


api_version = "1.10.1.0"

COOLDOWNS = {}
OVERHEATED = {}

function OnScriptLoad()
	register_callback(cb["EVENT_TICK"],"OnTick")
	for i=1,16 do
		COOLDOWNS[i] = 0
		OVERHEATED[i] = 0
	end
end

function OnScriptUnload()
end

function OnTick()
	for i=1,16 do
		if player_alive(i) and OVERHEATED[i] == 0 then
			local player = get_dynamic_player(i)
			local vehicle = get_object_memory(read_dword(player + 0x11C))
			local seat = read_word(player + 0x2F0)
			if vehicle ~= 0 and seat == 0 then
				if show_boost_level and OVERHEATED[i] == 1 then
					ClearConsole(i)
					rprint(i, "|rBoost "..COOLDOWNS[i])
				end
				local crouch_key = read_bit(vehicle + 0x4CC, 2)
				local flipped_over = read_bit(vehicle + 0x8B, 7)
				local on_ground = read_bit(vehicle + 0x10, 1)
				local name = read_string(read_dword(read_word(vehicle) * 32 + 0x40440038))
				local boost_rate = VEHICLES[name]
				if boost_rate == nil then
					boost_rate = FLYING_VEHICLES[name]
					on_ground = 1
				end
				if boost_rate ~= nil and crouch_key == 1 and flipped_over == 0 then
					local x_vel, y_vel, z_vel = read_vector3d(vehicle + 0x68)
					if on_ground == 1 and x_vel ~= 0 and y_vel ~= 0 then
						local pitch, yaw, roll = read_vector3d(vehicle + 0x74)
						local x, y, z = read_vector3d(vehicle + 0x5C)
						write_float(vehicle + 0x68, x_vel + boost_rate*pitch)
						write_float(vehicle + 0x6C, y_vel + boost_rate*yaw)
						execute_command("t "..i.." "..x.." "..y.." "..z)
						COOLDOWNS[i] = COOLDOWNS[i] + boost_heat
						if COOLDOWNS[i] >= boost_overheat_treshold then
							OVERHEATED[i] = 1
						end
					end
				end
			end
		end
		if COOLDOWNS[i] > 0 then
			COOLDOWNS[i] = COOLDOWNS[i] - 1
		end
		if COOLDOWNS[i] <= boost_cooldown_treshold then
			OVERHEATED[i] = 0
		end
	end
end	

function ClearConsole(i)--	Clears player's console from any messages
	for j=1,30 do
		rprint(i," ")
	end
end
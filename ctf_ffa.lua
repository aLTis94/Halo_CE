--Script made by Chalwk and modified by aLTis

api_version = "1.12.0.0"

local console_color = "|nc7FB3D5"

local CaptureTheFlag = {
	
	gametypes = {
		["ctf_ffa"] = true,
	},
	
	-- -- Radius (in world units) a flag spawn must be away from capture point
	flag_spawn_range = 9,
	
	flag_runner_speed = 1.3,

    -- Radius (in world units) a player must be from the capture point to score:
    trigger_radius = 1.1,

    -- Time (in seconds) the flag will respawn if it is dropped
    respawn_time = 15,

    -- Points awarded on capture:
    score_on_capture = 1,
	
	-- Points to win
	score_limit = 3,
	
	-- Should kills change score?
	score_on_kill = false,

    -- Enable this if you are using my Rank System script
    rank_system_support = true,
    rank_script = "Rank System",

	move_compass_ticks = true,
	
    flag_object = { "weap", "weapons\\flag\\flag" },

    on_respawn = "The flag respawned!",
    on_capture = "%name% captured a flag and has [%captures%] captures",
    on_respawn_trigger = "The flag was dropped and will respawn in %time% seconds",

    on_flag_pickup = {
        [1] = { "%name% has the flag!"},
        [2] = {
            "Return the flag to a base to score.",
        }
    },
}

local gsub = string.gsub
local time_scale = 1 / 30
local sqrt, floor = math.sqrt, math.floor

function CaptureTheFlag:Init()
    if (get_var(0, "$gt") ~= "n/a") then
        if self.gametypes[get_var(0, "$mode")] ~= nil then
			
            self.game_started = true
            self.players, self.flag = { }, { }
            for i = 1, 16 do
                if player_present(i) then
                    self:InitPlayer(i, false)
                end
            end

			execute_command("scorelimit "..self.score_limit)
			
			self:GetFlagLocation()
            self:SpawnFlag()

			local object_table_ptr = sig_scan("8B0D????????8B513425FFFF00008D") 
			self.object_table = read_dword(read_dword(object_table_ptr + 2))
			
            register_callback(cb["EVENT_TICK"], "OnTick")
            register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
            register_callback(cb["EVENT_JOIN"], "OnPlayerConnect")
            register_callback(cb["EVENT_LEAVE"], "OnPlayerDisconnect")
			register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
        else
            unregister_callback(cb["EVENT_TICK"])
            unregister_callback(cb["EVENT_JOIN"])
            unregister_callback(cb["EVENT_LEAVE"])
            unregister_callback(cb["EVENT_GAME_END"])
			unregister_callback(cb['EVENT_DIE'])
        end
    end
end

function PlayAnnouncerSound(sound_id)
	local server_announcer_address = 0x5BDE00
	write_dword(server_announcer_address + 0x8, 1) -- time until first sound in the queue stops playing
	write_dword(server_announcer_address + 0x14, sound_id) -- second sound ID in the queue (from globals multiplayer information > sounds)
	write_dword(server_announcer_address + 0x1C, 1) -- second sound in the queue will play
	write_dword(server_announcer_address + 0x50, 2) -- announcer sound queue
end

function OnScriptLoad()
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    CaptureTheFlag:Init()
end

function OnScriptUnload()
	if CaptureTheFlag.object_table == nil then return end
    local object_count = read_word(CaptureTheFlag.object_table + 0x2E)
    local first_object = read_dword(CaptureTheFlag.object_table + 0x34)
    for i=0,object_count-1 do
		local ID = read_word(first_object + i*12)*0x10000 + i
        local object = read_dword(first_object + i * 0xC + 0x8)
        if object ~= 0 and object ~= 0xFFFFFFFF then
			if read_dword(object) == CaptureTheFlag.flag_id then
				destroy_object(ID)
			end
		end
	end
end

function OnGameStart()
    CaptureTheFlag:Init()
end

function OnGameEnd()
    CaptureTheFlag.game_started = false
end

function OnError(msg)
	say_all(msg)
end

function OnPlayerDeath(i)
	for j=0,27 do
		rprint(i, " ")
	end
end

function CaptureTheFlag:GetFlagLocation()
	self.capture_points = {}
	self.flag_coordinates = {}
	
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6D617467 then
            local globals_tag = read_dword(tag + 0x14)
			self.flag_id = read_dword(read_dword(globals_tag + 0x164 + 4) + 0xC)
		end
	end
	
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_data = read_dword(scenario_tag + 0x14)
	netgame_flag_count = read_dword(scenario_data + 0x378)
	netgame_flags = read_dword(scenario_data + 0x378 + 4)
	
	-- Get capture points
	for i=0,netgame_flag_count-1 do
		local current_flag = netgame_flags + i*148
		local flag_type = read_word(current_flag + 0x10)
		local flag_team = read_short(current_flag + 0x12)
		local x,y,z = read_vector3d(current_flag)
		if flag_type == 0 then
			self.capture_points[flag_team] = {x,y,z}
		end
	end
	
	-- Create flag spawn positions
	for i=0,netgame_flag_count-1 do
		local current_flag = netgame_flags + i*148
		local flag_type = read_word(current_flag + 0x10)
		local flag_team = read_short(current_flag + 0x12)
		local x,y,z = read_vector3d(current_flag)
		
		if flag_type == 2 or flag_type == 3 then
			
			local far_enough = true
			
			for _, f in pairs(self.capture_points) do
				local X, Y, Z = f[1], f[2], f[3]
				if sqrt((x - X) ^ 2 + (y - Y) ^ 2 + (z - Z) ^ 2) <= self.flag_spawn_range then
					far_enough = false
				end
			end
			
			if far_enough then
				self.flag_coordinates[#self.flag_coordinates+1] = {x,y,z}
			end
		end
	end
end

function CaptureTheFlag:InitPlayer(Ply, Reset)
    if (not Reset) then
        self.players[Ply] = {
            captures = 0,
            name = get_var(Ply, "$name"),
        }
    end
end

function OnPlayerConnect(Ply)
    CaptureTheFlag:InitPlayer(Ply, false)
end

function OnPlayerDisconnect(Ply)
    CaptureTheFlag:InitPlayer(Ply, true)
end

function CaptureTheFlag:HUD()
	 for flag, v in pairs(self.flag) do
		if (flag) then
			local object = get_object_memory(flag)
			if object ~= 0 then
				local x, y, z = read_vector3d(object + 0x340 + 0x28)
				
				local inventory = read_bit(object + 0x1F4, 0)
				if inventory == 1 then
					local owner_id = read_dword(object + 0xC0)
					for i=1,16 do
						local player = get_dynamic_player(i)
						if player ~= 0 then
							if read_dword(player + 0x218) == owner_id then
								x, y, z = read_vector3d(player + 0x550 + 0x28)
								break
							end
						end
					end
				end
				
				for i=1,16 do
					local player = get_dynamic_player(i)
					if player ~= 0 then
						local px, py, pz = read_vector3d(player + 0x550 + 0x28)
						local x_aim,y_aim,z_aim = read_vector3d(player + 0x230)
						local angle2 = math.deg(math.atan2(x_aim,y_aim))
						
						--check if player is carrying the flag
						local has_flag = 0
						if self:hasObjective(player) then
							has_flag = 1
						end
						
						local ANGLES = {}
						
						for k=1,has_flag+1 do
							local x_dist = (x - px)
							local y_dist = (y - py)
							local z_dist = (z - pz)
							
							if has_flag == 1 then
								x_dist = (self.capture_points[k-1][1] - px)
								y_dist = (self.capture_points[k-1][2] - py)
								z_dist = (self.capture_points[k-1][3] - pz)
							end
							
							local distance = math.sqrt(x_dist*x_dist + y_dist*y_dist)

							local rot_x = x_dist / distance
							local rot_y = y_dist / distance
							
							local angle = math.deg(math.atan2(rot_x,rot_y))
							
							local angle_final = angle-angle2
							if angle_final > 180 then
								angle_final = angle_final - 360
							elseif angle_final < -180 then
								angle_final = angle_final + 360
							end
							
							angle_final = math.floor((angle_final*1.5 + 19)*1.5)
							
							ANGLES[k] = {}
							ANGLES[k].angle = angle_final
							ANGLES[k].dist = distance
							ANGLES[k].zdist = z_dist
						end
						
						for j=0,22 do
							rprint(i, " ")
						end
						
						local aim_angle = -math.ceil((angle2*1.5)*1.5)%12
						local message = ""
						local message2 = ""
						local chars = 60
						for j=0,chars do
							local new_dist = 99999
							local z_dist = 0
							
							for k=1,has_flag+1 do
								if j == ANGLES[k].angle or (ANGLES[k].angle < 0 and j == 0) or (ANGLES[k].angle > chars and j == chars) and ANGLES[k].dist < new_dist then
									new_dist = ANGLES[k].dist
									z_dist = ANGLES[k].zdist
								end
							end
							
							if new_dist ~= 99999 then
								if z_dist > 1.5 then
									message = message.."^"
								elseif z_dist < -0.8 then
									message = message.."v"
								else
									message = message.."O"
								end
								message2 = message2..math.floor((new_dist+math.abs(z_dist))*3.048 - 1)
							elseif (self.move_compass_ticks and j%12 == aim_angle) or (self.move_compass_ticks == false and j%8 == 0) then
								message = message.."|"
								message2 = message2.." "
							else
								message = message.." "
								message2 = message2.." "
							end
						end
						rprint(i, "|c"..message..console_color)
						rprint(i, "|c"..message2..console_color)
						for j=0,18 do
							--rprint(i, " ")
						end
					end
				end
			end
		end
	end
end

function CaptureTheFlag:OnTick()
    if (self.game_started) then
		
		--set game to appear as CTF
		--write_byte(0x6C7A9C, 1) -- don't do this lmao
		
		CaptureTheFlag:HUD()
        for i, _ in pairs(self.players) do
            if player_present(i) then
                self:MonitorFlag(i)
            end
        end
        for flag, v in pairs(self.flag) do
            if (flag) and self:FlagDropped() then
                if (v.held_by ~= nil) then
                    execute_command("s " .. v.held_by .. " 1")
                    v.held_by, v.warn, v.broadcast, v.timer = nil, true, true, 0
                elseif (v.timer ~= nil and v.timer >= 0) then
                    v.timer = v.timer + time_scale
                    local time = self.respawn_time - floor(v.timer % 60)
                    if (time == floor(self.respawn_time / 2)) then
                        if (v.warn) then
                            v.warn = false
                            local msg = gsub(self.on_respawn_trigger, "%%time%%", self.respawn_time / 2)
                            self:Respond(_, msg)
                        end
                    elseif (time <= 0) then
                        self:Respond(_, self.on_respawn)
                        self:SpawnFlag(nil, 1)
                    end
                end
            end
        end
    end
end

function CaptureTheFlag:GetRadius(pX, pY, pZ)
    for _, f in pairs(self.capture_points) do
        local X, Y, Z = f[1], f[2], f[3]
        if sqrt((pX - X) ^ 2 + (pY - Y) ^ 2 + (pZ - Z) ^ 2) <= self.trigger_radius then
            return true
        end
    end
    return false
end

function CaptureTheFlag:SpawnFlag(random_thingy, play_sound)
	if #self.flag_coordinates == 0 or self.flag_id == nil then return end

    for flag, _ in pairs(self.flag) do
        if (flag) then
            destroy_object(flag)
            self.flag[flag] = nil
        end
    end

	if random_thingy ~= nil then
		math.randomseed(random_thingy)
	else
		math.randomseed(os.date("%S"))
	end
	local random_point = math.random(1,#self.flag_coordinates)
	--random_point = 6
	--say(1, "flag spawned at point "..random_point)
    local c = self.flag_coordinates[random_point]
    local x, y, z = c[1], c[2], c[3]
    local flag = spawn_object("", "", x, y, z + 1, 0, self.flag_id)
	
	local object = get_object_memory(flag)
	if object == 0 or read_dword(object + 0x98) == 0 then
		say_all("Failed to spawn at ID "..random_point )
		if object ~= 0 then
			destroy_object(flag)
		end
		flag = nil
		
		if #self.flag_coordinates > 1 then
			self:SpawnFlag(x)
		end
	else
		
		if play_sound ~= nil then
			PlayAnnouncerSound(28)
		end
		
		self.flag[flag] = {
			timer = nil,
			warn = false,
			held_by = nil,
			broadcast = true,
		}
	end
end

function CaptureTheFlag:FlagDropped()
    for i, _ in pairs(self.players) do
        if player_present(i) then
            local DyN = get_dynamic_player(i)
            if (DyN ~= 0) then
                if self:hasObjective(DyN) then
                    return false
                end
            end
        end
    end
    return true
end

function CaptureTheFlag:MonitorFlag(Ply)
    for flag, v in pairs(self.flag) do
        if (flag) then

            local pos = self:GetXYZ(Ply)
            if (pos and self:hasObjective(pos.dyn)) then

                v.held_by = Ply

                local name, speed = self.players[Ply].name, self.flag_runner_speed

                if (v.broadcast) then
					
					PlayAnnouncerSound(42)
					
                    v.broadcast = false
                    execute_command("s " .. Ply .. " " .. speed)
                    for k, msg in pairs(self.on_flag_pickup) do
                        for i = 1, #msg do
                            local str = gsub(gsub(msg[i], "%%name%%", name), "%%speed%%", speed)
                            if (k == 1) then
                                self:Respond(Ply, str, 10, true)
                            else
                                self:Respond(Ply, str)
                            end
                        end
                    end
                end

                if self:GetRadius(pos.x, pos.y, pos.z) and (flag) then

					PlayAnnouncerSound(26)
				
                    local score = tonumber(get_var(Ply, "$score"))
                    if (self.rank_system_support) then
                        execute_command('lua_call "' .. self.rank_script .. '" OnPlayerScore ' .. Ply)
                    end

                    score = score + self.score_on_capture
                    execute_command("s " .. Ply .. " 1")
                    execute_command("score " .. Ply .. " " .. score)

                    self.players[Ply].captures = self.players[Ply].captures + 1
                    self:Respond(_, gsub(gsub(self.on_capture, "%%name%%", name), "%%captures%%", self.players[Ply].captures))
                    self:SpawnFlag()
                    break
                end
            end
        end
    end
	
	if self.score_on_kill == false then
		execute_command("score " .. Ply .. " " .. self.players[Ply].captures)
	end
end

function CaptureTheFlag:GetXYZ(Ply)
    local DyN = get_dynamic_player(Ply)
    if (DyN ~= 0) then
        local VehicleID = read_dword(DyN + 0x11C)
        if (VehicleID == 0xFFFFFFFF) then
            local x, y, z = read_vector3d(DyN + 0x5c)
            return { x = x, y = y, z = z, dyn = DyN }
        end
    end
    return nil
end

function CaptureTheFlag:hasObjective(DyN)
    for i = 0, 3 do
        local WeaponID = read_dword(DyN + 0x2F8 + (i * 4))
        if (WeaponID ~= 0xFFFFFFFF) then
            local WeaponObject = get_object_memory(WeaponID)
            if (WeaponObject ~= 0) then
                if (read_dword(WeaponObject) == self.flag_id) then
                    return true
                end
            end
        end
    end
    return false
end

function CaptureTheFlag:Respond(Ply, Message, Color, Exclude)
    Color = Color or 10
    if (Ply == 0) then
        cprint(Message, Color)
    elseif (Ply and not Exclude) then
        say(Ply, Message)
    else
        cprint(Message, Color)
        for i = 1, 16 do
            if player_present(i) then
                if (not Exclude) then
                    say(i, Message)
                elseif (i ~= Ply) then
                    say(i, Message)
                end
            end
        end
    end
end

function OnTick()
    return CaptureTheFlag:OnTick()
end
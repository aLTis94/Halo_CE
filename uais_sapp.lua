
-- V.1.4, BETA paradigm. By IceCrow14

-- "Reminder", "Pending"

-- Implement Garbage collection, but be careful. Ask each of the clients...

api_version = "1.10.1"

-- Globals

clients = {}
match_bipeds = {}
game_ready = false

object_request_delay = 90 -- Ticks

allowed_distance_change = 0.05 -- These are arbitrary values...
allowed_rotation_change = 0.01

tag_collection_module = require("uais_shared_tag_collection_a_1_0")
tag_manipulation_module = require("uais_shared_tag_manipulation_a_1_0")
object_table_module = require("uais_shared_object_table_a_1_0")
data_compression_module = require("uais_shared_data_compression_a_1_0")
globals_module = require("uais_globals_a_1_0")

function OnScriptLoad()
	-- Remote console bypass. Necessary to allow client to server communication. Credits to Sled
	local rcon_command_failed_message = sig_scan("B8????????E8??000000A1????????55")
	local rcon_command_finished_message = sig_scan("B8????????E8??0000008D????50")
	if (rcon_command_failed_message ~= 0) then
        message_address = read_dword(rcon_command_failed_message + 1)
        safe_write(true)
        write_byte(message_address, 0)
        safe_write(false)
    end

	-- Callbacks
	register_callback(cb['EVENT_GAME_START'],'OnGameStart')
	register_callback(cb['EVENT_GAME_END'],'OnGameEnd')
	register_callback(cb['EVENT_JOIN'],'OnPlayerJoin')
	register_callback(cb['EVENT_LEAVE'],'OnPlayerLeave')
	register_callback(cb['EVENT_TICK'],'OnTick')
	register_callback(cb['EVENT_COMMAND'],'OnCommand')

	-- Misc.
	data_compression_module.LoadCharValuesTable()
end

function OnScriptUnload()
	-- Pending: Reset all variables and unload modules
end

function OnGameStart()
	-- Clients table is reset automatically, forces players to re-join after game start
	match_bipeds = {} -- Reset match & map variables
	tag_collection_module.LoadTagTables(1) 
	tag_manipulation_module.TagManipulationServerSide(1, tag_collection_module.actv_tag_paths())
	game_ready = true
end

function OnGameEnd()
	game_ready = false
end

function OnPlayerJoin(PlayerIndex)
	WhenPlayerJoins(PlayerIndex)
end

function OnPlayerLeave(PlayerIndex)
	WhenPlayerLeaves(PlayerIndex)
end

function OnTick()
	if game_ready then
		local ticks = get_var(0, "$ticks")
		local current_bipeds = object_table_module.GetObjects(1, 0, 1) -- Gather current objects
		for i = 1, #current_bipeds do -- Register new bipeds (server-side)
			local object_id = current_bipeds[i]
			local server_side_registered = false
			for k, v in pairs(match_bipeds) do
				if v == object_id then
					server_side_registered = true
					break
				end
			end
			if not server_side_registered then
				table.insert(match_bipeds, object_id)

				cprint("Biped #"..#match_bipeds.." created.") -- NOTE: Before GC

			end
		end

		for i = 1, 16 do
			local client = clients[i]
			if client then
				if client["connected"] then
					local current_tick_rcon_updates_left = client["rcon_updates_per_tick"]
					for k, v in pairs(match_bipeds) do -- Pending... Add server-side garbage collection
						local object_address = get_object_memory(v)
						local client_side_biped = client["bipds"][k]

						-- NOTE: Cannot enable GC the way I did before (nulling out bipeds and their items, at least not without client and server side confirmation)

						-- Call priority: "d" > "c" > "k" > "u"

						if object_address == 0 then -- "d" (runs before anything else)
							if client_side_biped then
								if current_tick_rcon_updates_left > 0 then
									if client_side_biped < 4 then -- Prepare to delete (stops updating) & max priority for first attempt
										clients[i]["bipds"][k] = 4
										clients[i]["bipds_last_update_tick"][k] = ticks
										current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
										DeleteBipedClientSide(i, k)
									elseif client_side_biped < 5 then
										if ticks - clients[i]["bipds_last_update_tick"][k] > object_request_delay then -- No priority check over here, just repeats after set time
											clients[i]["bipds_last_update_tick"][k] = ticks
											current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
											DeleteBipedClientSide(i, k)
										end
									end
								end
							end
						else -- "c", "k" & "u"
							local player_id = read_dword(object_address + 0xC0)
							local dead = read_bit(object_address + 0x106, 2)
							if player_id == 0xFFFFFFFF then

								local packet_data = {}
								local tag_id = read_dword(object_address) -- Might be used anyway...
								local x = read_dword(object_address + 0x5C)
								local y = read_dword(object_address + 0x60)
								local z = read_dword(object_address + 0x64)
								local pitch = read_dword(object_address + 0x74)
								local yaw = read_dword(object_address + 0x78)

								-- NEW: START
								local weapon_tag_id
								local weapon_object_id = read_dword(object_address + 0x118) -- NOTE: Needs testing, otherwise use primary weapon object ID from unit struct

								local animation = read_word(object_address + 0xD0) -- NOTE: Patch animations to repeat if lacking a key frame index (set to first frame if null), and log when updated
								-- NEW: END

								local float_x = read_float(object_address + 0x5C)
								local float_y = read_float(object_address + 0x60)
								local float_z = read_float(object_address + 0x64)
								local float_pitch = read_float(object_address + 0x74)
								local float_yaw = read_float(object_address + 0x78)

								if not client_side_biped then
									if dead == 0 then -- Prepare for registry process
										clients[i]["bipds"][k] = 0
									end
								else
									if client_side_biped == 0 then -- Create -- NEW: START
										if dead == 0 then
											if current_tick_rcon_updates_left > 0 then

												-- NEW: Find weapon tag id index, if any
												if weapon_object_id ~= 0xFFFFFFFF then
													local weapon_object_address = get_object_memory(weapon_object_id)
													if weapon_object_address ~= 0 then
														weapon_tag_id = read_dword(weapon_object_address) -- This can be passed to the data table to be compared later
													end
												end
												-- NEW: END

												packet_data = {tag_id, x, y, z, pitch, yaw, weapon_tag_id} -- NEW: Introduced W.T.ID.

												if not clients[i]["bipds_last_update_tick"][k] then -- Max priority for first attempt
													clients[i]["bipds_last_update_tick"][k] = ticks

													clients[i]["bipds_last_x"][k] = float_x -- Testing: Log first data
													clients[i]["bipds_last_y"][k] = float_y
													clients[i]["bipds_last_z"][k] = float_z
													clients[i]["bipds_last_pitch"][k] = float_pitch
													clients[i]["bipds_last_yaw"][k] = float_yaw

													clients[i]["bipds_last_animation"][k] = animation -- NEW

													current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
													CreateBipedClientSide(i, k, packet_data)
												else
													if ticks - clients[i]["bipds_last_update_tick"][k] > object_request_delay then -- No priority check over here, just repeats after set time
														clients[i]["bipds_last_update_tick"][k] = ticks

														clients[i]["bipds_last_x"][k] = float_x -- Testing: Log first data
														clients[i]["bipds_last_y"][k] = float_y
														clients[i]["bipds_last_z"][k] = float_z
														clients[i]["bipds_last_pitch"][k] = float_pitch
														clients[i]["bipds_last_yaw"][k] = float_yaw

														clients[i]["bipds_last_animation"][k] = animation -- NEW

														current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
														CreateBipedClientSide(i, k, packet_data)
													end
												end
											end
										else
											if clients[i]["bipds_last_update_tick"][k] then -- "c" has been issued, then kill
												clients[i]["bipds"][k] = 2 -- First attempt to kill, and prepare to repeat in case of failure

												if current_tick_rcon_updates_left > 0 then
													clients[i]["bipds_last_update_tick"][k] = ticks
													current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
													KillBipedClientSide(i, k)
												end

											else
												clients[i]["bipds"][k] = 5 -- Set as deleted, as if it would have never existed. Testing
											end
										end

									elseif client_side_biped == 2 then -- Kill
										if current_tick_rcon_updates_left > 0 then
											if ticks - clients[i]["bipds_last_update_tick"][k] > object_request_delay then
												clients[i]["bipds_last_update_tick"][k] = ticks
												current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
												KillBipedClientSide(i, k)
											end
										end
									elseif client_side_biped == 1 then -- Update

										if dead == 1 then
											clients[i]["bipds"][k] = 2
										end
										
										-- Pending: The block below is absolutely in testing state...
										if current_tick_rcon_updates_left > 0 then
											-- Determine if an update is necessary, then compare against others
											-- Update request bitmask boolean contents: Position, Rotation, Animation (Pending). NOTE: 3x Unused
											local update_request_bitmask = {0, 0, 0, 0, 0, 0} -- NOTE: Have to test if bitmask de/com/pression works. It does?

											local last_x = clients[i]["bipds_last_x"][k]
											local last_y = clients[i]["bipds_last_y"][k]
											local last_z = clients[i]["bipds_last_z"][k]
											local distance_since_last_update = math.sqrt((float_x - last_x) ^ 2 + (float_y - last_y) ^ 2 + (float_z - last_z) ^ 2)

											local last_pitch = clients[i]["bipds_last_pitch"][k]
											local last_yaw = clients[i]["bipds_last_yaw"][k]
											local pitch_change_since_last_update = math.abs(float_pitch - last_pitch)
											local yaw_change_since_last_update = math.abs(float_yaw - last_yaw)

											local last_animation = clients[i]["bipds_last_animation"][k] -- NEW

											if distance_since_last_update > allowed_distance_change then -- Checks
												update_request_bitmask[1] = 1
											end
											if pitch_change_since_last_update > allowed_rotation_change or yaw_change_since_last_update > allowed_rotation_change then
												update_request_bitmask[2] = 1
											end
											if last_animation ~= animation then -- NEW
												update_request_bitmask[3] = 1
											end

											table.insert(packet_data, update_request_bitmask) -- Packet data table setup
											if update_request_bitmask[1] == 1 then
												table.insert(packet_data, x)
												table.insert(packet_data, y)
												table.insert(packet_data, z)
											end
											if update_request_bitmask[2] == 1 then
												table.insert(packet_data, pitch)
												table.insert(packet_data, yaw)
											end
											if update_request_bitmask[3] == 1 then -- NEW
												table.insert(packet_data, animation)
											end

											for j = 1, 6 do
												if update_request_bitmask[j] == 1 then
													clients[i]["bipds_requesting_update"][k] = true -- Set as requesting update
													break
												end
											end

											if clients[i]["bipds_requesting_update"][k] then -- Define priority
												local better_target_bipeds = 0
												for l, w in pairs(match_bipeds) do
													if clients[i]["bipds_requesting_update"][l] then
														if clients[i]["bipds_last_update_tick"][k] > clients[i]["bipds_last_update_tick"][l] then -- Current biped (k) has less priority due to having been updated more recently
															better_target_bipeds = better_target_bipeds + 1
														end
													end
												end

												if not (better_target_bipeds >= current_tick_rcon_updates_left) then -- Update, release update request and log last update data
													clients[i]["bipds_requesting_update"][k] = false

													if update_request_bitmask[1] == 1 then -- Log position
														clients[i]["bipds_last_x"][k] = float_x
														clients[i]["bipds_last_y"][k] = float_y
														clients[i]["bipds_last_z"][k] = float_z
													end
													if update_request_bitmask[2] == 1 then -- Log rotation
														clients[i]["bipds_last_pitch"][k] = float_pitch
														clients[i]["bipds_last_yaw"][k] = float_yaw
													end
													if update_request_bitmask[3] == 1 then -- Log animation (NEW)
														clients[i]["bipds_last_animation"][k] = animation
													end

													current_tick_rcon_updates_left = current_tick_rcon_updates_left - 1
													UpdateBipedClientSide(i, k, packet_data)
												end

											end
										end

									end -- NEW: END
								end
							end
						end
					end
				end
			end
		end

		if ticks % 90 == 0 then
			-- Debug stuff...
		end

	end
end

function OnCommand(PlayerIndex, Command, Environment, RconPassword)
	if Environment == 1 and RconPassword == globals_module.rc_password then -- Main RCON handle
		local player_name = get_var(PlayerIndex, "$name")
		local hash_char = string.sub(Command, 1, 1)
		local object_char = string.sub(Command, 2, 2)
		local action_char = string.sub(Command, 3, 3)
		if hash_char == "@" then
			if object_char == "b" then
				if action_char == "d" then
					ConfirmBipedActionClientSide(PlayerIndex, Command, 5)
				elseif action_char == "c" then
					ConfirmBipedActionClientSide(PlayerIndex, Command, 1)
				elseif action_char == "k" then
					ConfirmBipedActionClientSide(PlayerIndex, Command, 3)
				end
			else
				if Command == globals_module.rc_handshake_message then -- Handshake answered
					SuccessfulHandshake(PlayerIndex, player_name)
				end
			end
			return false
		end
	else
		-- Reminder: Debug commands...
		if Command == "bipd_count" then
			cprint(#match_bipeds.." bipeds found.", 0xF) -- NOTE: Might not work after GC is implemented.
		end
	end
end

-- Additional functions

-- Biped network states:
-- 0 == Registering, 1 == Registered, 2 == Killing, 3 == Killed, 4 == Deleting, 5 == Deleted

function WhenPlayerJoins(PlayerIndexNumber)
	InitializeClient(PlayerIndexNumber)
	TryHandshake(PlayerIndexNumber)
	timer(globals_module.hs_call_delay, "TryHandshake", PlayerIndexNumber)
	cprint("Client #"..PlayerIndexNumber.." has joined the game.", 0xF)
end

function WhenPlayerLeaves(PlayerIndexNumber)
	clients[PlayerIndexNumber] = nil
	cprint("Client #"..PlayerIndexNumber.." has left the game.", 0xF)
end

function TryHandshake(PlayerIndex) -- NOTE: Called from timer
	local player_index = tonumber(PlayerIndex)
	if clients[player_index] then
		local player_name = get_var(player_index, "$name")
		if not clients[player_index]["connected"] then
			if clients[player_index]["calls_left"] > 0 then
				cprint("Attempting UAIS handshake with client #"..PlayerIndex.." ("..player_name..")...", 0x2)
				rprint(player_index, globals_module.rc_handshake_message)
				clients[player_index]["calls_left"] = clients[player_index]["calls_left"] - 1
				return true
			else
				cprint("UAIS handshake failed for client #"..PlayerIndex.." ("..player_name.."). Notifying...", 0xC)
				timer(globals_module.hs_failed_warning_delay, "HandshakeFailed", PlayerIndex)
			end
		end
	end
end

function HandshakeFailed(PlayerIndex) -- NOTE: Called from timer
	local player_index = tonumber(PlayerIndex)
	if clients[player_index] then
		for i = 1, #globals_module.hs_failed_warning_messages do
			local m = globals_module.hs_failed_warning_messages[i]
			rprint(player_index, m)
		end
		return true
	end
end

function SuccessfulHandshake(PlayerIndexNumber, PlayerName)
	if clients[PlayerIndexNumber] then
		clients[PlayerIndexNumber]["connected"] = true
		cprint("Client #"..PlayerIndexNumber.." ("..PlayerName..") joined successfully.", 0xA)
	end
end

function InitializeClient(PlayerIndexNumber)
	clients[PlayerIndexNumber] = { -- NOTE: Had to do this this way due to Lua's lack of a built-in table copy function... Values are copied to the client template. What the fuck?
		connected = false,
		calls_left = globals_module.hs_call_attempts,
		rcon_updates_per_tick = globals_module.rc_default_updates_per_tick,
		bipds = {},
		bipds_last_update_tick = {},
		bipds_requesting_update = {}, -- I'll stick with the basics for now
		bipds_last_x = {},
		bipds_last_y = {},
		bipds_last_z = {},
		bipds_last_pitch = {},
		bipds_last_yaw = {},

		bipds_last_animation = {} -- NEW
	}
end

-- Local

-- NOTE: Confirmations require existance checks, calls don't

function CreateBipedClientSide(PlayerIndexNumber, ObjectIndexNumber, Data) -- NOTE: Initial animation should also be sent...
	local packet
	local final_tag_index

	local final_weapon_tag_index = "0000" -- Not found, or not wielding a weapon

	local final_object_index = data_compression_module.Word16ToHex(ObjectIndexNumber)
	local final_x = data_compression_module.Dword32ToBase85(Data[2])
	local final_y = data_compression_module.Dword32ToBase85(Data[3])
	local final_z = data_compression_module.Dword32ToBase85(Data[4])
	local final_pitch = data_compression_module.Dword32ToBase85(Data[5])
	local final_yaw = data_compression_module.Dword32ToBase85(Data[6])
	for k, v in pairs(tag_collection_module.bipd_tag_ids()) do
		if v == Data[1] then
			final_tag_index = data_compression_module.Word16ToHex(k)
			break
		end
	end

	for k, v in pairs( tag_collection_module.weap_tag_ids() ) do
		if v == Data[7] then
			final_weapon_tag_index = data_compression_module.Word16ToHex(k)
			break
		end
	end

	packet = "@bc"..final_object_index..final_tag_index..final_x..final_y..final_z..final_pitch..final_yaw..final_weapon_tag_index -- NOTE: Weapon tag index added
	rprint(PlayerIndexNumber, packet)
end

function KillBipedClientSide(PlayerIndexNumber, ObjectIndexNumber)
	local packet
	local final_object_index = data_compression_module.Word16ToHex(ObjectIndexNumber)
	packet = "@bk"..final_object_index
	rprint(PlayerIndexNumber, packet)
end

function DeleteBipedClientSide(PlayerIndexNumber, ObjectIndexNumber)
	local packet
	local final_object_index = data_compression_module.Word16ToHex(ObjectIndexNumber)
	packet = "@bd"..final_object_index
	rprint(PlayerIndexNumber, packet)
end

function ConfirmBipedActionClientSide(PlayerIndexNumber, Command, ActionNumberID) -- ActionNumberID: 1 = Created, 3 = Killed, 5 = Deleted
	local object_index = tonumber( data_compression_module.HexToNumber( string.sub(Command, 4, 7) ) )
	local client = clients[PlayerIndexNumber]
	if client then
		if client["connected"] then
			if client["bipds"][object_index] then
				clients[PlayerIndexNumber]["bipds"][object_index] = ActionNumberID
				cprint("Client #"..PlayerIndexNumber.." confirmed action #"..ActionNumberID.." for biped #"..object_index, 0xD)
			end
		end
	end
end

-- NOTE: In development

--[[function UpdateBipedClientSide(PlayerIndexNumber, ObjectIndexNumber, Data) -- NOTE: Now should accept a dynamic amount of data, remember to adequate the client side function
	
	local update_request_bitmask = Data[1]

	local final_object_index = data_compression_module.Word16ToHex(ObjectIndexNumber)
	local final_update_request_bitmask = data_compression_module.Integer6ToPrintableChar(nil, update_request_bitmask) -- Used for the client to understand which items to update...
	local final_x
	local final_y
	local final_z
	local final_pitch
	local final_yaw
	local packet = "@bu"..final_object_index..final_update_request_bitmask

	if update_request_bitmask[1] == 1 then

		final_x = data_compression_module.Dword32ToBase85(Data[2])
		final_y = data_compression_module.Dword32ToBase85(Data[3])
		final_z = data_compression_module.Dword32ToBase85(Data[4])
		if update_request_bitmask[2] == 1 then
			final_pitch = data_compression_module.Dword32ToBase85(Data[5])
			final_yaw = data_compression_module.Dword32ToBase85(Data[6])

			packet = packet..final_x..final_y..final_z..final_pitch..final_yaw
		else
			packet = packet..final_x..final_y..final_z
		end

	else
		if update_request_bitmask[2] == 1 then
			final_pitch = data_compression_module.Dword32ToBase85(Data[2])
			final_yaw = data_compression_module.Dword32ToBase85(Data[3])

			packet = packet..final_pitch..final_yaw
		else
			-- Same, empty (Just like me, r.n.)
		end
	end

	rprint(PlayerIndexNumber, packet)
end]]

function UpdateBipedClientSide(PlayerIndexNumber, ObjectIndexNumber, Data) -- NOTE: Remember to adequate the client side function
	local update_request_bitmask = Data[1]

	local final_object_index = data_compression_module.Word16ToHex(ObjectIndexNumber)
	local final_update_request_bitmask = data_compression_module.Integer6ToPrintableChar(nil, update_request_bitmask) -- Used for the client to understand which items to update...
	local final_x
	local final_y
	local final_z
	local final_pitch
	local final_yaw

	local final_animation

	local packet = "@bu"..final_object_index..final_update_request_bitmask
	if update_request_bitmask[1] == 1 then

		final_x = data_compression_module.Dword32ToBase85(Data[2])
		final_y = data_compression_module.Dword32ToBase85(Data[3])
		final_z = data_compression_module.Dword32ToBase85(Data[4])
		packet = packet..final_x..final_y..final_z

		if update_request_bitmask[2] == 1 then

			final_pitch = data_compression_module.Dword32ToBase85(Data[5])
			final_yaw = data_compression_module.Dword32ToBase85(Data[6])
			packet = packet..final_pitch..final_yaw

			if update_request_bitmask[3] == 1 then
				final_animation = data_compression_module.Word16ToHex(Data[7])
				packet = packet..final_animation
			end

		else

			if update_request_bitmask[3] == 1 then
				final_animation = data_compression_module.Word16ToHex(Data[5])
				packet = packet..final_animation
			end

		end

	else

		if update_request_bitmask[2] == 1 then

			final_pitch = data_compression_module.Dword32ToBase85(Data[2])
			final_yaw = data_compression_module.Dword32ToBase85(Data[3])
			packet = packet..final_pitch..final_yaw

			if update_request_bitmask[3] == 1 then
				final_animation = data_compression_module.Word16ToHex(Data[4])
				packet = packet..final_animation
			end

		else
			
			if update_request_bitmask[3] == 1 then
				final_animation = data_compression_module.Word16ToHex(Data[2])
				packet = packet..final_animation
			end

		end
	end

	rprint(PlayerIndexNumber, packet)
end
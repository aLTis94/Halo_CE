-- Map Downloader by Devieth
-- For SAPP

-- Required files:
-- wget.exe
-- 7z.exe
-- 7z.dll

hac2_repo = "http://maps.halonet.net/" -- HAC2 Repo
hac2_legacy_repo = "http://maps.haloanticheat.com/" -- Legacy HAC2 Repo

api_version = "1.10.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_COMMAND'], "OnEventCommand")
	-- Assign the repo to use.
	map_repo = hac2_repo
	-- Get the EXE Path
	exe_path = read_string(read_dword(sig_scan("0000BE??????005657C605") + 0x3))
	-- Split the string
	local t = tokenizestring(exe_path, "\\")
	-- Create the maps_folder_path
	maps_folder_path = string.sub(exe_path, 0, string.len(exe_path) - string.len(t[#t])).."\\maps\\"
end

function OnScriptUnload() end

function OnEventCommand(PlayerIndex, Command, Enviroment, Password)
	local t = tokenizestring(string.lower(string.gsub(Command, '"', "")), " ")
	if get_var(PlayerIndex, "$lvl") ~= "-1" or tonumber(Enviroment) == 0 then

		-- Hi-Jack SAPP's command.
		if t[1] == "map_download" then

			-- Make sure they actually used a name
			if t[2] then
				local downloaded, map_name = false, tostring(t[2])

				say_all("The server is downloading the map "..map_name)
				
				-- Download the map.
				local map = assert(io.popen('wget -O "'..map_name..'" -c '..map_repo.."map_download.php?map="..map_name))
				map:close()

				-- Check if the download was successful.
				local file = io.open(map_name)
				if file then
					downloaded = true
					file:close()
				end

				if downloaded then
					-- Unzip the map.
					local sevenz = assert(io.popen('7z.exe e "'..map_name..'" -o'..maps_folder_path))
					sevenz:close()

					-- Load the map.
					execute_command("map_load "..map_name)
					rcon_return(tonumber(Enviroment), PlayerIndex, "Download of "..map_name.. " complete!")

					-- Delete the .zip file.
					os.remove(map_name)
				else

					-- Alert the usere that the download failed.
					rcon_return(tonumber(Enviroment), PlayerIndex, "Failed to download "..map_name)
					rcon_return(tonumber(Enviroment), PlayerIndex, "Check the spelling of the map.")
					rcon_return(tonumber(Enviroment), PlayerIndex, "Check the repo for the map @ http://maps.halonet.net/maplist.php")
				end
			else
				-- Let them know how to use the hi-jacked command.
				rcon_return(tonumber(Enviroment), PlayerIndex, "map_download <map name>")
			end
			return false
		elseif t[1] == "map_download.map" then
			if t[2] then
				if t[3] then
					local downloaded, URL, map_name = false, tostring(t[2]), tostring(t[3])

					-- Download the map.
					local map = assert(io.popen('wget -c '..URL..' -O '..maps_folder_path..map_name))
					map:close()

					--Load the map
					execute_command("map_load "..map_name)
				else
					rcon_return(tonumber(Enviroment), PlayerIndex, "Please include the full map and file name. EX: cmt_snow_grove.map")
				end
			else
				rcon_return(tonumber(Enviroment), PlayerIndex, "map_download.map <URL> <map_name.map>")
			end
			return false
		elseif t[1] == "map_download.zip" then
			if t[2] then
				if t[3] then
					local downloaded, URL, map_name = false, tostring(t[2]), tostring(t[3])

					-- Download the map.
					local map = assert(io.popen('wget -O "'..map_name..'" -c '..URL))
					map:close()

					-- Check if the download was successful.
					local file = io.open(map_name)
					if file then
						downloaded = true
						file:close()
					end

					if downloaded then
						SayDelayed(":lag::question:")
						-- Unzip the map.
						local sevenz = assert(io.popen('7z.exe e "'..map_name..'" -o'..maps_folder_path))
						sevenz:close()
						-- Load the map.
						execute_command("map_load "..map_name)
						rcon_return(tonumber(Enviroment), PlayerIndex, "Download of "..map_name.." complete!")
						-- Delete the .zip file.
						os.remove(map_name)
					else
						-- Alert the usere that the download failed.
						rcon_return(tonumber(Enviroment), PlayerIndex, "Download failed.")
					end
				else
					rcon_return(tonumber(Enviroment), PlayerIndex, "Map name required! Ex: garden_ce")
				end
			else
				rcon_return(tonumber(Enviroment), PlayerIndex, "map_download.zip <URL> <map_name>")
			end
			return false
		elseif t[1] == "repo" then
			if t[2] then
				if t[2] == "legacy" then
					map_repo = hac2_legacy_repo
				else
					map_repo = tostring(t[2])
				end
				rcon_return(tonumber(Enviroment), PlayerIndex, "Map Repo set to: "..repo)
			else
				rcon_return(tonumber(Enviroment), PlayerIndex, "Current Map Repo: "..repo)
			end
			return false
		end
	end
end

function rcon_return(Enviroment, PlayerIndex, Message)
	local Compatable_Message = string.gsub(tostring(Message), "|t", "	")
	if Enviroment == 0 then
		cprint(Compatable_Message,14)
	elseif Enviroment == 1 then
		rprint(PlayerIndex, Message)
	elseif Enviroment == 2 then
		say(PlayerIndex, Compatable_Message)
	end
end

function tokenizestring(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

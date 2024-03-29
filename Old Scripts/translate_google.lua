-- Message translation script

-- CONFIG

	translation_type = "Google" -- choose google or yandex

	minimum_length = 4 -- if message is this short, we don't need to translate it

	DEFAULT_MSG_PREFIX = "**SAPP** "

	SPANISH_COUNTRIES = {
		"Argentina",
		"Bolivia",
		"Chile",
		"Colombia",
		"Costa Rica",
		"Cuba",
		"Dominican Republic",
		"Ecuador",
		"El Salvador",
		"Equatorial Guinea",
		"Guatemala",
		"Honduras",
		"Mexico",
		"Nicaragua",
		"Panama",
		"Paraguay",
		"Peru",
		"Puerto Rico",
		"Spain",
		"Uruguay",
		"Venezuela",
	}

	COMMAND_TO_SET_LANG_TO_ENGLISH = "eng"
	COMMAND_TO_SET_LANG_TO_SPANISH = "esp"
	COMMAND_TO_TOGGLE_TRANSLATION = "translate"

	COMMAND_SEQUENCE_ON_JOIN = "w8 4;say $n '$toggle_translation';say $n '$change_language';say $n '$set_language';"

	MESSAGES = {
		["set_language"] = {
			["en"] = "Your language is set to English.",
			["es"] = "Su idioma esta establecido en espanol.",
		},
		["change_language"] = {
			["en"] = "To change your language to Spanish type /" .. COMMAND_TO_SET_LANG_TO_SPANISH,
			["es"] = "Para cambiar su idioma al ingles escriba /" .. COMMAND_TO_SET_LANG_TO_ENGLISH,
		},
		["toggle_translation"] = {
			["en"] = "To toggle translation on and off type /" .. COMMAND_TO_TOGGLE_TRANSLATION,
			["es"] = "Para activar y desactivar la traduccion escriba /" .. COMMAND_TO_TOGGLE_TRANSLATION,
		},
		["translation_off"] = {
			["en"] = "Translations have been turned off.",
			["es"] = "Las traducciones se han desactivado.",
		},
		["translation_on"] = {
			["en"] = "Translations have been turned on.",
			["es"] = "Las traducciones se han activado.",
		},
	}

	ACCENTS = {
		{ "á", 225 },
		{ "é", 233 },
		{ "í", 237 },
		{ "ó", 243 },
		{ "ú", 250 },
		{ "ñ", 241 },
		{ "ü", 252 },
		{ "¡", 161 },
		{ "¿", 191 },
	}

-- END OF CONFIG

api_version = "1.9.0.0"

ffi = require("ffi")
ffi.cdef [[
    typedef void http_response;
    http_response *http_get(const char *url, bool async);
    void http_destroy_response(http_response *);
    void http_wait_async(const http_response *);
    bool http_response_is_null(const http_response *);
    bool http_response_received(const http_response *);
    const char *http_read_response(const http_response *);
    uint32_t http_response_length(const http_response *);
]]
http_client = ffi.load("lua_http_client")

translation_disabled = {}
saved_language = {}
player_language = {}
async_table = {}
charset = {}
chat_type_address = 0x18C8A0
chat_message_address = 0x18C8D0

geolocate_url = "http://ip-api.com/line/$ip?fields=country"
-- Google translate
translate_url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q="
-- Yandex translate
YANDEX_KEY = "trnsl.1.1.20170802T134634Z.940e24a70a06973f.0744f5ccd03a7d0985fc8e66c575fcf9e963e8a4"
URL = "https://translate.yandex.net/api/v1.5/tr.json/translate?key=" .. YANDEX_KEY .. "&lang="
URL2 = "&format=plain&text="

function OnScriptLoad()
	for i=48,57 do table.insert(charset, string.char(i)) end
	for i=65,90 do table.insert(charset, string.char(i)) end
	for i=97,122 do table.insert(charset, string.char(i)) end
	
	if(halo_type == "CE") then
		chat_type_address = chat_type_address + 0x20
	end
	
	add_var("language", 3)
	
	for i=1,16 do
		set_var(i, "$language","en")
	end
	
	register_callback(cb['EVENT_JOIN'], "OnJoin")
	register_callback(cb['EVENT_LEAVE'], "OnLeave")
	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	register_callback(cb['EVENT_COMMAND'], "OnCommand")
    register_callback(cb['EVENT_CHAT'], "OnChat")
	register_callback(cb["EVENT_TICK"],"OnTick")
end

function OnTick()
	for i=1,16 do
		player_language[i] = get_var(i,"$language")
	end
end

function OnJoin(PlayerIndex)
	local player_ip = get_var(PlayerIndex, "$ip")
	player_ip = string.sub(player_ip, 1, string.find(player_ip, ":") - 1)
	if(saved_language[player_ip] ~= nil) then
		player_language[PlayerIndex] = saved_language[player_ip]
		CommandSequenceOnJoin(PlayerIndex, saved_language[player_ip])
	else
		local temp_ip = player_ip
		if(temp_ip:startsWith('127.') or temp_ip:startsWith('192.168.')) then
			temp_ip = ""
		end
		
		local url = geolocate_url:gsub("$ip", temp_ip)
		
		local random_string = string.random(64)
		async_table[random_string] = http_client.http_get(url, true)
		timer(1, "CheckLocation", random_string, PlayerIndex, player_ip)
	end
	
	if player_language[PlayerIndex] ~= nil then
		set_var(PlayerIndex, "$language",player_language[PlayerIndex])
	end
	
	translation_disabled[PlayerIndex] = false
end

function OnLeave(PlayerIndex)
	player_language[PlayerIndex] = nil
end

function OnGameStart()
	translation_disabled = {}
	player_language = {}
end

function OnCommand(PlayerIndex, Command)
	if(PlayerIndex > 0) then
		Command = Command:lower()
		if(Command == COMMAND_TO_SET_LANG_TO_ENGLISH) then
			local player_ip = get_var(PlayerIndex, "$ip")
			player_ip = string.sub(player_ip, 1, string.find(player_ip, ":") - 1)
			
			player_language[PlayerIndex] = "en"
			saved_language[player_ip] = "en"
			
			say(PlayerIndex, MESSAGES["set_language"]["en"])
			
			set_var(PlayerIndex, "$language",player_language[PlayerIndex])
			
			return false
		end
		
		if(Command == COMMAND_TO_SET_LANG_TO_SPANISH) then
			local player_ip = get_var(PlayerIndex, "$ip")
			player_ip = string.sub(player_ip, 1, string.find(player_ip, ":") - 1)
			
			player_language[PlayerIndex] = "es"
			saved_language[player_ip] = "es"
			
			say(PlayerIndex, MESSAGES["set_language"]["es"])
			
			set_var(PlayerIndex, "$language",player_language[PlayerIndex])
			
			return false
		end
		
		if(Command == COMMAND_TO_TOGGLE_TRANSLATION) then
			translation_disabled[PlayerIndex] = not translation_disabled[PlayerIndex]
			if(translation_disabled[PlayerIndex]) then
				if(player_language[PlayerIndex] == "es") then
					say(PlayerIndex, MESSAGES["translation_off"]["es"])
				else
					say(PlayerIndex, MESSAGES["translation_off"]["en"])
				end
			else
				if(player_language[PlayerIndex] == "es") then
					say(PlayerIndex, MESSAGES["translation_on"]["es"])
				else
					say(PlayerIndex, MESSAGES["translation_on"]["en"])
				end
			end
			
			return false
		end
	end
	
	return true
end

function OnChat(PlayerIndex, Message)
	local first_character = string.sub(Message, 0, 1)
	if(first_character ~= "\\" and first_character ~= "/") then
		local player_name = get_var(PlayerIndex, "$name")
		local player_team = get_var(PlayerIndex, "$team")
		local message_type = read_byte(chat_type_address)
		local vehicle_objectid = 0xFFFFFFFF
		--rprint(1, "message type: "..message_type)
		if(message_type == 2) then
			local player = get_dynamic_player(PlayerIndex)
			if(player ~= 0) then
				vehicle_objectid = read_dword(player + 0x11C)
			end
		end
		
		local from_language = "en"
		local to_language = "es"
		if(player_language[PlayerIndex] == "es") then
			from_language = "es"
			to_language = "en"
		end
		
		local real_message = ""
		for i=0,63 do
			local temp_word = read_word(chat_message_address + i*2)
			if(temp_word == 0) then
				break;
			else
				if(temp_word <= 0xFF) then
					local temp_char = string.char(temp_word)
					real_message = real_message .. temp_char
				else
					real_message = real_message .. "?"
				end
			end
		end
		
		--Message = real_message
		
		local url = translate_url
		url = url:gsub("$from", from_language)
		url = url:gsub("$to", to_language)
		url = url .. URL_Encode(Message)
		
		local random_string = string.random(64)
		async_table[random_string] = http_client.http_get(url, true)
		--rprint(1, "OnChat")
		timer(1, "CheckTranslation", random_string, player_name, from_language, Message, message_type, player_team, vehicle_objectid)
		return false
	end

	return true
end

function CheckLocation(ResultName, PlayerIndex, PlayerIP)
    if http_client.http_response_received(async_table[ResultName]) then
        if(http_client.http_response_is_null(async_table[ResultName])) then
			if(player_language[PlayerIndex] == nil) then
				if(player_present(PlayerIndex)) then
					local player_ip = get_var(PlayerIndex, "$ip")
					player_ip = string.sub(player_ip, 1, string.find(player_ip, ":") - 1)
					if(player_ip == PlayerIP) then
						player_language[PlayerIndex] = "en"
						saved_language[player_ip] = "en"
						CommandSequenceOnJoin(PlayerIndex, "en")
					end
				end
			end
		else
			local response = string.gsub(string.gsub(ffi.string(http_client.http_read_response(async_table[ResultName])),"\t"," "),"\n","")
			PlayerIndex = tonumber(PlayerIndex)
			if(player_language[PlayerIndex] == nil) then
				if(player_present(PlayerIndex)) then
					local player_ip = get_var(PlayerIndex, "$ip")
					player_ip = string.sub(player_ip, 1, string.find(player_ip, ":") - 1)
					if(player_ip == PlayerIP) then
						for i=1,#SPANISH_COUNTRIES do
							if(response == SPANISH_COUNTRIES[i]) then
								player_language[PlayerIndex] = "es"
								saved_language[player_ip] = "es"
								CommandSequenceOnJoin(PlayerIndex, "es")
							end
						end
						if(player_language[PlayerIndex] == nil) then
							player_language[PlayerIndex] = "en"
							saved_language[player_ip] = "en"
							CommandSequenceOnJoin(PlayerIndex, "en")
						end
					end
				end
			end
        end
        http_client.http_destroy_response(async_table[ResultName])
        return false
    end
    return true
end

function CommandSequenceOnJoin(PlayerIndex, Language)
	local command_sequence = COMMAND_SEQUENCE_ON_JOIN
	command_sequence = command_sequence:gsub("$toggle_translation", MESSAGES["toggle_translation"][Language])
	command_sequence = command_sequence:gsub("$change_language", MESSAGES["change_language"][Language])
	command_sequence = command_sequence:gsub("$set_language", MESSAGES["set_language"][Language])
	command_sequence = command_sequence:gsub("$n", PlayerIndex)
	execute_command_sequence(command_sequence)
end

function CheckTranslation(ResultName, PlayerName, Language, Message, MessageType, PlayerTeam, VehicleObjectID)
    if http_client.http_response_received(async_table[ResultName]) then
		--rprint(1, "CheckTranslation")
        if http_client.http_response_is_null(async_table[ResultName]) then
            SendMessage(PlayerName, Language, Message, Message, tonumber(MessageType), PlayerTeam, tonumber(VehicleObjectID))
        else
			local response = string.gsub(string.gsub(ffi.string(http_client.http_read_response(async_table[ResultName])),"\t"," "),"\n","")
			local check1 = string.sub(response, 1, 4)
			if(check1 == "[[[\"") then
				local check2 = string.find(response, "\",\"")
				if(check2 ~= nil) then
					response = string.sub(response, 5, check2 - 1)
					response = string.gsub(response, "\\\"", "\"")
					SendMessage(PlayerName, Language, Message, response, tonumber(MessageType), PlayerTeam, tonumber(VehicleObjectID))
				else
					SendMessage(PlayerName, Language, Message, Message, tonumber(MessageType), PlayerTeam, tonumber(VehicleObjectID))
				end
			else
				SendMessage(PlayerName, Language, Message, Message, tonumber(MessageType), PlayerTeam, tonumber(VehicleObjectID))
			end
        end
        http_client.http_destroy_response(async_table[ResultName])
        return false
    end
    return true
end

function SendMessage(PlayerName, Language, OriginalMessage, TranslatedMessage, MessageType, PlayerTeam, VehicleObjectID)
	execute_command("msg_prefix \"\"")

	for i=1,#ACCENTS do
		TranslatedMessage = TranslatedMessage:gsub(ACCENTS[i][1], string.char(ACCENTS[i][2]))
	end
	--rprint(1, "SendMessage")
	local en_message = OriginalMessage
	local es_message = TranslatedMessage .. " (eng)"
	if(Language == "es") then
		en_message = TranslatedMessage .. " (esp)"
		es_message = OriginalMessage
	end
	
	--TEMPRORARY!!!
	MessageType = 0
	if(MessageType == 0) then
		en_message = PlayerName .. ": " .. en_message
		es_message = PlayerName .. ": " .. es_message
		
		for i=1,16 do
			if(player_present(i)) then
				rprint(i, es_message)
				rprint(i, en_message)
				if(player_language[i] == "es") then
					say(i, es_message)
					--rprint(1, "type 0")
					--rprint(1, es_message)
				else
					say(i, en_message)
				end
			end
		end
	elseif(MessageType == 1) then
		en_message = "[" .. PlayerName .. "]: " .. en_message
		es_message = "[" .. PlayerName .. "]: " .. es_message
		
		for i=1,16 do
			if(player_present(i)) then
				if(PlayerTeam == get_var(i, "$team")) then
					if(player_language[i] == "es") then
						say(i, es_message)
					else
						say(i, en_message)
					end
				end
			end
		end
	elseif(MessageType == 2) then
		en_message = "[" .. PlayerName .. "]: " .. en_message
		es_message = "[" .. PlayerName .. "]: " .. es_message
		
		for i=1,16 do
			if(player_alive(i)) then
				local player = get_dynamic_player(i)
				if(player ~= 0) then
					local vehicle_objectid = read_dword(player + 0x11C)
					if(VehicleObjectID == vehicle_objectid) then
						if(player_language[i] == "es") then
							say(i, es_message)
						else
							say(i, en_message)
						end
					end
				end
			end
		end
	end
	
	execute_command("msg_prefix \"" .. DEFAULT_MSG_PREFIX .. "\"")
end

function URL_Encode(str)
	if (str) then
		str = string.gsub (str, "([^%w ])", function (c) return string.format ("%%%02X", string.byte(c)) end)
	end
	return str
end

function string.random(length)
	math.randomseed(os.time())
	if length > 0 then
		return string.random(length - 1) .. charset[math.random(1, #charset)]
	else
		return ""
	end
end

function string:startsWith(prefix)
    return self:sub(1, string.len(prefix)) == prefix
end

function OnScriptUnload() 
	del_var("language")
end
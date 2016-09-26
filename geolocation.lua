-- Geolocation by giraffe --
-- Execute commands when a player joins based on the player's IP location --

-- Config --

MATCHES = {

    -- First variable is either: 'country', 'region' or 'city' --
    -- Second variable is the name of the country, region, or city --
    -- Third variable is commands to execute if player matches location --
    -- $country, $region, and $city can be used as variables in the commands --

    { 'country', 'Mexico', 'say * "$name will not share his WORLD FAMOUS taco recipe with you!";' },
    { 'country', 'Libya', 'say * "Ask $name how hot it is in $country.";' },
    { 'country', 'North Korea', 'say * "$name was kicked. Reason: $country.";sv_kick $n;' },
    { 'region', 'Kentucky', 'say * "$name is eating a bucket of $region Fried Chicken with Colonel Sanders.";' },
    { 'city', 'London', 'say * "$name might just be a werewolf from $city...";' },

}

-- Commands to execute if player does not match any of the specified locations --
NO_MATCH = 'say * "$name has connected from $country.";'

-- End of config --

api_version = '1.8.0.0'

function OnScriptLoad()
    register_callback(cb['EVENT_JOIN'], 'OnPlayerJoin')
end

function string:split(sep)
    local sep, fields = sep or ':', {}
    local pattern = string.format('([^%s]+)', sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function string:startsWith(prefix)
    return self:sub(1, string.len(prefix)) == prefix
end

function get_geolocation(IP)
    if(IP:startsWith('127.') or IP:startsWith('192.168.')) then
        IP = ''
    end
    local p = assert(io.popen('wget -qO- http://ip-api.com/line/' .. IP .. '?fields=country,regionName,city'))
    local result = p:read('*all')
    p:close()
    if(result ~= nil) then
        local geodata = result:split('\n')
        if(#geodata < 3) then
            return nil
        end
        return geodata
    end
    return nil
end

function OnPlayerJoin(PlayerIndex)
     local location = get_geolocation(get_var(PlayerIndex,'$ip'):split(':')[1])
     if(location ~= nil) then
         for i=1,#MATCHES do
             if( (MATCHES[i][1]:lower() == 'country' and MATCHES[i][2]:lower() == location[1]:lower()) or (MATCHES[i][1]:lower() == 'region' and MATCHES[i][2]:lower() == location[2]:lower()) or (MATCHES[i][1]:lower() == 'city' and MATCHES[i][2]:lower() == location[3]:lower()) ) then
                 local commands = MATCHES[i][3]
                 commands = string.gsub(commands, '$country', location[1])
                 commands = string.gsub(commands, '$region', location[2])
                 commands = string.gsub(commands, '$city', location[3])
                 execute_command_sequence(commands, PlayerIndex)
                 return
             end
         end
         local commands = NO_MATCH
         commands = string.gsub(commands, '$country', location[1])
         commands = string.gsub(commands, '$region', location[2])
         commands = string.gsub(commands, '$city', location[3])
         execute_command_sequence(commands, PlayerIndex)
     end
     return
end

function OnScriptUnload() end
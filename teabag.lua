-- Teabagging Script by 002 v1.0.1
-- Configuration

-- Seconds until the teabag "expires"
EXPIRE_TIME = 30

-- Teabag radius in world units (1 world unit = 3 meters)
TEABAG_RADIUS = 2/3

-- Message to announce
-- $VICTIM = killed player's name
-- $KILLER = killer's name
TEABAG_MESSAGE = "$VICTIM was teabagged by $KILLER"

-- End of configuration
api_version = "1.6.0.0"
function OnScriptLoad()
    register_callback(cb['EVENT_TICK'],"OnTick")
    register_callback(cb['EVENT_DIE'],"OnDie")
end
function OnScriptUnload()

end

player_locations = {}

-- {OwnerName,KillerHash,x,y,z,Expires}
bodies = {}

function DistanceFormula(x1,y1,z1,x2,y2,z2)
    return math.sqrt(math.pow(x1 - x2,2) + math.pow(y1 - y2,2) + math.pow(z1 - z2,2))
end

function OnTick()
    local time = os.clock()
    for i=#bodies,1,-1 do
        if(bodies[i].Expires < time) then
            table.remove(bodies,i)
        end
    end
    for i=1,16 do
        if(player_alive(i)) then
            local player_object = get_dynamic_player(i)
            local x,y,z = read_vector3d(player_object + 0x5C)
            local vehicle_objectid = read_dword(player_object + 0x11C)
            local vehicle_object = get_object_memory(vehicle_objectid)

            if(vehicle_object ~= 0) then
                local a,b,c = read_vector3d(vehicle_object + 0x5C)
                x=x+a
                y=y+b
                z=z+c
            elseif(bit.band(read_dword(player_object + 0x208),1) ~= 0) then
                local hash = get_var(i,"$hash")
                for k=#bodies,1,-1 do
                    if(bodies[k].KillerHash == hash) then
                        if(DistanceFormula(x,y,z,bodies[k].x,bodies[k].y,bodies[k].z) < TEABAG_RADIUS) then
                            --say_all(string.gsub(string.gsub(TEABAG_MESSAGE,"$VICTIM",bodies[k].OwnerName),"$KILLER",get_var(i,"$name")))
                            table.remove(bodies,k)
							SoundObject = spawn_object("weap", "altis\\weapons\\lets_get_it_on\\sound", x, y, (z + 0.1))
							timer(5000, "RemoveSoundObject", SoundObject)
                        end
                    end
                end
            end
            player_locations[i] = {}
            player_locations[i].x = x
            player_locations[i].y = y
            player_locations[i].z = z
        end
    end

end

function RemoveSoundObject(ObjectID)
	destroy_object(ObjectID)
end

function OnDie(PlayerIndex,KillerIndex)
    KillerIndex = tonumber(KillerIndex)

    --if(player_locations[PlayerIndex] and KillerIndex > 0 and PlayerIndex ~= KillerIndex) then
	if(player_locations[PlayerIndex] and KillerIndex > 0) then
        local entry = {}
        entry.OwnerName = get_var(PlayerIndex,"$name")
        entry.KillerHash = get_var(KillerIndex,"$hash")
        entry.x = player_locations[PlayerIndex].x
        entry.y = player_locations[PlayerIndex].y
        entry.z = player_locations[PlayerIndex].z
        entry.Expires = os.clock() + EXPIRE_TIME
        bodies[#bodies + 1] = entry
    end
end
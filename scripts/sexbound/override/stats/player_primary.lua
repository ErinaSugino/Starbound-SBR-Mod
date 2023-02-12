require "/scripts/sexbound/util.lua"

local Sexbound_Override_Player_Primary_init = init
function init()
    Sexbound_Override_Player_Primary_init()

    message.setHandler("Sexbound:removeStatusEffect", function(_, _, effectName)
        status.removeEphemeralEffect(effectName)
    end)
end

local Sexbound_Override_Player_Primary_update = update
function update(dt)
    Sexbound_Override_Player_Primary_update(dt)
end

require "/scripts/sexbound/util.lua"
require "/stats/sexbound/sexbounddefeat.lua"

local Sexbound_Override_Player_Primary_init = init
function init()
    Sexbound_Override_Player_Primary_init()

    message.setHandler("Sexbound:removeStatusEffect", function(_, _, effectName)
        status.removeEphemeralEffect(effectName)
    end)

    -- Defeat init
    self.sexboundDefeat = SexboundDefeat:new("player")
    status.removeEphemeralEffect("sexbound_sex")
    status.removeEphemeralEffect("sexbound_defeat_stun")
    status.removeEphemeralEffect("regeneration4")

    message.setHandler("Sexbound:Defeat:SetPosition", function(_, _, position)
        mcontroller.setPosition(position)
    end)
    
end

local Sexbound_Override_Player_Primary_update = update
function update(dt)
    self.sexboundDefeat:update(dt, Sexbound_Override_Player_Primary_update)
end

-- Override Apply Damage Request Hook (Defeat)
local sexbound_defeat_applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
	return self.sexboundDefeat:handleApplyDamageRequest(sexbound_defeat_applyDamageRequest, damageRequest)
end

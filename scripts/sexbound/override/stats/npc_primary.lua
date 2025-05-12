require "/stats/sexbound/sexbounddefeat.lua"

local sexbound_NPC_Primary_init = init
function init()
    sexbound_NPC_Primary_init()

    message.setHandler("Sexbound:removeStatusEffect", function(_, _, effectName)
        status.removeEphemeralEffect(effectName)
    end)

    -- Defeat init
    self.sexboundDefeat = SexboundDefeat:new("npc")
    status.removeEphemeralEffect("sexbound_sex")
    status.removeEphemeralEffect("sexbound_defeat_stun")

end

-- Override Update Hook (defeat)
local sexbound_defeat_update = update
function update(dt)
	self.sexboundDefeat:update(dt, sexbound_defeat_update)
end

-- Override Apply Damage Request Hook (defeat)
local sexbound_defeat_applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
	return self.sexboundDefeat:handleApplyDamageRequest(sexbound_defeat_applyDamageRequest, damageRequest)
end
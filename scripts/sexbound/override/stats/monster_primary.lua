require "/stats/sexbound/sexbounddefeat.lua"

local sexbound_monster_primary_init = init
function init()
    sexbound_monster_primary_init()

    message.setHandler("Sexbound:removeStatusEffect", function(_, _, effectName)
        status.removeEphemeralEffect(effectName)
    end)

    --Defeat Init
    self.sexboundDefeat = SexboundDefeat:new("monster")
    status.removeEphemeralEffect("sexbound_sex")
    status.removeEphemeralEffect("sexbound_defeat_stun")
end

-- Override Update Hook (Defeat)
local sexbound_defeat_update = update
function update(dt)
	self.sexboundDefeat:update(dt, sexbound_defeat_update)
end

-- Override Apply Damage Request Hook (Defeat)
local sexbound_defeat_applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
	return self.sexboundDefeat:handleApplyDamageRequest(sexbound_defeat_applyDamageRequest, damageRequest)
end
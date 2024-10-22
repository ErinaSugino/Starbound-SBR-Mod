require "/stats/sexbound/sexbounddefeat.lua"

-- Override Init Hook
local sexbound_defeat_init = init
function init()
	self.sexboundDefeat = SexboundDefeat:new("player")
  sexbound_defeat_init() -- call actual init function
  status.removeEphemeralEffect("sexbound_sex")
  status.removeEphemeralEffect("sexbound_defeat_stun")
  status.removeEphemeralEffect("regeneration4")
  message.setHandler("Sexbound:Defeat:SetPosition", function(_, _, position)
    mcontroller.setPosition(position)
  end)
end

-- Override Update Hook
local sexbound_defeat_update = update
function update(dt)
	self.sexboundDefeat:update(dt, sexbound_defeat_update)
end

-- Override Apply Damage Request Hook
local sexbound_defeat_applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
	return self.sexboundDefeat:handleApplyDamageRequest(sexbound_defeat_applyDamageRequest, damageRequest)
end

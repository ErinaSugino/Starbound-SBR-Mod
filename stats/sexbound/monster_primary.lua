require "/stats/sexbound/sexbounddefeat.lua"

-- Override Init Hook
local sexbound_defeat_init = init
function init()
	self.sexboundDefeat = SexboundDefeat:new("monster")
  sexbound_defeat_init() -- call actual init function
  status.removeEphemeralEffect("sexbound_sex")
  status.removeEphemeralEffect("sexbound_stun")
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

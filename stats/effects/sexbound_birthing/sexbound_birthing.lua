function init()
  if status.stat('specialStatusImmunity') > 0 then effect.expire() return end
  
  effect.addStatModifierGroup({
    { stat = "invulnerable",           amount = 1 },
    { stat = "fireStatusImmunity",     amount = 1 },
    { stat = "iceStatusImmunity",      amount = 1 },
    { stat = "electricStatusImmunity", amount = 1 },
    { stat = "poisonStatusImmunity",   amount = 1 },
    { stat = "powerMultiplier",        effectiveMultiplier = 0 }
  })
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  mcontroller.setVelocity({ 0, 0 })
  status.setStatusProperty("sexbound_stun", true)
end

function update()
  mcontroller.setVelocity({ 0, 0 })
  mcontroller.controlModifiers({ facingSuppressed = true, movementSuppressed = true })
end

function uninit()
  if status.isResource("stunned") then status.setResource("stunned", 0) end
  status.setStatusProperty("sexbound_stun", false)
end
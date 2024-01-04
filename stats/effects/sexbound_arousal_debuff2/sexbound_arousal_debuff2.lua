function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_strong", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused_strong")
  
  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = 0.9 }
  })
  
  self._effectTimer = 0
  self._doEffect = false
end

function update(dt)
  self._effectTimer = self._effectTimer - dt
  if self._effectTimer <= 0 then
    if math.random() <= 0.1  then self._doEffect = true else self._doEffect = false end
    self._effectTimer = 10
  end
  if self._doEffect then
    mcontroller.controlModifiers({
      speedModifier = 0.9
    })
  end
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_strong", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused_strong")
end

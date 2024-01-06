function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat_weak", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused_heat_weak")
  
  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = 0.95 }
  })
  
  self._effectTimer = 0

  world.sendEntityMessage(entityId, "Sexbound:Arousal:GetMoans", function(moans)
    self._moanSfx = moans or {}
    if self._moanSfx.soundEffects then animator.setSoundPool("moan", self._moanSfx.soundEffects) end
  end
end

function update(dt)
  self._effectTimer = self._effectTimer - dt
  if self._effectTimer <= 0 then
    local rng = math.random()
    if rng <= 0.05 then
      local pitch = self._moanConfig.pitch or 1.0
      if type(pitch) == "table" then pitch = pitch[1] + (math.random() * (pitch[2] - pitch[1])) end
      animator.setSoundPitch("moan", pitch)
      animator.playSound("moan")
    end
    self._effectTimer = 10
  end
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat_weak", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused_heat_weak")
end

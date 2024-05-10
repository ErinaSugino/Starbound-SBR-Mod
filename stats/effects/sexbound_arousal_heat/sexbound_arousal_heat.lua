require "/scripts/messageutil.lua"

function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused_heat")
  
  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = 0.9 }
  })
  
  self._effectTimer = 0
  self._doEffect = false
  self._moanSfx = {}
  self._triedToFetch = false
end

function update(dt)
  promises:update()
  if not self._triedToFetch then
    promises:add(world.sendEntityMessage(entity.id(), "Sexbound:Arousal:GetMoans"), function(moans)
      self._moanSfx = moans or {}
      if self._moanSfx.soundEffects then animator.setSoundPool("moan", self._moanSfx.soundEffects) end
    end)
    self._triedToFetch = true
  end
  self._effectTimer = self._effectTimer - dt
  if self._effectTimer <= 0 then
    local rng = math.random()
    if rng <= 0.1 then
      self._doEffect = true
      local pitch = self._moanSfx.pitch or 1.0
      if type(pitch) == "table" then pitch = pitch[1] + (math.random() * (pitch[2] - pitch[1])) end
      animator.setSoundPitch("moan", pitch)
      animator.playSound("moan")
    else self._doEffect = false end
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
  status.setStatusProperty("sexbound_aroused_heat", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused_heat")
end

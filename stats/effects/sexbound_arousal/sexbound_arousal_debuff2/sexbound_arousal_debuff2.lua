require "/scripts/messageutil.lua"
require "/stats/effects/sexbound_arousal/sexbound_arousal.lua"

function init()
  self._effect = "strong"
  
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_strong", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused_strong")
  
  fetchConfig()
  fetchSpeciesConfig()
  setupEffects()
  setupTimers()
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_strong", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused_strong")
end

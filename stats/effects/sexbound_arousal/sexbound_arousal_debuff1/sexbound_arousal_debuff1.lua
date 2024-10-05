require "/scripts/messageutil.lua"
require "/stats/effects/sexbound_arousal/sexbound_arousal.lua"

function init()
  self._effect = "heat"
  
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused")
  
  fetchConfig()
  fetchSpeciesConfig()
  setupEffects()
  setupTimers()
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused")
end

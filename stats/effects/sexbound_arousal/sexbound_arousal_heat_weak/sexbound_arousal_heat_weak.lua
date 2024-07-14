require "/scripts/messageutil.lua"
require "/stats/effects/sexbound_arousal/sexbound_arousal.lua"

function init()
  self._effect = "heatWeak"
  
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat_weak", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused_heat_weak")
  
  fetchConfig()
  fetchSpeciesConfig()
  setupEffects()
  setupTimers()
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat_weak", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused_heat_weak")
end

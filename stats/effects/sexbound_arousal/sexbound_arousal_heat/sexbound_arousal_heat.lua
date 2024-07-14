require "/scripts/messageutil.lua"
require "/stats/effects/sexbound_arousal/sexbound_arousal.lua"

function init()
  self._effect = "heat"
  
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused_heat")
  
  fetchConfig()
  fetchSpeciesConfig()
  setupEffects()
  setupTimers()
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused_heat", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused_heat")
end

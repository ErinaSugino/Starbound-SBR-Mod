function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_aroused")
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_aroused", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_aroused")
end

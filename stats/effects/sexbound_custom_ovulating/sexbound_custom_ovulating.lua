function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_custom_ovulating", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_custom_ovulating")
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_custom_ovulating", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_custom_ovulating")
end

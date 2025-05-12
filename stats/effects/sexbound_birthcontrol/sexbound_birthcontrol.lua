function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_birthcontrol", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "birthcontrol")
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_birthcontrol", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "birthcontrol")
end

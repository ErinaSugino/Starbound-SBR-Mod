function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_custom_fertility", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_custom_fertility")
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_custom_fertility", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_custom_fertility")
end

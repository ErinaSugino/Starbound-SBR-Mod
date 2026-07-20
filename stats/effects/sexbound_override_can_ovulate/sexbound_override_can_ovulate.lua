function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_override_can_ovulate", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_override_can_ovulate")
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_override_can_ovulate", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_override_can_ovulate")
end

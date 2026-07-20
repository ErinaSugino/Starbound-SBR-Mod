function init()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_override_can_produce_sperm", true)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:AddStatus", "sexbound_override_can_produce_sperm")
end

function uninit()
  local entityId = entity.id()
  status.setStatusProperty("sexbound_override_can_produce_sperm", false)
  world.sendEntityMessage(entityId, "Sexbound:Pregnant:RemoveStatus", "sexbound_override_can_produce_sperm")
end

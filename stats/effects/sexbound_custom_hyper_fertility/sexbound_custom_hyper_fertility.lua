function init()
  self._aborted = status.getStatusProperty("sexbound_penalty_hyper_fertility", false)
  if self._aborted then effect.expire() end
  status.setStatusProperty("sexbound_custom_hyper_fertility", true)
  world.sendEntityMessage(entity.id(), "Sexbound:Pregnant:AddStatus", "sexbound_custom_hyper_fertility")
end

function uninit()
  status.setStatusProperty("sexbound_custom_hyper_fertility", false)
  world.sendEntityMessage(entity.id(), "Sexbound:Pregnant:RemoveStatus", "sexbound_custom_hyper_fertility")
end

function onExpire()
end

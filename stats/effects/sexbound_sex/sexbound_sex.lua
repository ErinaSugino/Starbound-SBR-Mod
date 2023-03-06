function init()
  effect.setParentDirectives("?multiply=ffffff00") -- Hide the entity from view
  status.setStatusProperty("sexbound_sex", true)
  world.sendEntityMessage(entity.id(), "Sexbound:Common:StartSexMusic")
end

function uninit()
  status.setStatusProperty("sexbound_sex", false)
  world.sendEntityMessage(entity.id(), "Sexbound:Common:StopSexMusic")
end

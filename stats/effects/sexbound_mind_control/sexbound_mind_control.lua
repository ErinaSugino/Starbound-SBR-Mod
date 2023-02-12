function init()
  local defaultTimeout = 300
  world.sendEntityMessage(entity.id(), "Sexbound:Transform", {
    timeout = effect.getParameter("timeout", defaultTimeout)
  })
  effect.expire()
end
require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
  
  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
	forceRole = 1,
    identity = {
      name    = "Glitch Dildo",
      species = "sexbound_dildo_glitch",
      gender  = "male",
      forceRole    = 1
    }
  })
end

function update(dt)
  Sexbound.API.update(dt)
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args)
end

function uninit()
  Sexbound.API.uninit()
end

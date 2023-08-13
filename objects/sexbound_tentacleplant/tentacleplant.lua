require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
  
  local hueshiftvalue = "?hueshift=0;"
  
  hueshiftvalue = ("?hueshift=" .. object.level())
  
  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
    identity = {
      name    = "Tentacle Plant",
      species = "sexbound_tentacleplant",
      gender  = "male",
      role    = 1,
	  bodyDirectives = hueshiftvalue
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

require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
  
  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
	forceRole = 1,
    identity = {
      name    = "Rainbow Dildo",
      species = "sexbound_dildo_rainbow",
      gender  = "male",
      forceRole    = 1
    }
  })
end

local rainbowvalue = 0
local rainbowvaluetrue = "?hueshift="
local rainbowvaluefinal = "?hueshift=0"

function update(dt)
  Sexbound.API.update(dt)
  rainbowvalue = rainbowvalue + 5
  if ( rainbowvalue == 360 ) then rainbowvalue = 0 end
  rainbowvaluefinal = (rainbowvaluetrue .. rainbowvalue)
  animator.setGlobalTag("actor1-bodyDirectives", rainbowvaluefinal)
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args)
end

function uninit()
  Sexbound.API.uninit()
end

require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
  
  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
	forceRole = 2,
    identity = {
      name    = "Rainbow Fleshlight",
      species = "sexbound_fleshlight_rainbow",
      gender  = "female",
      forceRole    = 2
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
  animator.setGlobalTag("actor2-bodyDirectives", rainbowvaluefinal)
  animator.setGlobalTag("rainbowDirectives", rainbowvaluefinal)
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args)
end

function uninit()
  Sexbound.API.uninit()
end

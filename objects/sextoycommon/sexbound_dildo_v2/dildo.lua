require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
  
  local colorvaluetrue = "?hueshift="
  local colorvaluefinal = "?hueshift=0"
  local saturationvaluetrue = ";?saturation="
  local saturationvaluefinal = ";?saturation=-1"
  local brightnessvaluetrue = ";?brightness="
  local brightnessvaluefinal = ";?brightness=0"
  
  if config.getParameter("cleanObject", true) then
  
    local colorvalue = ( math.floor( 360 * math.random() ) ) 
	local saturationvalue = ( -( math.floor( 101 * math.random() ) ) )
	local brightnessvalue = ( -( math.floor( 81 * math.random() ) ) )
    object.setConfigParameter("cleanObject", false)
	object.setConfigParameter("description", config.getParameter("descriptionNew"))
	object.setConfigParameter("shortdescription", config.getParameter("shortdescriptionNew"))
	object.setConfigParameter("hueshiftValue", colorvalue)
	object.setConfigParameter("saturationValue", saturationvalue)
	object.setConfigParameter("brightnessValue", brightnessvalue)	
	colorvaluefinal = (colorvaluetrue .. colorvalue)
	saturationvaluefinal = (saturationvaluetrue .. saturationvalue)	
	brightnessvaluefinal = (brightnessvaluetrue .. brightnessvalue)
	object.setConfigParameter("inventoryIcon", "dildoicon.png" .. colorvaluefinal .. saturationvaluefinal .. brightnessvaluefinal)
	
  else
  
    local colorvalue = config.getParameter("hueshiftValue")
	local saturationvalue = config.getParameter("saturationValue")
	local brightnessvalue = config.getParameter("brightnessValue")	
	colorvaluefinal = (colorvaluetrue .. colorvalue)
	saturationvaluefinal = (saturationvaluetrue .. saturationvalue)	
	brightnessvaluefinal = (brightnessvaluetrue .. brightnessvalue)
	object.setConfigParameter("inventoryIcon", "dildoicon.png" .. colorvaluefinal .. saturationvaluefinal .. brightnessvaluefinal)
	
  end
  
  animator.setGlobalTag("actor1-bodyDirectives", colorvaluefinal .. saturationvaluefinal .. brightnessvaluefinal)
  
  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
	forceRole = 1,
    identity = {
      name    = "Colored Dildo",
      species = "sexbound_dildo_v2",
      gender  = "male",
      forceRole    = 1,
	  bodyDirectives = (colorvaluefinal .. saturationvaluefinal .. brightnessvaluefinal)
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

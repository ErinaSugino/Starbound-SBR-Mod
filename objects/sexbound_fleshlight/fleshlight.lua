require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
  
  local hueshiftvalue = "?hueshift=0;"
  
  hueshiftvalue = ("?hueshift=" .. object.level() .. ";")
  
  local brightnessvalue = "?brightness=-20;"
  
  if (object.name() == "sexbound_fleshlight_white") then brightnessvalue = "?brightness=0;" 
  elseif (object.name() == "sexbound_fleshlight_grey") then brightnessvalue = "?brightness=-45;" 
  elseif (object.name() == "sexbound_fleshlight") then brightnessvalue = "?brightness=-50;" 
  elseif (object.name() == "sexbound_fleshlight_black") then brightnessvalue = "?brightness=-70;" 
  elseif (object.name() == "sexbound_fleshlight_skin1") then brightnessvalue = "?brightness=-3;" 
  elseif (object.name() == "sexbound_fleshlight_skin2") then brightnessvalue = "?brightness=-5;" 
  elseif (object.name() == "sexbound_fleshlight_skin3") then brightnessvalue = "?brightness=-16;" 
  elseif (object.name() == "sexbound_fleshlight_skin4") then brightnessvalue = "?brightness=-31;" 
  elseif (object.name() == "sexbound_fleshlight_skin5") then brightnessvalue = "?brightness=-51;"
  end
  
  local saturationvalue = "?saturation=-20"
  
  if ((object.name() == "sexbound_fleshlight_pink") or (object.name() == "sexbound_fleshlight")) then saturationvalue = "?saturation=-50" 
  elseif ((object.name() == "sexbound_fleshlight_white") or (object.name() == "sexbound_fleshlight_grey") or (object.name() == "sexbound_fleshlight_black")) then saturationvalue = "?saturation=-100" 
  elseif (object.name() == "sexbound_fleshlight_skin1") then saturationvalue = "?saturation=-73" 
  elseif (object.name() == "sexbound_fleshlight_skin2") then saturationvalue = "?saturation=-57"
  elseif (object.name() == "sexbound_fleshlight_skin3") then saturationvalue = "?saturation=-54"
  elseif (object.name() == "sexbound_fleshlight_skin4") then saturationvalue = "?saturation=-40"
  elseif (object.name() == "sexbound_fleshlight_skin5") then saturationvalue = "?saturation=-40" 
  end
  
  --sb.logInfo("Hue, Bright, Sat" .. (hueshiftvalue .. brightnessvalue .. saturationvalue))
  
  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
	forceRole = 2,
    identity = {
      name    = "Fleshlight",
      species = "sexbound_fleshlight",
      gender  = "female",
      forceRole    = 2,
	  bodyDirectives = (hueshiftvalue .. brightnessvalue .. saturationvalue)
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

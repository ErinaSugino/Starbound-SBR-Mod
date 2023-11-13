require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()

  local colorvaluetrue = "?hueshift="
  local colorvaluefinal = "?hueshift=0"

  if config.getParameter("cleanObject", true) then
    local colorvalue = (math.floor(360 * math.random()))
    object.setConfigParameter("cleanObject", false)
    object.setConfigParameter("description", config.getParameter("descriptionNew"))
    object.setConfigParameter("shortdescription", config.getParameter("shortdescriptionNew"))
    object.setConfigParameter("hueshiftValue", colorvalue)
    colorvaluefinal = (colorvaluetrue .. colorvalue)
    object.setConfigParameter("inventoryIcon", "tentacleplanticon.png" .. colorvaluefinal)
  else
    local colorvalue = config.getParameter("hueshiftValue")
    colorvaluefinal = (colorvaluetrue .. colorvalue)
    object.setConfigParameter("inventoryIcon", "tentacleplanticon.png" .. colorvaluefinal)
  end

  Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", { 0, 20 }))

  Sexbound.API.Actors.addActor({
    entityId   = entity.id(),
    entityType = "object",
    identity   = {
      name             = "Tentacle Plant",
      species          = "sexbound_tentacleplant_v2",
      gender           = "male",
      role             = 1,
      offspringType    = "monsters",
      offspringSpecies = "monopus",
      bodyDirectives   = colorvaluefinal
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

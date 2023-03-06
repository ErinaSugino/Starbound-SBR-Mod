require "/scripts/sexbound/v2/api.lua"

function init()
  self.debug = true

  Sexbound.API.init()

  local sitPositions  = config.getParameter("sexboundConfig.sitPositions")
  local nodePositions = config.getParameter("sexboundConfig.nodePositions")

  Sexbound.API.Nodes.addNode(nodePositions[1], sitPositions[1])
  Sexbound.API.Nodes.addNode(nodePositions[2], sitPositions[2])

  local actors = config.getParameter("sexboundConfig.actors")

  if not actors then return end

  for _,actor in ipairs(actors) do
    Sexbound.API.Actors.addActor(actor)
  end
end

function update(dt)
  Sexbound.API.update(dt)
end
function onInteraction(args) return Sexbound.API.handleInteract(args) or nil end
function uninit() Sexbound.API.uninit() end

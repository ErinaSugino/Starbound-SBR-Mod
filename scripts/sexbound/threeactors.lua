require "/scripts/sexbound/v2/api.lua"

function init()
    local defaultPositions = {{0, 0}, {0, 0}, {0, 0}}
    local nodePositions = config.getParameter("sexboundConfig.nodePositions", defaultPositions)
    local sitPositions = config.getParameter("sexboundConfig.sitPositions", defaultPositions)
    Sexbound.API.init(3)
    Sexbound.API.Nodes.addNode(nodePositions[1], sitPositions[1]) -- Add Node #1
    Sexbound.API.Nodes.addNode(nodePositions[2], sitPositions[2]) -- Add Node #2
    Sexbound.API.Nodes.addNode(nodePositions[3], sitPositions[3]) -- Add Node #3
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

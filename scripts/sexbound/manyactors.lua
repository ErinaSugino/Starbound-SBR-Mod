require "/scripts/sexbound/v2/api.lua"

function init()
    local defaultPositions = {{0, 0}, {0, 0}, {0, 0}, {0, 0}}
    local nodePositions = config.getParameter("sexboundConfig.nodePositions", defaultPositions)
    local sitPositions = config.getParameter("sexboundConfig.sitPositions", defaultPositions)
    local nodeCount = #nodePositions
    Sexbound.API.init(nodeCount)
    for i = 1, nodeCount do
        Sexbound.API.Nodes.addNode(nodePositions[i], sitPositions[i]) -- Add Node(s)
    end
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

require "/scripts/sexbound/v2/api.lua"

function init()
    Sexbound.API.init()
    Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
end

function onInteraction(args)
    return Sexbound.API.handleInteract(args)
end

function update(dt)
    Sexbound.API.update(dt)
end

function uninit()
    Sexbound.API.uninit()
end

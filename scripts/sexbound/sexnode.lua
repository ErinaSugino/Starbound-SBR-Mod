require "/scripts/sexbound/v2/api.lua"

function init()
    local seats = config.getParameter("sitPositions", nil)
    if seats == nil then seats = {config.getParameter("sitPosition", nil)} end
    Sexbound.API.init(#seats)
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

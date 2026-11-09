require "/scripts/sexbound/v2/api.lua"

function init()
    ObjectAddons:init({isAddons = {{name = "sexnodeAddon"}}})

    message.setHandler("Sexbound:Addon:Interact", onRemoteInteraction)

    local seats = config.getParameter("sitPositions", nil)
    if seats == nil then seats = {config.getParameter("sitPosition", nil)} end
    Sexbound.API.init(#seats)
end

function uninit()
    Sexbound.API.uninit()
    ObjectAddons:uninit()
end

function update(dt)
    Sexbound.API.update(dt)
end

function die(smashed)
    local host = ObjectAddons:isConnectedAs("sexnodeAddon")
    if host and world.entityExists(host) then world.breakObject(host, smashed) end
end

--- Normal interact handler
--- @param request table InteractRequest
--- @return string|[string, any]|nil # The generated InteractAction data
function onInteraction(request)
    local host = ObjectAddons:isConnectedAs("sexnodeAddon")
    if host and world.loungeableOccupied(host) then return nil end

    local sxbRet = Sexbound.API.handleInteract(request)
    if not sxbRet then return nil end

    return {"SitDown", -1}
end

--- Handler for faked remote interaction request
--- @param args table The provided interaction request
--- @return string|[string, EntityId?, any]? # The InteractAction data as onInteraction should return it, based on the logic of how the object should do it in the backend
function onRemoteInteraction(_, _, args)
    local ret = nil

    if onInteraction then
        local res = onInteraction(args)
        if type(res) == "string" then
            ret = {res, entity.id(), nil}
        elseif res ~= nil then
            ret = {res[1], entity.id(), res[2]}
        end
    else
        local type = config.getParameter("interactAction", nil)
        if type == nil then ret = nil
        else
            local data = config.getParameter("interactData", nil)
            ret = {type, entity.id(), data}
        end
    end

    return ret
end
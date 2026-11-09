local _org_init = init
function init()
    ObjectAddons:init({usesAddons = {{name = "sexnodeAddon", position = config.getParameter("anchorSpace", {0,0})}}})

    if _org_init ~= nil then pcall(_org_init) end

    message.setHandler("Sexbound:Addon:Interact", onRemoteInteraction)

    if not storage._sxbSetup then
        setupSpaces()
        storage._sxbSetup = true
    end
end

local _org_uninit = uninit
function uninit()
    ObjectAddons:uninit()
    if _org_uninit then pcall(_org_uninit) end
end

local _org_update = update
function update(dt)
    if _org_update then pcall(_org_update, dt) end

    if storage._doSxbPlacement then
        placeNode()
    elseif storage._doDungeonProtection ~= nil then
        world.setTileProtection(storage._doDungeonProtection, true)
        storage._doDungeonProtection = nil
    end
end

local _org_onInteraction = onInteraction
function onInteraction(request)
    local node = ObjectAddons:isConnectedTo("sexnodeAddon")
    if node == nil then return {"ShowPopup", {message = "Something didn't work with the addon connection"}} end

    local mySeats = config.getParameter("sitPositions", nil)
    if mySeats == nil then mySeats = {config.getParameter("sitPosition", nil)} end
    mySeats = #mySeats
    local nodeSeats = world.getObjectParameter(node, "sitPositions", nil)
    if nodeSeats == nil then nodeSeats = {world.getObjectParameter(node, "sitPosition", nil)} end
    nodeSeats = #nodeSeats
    return {"ScriptPane", {baseConfig = "/interface/sexbound/selector/radialMenu.config", config = {
        request = request,
        options = {
            {
                type = config.getParameter("objectType", "object"),
                entityId = entity.id(),
                seats = mySeats
            },
            {
                type = "sexnode",
                entityId = node,
                seats = nodeSeats
            }
        }
    }}}
end

--- Defines the correct meta material spaces
function setupSpaces()
    local anchorLocation = config.getParameter("anchorSpace", {0,0})
    object.setMaterialSpaces({{anchorLocation, "metamaterial:sexboundaddonbase"}})

    storage._doSxbPlacement = true
end

--- Sets up the addon node or dies trying
function placeNode()
    storage._doSxbPlacement = nil
    local nodeParams = {
        sexboundConfig = config.getParameter("sexboundConfig", {})
    }

    local prot, dungeonId = world.isTileProtected(object.position()), world.dungeonId(object.position())

    if prot then
        storage._doDungeonProtection = dungeonId
        world.setTileProtection(dungeonId, false)
    end

    local addonConfig = config.getParameter("addonConfig", {})
    if addonConfig.seatCount then nodeParams.sitPositions = _generateSitPositions(addonConfig.seatCount) end
    local res = world.placeObject(addonConfig.addonName or "sexboundaddon00x01", object.position(), object.direction(), nodeParams)
    if not res then
        object.smash(false)
        if prot then world.setTileProtection(dungeonId, true) end
    end
end

--- Handler for faked remote interaction request
--- @param args table The provided interaction request
--- @return string|[string, EntityId?, any]? # The InteractAction data as onInteraction should return it, based on the logic of how the object should do it in the backend
function onRemoteInteraction(_, _, args)
    local objectType = config.getParameter("objectType", "object")
    local ret = nil

    if _org_onInteraction then
        local res = _org_onInteraction(args) --[[@as string|table|nil]]
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

    if ret == nil and objectType == "loungeable" then
        ret = {"SitDown", entity.id(), -1}
    end

    return ret
end

--- [Helper] Generate balanced sitPositions for node param override
--- @param seatCount integer The number of seats to generate
--- @return Vec2I[] # The generated sitPositions
function _generateSitPositions(seatCount)
    local sitPositions = {}
    for i=0,seatCount-1 do
        -- 8-step centered pendulum position (0, -8, 8, -16, 16, ...)
        local mult = (i%2 == 0) and 1 or -1
        local offset = i == 0 and 0 or math.floor((i+1)/2)*8
        table.insert(sitPositions, {mult*offset, 0})
    end
    return sitPositions
end
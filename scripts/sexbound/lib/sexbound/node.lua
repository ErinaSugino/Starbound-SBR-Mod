--- Sexbound.Node Class Module.
--- @class Sexbound.Node
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _controllerId EntityId
--- @field private _logPrefix string
--- @field private _name string
--- @field _sitPosition table<integer, number>
--- @field _tilePosition table<integer, number>
--- @field _parent Sexbound
--- @field _placeObject boolean
--- @field _respawnTimer number
--- @field _respawnTime integer
--- @field _log Sexbound.Log
Sexbound.Node = {}
Sexbound.Node_mt = {
    __index = Sexbound.Node
}

--- Instantiates a new instance of Node.
--- @param parent Sexbound The calling parent sexnode instance
--- @param tilePosition Vec2F X and Y coordinate of position of the node
--- @param sitPosition Vec2F X and Y coordinate of the seat of the node
--- @param placeObject boolean Whethere or not a new node object is to be placed
--- @return Sexbound.Node # The new node instance
function Sexbound.Node.new(parent, tilePosition, sitPosition, placeObject)
    local self = setmetatable({
        _controllerId = parent:getEntityId(),
        _logPrefix = "NODE",
        _name = "sexbound_node_node",
        _sitPosition = sitPosition or {0, 0},
        _parent = parent,
        _placeObject = placeObject,
        _respawnTimer = 0,
        _respawnTime = 5
    }, Sexbound.Node_mt)

    Sexbound.Messenger.get("main"):addBroadcastRecipient(self)

    self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())

    -- Adjust sit position based on object's facing direction
    self._sitPosition[1] = self._sitPosition[1] * object.direction()

    tilePosition = tilePosition or {0, 0}

    self._tilePosition = vec2.floor(vec2.add(entity.position(), tilePosition))

    if not self._placeObject then
        self:setEntityId(self._controllerId)
    end

    return self
end

--- Function called each tick
--- @param dt number The delta time since last tick
function Sexbound.Node:update(dt)
    if not self._placeObject then
        return
    end

    self._respawnTimer = self._respawnTimer + dt

    if self._respawnTimer >= self._respawnTime then
        local uniqueId = self:getUniqueId()

        if not uniqueId or world.findUniqueEntity(uniqueId):result() == nil then
            self:create()
        end

        self._respawnTimer = 0
    end
end

--- Place a new sexbound node object at specified tile position.
--- @param params ?table Optional parameters
function Sexbound.Node:create(params)
    params = params or {}

    local uniqueId = sb.makeUuid()

    params.sitPosition = self._sitPosition
    params.controllerId = self._controllerId
    params.uniqueId = uniqueId

    local dungeonId = Sexbound.Util.tileProtectionDisable(self._tilePosition);

    if world.placeObject(self._name, self._tilePosition, object.direction(), params) then
        self._uniqueId = uniqueId
    end

    if dungeonId ~= nil then Sexbound.Util.tileProtectionEnable(dungeonId) end
end

--- Sends lounging command to target entity.
--- @param entityId EntityId The entity's id who is to lounge in here
function Sexbound.Node:lounge(entityId)
    local loungeId = self:getEntityId()

    if entityId and loungeId then
        world.sendEntityMessage(entityId, "Sexbound:Node:Lounge", {
            controllerId = self:getControllerId(),
            loungeId = loungeId
        })
    end
end

--- Returns whether or not this node is occupied.
--- @return boolean # Whethere or not this node is occupied
function Sexbound.Node:occupied()
    local entityId = self:getEntityId()

    if entityId and world.entityExists(entityId) then
        return world.loungeableOccupied(entityId)
    end

    return true
end

--- Uninitializes this instance.
function Sexbound.Node:uninit()
    local controllerId = self:getUniqueId() or self:getEntityId()

    if controllerId then
        world.sendEntityMessage(controllerId, "Sexbound:Node:Uninit")
    end
end

--- Returns the entityId for this node.
--- @return EntityId # This instance's entity ID
function Sexbound.Node:getEntityId()
    return self._entityId
end

--- Set this instance's entity ID
--- @param entityId EntityId The new entity ID to react to
function Sexbound.Node:setEntityId(entityId)
    self._entityId = entityId
end

--- Returns this node's parent sexnode's entity ID
--- @return EntityId # The parent sexnode's entity ID
function Sexbound.Node:getControllerId()
    return self._controllerId
end

--- Returns the uniqueId for this Node's object.
--- @return string # The uuid of this object
function Sexbound.Node:getUniqueId()
    return self._uniqueId
end

--- Sets a new uniqueId for this Node's object
--- @param uniqueId string The new uuid
function Sexbound.Node:setUniqueId(uniqueId)
    self._uniqueId = uniqueId
end

--- Returns this Node's logger instance
--- @return Sexbound.Log # The logging instance
function Sexbound.Node:getLog()
    return self._log
end

--- Returns the set log prefix
--- @return string # This Node's log prefix
function Sexbound.Node:getLogPrefix()
    return self._logPrefix
end

--- Returns the parent sexnode instance
--- @return Sexbound # The parent sexnode instance
function Sexbound.Node:getParent()
    return self._parent
end

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/spawnPoint.lua"

--- Abstract shared transformation manager class
--- @class Sexbound.Common.Transform
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _canTransform boolean
--- @field protected _nodeName string
--- @field _timeout number
--- @field _feetOffset number
Sexbound.Common.Transform = {}
Sexbound.Common.Transform_mt = {
    __index = Sexbound.Common.Transform
}

--- Creates new instance of shared transformation manager
--- @return Sexbound.Common.Transform # The newly created transformation manager instance
function Sexbound.Common.Transform:new()
    return setmetatable({
        _canTransform = false,
        _nodeName = "sexbound_main_node",
        _timeout = 300
    }, Sexbound.Common.Transform_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Transform:init(parent)
    self._parent = parent

    self._feetOffset = self:calculateFeetPositionOffset()
end

--- Returns a nearby position within the specified rectangle.
--- @param rectSize number? # Unused
--- @return Vec2I? # The tile coordinates of the space, if any found
function Sexbound.Common.Transform:findNearbyOpenSpace(rectSize)
    local yOffset = 0.5

    local startPosition = entity.position()
    startPosition[2] = (startPosition[2] - self._feetOffset) + yOffset

    local endPosition = vec2.add(startPosition, {0, -10})

    local position = world.lineCollision(startPosition, endPosition, {"Block", "Platform"})

    if position == nil then
        return nil
    end

    position = vec2.floor(position)

    if not world.tileIsOccupied(position, true) then
        return position
    end

    return nil
end

--- Attempts to place a sex node at a specified position.
--- @param position Vec2I The tile position to place at
--- @param spawnOptions table? Spawn override parameters
--- @return string? # The uuid of the spawned node, if successful
function Sexbound.Common.Transform:placeSexNode(position, spawnOptions)
    local dungeonId = Sexbound.Util.tileProtectionDisable(position)

    local result = self:helper_SpawnSexNode(position, spawnOptions)
    if dungeonId ~= nil then Sexbound.Util.tileProtectionEnable(dungeonId) end

    return result
end

--- Destroy the associated transformation sexnode
--- OG Comment: "This function may never actually work while the NPC is stunned"
function Sexbound.Common.Transform:smashSexNode()
    local controllerId = self._controllerId or (self._parent --[[@as Sexbound.NPC]])._loungeId

    if controllerId then world.sendEntityMessage(controllerId, "Sexbound:Smash") end
    self._controllerId = nil
end

--- [Helper] Returns the entity's feet position.
--- @return number # Y-offset of the entity's feet from the entity position center
function Sexbound.Common.Transform:calculateFeetPositionOffset()
    local position = entity.position()

    if mcontroller then
        return position[2] - poly.boundBox(mcontroller.collisionBody())[2]
    end

    return 2.5 -- Else take a wild guess that it's 2.5
end

--- [Helper] Handles the process of spawning a sex node at a specified position.
--- @protected
--- @param position Vec2I Tile position to spawn at
--- @param spawnOptions table? Spawn override parameters
--- @return string? # The uuid of the spawned object entity, if successful
function Sexbound.Common.Transform:helper_SpawnSexNode(position, spawnOptions)
    spawnOptions = spawnOptions or {}

    local params = {
        mindControl = {
            timeout = self._timeout -- 5 minutes by default unless overrided
        },
        respawner = storage.respawner,
        sexboundConfig = self:getSexboundConfig(),
        storedActor = self:getParent():getActorData(),
        uniqueId = sb.makeUuid()
    }

    -- Randomize the start position when true
    params.sexboundConfig.randomStartPosition = spawnOptions.randomStartPosition

    local facingDirection = 1

    -- Determine facing direction of the entity
    if mcontroller and "function" == type(mcontroller.facingDirection) then
        facingDirection = mcontroller.facingDirection()
    end

    if world.placeObject(self._nodeName, position, facingDirection, params) then
        self:setPosition(position[1], position[2] + self._feetOffset)

        if not spawnOptions.noEffect then
            world.sendEntityMessage(entity.id(), "applyStatusEffect", "sexbound_transform")
        end

        return params.uniqueId
    end

    return nil
end

-- [[ Getters/Setters ]]

--- Returns whethere or not this entity can transform
--- @return boolean # Whethere or not this entity can transform
function Sexbound.Common.Transform:getCanTransform()
    return self._canTransform
end

--- Sets whethere or not this entity can transform
--- @param canTransform boolean Whethere or not this entity can transform
function Sexbound.Common.Transform:setCanTransform(canTransform)
    self._canTransform = canTransform
end

--- Returns parent entity manager instance
--- @return Sexbound.Common # The parent entity manager instance
function Sexbound.Common.Transform:getParent()
    return self._parent
end

--- Returns the entity's potential sexboundConfig extra data
--- @return table # The defined data
function Sexbound.Common.Transform:getSexboundConfig()
    return self._sexboundConfig or config.getParameter("sexboundConfig", {})
end

--- Sets the entity's sexboundConfig extra data
--- @param sexboundConfig table The new sexboundConfig extra data
function Sexbound.Common.Transform:setSexboundConfig(sexboundConfig)
    self._sexboundConfig = sexboundConfig
end

--- Returns the entity's transformation timeout
--- @return number # The current timeout value
function Sexbound.Common.Transform:getTimeout()
    return self._timeout
end

--- Sets the entity's transformation timeout
--- @param amount number The new timeout value
function Sexbound.Common.Transform:setTimeout(amount)
    self._timeout = amount or self._timeout
end

--- Moves the entity if possible
--- @param x number X coordinate
--- @param y number Y coordinate
function Sexbound.Common.Transform:setPosition(x, y)
    if mcontroller == nil then
        return
    end

    if type(mcontroller.setXPosition) == "function" and type(mcontroller.setYPosition) == "function" then
        mcontroller.setXPosition(x)
        mcontroller.setYPosition(y)
    end
end

-- [[ Abstract ]]
--- Placeholder message handler for transformation request
--- @param args table Transformation config
--- @return table|boolean|nil # The transform result, true if request was sent or false if not possible
function Sexbound.Common.Transform:handleTransform(args) return nil end

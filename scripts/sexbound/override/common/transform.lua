require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/spawnPoint.lua"

Sexbound.Common.Transform = {}
Sexbound.Common.Transform_mt = {
    __index = Sexbound.Common.Transform
}

function Sexbound.Common.Transform:new()
    return setmetatable({
        _canTransform = false,
        _nodeName = "sexbound_main_node",
        _timeout = 300
    }, Sexbound.Common.Transform_mt)
end

--- Initializes this object
function Sexbound.Common.Transform:init(parent)
    self._parent = parent

    self._feetOffset = self:calculateFeetPositionOffset()
end

--- Returns a nearby position within the specified rectangle.
-- @param rectSize
function Sexbound.Common.Transform:findNearbyOpenSpace(rectSize)
    local yOffset = 0.5

    local startPosition = entity.position()
    startPosition[2] = (startPosition[2] - self._feetOffset) + yOffset

    local endPosition = vec2.add(startPosition, {0, -10})

    local position = world.lineCollision(startPosition, endPosition, {"Block", "Platform"})

    if position == nil then
        return false
    end

    position = vec2.floor(position)

    if not world.tileIsOccupied(position, true) then
        return position
    end

    return false
end

--- Attempts to place a sex node at a specified position.
-- @param position
-- @param spawnOptions
function Sexbound.Common.Transform:placeSexNode(position, spawnOptions)
    local dungeonId = Sexbound.Util.tileProtectionDisable(position)
    local result = self:helper_SpawnSexNode(position, spawnOptions)

    Sexbound.Util.tileProtectionEnable(dungeonId)

    return result
end

--- This function may never actually work while the NPC is stunned
function Sexbound.Common.Transform:smashSexNode()
    local controllerId = self._controllerId or self._loungeId

    if controllerId then world.sendEntityMessage(controllerId, "Sexbound:Smash") end
    self._controllerId = nil
end

-- [Helper] Returns the entity's feet position.
function Sexbound.Common.Transform:calculateFeetPositionOffset()
    local position = entity.position()

    if mcontroller then
        return position[2] - poly.boundBox(mcontroller.collisionBody())[2]
    end

    return 2.5 -- Else take a wild guess that it's 2.5
end

-- [Helper] Handles the process of spawning a sex node at a specified position.
-- @param position
-- @param spawnOptions
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

-- Getters/Setters

function Sexbound.Common.Transform:getCanTransform()
    return self._canTransform
end
function Sexbound.Common.Transform:setCanTransform(canTransform)
    self._canTransform = canTransform
end
function Sexbound.Common.Transform:getParent()
    return self._parent
end
function Sexbound.Common.Transform:getSexboundConfig()
    return self._sexboundConfig or config.getParameter("sexboundConfig", {})
end
function Sexbound.Common.Transform:setSexboundConfig(sexboundConfig)
    self._sexboundConfig = sexboundConfig
end
function Sexbound.Common.Transform:getTimeout()
    return self._timeout
end
function Sexbound.Common.Transform:setTimeout(amount)
    self._timeout = amount or self._timeout
end

function Sexbound.Common.Transform:setPosition(x, y)
    if mcontroller == nil then
        return
    end

    if type(mcontroller.setXPosition) == "function" and type(mcontroller.setYPosition) == "function" then
        mcontroller.setXPosition(x)
        mcontroller.setYPosition(y)
    end
end

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
        _timeout = 300,
        _promises = PromiseKeeper.new()
    }, Sexbound.Common.Transform_mt)
end

--- Initializes this object
function Sexbound.Common.Transform:init(parent)
    self._parent = parent

    self._feetOffset = self:calculateFeetPositionOffset()
end

--- Returns 5 nearby positions within 10 blocks underneath the entity.
function Sexbound.Common.Transform:findNearbyOpenSpace(startPosition)
    local yOffset = 0.5
    local distance = 6
    local positive = true
    local positions = {}
    local counter = 0
    local position = nil
    startPosition = startPosition or entity.position()
    startPosition[2] = (startPosition[2] - self._feetOffset) + yOffset
    local endPosition = vec2.add(startPosition, {0, -10})
    for i=0,distance * 2 do
        position = world.lineCollision(startPosition, endPosition, {"Block", "Platform"})
        table.insert(positions, position)
        counter = counter + 1
        if positive then
            startPosition[1] = startPosition[1] + counter
            endPosition[1] = endPosition[1] + counter
            positive = false
        else
            startPosition[1] = startPosition[1] - counter
            endPosition[1] = endPosition[1] - counter
            positive = true
        end

    end

    if positions == {} then
        return false
    end

    return positions
end

--- Attempts to place a sex node beneath an entity.
-- @param position
-- @param spawnOptions
function Sexbound.Common.Transform:placeSexNode(spawnOptions, position, actorData)
    local dungeonId = Sexbound.Util.tileProtectionDisable(position or entity.position())
    local uniqueId = self:helper_SpawnSexNode(spawnOptions, position or nil, actorData or nil)
    Sexbound.Util.tileProtectionEnable(dungeonId)
    return uniqueId
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

-- [Helper] Handles the process of spawning a sex node in a tile beneath the entity.
-- @param position
-- @param spawnOptions
function Sexbound.Common.Transform:helper_SpawnSexNode(spawnOptions, position, actorData)
    local positions = self:findNearbyOpenSpace(position)
    local params = {
        mindControl = {
            timeout = self._timeout -- 5 minutes by default unless overrided
        },
        respawner = storage.respawner,
        sexboundConfig = self:getSexboundConfig(),
        storedActor = actorData or nil,
        uniqueId = sb.makeUuid()
    }


    spawnOptions = spawnOptions or {}

    -- Randomize the start position when true
    --params.sexboundConfig.randomStartPosition = spawnOptions.randomStartPosition

    local facingDirection = 1

    -- Determine facing direction of the entity
    if mcontroller and "function" == type(mcontroller.facingDirection) then
        facingDirection = mcontroller.facingDirection()
    end

    -- Iterate through list of scanned tile positions until node is placed.
    local uniqueId = params.uniqueId
    for _, targetTile in ipairs(positions) do
        -- In the future, we'll need to handle tile protection on a different entity in case of a player being transformed
        local placed = world.placeObject(self._nodeName, targetTile, facingDirection, params)
        if placed then
            if actorData.entityType == "player" then 
                world.sendEntityMessage(actorData.entityId, "Sexbound:Defeat:SetPosition", {targetTile[1], targetTile[2] + 2.5})
            elseif mcontroller then
                mcontroller.setPosition(targetTile[1], targetTile[2] + self._feetOffset)
            end
            if not spawnOptions.noEffect then
                world.sendEntityMessage(actorData.entityId, "applyStatusEffect", "sexbound_transform")
            end
            return params.uniqueId
        end
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

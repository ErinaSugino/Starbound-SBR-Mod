--- Sexbound.API Module.
-- @module Sexbound.API
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require "/scripts/sexbound/lib/sexbound.lua"
end

Sexbound.API = {}

if not SXB_RUN_TESTS then
    require "/scripts/sexbound/v2/api/actors.lua"
    require "/scripts/sexbound/v2/api/nodes.lua"
    require "/scripts/sexbound/v2/api/positions.lua"
    require "/scripts/sexbound/v2/api/statemachine.lua"
end

--- Initializes a new instance of Sexbound.
-- @usage function init() Sexbound.API.init() end
Sexbound.API.init = function(maxActors)
    maxActors = maxActors or 2
    if maxActors <= 0 then maxActors = 1 end
    local _, result = xpcall(function()
        self._sexbound = Sexbound.new(maxActors)

        return self._sexbound
    end, sb.logError)

    return result
end

--- Updates the current instance.
-- @param dt The attached to entities delta time value.
-- @usage function update(dt) Sexbound.API.update(dt) end
Sexbound.API.update = function(dt)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:update(dt)
    end, sb.logError)

    return result
end

--- Uninitializes the current instance.
-- @usage function uninit() Sexbound.API.uninit() end
Sexbound.API.uninit = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:uninit()
    end, sb.logError)

    return result
end

--- Returns the running configuration for the current instance.
-- @usage local version = Sexbound.API.getConfig().version
Sexbound.API.getConfig = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getConfig()
    end, sb.logError)

    return result
end

--- Return the current animation rate of the attached to entity.
-- @usage local animationRate = Sexbound.API.getAnimationRate()
Sexbound.API.getAnimationRate = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getAnimationRate()
    end, sb.logError)

    return result
end

--- Replace the animation rate with a specified rate.
-- @param animRate A positive integer value.
-- @usage Sexbound.API.setAnimationRate(1)
Sexbound.API.setAnimationRate = function(animRate)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:setAnimationRate(animRate)
    end, sb.logError)

    return result
end

--- Returns the facing direction of the attached to entity.
-- @usage local facingDirection = Sexbound.API.getFacingDirection()
Sexbound.API.getFacingDirection = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getFacingDirection()
    end, sb.logError)

    return result
end

--- Returns the entity name of the attached to entity.
-- @usage local name = Sexbound.API.getEntityName()
Sexbound.API.getEntityName = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getEntityName()
    end, sb.logError)

    return result
end

--- Returns the state machine for the current instance.
-- @usage local stateMachine = Sexbound.API.getStateMachine()
Sexbound.API.getStateMachine = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getStateMachine()
    end, sb.logError)

    return result
end

--- Returns the UUID of the entity running Sexbound.
-- @usage local id = Sexbound.API.getUniqueId()
Sexbound.API.getUniqueId = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getUniqueId()
    end, sb.logError)

    return result
end

--- Returns the storage of this entity
-- @usage local s = Sexbound.API.getStorage()
Sexbound.API.getStorage = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getStorage()
    end, sb.logError)

    return result
end

--- Returns the current version of the API.
-- @usage local version = Sexbound.API.getVersion()
Sexbound.API.getVersion = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getVersion()
    end, sb.logError)

    return result
end

--- Handles the specified arguments from an interact request.
-- @param args The arguments table from this object's onInteraction hook.
-- @usage function onInteraction(args) return Sexbound.API.handleInteract(args) end
Sexbound.API.handleInteract = function(args)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:handleInteract(args)
    end, sb.logError)

    return result
end

--- Commands this object to respawn the stored actor.
-- @usage function die() Sexbound.API.respawnStoredActor() end
Sexbound.API.respawnStoredActor = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:respawnStoredActor()
    end, sb.logError)

    return result
end

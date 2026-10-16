if not SXB_RUN_TESTS then
    require "/scripts/sexbound/lib/sexbound.lua"
end

--- Sexbound.API Module.
--- @class Sexbound.API
--- @author Locuturus
--- @license GNU General Public License v3.0
Sexbound.API = {}

if not SXB_RUN_TESTS then
    require "/scripts/sexbound/v2/api/actors.lua"
    require "/scripts/sexbound/v2/api/nodes.lua"
    require "/scripts/sexbound/v2/api/positions.lua"
    require "/scripts/sexbound/v2/api/statemachine.lua"
end

--- Initializes a new instance of Sexbound.
--- @param maxActors integer The maximum number of actors
--- @return Sexbound # The Sexbound instance or the error message
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
--- @param dt number The delta time since last tick
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
--- @return boolean # Whethere or not uninitialization was successful
Sexbound.API.uninit = function()
    if not self._sexbound then
        return true
    end

    local _, result = xpcall(function()
        return self._sexbound:uninit()
    end, sb.logError)

    return result
end

--- Returns the running configuration for the current instance.
--- @return table? # The config of the sexbound instance or nil if sexbound instance does not exist
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
--- @return number # The current animation rate
Sexbound.API.getAnimationRate = function()
    if not self._sexbound then
        return 0
    end

    local _, result = xpcall(function()
        return self._sexbound:getAnimationRate()
    end, sb.logError)

    return result
end

--- Replace the animation rate with a specified rate.
--- @param animRate number The new animation rate
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
--- @return integer|nil
--- |"1" # Right
--- |"-1" # Left
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
--- @return string? # The object entity's name or nil if sexbound instance does not exist
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
--- @return Sexbound.StateMachine? # The statemachine or nil if sexbound instance doesn't exist
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
--- @return string? # The sexnode's uuid or nil if sexbound instance does not exist
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
--- @return table? # The object's storage or nil if sexbound instance does not exist
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
--- @return string? # The version number or nil if sexbound instance does not exist
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
--- @param args table The arguments table from this object's onInteraction hook.
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
Sexbound.API.respawnStoredActor = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:respawnStoredActor()
    end, sb.logError)

    return result
end

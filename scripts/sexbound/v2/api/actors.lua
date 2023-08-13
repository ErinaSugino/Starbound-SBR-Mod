--- Sexbound.API.Actors Module.
-- @module Sexbound.API.Actors
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.API.Actors = {}

--- Adds a new actor to the current instance.
-- @param actorConfig A table representing the actor.
-- @param store A boolean indicating wether or not to store the actor.
-- @usage Sexbound.API.Actors.addActor(actorConfig, false)
Sexbound.API.Actors.addActor = function(actorConfig, store)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:addActor(actorConfig, store)
    end, sb.logError)

    return result
end

--- Returns a list of all current actors.
-- @usage local actors = Sexbound.API.Actors.getActors()
Sexbound.API.Actors.getActors = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getActors()
    end, sb.logError)

    return result
end

--- Replace current actors with a list of new actors.
-- @param newActors A list of actors.
Sexbound.API.Actors.setActors = function(newActors)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:setActors(newActors)
    end, sb.logError)

    return result
end

--- Returns the current actor count.
-- @usage local actorsCount = Sexbound.API.Actors.getActorCount()
Sexbound.API.Actors.getActorCount = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getActorCount()
    end, sb.logError)

    return result
end

--- Uninitializes all actors.
-- @usage Sexbound.API.Actors.uninitActors()
Sexbound.API.Actors.uninitActors = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:uninitActors()
    end, sb.logError)

    return result
end

--- Translates actors to a new position.
-- @param translation { x, y }
Sexbound.API.Actors.adjustPosition = function(translation)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        local controller = self._sexbound._adjustActorsPositionController

        return controller:adjustActorsPosition(translation)
    end, sb.logError)

    return result
end

--- Rotates actors to a new rotation.
-- @param rotation (euler)
-- @param[opt] rotationCenter
Sexbound.API.Actors.adjustRotation = function(rotation, rotationCenter)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        local controller = self._sexbound._adjustActorsRotationController

        return controller:adjustActorsRotation(rotation, rotationCenter)
    end, sb.logError)

    return result
end

--- Scales actors to a new scale.
-- @param scale a floating point number.
-- @param[opt] scaleCenter
Sexbound.API.Actors.adjustScale = function(scale, scaleCenter)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        local controller = self._sexbound._adjustActorsScaleController

        return controller:adjustActorsScale(scale, scaleCenter)
    end, sb.logError)

    return result
end

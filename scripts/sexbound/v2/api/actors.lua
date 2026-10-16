--- Sexbound.API.Actors Module.
--- @class Sexbound.API.Actors
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.API.Actors = {}

--- Adds a new actor to the current instance.
--- @param actorConfig table A table representing the actor.
--- @param store boolean? A boolean indicating wether or not to store the actor.
--- @return boolean # Whethere or not the actor was successfully added
Sexbound.API.Actors.addActor = function(actorConfig, store)
    if not self._sexbound then
        return false
    end

    local _, result = xpcall(function()
        return self._sexbound:addActor(actorConfig, store)
    end, sb.logError)

    return result
end

--- Returns a list of all current actors.
--- @return table<integer, Sexbound.Actor>? # The list of actors or nil if sexbound instance does not exist
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
--- @param newActors table<integer, Sexbound.Actor> A list of actors.
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
--- @return integer # The current amount of actors
Sexbound.API.Actors.getActorCount = function()
    if not self._sexbound then
        return 0
    end

    local _, result = xpcall(function()
        return self._sexbound:getActorCount()
    end, sb.logError)

    return result
end

--- Uninitializes all actors.
--- @return boolean # Wethere or not uninitializing the actors was successful
Sexbound.API.Actors.uninitActors = function()
    if not self._sexbound then
        return false
    end

    local _, result = xpcall(function()
        return self._sexbound:uninitActors()
    end, sb.logError)

    return result
end

--- Translates actors to a new position.
--- @param translation Vec2F Actor translation
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
--- @param rotation number Rotation (in degrees?)
--- @param rotationCenter Vec2F? Rotation axis offset from top left
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
--- @param scale number New scale factor
--- @param scaleCenter Vec2F? Scale center offset from top left
--- @return boolean # Whethere or not scaling was successful
Sexbound.API.Actors.adjustScale = function(scale, scaleCenter)
    if not self._sexbound then
        return false
    end

    local _, result = xpcall(function()
        local controller = self._sexbound._adjustActorsScaleController

        return controller:adjustActorsScale(scale, scaleCenter)
    end, sb.logError)

    return result
end

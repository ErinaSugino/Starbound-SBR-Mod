if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/animator/AnimatorService.lua")
end

--- Yet another wrapper for animator operations - Transformations
--- @class Sexbound.TransformationsGateway
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _animatorService Sexbound.AnimatorService
Sexbound.TransformationsGateway = {}
Sexbound.TransformationsGateway_mt = {
    __index = Sexbound.TransformationsGateway
}

--- Creates new wrapper instance
--- @param animatorService Sexbound.AnimatorService|nil A pre-existing animator wrapper
--- @return Sexbound.TransformationsGateway # The new wrapper instance
function Sexbound.TransformationsGateway:new(animatorService)
    return setmetatable({
        _animatorService = animatorService or Sexbound.AnimatorService:new()
    }, Sexbound.TransformationsGateway_mt)
end

--- Adjusts the position of the actors in the sexnode
--- @param translation Vec2F X and Y coordinate as to how to offset the actors from their origin
function Sexbound.TransformationsGateway:adjustActorsPosition(translation)
    self._animatorService:translateTransformationGroup("actors", translation)
end

--- Rotates the actors in the sexnode
--- @param rotation number Rotation (in degrees?)
--- @param rotationCenter Vec2F X and Y coordinate of where the rotation axle is offset from top left
function Sexbound.TransformationsGateway:adjustActorsRotation(rotation, rotationCenter)
    self._animatorService:rotateTransformationGroup("actors", rotation, rotationCenter)
end

--- Scales the actors in the sexnode
--- @param scale number The scale factor. 1 for normal size
--- @param scaleCenter Vec2F X and Y coordinate of where the scale origin is offset from top left
function Sexbound.TransformationsGateway:adjustActorsScale(scale, scaleCenter)
    self._animatorService:scaleTransformationGroup("actors", scale, scaleCenter)
end

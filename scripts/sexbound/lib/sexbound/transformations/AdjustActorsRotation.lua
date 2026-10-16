if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/TransformationsGateway.lua")
end

--- Wrapper for actor rotation
--- @class Sexbound.AdjustActorsRotation
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _gateway Sexbound.TransformationsGateway
Sexbound.AdjustActorsRotation = {}
Sexbound.AdjustActorsRotation_mt = {
    __index = Sexbound.AdjustActorsRotation
}

--- Creates new wrapper instance
--- @param adjustActorsRotating Sexbound.TransformationsGateway|nil A pre-existing transformation wrapper
--- @return Sexbound.AdjustActorsRotation # The new wrapper instance
function Sexbound.AdjustActorsRotation:new(adjustActorsRotating)
    return setmetatable({
        _gateway = adjustActorsRotating or Sexbound.TransformationsGateway:new()
    }, Sexbound.AdjustActorsRotation_mt)
end

--- Rotates actors in a complicatedly nested way
--- @param adjustActorsRotationInput table The rotation data - needs to contain "rotation" as number and can contain "rotationCenter" as Vec2F
function Sexbound.AdjustActorsRotation:execute(adjustActorsRotationInput)
    self:adjustActorsRotation(adjustActorsRotationInput)
end

--- Actually rotates actors in a complicatedly nested way
--- @param adjustActorsRotationInput table The rotation data - needs to contain "rotation" as number and can contain "rotationCenter" as Vec2F
function Sexbound.AdjustActorsRotation:adjustActorsRotation(adjustActorsRotationInput)
    self._gateway:adjustActorsRotation(adjustActorsRotationInput.rotation, adjustActorsRotationInput.rotationCenter)
end

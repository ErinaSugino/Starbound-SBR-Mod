if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/TransformationsGateway.lua")
end

Sexbound.AdjustActorsRotation = {}
Sexbound.AdjustActorsRotation_mt = {
    __index = Sexbound.AdjustActorsRotation
}

function Sexbound.AdjustActorsRotation:new(adjustActorsRotating)
    return setmetatable({
        _gateway = adjustActorsRotating or Sexbound.TransformationsGateway:new()
    }, Sexbound.AdjustActorsRotation_mt)
end

function Sexbound.AdjustActorsRotation:execute(adjustActorsRotationInput)
    self:adjustActorsRotation(adjustActorsRotationInput)
end

function Sexbound.AdjustActorsRotation:adjustActorsRotation(adjustActorsRotationInput)
    self._gateway:adjustActorsRotation(adjustActorsRotationInput.rotation, adjustActorsRotationInput.rotationCenter)
end

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsRotation.lua")
end

Sexbound.AdjustActorsRotationController = {}
Sexbound.AdjustActorsRotationController_mt = {
    __index = Sexbound.AdjustActorsRotationController
}

function Sexbound.AdjustActorsRotationController:new(useCase)
    return setmetatable({
        _useCase = useCase or Sexbound.AdjustActorsRotation:new()
    }, Sexbound.AdjustActorsRotationController_mt)
end

function Sexbound.AdjustActorsRotationController:adjustActorsRotation(rotation, rotationCenter)
    self._useCase:execute({
        rotation = rotation,
        rotationCenter = rotationCenter
    })
end

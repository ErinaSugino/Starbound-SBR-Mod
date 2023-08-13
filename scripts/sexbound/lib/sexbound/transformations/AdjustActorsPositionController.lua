if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsPosition.lua")
end

Sexbound.AdjustActorsPositionController = {}
Sexbound.AdjustActorsPositionController_mt = {
    __index = Sexbound.AdjustActorsPositionController
}

function Sexbound.AdjustActorsPositionController:new(useCase)
    return setmetatable({
        _useCase = useCase or Sexbound.AdjustActorsPosition:new()
    }, Sexbound.AdjustActorsPositionController_mt)
end

function Sexbound.AdjustActorsPositionController:adjustActorsPosition(translation)
    self._useCase:execute({
        translation = translation
    })
end

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/TransformationsGateway.lua")
end

Sexbound.AdjustActorsPosition = {}
Sexbound.AdjustActorsPosition_mt = {
    __index = Sexbound.AdjustActorsPosition
}

function Sexbound.AdjustActorsPosition:new(adjustActorsPositioning)
    return setmetatable({
        _gateway = adjustActorsPositioning or Sexbound.TransformationsGateway:new()
    }, Sexbound.AdjustActorsPosition_mt)
end

function Sexbound.AdjustActorsPosition:execute(adjustActorsPositionInput)
    self:adjustActorsPosition(adjustActorsPositionInput)
end

function Sexbound.AdjustActorsPosition:adjustActorsPosition(adjustActorsPositionInput)
    self._gateway:adjustActorsPosition(adjustActorsPositionInput.translation)
end

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/TransformationsGateway.lua")
end

Sexbound.AdjustActorsScale = {}
Sexbound.AdjustActorsScale_mt = {
    __index = Sexbound.AdjustActorsScale
}

function Sexbound.AdjustActorsScale:new(adjustActorsScaling)
    return setmetatable({
        _gateway = adjustActorsScaling or Sexbound.TransformationsGateway:new()
    }, Sexbound.AdjustActorsScale_mt)
end

function Sexbound.AdjustActorsScale:execute(adjustActorsScaleInput)
    self:adjustActorsScale(adjustActorsScaleInput)
end

function Sexbound.AdjustActorsScale:adjustActorsScale(adjustActorsScaleInput)
    self._gateway:adjustActorsScale(adjustActorsScaleInput.scale, adjustActorsScaleInput.scaleCenter)
end

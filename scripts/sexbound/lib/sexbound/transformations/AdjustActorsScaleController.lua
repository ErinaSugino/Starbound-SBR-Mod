if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsScale.lua")
end

Sexbound.AdjustActorsScaleController = {}
Sexbound.AdjustActorsScaleController_mt = {
    __index = Sexbound.AdjustActorsScaleController
}

function Sexbound.AdjustActorsScaleController:new(useCase)
    return setmetatable({
        _useCase = useCase or Sexbound.AdjustActorsScale:new()
    }, Sexbound.AdjustActorsScaleController_mt)
end

function Sexbound.AdjustActorsScaleController:adjustActorsScale(scale, scaleCenter)
    if not self:validateScale(scale) then
        return
    end
    if not self:validateScaleCenter(scaleCenter) then
        return
    end

    self._useCase:execute({
        scale = scale,
        scaleCenter = scaleCenter
    })

    return true
end

function Sexbound.AdjustActorsScaleController:validateScale(scale)
    local datatype = type(scale)
    if datatype == "number" then
        return true
    end
    if datatype ~= "table" then
        return false
    end
    if #scale <= 1 then
        return false
    end
    for _, value in ipairs(scale) do
        if type(value) ~= "number" then
            return false
        end
    end
    return true
end

function Sexbound.AdjustActorsScaleController:validateScaleCenter(scaleCenter)
    local datatype = type(scaleCenter)
    if datatype == "nil" then
        return true
    end
    if datatype ~= "table" then
        return false
    end
    if #scaleCenter <= 1 then
        return false
    end
    for _, value in ipairs(scaleCenter) do
        if type(value) ~= "number" then
            return false
        end
    end
    return true
end

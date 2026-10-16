if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsScale.lua")
end

--- Actor scale wrapper wrapper
--- @class Sexbound.AdjustActorsScaleController
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _useCase Sexbound.AdjustActorsScale
Sexbound.AdjustActorsScaleController = {}
Sexbound.AdjustActorsScaleController_mt = {
    __index = Sexbound.AdjustActorsScaleController
}

--- Creates new wrapper instance
--- @param useCase Sexbound.AdjustActorsScale|nil A pre-existing scale wrapper
--- @return Sexbound.AdjustActorsScaleController # The new wrapper instance
function Sexbound.AdjustActorsScaleController:new(useCase)
    return setmetatable({
        _useCase = useCase or Sexbound.AdjustActorsScale:new()
    }, Sexbound.AdjustActorsScaleController_mt)
end

--- Scales actors based on input
--- @param scale integer|table<integer,integer> The target scale. 1 is normal
--- @param scaleCenter Vec2F? X and Y coordinate for where the scale origin is offset from top left
--- @return boolean # If the scaling happened or not
function Sexbound.AdjustActorsScaleController:adjustActorsScale(scale, scaleCenter)
    if not self:validateScale(scale) then
        return false
    end
    if not self:validateScaleCenter(scaleCenter) then
        return false
    end

    self._useCase:execute({
        scale = scale,
        scaleCenter = scaleCenter
    })

    return true
end

--- Validates if a target scale is acceptable
--- @param scale any Some input to validate
--- @return boolean # Whethere or not it's a valid scale instruction
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

--- Validates if a scale center is acceptable
--- @param scaleCenter any Some input to validate
--- @return boolean # Whethere or not it's a valid scale center
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

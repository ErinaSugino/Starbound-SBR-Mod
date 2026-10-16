if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/TransformationsGateway.lua")
end

--- Actor scale wrapper
--- @class Sexbound.AdjustActorsScale
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _gateway Sexbound.TransformationsGateway
Sexbound.AdjustActorsScale = {}
Sexbound.AdjustActorsScale_mt = {
    __index = Sexbound.AdjustActorsScale
}

--- Creates new wrapper instance
--- @param adjustActorsScaling Sexbound.TransformationsGateway|nil A pre-existing transformation wrapper
--- @return Sexbound.AdjustActorsScale # The new wrapper instance
function Sexbound.AdjustActorsScale:new(adjustActorsScaling)
    return setmetatable({
        _gateway = adjustActorsScaling or Sexbound.TransformationsGateway:new()
    }, Sexbound.AdjustActorsScale_mt)
end

--- Scales actors in a complicatedly nested way
--- @param adjustActorsScaleInput table The scale input, needs to contain "scale" as number or Vec2F and can contain "scaleCenter" as Vec2F
function Sexbound.AdjustActorsScale:execute(adjustActorsScaleInput)
    self:adjustActorsScale(adjustActorsScaleInput)
end

--- Actually scales actors in a complicatedly nested way
--- @param adjustActorsScaleInput table The scale input, needs to contain "scale" as number or Vec2F and can contain "scaleCenter" as Vec2F
function Sexbound.AdjustActorsScale:adjustActorsScale(adjustActorsScaleInput)
    self._gateway:adjustActorsScale(adjustActorsScaleInput.scale, adjustActorsScaleInput.scaleCenter)
end

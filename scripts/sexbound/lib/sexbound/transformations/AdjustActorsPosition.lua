if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/TransformationsGateway.lua")
end

--- An actor movement operation wrapper
--- @class Sexbound.AdjustActorsPosition
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _gateway Sexbound.TransformationsGateway
Sexbound.AdjustActorsPosition = {}
Sexbound.AdjustActorsPosition_mt = {
    __index = Sexbound.AdjustActorsPosition
}

--- Creates a new wrapper instance
--- @param adjustActorsPositioning Sexbound.TransformationsGateway|nil A pre-existing transformation wrapper
--- @return Sexbound.AdjustActorsPosition # The new instance
function Sexbound.AdjustActorsPosition:new(adjustActorsPositioning)
    return setmetatable({
        _gateway = adjustActorsPositioning or Sexbound.TransformationsGateway:new()
    }, Sexbound.AdjustActorsPosition_mt)
end

--- Performs actor translation but complicatedly wrapped
--- @param adjustActorsPositionInput table Translation instructions - needs to have "translation" as Vec2F
function Sexbound.AdjustActorsPosition:execute(adjustActorsPositionInput)
    self:adjustActorsPosition(adjustActorsPositionInput)
end

--- Actually translated the actors but complicatedly wrapped
--- @param adjustActorsPositionInput table Translation instructions - needs to have "translation" as Vec2F
function Sexbound.AdjustActorsPosition:adjustActorsPosition(adjustActorsPositionInput)
    self._gateway:adjustActorsPosition(adjustActorsPositionInput.translation)
end

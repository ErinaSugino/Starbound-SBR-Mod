if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsPosition.lua")
end

--- Some witchcraft wrapper nonesense for moving actors
--- @class Sexbound.AdjustActorsPositionController
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _useCase Sexbound.AdjustActorsPosition
Sexbound.AdjustActorsPositionController = {}
Sexbound.AdjustActorsPositionController_mt = {
    __index = Sexbound.AdjustActorsPositionController
}

--- Creates new wrapper instance
--- @param useCase Sexbound.AdjustActorsPosition|nil A pre-existing movement transformation
--- @return Sexbound.AdjustActorsPositionController # The new instance
function Sexbound.AdjustActorsPositionController:new(useCase)
    return setmetatable({
        _useCase = useCase or Sexbound.AdjustActorsPosition:new()
    }, Sexbound.AdjustActorsPositionController_mt)
end

--- Performs a movement operation
--- @param translation Vec2F X and Y coordinate for the offset to apply
function Sexbound.AdjustActorsPositionController:adjustActorsPosition(translation)
    self._useCase:execute({
        translation = translation
    })
end

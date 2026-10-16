if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsRotation.lua")
end

--- Actor rotation wrapper wrapper
--- @class Sexbound.AdjustActorsRotationController
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _useCase Sexbound.AdjustActorsRotation
Sexbound.AdjustActorsRotationController = {}
Sexbound.AdjustActorsRotationController_mt = {
    __index = Sexbound.AdjustActorsRotationController
}

--- Creates new wrapper instance
--- @param useCase Sexbound.AdjustActorsRotation|nil A pre-existing rotation wrapper
--- @return Sexbound.AdjustActorsRotationController # The new wrapper instance
function Sexbound.AdjustActorsRotationController:new(useCase)
    return setmetatable({
        _useCase = useCase or Sexbound.AdjustActorsRotation:new()
    }, Sexbound.AdjustActorsRotationController_mt)
end

--- Rotates the actors in a complicatedly nested way
--- @param rotation number Target rotation (in degrees?)
--- @param rotationCenter Vec2F? X and Y coordinate for where the rotation axle is offset from top left
function Sexbound.AdjustActorsRotationController:adjustActorsRotation(rotation, rotationCenter)
    self._useCase:execute({
        rotation = rotation,
        rotationCenter = rotationCenter
    })
end

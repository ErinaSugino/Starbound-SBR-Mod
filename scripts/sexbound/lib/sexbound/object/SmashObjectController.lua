if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/object/DefaultSmashObjectUseCaseFactory.lua")
end

--- Wrapper wrapper for destroying a sexnode object
--- @class Sexbound.SmashObjectController
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _useCase Sexbound.SmashObject
Sexbound.SmashObjectController = {}
Sexbound.SmashObjectController_mt = {
    __index = Sexbound.SmashObjectController
}

--- Create new wrapper instance
--- @param useCase Sexbound.SmashObject|nil A pre-existing wrapper instance
--- @return Sexbound.SmashObjectController # The new instance
function Sexbound.SmashObjectController:new(useCase)
    return setmetatable({
        _useCase = useCase or DefaultSmashObjectUseCaseFactory.make()
    }, Sexbound.SmashObjectController_mt)
end

--- Smash the underlying object throuch complicatedly nested means
function Sexbound.SmashObjectController:smashObject()
    self._useCase:execute()
end

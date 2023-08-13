if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/object/DefaultSmashObjectUseCaseFactory.lua")
end

Sexbound.SmashObjectController = {}
Sexbound.SmashObjectController_mt = {
    __index = Sexbound.SmashObjectController
}

function Sexbound.SmashObjectController:new(useCase)
    return setmetatable({
        _useCase = useCase or DefaultSmashObjectUseCaseFactory.make()
    }, Sexbound.SmashObjectController_mt)
end

function Sexbound.SmashObjectController:smashObject()
    self._useCase:execute()
end

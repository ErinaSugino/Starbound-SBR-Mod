if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/object/SmashObject.lua")
end

DefaultSmashObjectUseCaseFactory = {}

function DefaultSmashObjectUseCaseFactory.make()
    return Sexbound.SmashObject:new(smash)
end

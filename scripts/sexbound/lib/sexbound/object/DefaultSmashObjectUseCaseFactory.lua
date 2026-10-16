if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/object/SmashObject.lua")
end

DefaultSmashObjectUseCaseFactory = {}

--- Make SmashObject but abstract
--- @return Sexbound.SmashObject
function DefaultSmashObjectUseCaseFactory.make(smash)
    return Sexbound.SmashObject:new(smash)
end

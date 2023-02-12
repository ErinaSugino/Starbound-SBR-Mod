require "/scripts/sexbound/override/common/subgender.lua"

Sexbound.NPC.SubGender = Sexbound.Common.SubGender:new()
Sexbound.NPC.SubGender_mt = {
    __index = Sexbound.NPC.SubGender
}

function Sexbound.NPC.SubGender:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.SubGender_mt)

    storage.sexbound = storage.sexbound or {}
    storage.sexbound.subgender = storage.sexbound.subgender or {}

    --if storage.sexbound.subgender.hasAlreadyTriedGeneratingSubGender == false then
    --    _self:tryGeneratingSubGender()
    --end
    
    _self:init()

    return _self
end

function Sexbound.NPC:tryGeneratingSubGender()
    storage.sexbound.subgender.hasAlreadyTriedGeneratingSubGender = true

    self:tryChangingSubGenderToBeFutanari()
end

function Sexbound.NPC:tryChangingSubGenderToBeFutanari()
    if npc.gender() ~= "female" then
        return false
    end
    local randomNumber = util.randomInRange({0.0, 1.0})
    if randomNumber <= 0.1 then -- 10% chance
        self:setSxbSubGender("futanari")
        return true
    end
    return false
end

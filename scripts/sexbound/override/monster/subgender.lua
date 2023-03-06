require "/scripts/sexbound/override/common/subgender.lua"

Sexbound.Monster.SubGender = Sexbound.Common.SubGender:new()
Sexbound.Monster.SubGender_mt = {
    __index = Sexbound.Monster.SubGender
}

function Sexbound.Monster.SubGender:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.SubGender_mt)
    
    storage.sexbound = storage.sexbound or {}
    storage.sexbound.subgender = storage.sexbound.subgender or {}
    
    if storage.sexbound.subgender.hasAlreadyTriedGeneratingSubGender == false then
        _self:tryGeneratingSubGender()
    end
    
    _self:init()
    
    return _self
end

function Sexbound.Monster.SubGender:tryGeneratingSubGender()
    storage.sexbound.subgender.hasAlreadyTriedGeneratingSubGender = true
    if status.isResource("gender") then
        local _gender = status.resource("gender") end
    if _gender == 3 then
        self:setSxbSubGender("futanari") end
end

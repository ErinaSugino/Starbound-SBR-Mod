require "/scripts/sexbound/override/common/subgender.lua"

--- Monster Sub-Gender manager class
--- @class Sexbound.Monster.SubGender: Sexbound.Common.SubGender
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Monster.SubGender = Sexbound.Common.SubGender:new()
Sexbound.Monster.SubGender_mt = {
    __index = Sexbound.Monster.SubGender
}

--- Creates a new monster sub-gender manager instance
--- @param parent Sexbound.Monster The calling parent monster manager instance
--- @return Sexbound.Monster.SubGender # The newly created monster sub-gender manager instance
function Sexbound.Monster.SubGender:new(parent)
    local _self = setmetatable({}, Sexbound.Monster.SubGender_mt)

    storage.sexbound = storage.sexbound or {}
    storage.sexbound.subgender = storage.sexbound.subgender or {}

    if storage.sexbound.subgender.hasAlreadyTriedGeneratingSubGender == false then
        _self:tryGeneratingSubGender()
    end

    _self:init(parent)

    return _self
end

--- Safely tries to generate sub-gender based on monster config
function Sexbound.Monster.SubGender:tryGeneratingSubGender()
    storage.sexbound.subgender.hasAlreadyTriedGeneratingSubGender = true
    local _gender = 0
    if status.isResource("gender") then
        _gender = status.resource("gender") end
    if _gender == 3 then
        self:setSxbSubGender("futanari") end
end

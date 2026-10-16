require "/scripts/sexbound/override/common/subgender.lua"

--- NPC sub-gender manager class
--- @class Sexbound.NPC.SubGender: Sexbound.Common.SubGender
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.NPC.SubGender = Sexbound.Common.SubGender:new()
Sexbound.NPC.SubGender_mt = {
    __index = Sexbound.NPC.SubGender
}

--- Creates new npc sub-gender manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.SubGender # The newly created npc sub-gender manager instance
function Sexbound.NPC.SubGender:new(parent)
    local _self = setmetatable({}, Sexbound.NPC.SubGender_mt)

    storage.sexbound = storage.sexbound or {}
    storage.sexbound.subgender = storage.sexbound.subgender or {}

    _self:init(parent)

    return _self
end

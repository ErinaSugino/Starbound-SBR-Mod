require "/scripts/sexbound/override/common/climax.lua"

--- NPC climax manager class
--- @class Sexbound.NPC.Climax: Sexbound.Common.Climax
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.NPC.Climax = Sexbound.Common.Climax:new()
Sexbound.NPC.Climax_mt = {
    __index = Sexbound.NPC.Climax
}

--- Creates a new npc climax manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.Climax # The newly created npc manager instance
function Sexbound.NPC.Climax:new(parent)
    local _self = setmetatable({}, Sexbound.NPC.Climax_mt)

    _self:init(parent)

    return _self
end

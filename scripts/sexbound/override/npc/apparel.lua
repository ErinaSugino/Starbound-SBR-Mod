require "/scripts/sexbound/override/common/apparel.lua"

--- NPC apparel manager class
--- @class Sexbound.NPC.Apparel: Sexbound.Common.Apparel
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.NPC.Apparel = Sexbound.Common.Apparel:new()
Sexbound.NPC.Apparel_mt = {
    __index = Sexbound.NPC.Apparel
}

--- Creates a new npc apparel manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.Apparel # The newly created npc apparel manager instance
function Sexbound.NPC.Apparel:new(parent)
    local _self = setmetatable({}, Sexbound.NPC.Apparel_mt)

    _self:init(parent)

    return _self
end

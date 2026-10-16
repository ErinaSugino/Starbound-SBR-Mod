require "/scripts/sexbound/override/common/status.lua"

--- NPC status manager class
--- @class Sexbound.NPC.Status: Sexbound.Common.Status
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.NPC.Status = Sexbound.Common.Status:new()
Sexbound.NPC.Status_mt = {
    __index = Sexbound.NPC.Status
}

--- Creates a new npc status manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.Status # The newly created monster npc manager instance
function Sexbound.NPC.Status:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Status_mt)

    _self:init(parent)

    return _self
end
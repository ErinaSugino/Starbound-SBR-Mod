require "/scripts/sexbound/override/common/statistics.lua"

--- NPC statistics manager class
--- @class Sexbound.NPC.Statistics: Sexbound.Common.Statistics
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.NPC.Statistics = Sexbound.Common.Statistics:new()
Sexbound.NPC.Statistics_mt = {
    __index = Sexbound.NPC.Statistics
}

--- Creates a new npc statistics manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.Statistics # The newly created npc statistics manager instance
function Sexbound.NPC.Statistics:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Statistics_mt)

    _self:init(parent)

    return _self
end


if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/arousal.lua"
end

--- NPC arousal manager class
--- @class Sexbound.NPC.Arousal: Sexbound.Common.Arousal
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.NPC.Arousal = Sexbound.Common.Arousal:new()
Sexbound.NPC.Arousal_mt = { __index = Sexbound.NPC.Arousal }

--- Creates a new npc arousal manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.Arousal # The newly created npc arousal manager instance
function Sexbound.NPC.Arousal:new(parent)
    local _self = setmetatable({}, Sexbound.NPC.Arousal_mt)

    _self:init(parent, npc.seed())

    return _self
end

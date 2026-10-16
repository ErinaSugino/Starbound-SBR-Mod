if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/arousal.lua"
end

--- Monster arousal manager class
--- @class Sexbound.Monster.Arousal: Sexbound.Common.Arousal
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Monster.Arousal = Sexbound.Common.Arousal:new()
Sexbound.Monster.Arousal_mt = { __index = Sexbound.Monster.Arousal }

--- Creates a new monster arousal manager instance
--- @param parent Sexbound.Monster The calling parent monster manager instance
--- @return Sexbound.Monster.Arousal # The newly created monster arousal manager instance
function Sexbound.Monster.Arousal:new(parent)
    local _self = setmetatable({}, Sexbound.Monster.Arousal_mt)

    _self:init(parent, monster.seed())

    return _self
end

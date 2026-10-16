require "/scripts/sexbound/override/common/statistics.lua"

--- Monster statistics manager class
--- @class Sexbound.Monster.Statistics: Sexbound.Common.Statistics
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Monster.Statistics = Sexbound.Common.Statistics:new()
Sexbound.Monster.Statistics_mt = {
    __index = Sexbound.Monster.Statistics
}

--- Creates a new monster statistics manager instance
--- @param parent Sexbound.Monster The calling parent monster manager instance
--- @return Sexbound.Monster.Statistics # The newly created monster statistics manager instance
function Sexbound.Monster.Statistics:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Statistics_mt)

    _self:init(parent)

    return _self
end


require "/scripts/sexbound/override/common/statistics.lua"

--- Player statistics manager class
--- @class Sexbound.Player.Statistics: Sexbound.Common.Statistics
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Player.Statistics = Sexbound.Common.Statistics:new()
Sexbound.Player.Statistics_mt = {
    __index = Sexbound.Player.Statistics
}

--- Creates a new player statistics manager instance
--- @param parent Sexbound.Player The calling parent player manager instance
--- @return Sexbound.Player.Statistics # The newly created player statistics manager instance
function Sexbound.Player.Statistics:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Statistics_mt)

    _self:init(parent)

    return _self
end

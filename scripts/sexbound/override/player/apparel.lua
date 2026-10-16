require "/scripts/sexbound/override/common/apparel.lua"

--- Player apparel manager class
--- @class Sexbound.Player.Apparel: Sexbound.Common.Apparel
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Player.Apparel = Sexbound.Common.Apparel:new()
Sexbound.Player.Apparel_mt = {
    __index = Sexbound.Player.Apparel
}

--- Creates a new player apparel manager instance
--- @param parent Sexbound.Player The calling parent player manager instance
--- @return Sexbound.Player.Apparel # The newly created player apparel manager instance
function Sexbound.Player.Apparel:new(parent)
    local _self = setmetatable({}, Sexbound.Player.Apparel_mt)

    _self:init(parent)

    return _self
end

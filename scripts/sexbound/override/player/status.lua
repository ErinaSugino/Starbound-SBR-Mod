require "/scripts/sexbound/override/common/status.lua"

--- Player status manager class
--- @class Sexbound.Player.Status: Sexbound.Common.Status
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Player.Status = Sexbound.Common.Status:new()
Sexbound.Player.Status_mt = {
    __index = Sexbound.Player.Status
}

--- Creates a new player status manager instance
--- @param parent Sexbound.Player The calling parent player manager instance
--- @return Sexbound.Player.Status # The newly created monster player manager instance
function Sexbound.Player.Status:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Status_mt)

    _self:init(parent)

    return _self
end
require "/scripts/sexbound/override/common/climax.lua"

--- Player climax manager class
--- @class Sexbound.Player.Climax: Sexbound.Common.Climax
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Player.Climax = Sexbound.Common.Climax:new()
Sexbound.Player.Climax_mt = {
    __index = Sexbound.Player.Climax
}

--- Creates a new player climax manager instance
--- @param parent Sexbound.Player The calling parent player manager instance
--- @return Sexbound.Player.Climax # The newly created player manager instance
function Sexbound.Player.Climax:new(parent)
    local _self = setmetatable({}, Sexbound.Player.Climax_mt)

    _self:init(parent)

    return _self
end

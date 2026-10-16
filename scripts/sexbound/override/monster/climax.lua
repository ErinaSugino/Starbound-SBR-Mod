require "/scripts/sexbound/override/common/climax.lua"

--- Monster climax manager class
--- @class Sexbound.Monster.Climax: Sexbound.Common.Climax
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Monster.Climax = Sexbound.Common.Climax:new()
Sexbound.Monster.Climax_mt = {
    __index = Sexbound.Monster.Climax
}

--- Creates a new monster climax manager instance
--- @param parent Sexbound.Monster The calling parent monster manager instance
--- @return Sexbound.Monster.Climax # The newly created monster manager instance
function Sexbound.Monster.Climax:new(parent)
    local _self = setmetatable({}, Sexbound.Monster.Climax_mt)

    _self:init(parent)

    return _self
end

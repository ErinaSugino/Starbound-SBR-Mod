require "/scripts/sexbound/override/common/status.lua"

--- Monster status manager class
--- @class Sexbound.Monster.Status: Sexbound.Common.Status
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Monster.Status = Sexbound.Common.Status:new()
Sexbound.Monster.Status_mt = {
    __index = Sexbound.Monster.Status
}

--- Creates a new monster status manager instance
--- @param parent Sexbound.Monster The calling parent monster manager instance
--- @return Sexbound.Monster.Status # The newly created monster status manager instance
function Sexbound.Monster.Status:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Status_mt)

    _self:init(parent)

    return _self
end
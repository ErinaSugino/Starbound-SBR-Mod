require "/scripts/sexbound/override/common/apparel.lua"

Sexbound.Player.Apparel = Sexbound.Common.Apparel:new()
Sexbound.Player.Apparel_mt = {
    __index = Sexbound.Player.Apparel
}

function Sexbound.Player.Apparel:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Apparel_mt)

    _self:init(parent)

    return _self
end

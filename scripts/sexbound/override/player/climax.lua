require "/scripts/sexbound/override/common/climax.lua"

Sexbound.Player.Climax = Sexbound.Common.Climax:new()
Sexbound.Player.Climax_mt = {
    __index = Sexbound.Player.Climax
}

function Sexbound.Player.Climax:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Climax_mt)

    _self:init(parent)

    return _self
end

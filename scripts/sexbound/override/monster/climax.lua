require "/scripts/sexbound/override/common/climax.lua"

Sexbound.Monster.Climax = Sexbound.Common.Climax:new()
Sexbound.Monster.Climax_mt = {
    __index = Sexbound.Monster.Climax
}

function Sexbound.Monster.Climax:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Climax_mt)

    _self:init(parent)

    return _self
end

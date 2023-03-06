require "/scripts/sexbound/override/common/apparel.lua"

Sexbound.NPC.Apparel = Sexbound.Common.Apparel:new()
Sexbound.NPC.Apparel_mt = {
    __index = Sexbound.NPC.Apparel
}

function Sexbound.NPC.Apparel:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Apparel_mt)

    _self:init(parent)

    return _self
end

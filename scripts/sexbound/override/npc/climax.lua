require "/scripts/sexbound/override/common/climax.lua"

Sexbound.NPC.Climax = Sexbound.Common.Climax:new()
Sexbound.NPC.Climax_mt = {
    __index = Sexbound.NPC.Climax
}

function Sexbound.NPC.Climax:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Climax_mt)

    _self:init(parent)

    return _self
end

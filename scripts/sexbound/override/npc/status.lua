require "/scripts/sexbound/override/common/status.lua"

Sexbound.NPC.Status = Sexbound.Common.Status:new()
Sexbound.NPC.Status_mt = {
    __index = Sexbound.NPC.Status
}

function Sexbound.NPC.Status:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Status_mt)
    
    _self:init()

    return _self
end
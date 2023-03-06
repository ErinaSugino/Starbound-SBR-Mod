require "/scripts/sexbound/override/common/status.lua"

Sexbound.Monster.Status = Sexbound.Common.Status:new()
Sexbound.Monster.Status_mt = {
    __index = Sexbound.Monster.Status
}

function Sexbound.Monster.Status:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Status_mt)
    
    _self:init()

    return _self
end
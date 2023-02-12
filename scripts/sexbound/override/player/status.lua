require "/scripts/sexbound/override/common/status.lua"

Sexbound.Player.Status = Sexbound.Common.Status:new()
Sexbound.Player.Status_mt = {
    __index = Sexbound.Player.Status
}

function Sexbound.Player.Status:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Status_mt)
    
    _self:init()

    return _self
end
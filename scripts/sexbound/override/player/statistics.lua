require "/scripts/sexbound/override/common/statistics.lua"

Sexbound.Player.Statistics = Sexbound.Common.Statistics:new()
Sexbound.Player.Statistics_mt = {
    __index = Sexbound.Player.Statistics
}

function Sexbound.Player.Statistics:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Statistics_mt)

    _self:init(parent)

    return _self
end

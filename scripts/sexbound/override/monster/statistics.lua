require "/scripts/sexbound/override/common/statistics.lua"

Sexbound.Monster.Statistics = Sexbound.Common.Statistics:new()
Sexbound.Monster.Statistics_mt = {
    __index = Sexbound.Monster.Statistics
}

function Sexbound.Monster.Statistics:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Statistics_mt)

    _self:init(parent)

    return _self
end


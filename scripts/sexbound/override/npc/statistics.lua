require "/scripts/sexbound/override/common/statistics.lua"

Sexbound.NPC.Statistics = Sexbound.Common.Statistics:new()
Sexbound.NPC.Statistics_mt = {
    __index = Sexbound.NPC.Statistics
}

function Sexbound.NPC.Statistics:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Statistics_mt)

    _self:init(parent)

    return _self
end


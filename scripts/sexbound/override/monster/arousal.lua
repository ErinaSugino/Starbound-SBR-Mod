if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/arousal.lua"
end

Sexbound.Monster.Arousal = Sexbound.Common.Arousal:new()
Sexbound.Monster.Arousal_mt = { __index = Sexbound.Monster.Arousal }

--- Instantiates this class which extends Common Arousal
-- @param parent
function Sexbound.Monster.Arousal:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Arousal_mt)

    _self:init(parent, monster.seed())

    return _self
end

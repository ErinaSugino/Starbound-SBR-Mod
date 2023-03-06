if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/arousal.lua"
end

Sexbound.Player.Arousal = Sexbound.Common.Arousal:new()
Sexbound.Player.Arousal_mt = { __index = Sexbound.Player.Arousal }

--- Instantiates this class which extends Common Arousal
-- @param parent
function Sexbound.Player.Arousal:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Arousal_mt)

    _self:init(parent)

    return _self
end

if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/arousal.lua"
end

Sexbound.NPC.Arousal = Sexbound.Common.Arousal:new()
Sexbound.NPC.Arousal_mt = { __index = Sexbound.NPC.Arousal }

--- Instantiates this class which extends Common Arousal
-- @param parent
function Sexbound.NPC.Arousal:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Arousal_mt)

    _self:init(parent, npc.seed())

    return _self
end

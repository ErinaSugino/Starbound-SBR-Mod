--- Sexbound.Position.AnimationState.State Class Module.
-- @classmod Sexbound.Position.AnimationState.State
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Position.AnimationState.State = {}
Sexbound.Position.AnimationState.State_mt = {
    __index = Sexbound.Position.AnimationState.State
}

--- Returns a reference to a new instance of this class.
function Sexbound.Position.AnimationState.State:new(parent, config)
    return setmetatable({
        _parent = parent,
        _config = config
    }, Sexbound.Position.AnimationState.State_mt)
end

function Sexbound.Position.AnimationState.State:getConfig()
    return self._config
end

function Sexbound.Position.AnimationState.State:getParent()
    return self._parent
end

function Sexbound.Position.AnimationState.State:getProperties(name, default)
    if name then
        return self:getConfig().properties[name] or default
    end

    return self:getConfig().properties
end

function Sexbound.Position.AnimationState.State:getAllowEmote(index)
    return self:getProperties("allowEmote", {true, true})[index]
end

function Sexbound.Position.AnimationState.State:getAllowMoan(index)
    return self:getProperties("allowMoan", {true, true})[index]
end

function Sexbound.Position.AnimationState.State:getAllowTalk(index)
    return self:getProperties("allowTalk", {true, true})[index]
end

function Sexbound.Position.AnimationState.State:getClimaxMultiplier(index)
    return self:getProperties("climaxMultiplier", {0, 0})[index]
end

function Sexbound.Position.AnimationState.State:getEnabled(index)
    return self:getProperties("enabled", nil)[index]
end

function Sexbound.Position.AnimationState.State:getFlipBody(index)
    return self:getProperties("flipBody", {false, false})[index]
end

function Sexbound.Position.AnimationState.State:getFlipHead(index)
    return self:getProperties("flipHead", {false, false})[index]
end

function Sexbound.Position.AnimationState.State:getMaxTempo()
    return self._maxTempo or self:nextMaxTempo()
end

function Sexbound.Position.AnimationState.State:setMaxTempo(newValue)
    self._maxTempo = newValue
end

function Sexbound.Position.AnimationState.State:getMinTempo()
    return self._minTempo or self:nextMinTempo()
end

function Sexbound.Position.AnimationState.State:setMinTempo(newValue)
    self._minTempo = newValue
end

function Sexbound.Position.AnimationState.State:nextMinTempo()
    self:setMinTempo(util.randomInRange(self:getProperties("minTempo", {1, 1})))

    return self._minTempo
end

function Sexbound.Position.AnimationState.State:nextMaxTempo()
    self:setMaxTempo(util.randomInRange(self:getProperties("maxTempo", {1, 1})))

    return self._maxTempo
end

function Sexbound.Position.AnimationState.State:getMouthOffset(index)
    return self:getProperties("mouthOffset", {0, 0})[index] or {0, 0}
end

function Sexbound.Position.AnimationState.State:getHeadBangSpeedMultiplier(index)
    return self:getProperties("headBangSpeedMultiplier", {0, 0})[index] or {0, 0}
end

function Sexbound.Position.AnimationState.State:getGroinMask(index)
    return self:getProperties("groinMask", {false, false})[index]
end

function Sexbound.Position.AnimationState.State:getPossiblePregnancy(index)
    return self:getProperties("possiblePregnancy", {false, false})[index]
end

function Sexbound.Position.AnimationState.State:getRotateBody(index)
    return self:getProperties("rotateBody", {0, 0})[index]
end

function Sexbound.Position.AnimationState.State:getRotateHead(index)
    return self:getProperties("rotateHead", {0, 0})[index]
end

function Sexbound.Position.AnimationState.State:getSprite(name, default)
    return self:getSprites()[name] or default
end

function Sexbound.Position.AnimationState.State:getSprites()
    return self:getProperties("sprites") or {}
end

function Sexbound.Position.AnimationState.State:getVisible(index)
    local visible = self:getProperties("visible") or {}

    if visible[index] == nil then
        return true
    end

    return visible[index] or false
end

function Sexbound.Position.AnimationState.State:getSustainedInterval()
    return self._sustainedInterval or self:nextSustainedInterval()
end

function Sexbound.Position.AnimationState.State:nextSustainedInterval()
    self:setSustainedInterval(util.randomInRange(self:getProperties("sustainedInterval", {20, 30})))

    return self._sustainedInterval
end

function Sexbound.Position.AnimationState.State:setSustainedInterval(value)
    self._sustainedInterval = value
end

function Sexbound.Position.AnimationState.State:getFrameName(default)
    return self:getProperties("frameName") or default or "default"
end

function Sexbound.Position.AnimationState.State:getOverrideRoles(index)
    local overrideRoles = self:getProperties("overrideRoles") or {}
    return overrideRoles[index]
end

function Sexbound.Position.AnimationState.State:getStateName(default)
    return self:getProperties("stateName") or default or "default"
end

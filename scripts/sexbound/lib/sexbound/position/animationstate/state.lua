--- Sexbound.Position.AnimationState.State Class Module.
--- @class Sexbound.Position.AnimationState.State
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Position.AnimationState
--- @field _config table
--- @field _minTempo ?number
--- @field _maxTempo ?number
--- @field _sustainedTempo ?number
Sexbound.Position.AnimationState.State = {}
Sexbound.Position.AnimationState.State_mt = {
    __index = Sexbound.Position.AnimationState.State
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Position.AnimationState The calling parent instance
--- @param config table The configuration for this state
--- @return Sexbound.Position.AnimationState.State # The new state instance
function Sexbound.Position.AnimationState.State:new(parent, config)
    return setmetatable({
        _parent = parent,
        _config = config
    }, Sexbound.Position.AnimationState.State_mt)
end

--- Returns the config table
--- @return table # The config table
function Sexbound.Position.AnimationState.State:getConfig()
    return self._config
end

--- Returns the parent instance
--- @return Sexbound.Position.AnimationState # The parent instance
function Sexbound.Position.AnimationState.State:getParent()
    return self._parent
end

--- Returns a given property by name of this state, or a given default is not set
--- @param name ?string The name of the property to get. Gives properties list if none given
--- @param default any The default value to return of name does not exist
--- @return any # The value or default, or list of all properties if none requested
function Sexbound.Position.AnimationState.State:getProperties(name, default)
    if name then
        return self:getConfig().properties[name] or default
    end

    return self:getConfig().properties
end

--- Returns whethere or not using emotes is allowed for a given actor role index
--- @param index integer The actor role index
--- @return boolean # Whethere or not the requested actor can use emotes
function Sexbound.Position.AnimationState.State:getAllowEmote(index)
    return self:getProperties("allowEmote", {true, true})[index] or false
end

--- Returns whethere or not moaning is allowed for a given actor role index
--- @param index integer The actor role index
--- @return boolean # Whethere or not the requested actor can moan
function Sexbound.Position.AnimationState.State:getAllowMoan(index)
    return self:getProperties("allowMoan", {true, true})[index] or false
end

--- Returns whethere or not talking is allowed for a given actor role index
--- @param index integer The actor role index
--- @return boolean # Whethere or not the requested actor can talk
function Sexbound.Position.AnimationState.State:getAllowTalk(index)
    return self:getProperties("allowTalk", {true, true})[index] or false
end

--- Returns the climax multiplier for a given actor role index
--- @param index integer The actor role index
--- @return number # The climax multiplier for the given actor
function Sexbound.Position.AnimationState.State:getClimaxMultiplier(index)
    return self:getProperties("climaxMultiplier", {0, 0})[index] or 0
end

--- Returns whethere or not a given actor role index is enabled
--- @param index integer The actor role index
--- @return boolean # Whethere or not the requested actor is enabled
function Sexbound.Position.AnimationState.State:getEnabled(index)
    return self:getProperties("enabled", {true, true})[index] or false
end

--- Returns whethere or not to flip the body of a given actor role index
--- @param index integer The actor role index
--- @return boolean # Whethere or not the requested actor's body is to be flipped
function Sexbound.Position.AnimationState.State:getFlipBody(index)
    return self:getProperties("flipBody", {false, false})[index] or false
end

--- Returns whethere or not flip the head of a given actor role index
--- @param index integer The actor role index
--- @return boolean # Whethere or not the requested actor's head is to be flipped
function Sexbound.Position.AnimationState.State:getFlipHead(index)
    return self:getProperties("flipHead", {false, false})[index] or false
end

--- Returns the max tempo of this state
--- @return number # The max tempo of this state
function Sexbound.Position.AnimationState.State:getMaxTempo()
    return self._maxTempo or self:nextMaxTempo()
end

--- Sets the max tempo of this state
--- @param newValue number The new max tempo
function Sexbound.Position.AnimationState.State:setMaxTempo(newValue)
    self._maxTempo = newValue
end

--- Returns the min tempo of this state
--- @return number # The min tempo of this state
function Sexbound.Position.AnimationState.State:getMinTempo()
    return self._minTempo or self:nextMinTempo()
end

--- Sets the min tempo of this state
--- @param newValue number The new min tempo
function Sexbound.Position.AnimationState.State:setMinTempo(newValue)
    self._minTempo = newValue
end

--- Generates the next min tempo from a range
--- @return number # The new min tempo, already set
function Sexbound.Position.AnimationState.State:nextMinTempo()
    self:setMinTempo(util.randomInRange(self:getProperties("minTempo", {1, 1})))

    return self._minTempo
end

--- Generates the next max tempo from a range
--- @return number # The new max tempo, already set
function Sexbound.Position.AnimationState.State:nextMaxTempo()
    self:setMaxTempo(util.randomInRange(self:getProperties("maxTempo", {1, 1})))

    return self._maxTempo
end

--- Returns the mouth offset of a given actor role index
--- @param index integer The actor role index
--- @return Vec2F # Mouth offset of the actor
function Sexbound.Position.AnimationState.State:getMouthOffset(index)
    return self:getProperties("mouthOffset", {{0, 0}, {0, 0}})[index] or {0, 0}
end

--- Returns the headbang speed multiplier of a given actor role index
--- @param index integer The actor role index
--- @return number # The headbang speed multiplier of the given actor role index
function Sexbound.Position.AnimationState.State:getHeadBangSpeedMultiplier(index)
    return self:getProperties("headBangSpeedMultiplier", {0, 0})[index] or 0
end

--- Returns whethere or not a given actor role index uses a groin mask
--- @param index integer The actor role index
--- @return boolean # Whethere or not to use a groin mask for the given actor role index
function Sexbound.Position.AnimationState.State:getGroinMask(index)
    return self:getProperties("groinMask", {false, false})[index] or false
end

--- Returns whethere or not pregnancy can occur for a given actor role index
--- @param index integer The actor role index
--- @return boolean # Whethere or not the given actor can get pregnant
function Sexbound.Position.AnimationState.State:getPossiblePregnancy(index)
    return self:getProperties("possiblePregnancy", {false, false})[index] or false
end

--- Returns the body rotation for a given role actor index
--- @param index integer The actor role index
--- @return integer # The actor role's body rotation in degrees
function Sexbound.Position.AnimationState.State:getRotateBody(index)
    return self:getProperties("rotateBody", {0, 0})[index] or 0
end

--- Returns the head rotation for a given role actor index
--- @param index integer The actor role index
--- @return integer # The actor role's head rotation in degrees
function Sexbound.Position.AnimationState.State:getRotateHead(index)
    return self:getProperties("rotateHead", {0, 0})[index] or 0
end

--- Returns the filepath of a given sprite name or a given default if not set
--- @param name string The name of the sprite to get
--- @param default string The fallback to return
--- @return string # The filepath or given default of the sprite
function Sexbound.Position.AnimationState.State:getSprite(name, default)
    return self:getSprites()[name] or default
end

--- Returns all sprites
--- @return table<string, string> # The list of all set sprite filepaths
function Sexbound.Position.AnimationState.State:getSprites()
    return self:getProperties("sprites") or {}
end

--- Returns whethere or not a given actor role index is visible
--- @param index integer The actor role index
--- @return boolean # Whethere or not the given actor role index is visible
function Sexbound.Position.AnimationState.State:getVisible(index)
    local visible = self:getProperties("visible") or {}

    if visible[index] == nil then
        return true
    end

    return visible[index] or false
end

--- Returns the sustained interval
--- @return number # The sustained interval
function Sexbound.Position.AnimationState.State:getSustainedInterval()
    return self._sustainedInterval or self:nextSustainedInterval()
end

--- Generates the next sustained interval from a range
--- @return number # The next sustained interval, already set
function Sexbound.Position.AnimationState.State:nextSustainedInterval()
    self:setSustainedInterval(util.randomInRange(self:getProperties("sustainedInterval", {20, 30})))

    return self._sustainedInterval
end

--- Sets the sustained interval
--- @param value number The new sustained interval
function Sexbound.Position.AnimationState.State:setSustainedInterval(value)
    self._sustainedInterval = value
end

--- Returns the frame name of this state or a given default if none set
--- @param default string? The fallback to return
--- @return string # The frameName of this state or the given fallback
function Sexbound.Position.AnimationState.State:getFrameName(default)
    return self:getProperties("frameName") or default or "default"
end

--- Returns the override role index, if any, for a given actor role index
--- @param index integer The requested actor role index
--- @return integer # The override role, if any given, for the requested actor role index
function Sexbound.Position.AnimationState.State:getOverrideRoles(index)
    local overrideRoles = self:getProperties("overrideRoles") or {}
    return overrideRoles[index] or index
end

--- Returns the state name or a given default if not set
--- @param default string? A fallback stateName to use
--- @return string # The state name
function Sexbound.Position.AnimationState.State:getStateName(default)
    return self:getProperties("stateName") or default or "default"
end

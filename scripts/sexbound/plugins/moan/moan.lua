--- Sexbound.Actor.Moan Class Module.
-- @classmod Sexbound.Actor.Moan
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

Sexbound.Actor.Moan = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Moan_mt = {
    __index = Sexbound.Actor.Moan
}

--- Instantiates a new instance of Moan.
-- @param parent
-- @param config
function Sexbound.Actor.Moan:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "MOAN",
        _config = config,
        _isActive = true,
        _soundConfig = {}
    }, Sexbound.Actor.Moan_mt)

    _self:init(parent, _self._logPrefix)

    _self:initMoanSoundConfig()
    _self:loadMoanSoundEffectsIntoSoundPool()

    _self:initOrgasmSoundConfig()
    _self:loadOrgasmSoundEffectsIntoSoundPool()

    return _self
end

function Sexbound.Actor.Moan:onMessage(message)
    if message:isType("Sexbound:Position:SwitchPosition") or message:isType("Sexbound:SwitchRoles") then
        local stateName = self:getParent():getParent():getStateMachine():stateDesc()
        self:processIsActive(stateName)
    end
end

function Sexbound.Actor.Moan:createNewTimer(name)
    self._timers = self._timers or {}
    self._timers[name] = 0
end

function Sexbound.Actor.Moan:createNewInterval(name)
    self._intervals = self._intervals or {}
    self._intervals[name] = 0
end

function Sexbound.Actor.Moan:loadMoanSoundEffectsIntoSoundPool()
    if not self:isMoanSoundsEnabled() then
        return
    end
    self:tryLoadingSoundEffectsIntoSoundPool("moan", self._soundConfig.moan.soundEffects)
end

function Sexbound.Actor.Moan:loadOrgasmSoundEffectsIntoSoundPool()
    if not self:isOrgasmSoundsEnabled() then
        return
    end
    self:tryLoadingSoundEffectsIntoSoundPool("orgasm", self._soundConfig.orgasm.soundEffects)
end

function Sexbound.Actor.Moan:convertToTable(value)
    local valueType = type(value)
    if valueType == "table" or valueType == "nil" then
        return value
    end
    return {value, value}
end

function Sexbound.Actor.Moan:initMoanSoundConfig()
    if not self:isMoanSoundsEnabled() then
        return
    end

    local name = "moan"
    local identity = self:getParent():getIdentity()

    local definedSoundConfig = self:getDefinedSoundConfigFromConfigFile(name) or {}
    local defaultSoundConfig = self:getDefaultSoundConfigFromConfigFile(name) or {}

    local sxbMoanInterval = identity.sxbMoanInterval or definedSoundConfig.interval
    sxbMoanInterval = self:convertToTable(sxbMoanInterval) or {}
    if isEmpty(sxbMoanInterval) then
        sxbMoanInterval = defaultSoundConfig.sxbMoanInterval or {2.0, 3.0}
    end

    local sxbMoanPitch = identity.sxbMoanPitch or definedSoundConfig.pitch
    sxbMoanPitch = self:convertToTable(sxbMoanPitch) or {}
    if isEmpty(sxbMoanPitch or {}) then
        sxbMoanPitch = defaultSoundConfig.sxbMoanPitch or {1.0, 1.0}
    end

    local sxbMoanSounds = identity.sxbMoanSounds or definedSoundConfig.soundEffects
    if isEmpty(sxbMoanSounds or {}) then
        sxbMoanSounds = defaultSoundConfig.sxbMoanSounds or {}
    end

    self._soundConfig[name] = {
        pitch = sxbMoanPitch,
        interval = sxbMoanInterval,
        soundEffects = sxbMoanSounds or {},
        soundPoolName = self:getParent():getRole() .. name
    }

    self:createNewTimer(name)
    self:createNewInterval(name)
end

function Sexbound.Actor.Moan:initOrgasmSoundConfig()
    if not self:isOrgasmSoundsEnabled() then
        return
    end

    local name = "orgasm"
    local identity = self:getParent():getIdentity()

    local definedSoundConfig = self:getDefinedSoundConfigFromConfigFile(name) or {}
    local defaultSoundConfig = self:getDefaultSoundConfigFromConfigFile(name) or {}

    local sxbOrgasmInterval = identity.sxbOrgasmInterval or definedSoundConfig.interval
    sxbOrgasmInterval = self:convertToTable(sxbOrgasmInterval) or {}
    if isEmpty(sxbOrgasmInterval or {}) then
        sxbOrgasmInterval = defaultSoundConfig.sxbOrgasmInterval or {2.0, 3.0}
    end

    local sxbOrgasmPitch = identity.sxbOrgasmPitch or definedSoundConfig.pitch
    sxbOrgasmPitch = self:convertToTable(sxbOrgasmPitch) or {}
    if isEmpty(sxbOrgasmPitch or {}) then
        sxbOrgasmPitch = defaultSoundConfig.sxbOrgasmPitch or {1.0, 1.0}
    end

    local sxbOrgasmSounds = identity.sxbOrgasmSounds or definedSoundConfig.soundEffects
    if isEmpty(sxbOrgasmSounds or {}) then
        sxbOrgasmSounds = defaultSoundConfig.sxbOrgasmSounds or {}
    end

    self._soundConfig[name] = {
        pitch = sxbOrgasmPitch,
        interval = sxbOrgasmInterval,
        soundEffects = sxbOrgasmSounds or {},
        soundPoolName = self:getParent():getRole() .. name
    }

    self:createNewTimer(name)
    self:createNewInterval(name)
end

function Sexbound.Actor.Moan:tryLoadingSoundEffectsIntoSoundPool(name, soundEffects)
    local soundPoolName = self:getParent():getRole() .. name
    if not animator.hasSound(soundPoolName) then
        return
    end
    animator.setSoundPool(soundPoolName, soundEffects)
end

function Sexbound.Actor.Moan:getDefaultSoundConfigFromConfigFile(name)
    local gender = self:getParent():getGender()
    return self:getConfig()[name].soundConfig.default[gender] or nil
end

function Sexbound.Actor.Moan:getDefinedSoundConfigFromConfigFile(name)
    local species = self:getParent():getSpecies()
    local gender = self:getParent():getGender()
    local soundConfig = self:getConfig()[name].soundConfig
    soundConfig = soundConfig[species] or {}
    return soundConfig[gender] or nil
end

function Sexbound.Actor.Moan:isMoanSoundsEnabled()
    return self:getIsEnabled("moan")
end

function Sexbound.Actor.Moan:isOrgasmSoundsEnabled()
    return self:getIsEnabled("orgasm")
end

function Sexbound.Actor.Moan:onEnterClimaxState()
    self:processIsActive("climaxState")

    if not self:getIsEnabled("orgasm") or not self._isActive then
        return
    end

    self:resetTimer("orgasm")
    self:stopSound("moan")
    self:playSound("orgasm")
end

--- Called each time the actor updates the ClimaxState
-- @param dt
function Sexbound.Actor.Moan:onUpdateClimaxState(dt)
    if not self:getIsEnabled("orgasm") or not self._isActive then
        return
    end

    self:tryPlaySound("orgasm", dt)
end

--- Called when the actor enters the SexState
function Sexbound.Actor.Moan:onEnterSexState()
    self:processIsActive("sexState")

    if not self:getIsEnabled("moan") or not self._isActive then
        return
    end

    self:resetTimer("moan")

    self:refreshInterval("moan")
end

function Sexbound.Actor.Moan:onUpdateSexState(dt)
    if not self:getIsEnabled("moan") or not self._isActive then
        return
    end

    self:tryPlaySound("moan", dt)
end

--- Updates sfx timer and plays sfx when the time is right.
-- @param name
-- @param dt
function Sexbound.Actor.Moan:tryPlaySound(name, dt)
    self:addToTimer(name, dt)

    if self:getTimer(name) < self:getInterval(name) then
        return
    end

    self:stopSound(name)

    self:playSound(name)

    self:resetTimer(name)

    self:refreshInterval(name)
end

--- Plays a sound effect from specified sound pool.
-- @param name
function Sexbound.Actor.Moan:playSound(name)
    -- Send message to emote plugin to have the actor update its emote
    Sexbound.Messenger.get("main"):send(self, self:getPlugin("emote"), "Sexbound:Emote:ChangeEmote", "moan")

    if not self._soundConfig[name] then
        return
    end

    local soundPoolName = self._soundConfig[name].soundPoolName

    -- Exit early when animator does not have the sound pool
    if not animator.hasSound(soundPoolName) then
        return
    end

    -- Adjust the sound pitch to a new random pitch
    animator.setSoundPitch(soundPoolName, util.randomInRange(self._soundConfig[name].pitch), 0)

    -- Play a random sfx from the sound pool
    animator.playSound(soundPoolName)
end

--- Stops sounds from playing from specified pool name
-- @param name
function Sexbound.Actor.Moan:stopSound(name)
    if not self._soundConfig[name] then
        return
    end

    local soundPoolName = self._soundConfig[name].soundPoolName

    if not animator.hasSound(soundPoolName) then
        return
    end

    animator.stopAllSounds(soundPoolName)
end

--- Checks the current position settings to set this plugin as active or not
-- @param[opt] stateName
function Sexbound.Actor.Moan:processIsActive(stateName)
    local actor = self:getParent()

    stateName = stateName or actor:getParent():getStateMachine():stateDesc()

    local position = actor:getParent():getPositions():getCurrentPosition()

    self._isActive = position:getAnimationState(stateName):getAllowMoan(actor:getActorNumber())
end

--- Refreshes the sfx interval for a specified sound config
-- @param name
function Sexbound.Actor.Moan:refreshInterval(name)
    if not self._soundConfig[name] then
        return
    end

    self._intervals[name] = util.randomInRange(self._soundConfig[name].interval)
end

--- Returns the current value of a specified sfx interval
-- @param name
-- @return a number value
function Sexbound.Actor.Moan:getInterval(name)
    if name then
        return self._intervals[name]
    end
end

--- Returns the current value of a specified sfx enabled status
-- @param name
-- @return a boolean value
function Sexbound.Actor.Moan:getIsEnabled(name)
    return self._config[name].enabled
end

--- Adds a specified amount to a specified sfx timer
-- @param name
-- @param amount
function Sexbound.Actor.Moan:addToTimer(name, amount)
    self._timers[name] = self._timers[name] + amount
end

--- Returns the current value of a specified sfx timer
-- @param name
-- @return a number value
function Sexbound.Actor.Moan:getTimer(name)
    if name then
        return self._timers[name]
    end
end

--- Resets a specified sfx timer
-- @param name
function Sexbound.Actor.Moan:resetTimer(name)
    self._timers[name] = 0
end

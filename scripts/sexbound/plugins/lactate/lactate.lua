--- Sexbound.Actor.Lactate Class Module.
-- @classmod Sexbound.Actor.Lactate
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

Sexbound.Actor.Lactate = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Lactate_mt = {
    __index = Sexbound.Actor.Lactate
}

--- Instantiates a new instance of Lactation.
-- @param parent
-- @param config
function Sexbound.Actor.Lactate:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "LACT",
        _config = config,
        _burstTimer1 = 0,
        _burstTimer2 = 0
    }, Sexbound.Actor.Lactate_mt)

    _self:init(parent, _self._logPrefix)

    _self._nextBurstTime1 = _self:generateNextBurstTime()
    _self._nextBurstTime2 = _self:generateNextBurstTime()

    return _self
end

--- Handles message events.
-- @param message
function Sexbound.Actor.Lactate:onMessage(message)
    if message:getType() == "Sexbound:Climax:FireShot" then
        self:burstNipple1("-lactation-spew1")
        self:burstNipple2("-lactation-spew2")
    end
end

--- Handles event: onUpdateSexState
-- @param dt delta time
function Sexbound.Actor.Lactate:onUpdateAnyState(dt)
    self._burstTimer1 = self._burstTimer1 + dt
    if self._burstTimer1 >= self._nextBurstTime1 then
        self:burstNipple1()
    end

    self._burstTimer2 = self._burstTimer2 + dt
    if self._burstTimer2 >= self._nextBurstTime2 then
        self:burstNipple2()
    end
end

--- Plays sexbound_lactation particle effect for Nipple position #1
function Sexbound.Actor.Lactate:burstNipple1(particleSuffix)
    if self:thisActorHasExcludedSpecies() then return end
    if self:getConfig().requiresPregnancy and not self:getParent():isVisiblyPregnant() then
        return
    end

    local actorRole = self:getParent():getRole()
    if actorRole == "actor1" then return end

    particleSuffix = particleSuffix or "-lactation-drip1"
    animator.burstParticleEmitter(actorRole .. particleSuffix)
    self._burstTimer1 = 0
    self._nextBurstTime1 = self:generateNextBurstTime()
end

--- Plays sexbound_lactation particle effect for Nipple position #2
function Sexbound.Actor.Lactate:burstNipple2(particleSuffix)
    if self:thisActorHasExcludedSpecies() then return end
    if self:getConfig().requiresPregnancy and not self:getParent():isVisiblyPregnant() then
        return
    end

    local actorRole = self:getParent():getRole()
    if actorRole == "actor1" then return end

    particleSuffix = particleSuffix or "-lactation-drip2"
    animator.burstParticleEmitter(actorRole .. particleSuffix)
    self._burstTimer2 = 0
    self._nextBurstTime2 = self:generateNextBurstTime()
end

--- Generates the Next Burst Time
function Sexbound.Actor.Lactate:generateNextBurstTime()
    local nextBurstTime = util.randomInRange(self:getConfig().nextBurstTime)

    if self:getParent():getStatus():hasStatus("equipped_nipplering") then
        nextBurstTime = nextBurstTime * 0.3
    end

    return nextBurstTime
end

--- Checks whether or not this actor is excluded by species
function Sexbound.Actor.Lactate:thisActorHasExcludedSpecies()
    for _, species in ipairs(self:getConfig().excludedSpecies or {}) do
        if self:getParent():getSpecies() == species then
            return true
        end
    end

    return false
end
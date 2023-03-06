if not SXB_RUN_TESTS then
    require "/scripts/sexbound/plugins/climax/scriptedclimax/scenariobase.lua"
end

Sexbound.ScriptedClimax.Scenario1 = Sexbound.ScriptedClimax:new()
Sexbound.ScriptedClimax.Scenario1_mt = {
    __index = Sexbound.ScriptedClimax.Scenario1
}

function Sexbound.ScriptedClimax.Scenario1:new(parent)
    local _self = setmetatable({}, Sexbound.ScriptedClimax.Scenario1_mt)

    _self._phase = 0
    _self:init(parent)

    return _self
end

function Sexbound.ScriptedClimax.Scenario1:reset()

end

function Sexbound.ScriptedClimax.Scenario1:run(dt)
    self:getParent():addTimer("scriptedclimax", dt)

    self:getParent():addTimer("shoot", dt)

    if self:getParent():getTimer("scriptedclimax") >= 10 then
        if self:getParent():getTimer("scriptedclimax") >= 15 and self._phase == 1 then
            self:getParent():getRoot()._overrideMinTempo = 0
            self:getParent():getRoot()._overrideMaxTempo = 0
            self:getParent():getRoot()._overrideClimaxAnimation = false
            self._phase = 2
            
            self:triggerClimaxState()
        elseif self._phase == 0 then
            self:getParent():getRoot()._overrideMinTempo = 0.5
            self:getParent():getRoot()._overrideMaxTempo = 0.5
            self:getParent():getRoot()._overrideClimaxAnimation = true
            self._phase = 1
            self:getParent():scriptedImpregnation()
            
            self:getParent():getParent():getStatus():removeStatus("preclimaxing")
            self:getParent():getParent():getStatus():addStatus("climaxing")
            self:getParent():getParent()._isClimaxing = true
            self:getParent():getParent():getStateMachine():setStatus("climaxing", true)

            -- Send message to SexTalk plugin of this actor
            Sexbound.Messenger.get("main"):send(self:getParent(), self:getParent():getParent(), "Sexbound:SexTalk:BeginClimax")
        end
        if self:getParent():getTimer("shoot") >= self:getParent():getCooldown() then
            self:getParent():shoot()
        end
    end

    if self:getParent():getTimer("scriptedclimax") >= 30 then
        self:getParent():endScriptedClimax()
    end
end

function Sexbound.ScriptedClimax.Scenario1:start()
    local parent = self._parent
    local main = parent:getRoot()

    main._overrideSustainedInterval = 30
    main._overrideMinTempo = 1
    main._overrideMaxTempo = 7

    self._phase = 0

    -- parent:getConfig().shotCooldown = vec2.mul(parent:getConfig().shotCooldown, 0.5)
end

function Sexbound.ScriptedClimax.Scenario1:stop()
    local parent = self._parent
    local main = parent:getRoot()

    main._overrideSustainedInterval = nil
    main._overrideMinTempo = nil
    main._overrideMaxTempo = nil
    main._overrideClimaxAnimation = nil

    -- parent:getConfig().shotCooldown = vec2.mul(parent:getConfig().shotCooldown, 2)
end

function Sexbound.ScriptedClimax.Scenario1:triggerClimaxState()
    local top = self:getParent():getRoot()
    local position = top:getPositions():getCurrentPosition()
    local animationState = position:getAnimationState("climaxState")
    local stateName = animationState:getStateName()

    if not pcall(function()
        animator.setAnimationState("props", stateName, true)
        animator.setAnimationState("actors", stateName, true)
    end) then
        self._parent:getLog():error("The animator could not enter the animation state : " .. stateName)
    end

    top:resetAllActors("climaxState")

    animator.setAnimationRate(1)
end

function Sexbound.ScriptedClimax.Scenario1:spawnExplosion()
    local spawnPosition = entity.position()
    spawnPosition = vec2.add(spawnPosition, {0, 2})

    world.spawnProjectile("burningexplosion", spawnPosition, self:getParent():getParent():getEntityId(), nil, false, {
        actionOnReap = {
            ["1"] = {
                action = "config",
                file = "/projectiles/explosions/burningexplosion/burningexplosion.config"
            }
        }
    })
end

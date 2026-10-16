if not SXB_RUN_TESTS then
    require "/scripts/sexbound/plugins/climax/scriptedclimax/scenariobase.lua"
end

--- Scripted Climax Class, Scenario 1
--- @class Sexbound.ScriptedClimax.Scenario1: Sexbound.ScriptedClimax
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _phase integer
Sexbound.ScriptedClimax.Scenario1 = Sexbound.ScriptedClimax:new()
Sexbound.ScriptedClimax.Scenario1_mt = {
    __index = Sexbound.ScriptedClimax.Scenario1
}

--- Creates new instance of this scripted climax scenario
--- @param parent Sexbound.Actor.Climax The calling parent climax plugin instance
--- @return Sexbound.ScriptedClimax.Scenario1 # The newly created scripted climax scenario
function Sexbound.ScriptedClimax.Scenario1:new(parent)
    local _self = setmetatable({}, Sexbound.ScriptedClimax.Scenario1_mt)

    _self._phase = 0
    _self:init(parent)

    return _self
end

--- Resets the scenario
function Sexbound.ScriptedClimax.Scenario1:reset()

end

--- Function called each tick to progress animation
--- @param dt number The delta time since last tick
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

--- Starts the scripted climax script
function Sexbound.ScriptedClimax.Scenario1:start()
    local parent = self._parent
    local main = parent:getRoot()

    main._overrideSustainedInterval = 30
    main._overrideMinTempo = 1
    main._overrideMaxTempo = 7

    self._phase = 0
end

--- Stops the scripted climax script
function Sexbound.ScriptedClimax.Scenario1:stop()
    local parent = self._parent
    local main = parent:getRoot()

    main._overrideSustainedInterval = nil
    main._overrideMinTempo = nil
    main._overrideMaxTempo = nil
    main._overrideClimaxAnimation = nil
end

--- Triggers the climax state on the position
function Sexbound.ScriptedClimax.Scenario1:triggerClimaxState()
    local top = self:getParent():getRoot()
    local position = top:getPositions():getCurrentPosition()
    local animationState = position:getAnimationState("climaxState") --[[@as Sexbound.Position.AnimationState.State]]
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

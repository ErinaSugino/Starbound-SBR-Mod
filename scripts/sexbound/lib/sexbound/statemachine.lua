--- Sexbound.StateMachine Class Module.
--- @class Sexbound.StateMachine
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound
--- @field private _logPrefix string
--- @field private _states table<integer, string>
--- @field private _status table<string, boolean>
--- @field _stateMachine table
--- @field _positionTimer number
--- @field _positionTimeout integer
--- @field _positionTimeoutRange table<integer, integer>
--- @field _delayedIdleTrigger boolean
--- @field _log Sexbound.Log
--- @field _stateDefinitions table<string, table<string, function>>
--- @field _postclimaxTimer ?number
Sexbound.StateMachine = {}
Sexbound.StateMachine_mt = {
    __index = Sexbound.StateMachine
}

if not SXB_RUN_TESTS then
    require "/scripts/stateMachine.lua" -- Chucklefish's StateMachine
end

--- Creates a new state machine instance
--- @param parent Sexbound The calling parent sexnode instance
--- @return Sexbound.StateMachine # The new state machine instance
function Sexbound.StateMachine.new(parent)
    local self = setmetatable({
        _logPrefix = "STMN",
        _parent = parent,
        _states = {"nullState", "idleState", "sexState", "climaxState", "postclimaxState", "exitState"},
        _status = {
            climaxing = false,
            havingSex = false,
            idle = false,
            reseting = false
        },
        _positionTimer = 0,
        _positionTimeout = 10,
        _positionTimeoutRange = {30, 50},
        _delayedIdleTrigger = false
    }, Sexbound.StateMachine_mt)

    Sexbound.Messenger.get("main"):addBroadcastRecipient(self)

    self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())

    self._positionTimeout = util.randomIntInRange(self._positionTimeoutRange)

    self._stateDefinitions = {
        -- [Null State]----------------------------------------------------------------------------------
        nullState = {
            enter = function()
                if not self:isIdle() and not self:isHavingSex() and not self:isClimaxing() and not self:isPostClimaxing() and not self:isReseting() then
                    return {}
                end
            end,

            enteringState = function(stateData)
                self:getLog():info("Entering Null State.")

                if animator and not pcall(function()
                    animator.setAnimationState("props", "none", true)
                    animator.setAnimationState("actors", "none", true)
                end) then
                    self:getLog():error("The animator could not enter the 'none' animation state.")
                end

                self:getParent():getSextalk():onEnterNullState()
            end,

            update = function(dt, stateData)
                -- Exit condition
                if self:getParent():getActorCount() > 0 then
                    self:setStatus("idle", true)
                    return true
                end
            end,

            leavingState = function(stateData)

            end
        },

        -- [Idle State]----------------------------------------------------------------------------------
        idleState = {
            enter = function()
                if self:isIdle() and not self:isHavingSex() then
                    return {
                        actors = self:getParent():getActors()
                    }
                end
            end,

            enteringState = function(stateData)
                self:getLog():info("Entering Idle State.")

                local position = self:getParent():getPositions():getCurrentPosition()

                local animationState = position:getAnimationState("idleState") --[[@as Sexbound.Position.AnimationState.State]]

                local stateName = animationState:getStateName()

                if animator and not pcall(function()
                    animator.setAnimationState("props", stateName, true)
                    animator.setAnimationState("actors", stateName, true)
                end) then
                    self:getLog():error("The animator could not enter the animation state : " .. stateName)
                end

                self:getParent():resetAllActors("idleState")

                animator.setAnimationRate(1)

                for _, actor in ipairs(stateData.actors) do
                    actor:onEnterAnyState()
                    actor:onEnterIdleState()
                end
                self:getParent():getSextalk():onEnterIdleState()

                if not self:getParent():getContainsPlayer() and self:getParent()._config.sex.npcStartSex then
                    self._delayedIdleTrigger = true
                end
            end,

            update = function(dt, stateData)
                -- Exit condition #1
                if self:getParent():getActorCount() < 1 then
                    self:setStatus("idle", false)
                    return true
                end

                if self:isHavingSex() then return true end
                --- Idling is now it's own mechanic

                if self._delayedIdleTrigger and self._stateMachine:stateDesc() == "idleState" then
                    self:getParent():getPositions():switchRandomSexPosition(true)
                    self._delayedIdleTrigger = false
                else
                    -- Skip update if we switch anyway
                    for _, actor in ipairs(stateData.actors) do
                        actor:onUpdateAnyState(dt)
                        actor:onUpdateIdleState(dt)
                    end
                end
            end,

            leavingState = function(stateData)
                for _, actor in ipairs(stateData.actors) do
                    actor:onExitAnyState()
                    actor:onExitIdleState()
                end
            end
        },

        -- [Sex State]-----------------------------------------------------------------------------------
        sexState = {
            enter = function()
                if self:getStatus("havingSex") and
                    not self:getStatus("climaxing") and
                    not self:getStatus("postclimax") and
                    not self:getStatus("reseting") then
                    local actors = self:getParent():getActors()

                    local npcOnly = true

                    for _, actor in ipairs(actors) do
                        if actor:getEntityType() == "player" then
                            npcOnly = false
                            break
                        end
                    end

                    return {
                        actors = actors,
                        npcOnly = npcOnly
                    }
                end
            end,

            enteringState = function(stateData)
                self:getLog():info("Entering Sex State.")

                local position = self:getParent():getPositions():getCurrentPosition()

                local animationState = position:getAnimationState("sexState") --[[@as Sexbound.Position.AnimationState.State]]

                animationState:nextMinTempo()
                animationState:nextMaxTempo()
                animationState:nextSustainedInterval()

                local stateName = animationState:getStateName()

                if not pcall(function()
                    animator.setAnimationState("props", stateName, true)
                    animator.setAnimationState("actors", stateName, true)
                end) then
                    self:getLog():error("The animator could not enter the animation state : " .. stateName)
                end

                self:getParent():resetAllActors("sexState")

                animator.setAnimationRate(1)

                for _, actor in ipairs(stateData.actors) do
                    actor:onEnterAnyState()
                    actor:onEnterSexState()
                end
                self:getParent():getSextalk():onEnterSexState()
            end,

            update = function(dt, stateData)
                if not self:isHavingSex() then return true end

                -- Exit condition #1
                if self:getParent():getActorCount() < 1 then
                    self:setStatus("havingSex", false)
                    return true
                end

                -- Exit condition #2
                if self:getStatus("climaxing") or self:getStatus("reseting") then
                    return true
                end

                -- Update the animation playback rate
                self:getParent():updateAnimationRate("sexState", dt)

                for _, actor in ipairs(stateData.actors) do
                    actor:onUpdateAnyState(dt)
                    actor:onUpdateSexState(dt)
                end

                -- Allow NPC only acts to switch positions. npcOnly was not defined
                if not self:getParent():getContainsPlayer() then
                    self._positionTimer = self._positionTimer + dt

                    if self._positionTimer >= self._positionTimeout then
                        self:getParent():getPositions():switchRandomSexPosition(false)

                        self._positionTimer = 0

                        self._positionTimeout = util.randomIntInRange(self._positionTimeoutRange)
                    end
                else self._positionTimer = 0 end
            end,

            leavingState = function(stateData)
                self:getParent():setAnimationRate(1)

                for _, actor in ipairs(stateData.actors) do
                    actor:onExitAnyState()
                    actor:onExitSexState()
                end
            end
        },

        -- [Climax State]--------------------------------------------------------------------------------
        climaxState = {
            enter = function()
                if self:getStatus("havingSex") and self:getStatus("climaxing") then
                    return {
                        actors = self:getParent():getActors()
                    }
                end
            end,

            enteringState = function(stateData)
                self:getLog():info("Entering Climax State.")

                -- For scripted Climax: Keep animating if flag is set
                if not self:getParent()._overrideClimaxAnimation then
                    local position = self:getParent():getPositions():getCurrentPosition()

                    local animationState = position:getAnimationState("climaxState") --[[@as Sexbound.Position.AnimationState.State]]

                    local stateName = animationState:getStateName()

                    if not pcall(function()
                        animator.setAnimationState("props", stateName, true)
                        animator.setAnimationState("actors", stateName, true)
                    end) then
                        self:getLog():error("The animator could not enter the animation state : " .. stateName)
                    end

                    self:getParent():resetAllActors("climaxState")

                    animator.setAnimationRate(1)
                else self:getLog():debug("Entering Climax State but skipping animator change due to flag") end

                for _, actor in ipairs(stateData.actors) do
                    actor:onEnterAnyState()
                    actor:onEnterClimaxState()
                end
                self:getParent():getSextalk():onEnterClimaxState()
            end,

            update = function(dt, stateData)
                -- Exit condition #1
                if self:getParent():getActorCount() <= 1 then
                    self:setStatus("havingSex", false)
                    return true
                end

                -- Exit condition #2
                if not self:getStatus("havingSex") or not self:getStatus("climaxing") then
                    return true
                end

                -- For scripted Climax: Keep animating if flag is set
                if self:getParent()._overrideClimaxAnimation then
                    self:getParent():updateAnimationRate("sexState", dt)
                end

                for _, actor in ipairs(stateData.actors) do
                    actor:onUpdateAnyState(dt)
                    actor:onUpdateClimaxState(dt)
                end
            end,

            leavingState = function(stateData)
                self:setStatus("climaxing", false)

                for _, actor in ipairs(stateData.actors) do
                    actor:onExitAnyState()
                    actor:onExitClimaxState()
                end
            end
        },

        -- [Post-Climax State]--------------------------------------------------------------------------------
        postclimaxState = {
            enter = function()
                if self:getStatus("havingSex") and self:getStatus("postclimax") and not self:getStatus("climaxing") then
                    return {
                        actors = self:getParent():getActors()
                    }
                end
            end,

            enteringState = function(stateData)
                self:getLog():info("Entering Post-Climax State.")

                local position = self:getParent():getPositions():getCurrentPosition()

                local animationState = position:getAnimationState("postclimaxState") --[[@as Sexbound.Position.AnimationState.State]]

                local stateName = animationState:getStateName()

                if not pcall(function()
                    animator.setAnimationState("props", stateName, true)
                    animator.setAnimationState("actors", stateName, true)
                end) then
                    self:getLog():error("The animator could not enter the animation state : " .. stateName)
                end

                self:getParent():resetAllActors("postclimaxState")

                for _, actor in ipairs(stateData.actors) do
                    actor:onEnterAnyState()
                end
                self:getParent():getSextalk():onEnterPostClimaxState()

                self._postclimaxTimer = 0
            end,

            update = function(dt, stateData)
                -- Exit condition #1
                if self:getParent():getActorCount() <= 1 then
                    self:setStatus("havingSex", false)
                    return true
                end

                -- Exit condition #2
                if not self:getStatus("havingSex") or not self:getStatus("postclimax") then
                    return true
                end
                
                -- Exit condition #3
                if self._postclimaxTimer >= 1.5 then
                    return true
                end

                self._postclimaxTimer = self._postclimaxTimer + dt

                for _, actor in ipairs(stateData.actors) do
                    actor:onUpdateAnyState(dt)
                end
            end,

            leavingState = function(stateData)
                self:setStatus("postclimax", false)

                for _, actor in ipairs(stateData.actors) do
                    actor:onExitAnyState()
                end
            end
        },

        -- [Exit State]----------------------------------------------------------------------------------
        exitState = {
            enter = function()
                if self:getStatus("havingSex") and self:getStatus("reseting") then
                    return {
                        actors = self:getParent():getActors()
                    }
                end
            end,

            enteringState = function(stateData)
                self:getLog():info("Entering Exit State.")

                local position = self:getParent():getPositions():getCurrentPosition()

                local animationState = position:getAnimationState("exitState") --[[@as Sexbound.Position.AnimationState.State]]

                local stateName = animationState:getStateName()

                if not pcall(function()
                    animator.setAnimationState("props", stateName, true)
                    animator.setAnimationState("actors", stateName, true)
                end) then
                    self:getLog():error("The animator could not enter the animation state : " .. stateName)
                end

                self:getParent():resetAllActors("exitState")

                animator.setAnimationRate(1)

                for _, actor in ipairs(stateData.actors) do
                    actor:onEnterAnyState()
                    actor:onEnterExitState()
                end
                self:getParent():getSextalk():onEnterExitState()
            end,

            update = function(dt, stateData)
                -- Exit condition #1
                if self:getParent():getActorCount() <= 1 then
                    self:setStatus("havingSex", false)
                    return true
                end

                -- Exit condition #2
                if not self:getStatus("havingSex") or not self:getStatus("reseting") then
                    return true
                end

                for _, actor in ipairs(stateData.actors) do
                    actor:onUpdateAnyState(dt)
                    actor:onUpdateExitState(dt)
                end
            end,

            leavingState = function(stateData)
                self:setStatus("reseting", false)

                for _, actor in ipairs(stateData.actors) do
                    actor:onExitAnyState()
                    actor:onExitExitState()
                end
            end
        }
    }

    -- Create default states
    self._stateMachine = stateMachine.create(self._states, self._stateDefinitions)

    return self
end

--- Function called each tick to update timers
--- @param dt number The delta time since last tick
function Sexbound.StateMachine:update(dt)
    self._stateMachine.update(dt)
end

--- Filters actors from a list based on who is enabled for the given animation state
--- @param animationState Sexbound.Position.AnimationState.State The current animation state
--- @param actors table<integer, Sexbound.Actor> The original list of actors
--- @return table<integer, Sexbound.Actor> # The filtered list
function Sexbound.StateMachine:filterEnabledActors(animationState, actors)
    local newActors = {}

    -- Filter out disabled actors
    for _, actor in ipairs(actors) do
        if animationState:getEnabled(actor:getActorNumber()) then
            table.insert(newActors, actor)
        end
    end

    return newActors
end

-- [[ Getters / Setters ]]

--- Returns the logging instance
--- @return Sexbound.Log # The logging instance
function Sexbound.StateMachine:getLog()
    return self._log
end

--- Returns the log prefix
--- @return string # The log prefix
function Sexbound.StateMachine:getLogPrefix()
    return self._logPrefix
end

--- Returns the parent sexbound instante
--- @return Sexbound # The parent sexbound instance
function Sexbound.StateMachine:getParent()
    return self._parent
end

--- Returns whethere or not a status enabled
--- @param name string The status name
--- @return boolean # Whethere or not that status enabled
function Sexbound.StateMachine:getStatus(name)
    return self._status[name]
end

--- Sets the enabled state of a given status
--- @param name string The status name
--- @param value boolean # The new enabled status
function Sexbound.StateMachine:setStatus(name, value)
    self._status[name] = value
end

--- Returns whethere or not the idle status is enabled
--- @return boolean # Whethere or not the idle status is enabled
function Sexbound.StateMachine:isIdle()
    return self:getStatus("idle")
end

--- Returns whethere or not the climax status is enabled
--- @return boolean # Whethere or not the climax status is enabled
function Sexbound.StateMachine:isClimaxing()
    return self:getStatus("climaxing")
end

--- Returns whethere or not the post-climax status is enabled
--- @return boolean # Whethere or not the post-climax status is enabled
function Sexbound.StateMachine:isPostClimaxing()
    return self:getStatus("postclimax")
end

--- Returns whethere or not the sex status is enabled
--- @return boolean # Whethere or not the sex status is enabled
function Sexbound.StateMachine:isHavingSex()
    return self:getStatus("havingSex")
end

--- Returns whethere or not the reset status is enabled
--- @return boolean # Whethere or not the reset status is enabled
function Sexbound.StateMachine:isReseting()
    return self:getStatus("reseting")
end

--- Returns the current state's description
--- @return string # The current state's description
function Sexbound.StateMachine:stateDesc()
    local stateName = self._stateMachine.stateDesc() or ""
    if stateName == "" then return "nullState" end
    return stateName
end

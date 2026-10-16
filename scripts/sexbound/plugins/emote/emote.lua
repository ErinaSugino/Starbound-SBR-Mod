if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

--- Sexbound.Actor.Emote Class Module.
--- @class Sexbound.Actor.Emote: Sexbound.Actor.Plugin
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _isActive boolean
--- @field _statusList table<integer, string>
Sexbound.Actor.Emote = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Emote_mt = {
    __index = Sexbound.Actor.Emote
}

--- Instantiates a new instance of Emote.
--- @param parent Sexbound.Actor The calling parent actor instance
--- @param config table The plugin's config
--- @return Sexbound.Actor.Emote # The newly created emote manager instance
function Sexbound.Actor.Emote:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "EMOT",
        _config = config,
        _isActive = true,
        _statusList = {}
    }, Sexbound.Actor.Emote_mt)

    _self:init(parent, _self._logPrefix)

    for _, emote in pairs(_self._config.emotePool) do
        if emote.statusName then
            table.insert(_self._statusList, emote.statusName)
        end
    end

    return _self
end

--- Handles a received message.
--- @param message Sexbound.Message The received message
function Sexbound.Actor.Emote:onMessage(message)
    if message:isType("Sexbound:Emote:ChangeEmote") then
        local functionName = "show_" .. message:getData()

        if "function" == type(self[functionName]) then
            self[functionName](self)
        end
    end

    -- On Message Received: SwitchPosition
    if message:isType("Sexbound:Positions:SwitchPosition") then
        local stateName = self:getParent():getParent():getStateMachine():stateDesc()

        self:processIsActive(stateName)
    end

    -- On Message Received: SwitchRoles
    if message:isType("Sexbound:SwitchRoles") then
        local stateName = self:getParent():getParent():getStateMachine():stateDesc()

        self:processIsActive(stateName)
    end
end

--- Function called each tick to update timers
--- @param dt number The delta time since last tick
function Sexbound.Actor.Emote:update(dt)
    if not self._isActive or not self:getParent():getStatus():hasOneOf(self._statusList) then
        self:show_none()
        return
    end
end

--- Clears all emote statuses
function Sexbound.Actor.Emote:clearAllEmoteStatuses()
    local myStatus = self:getParent():getStatus()

    for _, emote in pairs(self._config.emotePool) do
        if emote.statusName then
            myStatus:removeStatus(emote.statusName)
        end
    end
end

--- Triggers the "annoyed" emote
function Sexbound.Actor.Emote:show_annoyed()
    self:helper_show("annoyed")
end

--- Triggers the "blabber" emote
function Sexbound.Actor.Emote:show_blabber()
    self:helper_show("blabber")
end

--- Triggers the "climax" emote
function Sexbound.Actor.Emote:show_climax()
    self:helper_show("climax")
end

--- Triggers the "cry" emote
function Sexbound.Actor.Emote:show_cry()
    self:helper_show("cry")
end

--- Triggers the "happy" emote
function Sexbound.Actor.Emote:show_happy()
    self:helper_show("happy")
end

--- Triggers the "laugh" emote
function Sexbound.Actor.Emote:show_laugh()
    self:helper_show("laugh")
end

--- Triggers the "moan" emote
function Sexbound.Actor.Emote:show_moan()
    self:helper_show("moan")
end

--- Triggers the "neutral" emote
function Sexbound.Actor.Emote:show_neutral()
    self:helper_show("neutral")
end

--- Triggers the "shout" emote
function Sexbound.Actor.Emote:show_shout()
    self:helper_show("shout")
end

--- Triggers the "wink" emote
function Sexbound.Actor.Emote:show_wink()
    self:helper_show("wink")
end

--- Triggers the "none" emote
function Sexbound.Actor.Emote:show_none()
    self:changeAnimationState("none")
end

--- Changes the animation state for the parent actor.
--- @param stateName string Animation state name
function Sexbound.Actor.Emote:changeAnimationState(stateName)
    pcall(function()
        animator.setAnimationState("actor" .. self:getParent():getActorNumber() .. "Emote", stateName, true)
    end)
end

--- [Helper] Triggers animation state for a given emote
--- @private
--- @param emoteName string The emote name
function Sexbound.Actor.Emote:helper_show(emoteName)
    self:getLog():info("Triggering emotion "..emoteName.." on actor "..self:getParent():getName())
    if not self._isActive then
        self:getLog():debug("Aborting because not active")
        return
    end

    local myStatus = self:getParent():getStatus()

    self:clearAllEmoteStatuses()

    local emote = self:getEmotePool(emoteName)

    -- Can other emotes interrupt talking?
    if myStatus:hasStatus("talking") and self._config.talkingIsPriority then
        self:getLog():debug("Aborting because talking")
        return
    end

    if emote.statusName then
        myStatus:addStatus(emote.statusName, emote.timeout or 1)
    end

    if "table" == type(emote.animState) then
        self:changeAnimationState(util.randomChoice(emote.animState))
    end
end

--- Processes whethere or not emoting is active
--- @param stateName string Name of the current animation state
function Sexbound.Actor.Emote:processIsActive(stateName)
    local animState = self:getParent():getPosition():getAnimationState(stateName)

    if animState then
        self._isActive = animState:getAllowEmote(self:getParent():getActorNumber())
    else
        self._isActive = false
    end
end

--- Uninitializes this instance.
function Sexbound.Actor.Emote:uninit()
    self:getLog():info("Uniniting.")

    self:show_none()
end

--- State enter handler for idle state
function Sexbound.Actor.Emote:onEnterIdleState()
    self:show_none()

    self:processIsActive("idleState")
end

--- Function called each tick while in idle state
--- @param dt number The delta time since last tick
function Sexbound.Actor.Emote:onUpdateIdleState(dt)
    self:update(dt)
end

--- State enter handler for sex state
function Sexbound.Actor.Emote:onEnterSexState()
    self:show_none()

    self:processIsActive("sexState")
end

--- State enter handler for climax state
function Sexbound.Actor.Emote:onEnterClimaxState()
    self:processIsActive("climaxState")

    -- if self._isActive then self:show_climax() end
end

--- State enter handler for exit state
function Sexbound.Actor.Emote:onEnterExitState()
    self:show_none()

    self:processIsActive("exitState")
end

--- State leave handler for sex state
function Sexbound.Actor.Emote:onExitSexState()
    self:show_none()
end

--- Function called each tick while in climax state
--- @param dt number The delta time since last tick
function Sexbound.Actor.Emote:onUpdateClimaxState(dt)
    self:update(dt)
end

--- Function called each tick while in sex state
--- @param dt number The delta time since last tick
function Sexbound.Actor.Emote:onUpdateSexState(dt)
    self:update(dt)
end

--- Returns the list of emotes or a requested one
--- @param emoteName string? Name of the requested emote
--- @return table<string, any> # The requested emote data or the list of all emotes if none requested
function Sexbound.Actor.Emote:getEmotePool(emoteName)
    if emoteName then
        return self._config.emotePool[emoteName] or self._config.emotePool["default"]
    end
    return self._config.emotePool
end

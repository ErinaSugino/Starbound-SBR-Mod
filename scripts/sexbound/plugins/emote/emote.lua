--- Sexbound.Actor.Emote Class Module.
-- @classmod Sexbound.Actor.Emote
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

Sexbound.Actor.Emote = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Emote_mt = {
    __index = Sexbound.Actor.Emote
}

--- Instantiates a new instance of Emote.
-- @param parent
-- @param config
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
-- @param message
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

function Sexbound.Actor.Emote:update(dt)
    if not self._isActive or not self:getParent():getStatus():hasOneOf(self._statusList) then
        self:show_none()
        return
    end
end

function Sexbound.Actor.Emote:clearAllEmoteStatuses()
    local myStatus = self:getParent():getStatus()

    for _, emote in pairs(self._config.emotePool) do
        if emote.statusName then
            myStatus:removeStatus(emote.statusName)
        end
    end
end

function Sexbound.Actor.Emote:show_annoyed()
    self:helper_show("annoyed")
end
function Sexbound.Actor.Emote:show_blabber()
    self:helper_show("blabber")
end
function Sexbound.Actor.Emote:show_climax()
    self:helper_show("climax")
end
function Sexbound.Actor.Emote:show_cry()
    self:helper_show("cry")
end
function Sexbound.Actor.Emote:show_happy()
    self:helper_show("happy")
end
function Sexbound.Actor.Emote:show_laugh()
    self:helper_show("laugh")
end
function Sexbound.Actor.Emote:show_moan()
    self:helper_show("moan")
end
function Sexbound.Actor.Emote:show_neutral()
    self:helper_show("neutral")
end
function Sexbound.Actor.Emote:show_shout()
    self:helper_show("shout")
end
function Sexbound.Actor.Emote:show_wink()
    self:helper_show("wink")
end
function Sexbound.Actor.Emote:show_none()
    self:changeAnimationState("none")
end

--- Changes the animation state for the parent actor.
-- @param stateName
function Sexbound.Actor.Emote:changeAnimationState(stateName)
    pcall(function()
        animator.setAnimationState("actor" .. self:getParent():getActorNumber() .. "Emote", stateName, true)
    end)
end

function Sexbound.Actor.Emote:helper_show(emoteName)
    sb.logInfo("Triggering emotion "..emoteName.." on actor "..self:getParent():getName())
    if not self._isActive then
        sb.logInfo("Aborting because not active")
        return
    end

    local myStatus = self:getParent():getStatus()

    self:clearAllEmoteStatuses()

    local emote = self:getEmotePool(emoteName)

    -- Can other emotes interrupt talking?
    if myStatus:hasStatus("talking") and self._config.talkingIsPriority then
        sb.logInfo("Aborting because talking")
        return
    end

    if emote.statusName then
        myStatus:addStatus(emote.statusName, emote.timeout or 1)
    end

    if "table" == type(emote.animState) then
        self:changeAnimationState(util.randomChoice(emote.animState))
    end
end

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

function Sexbound.Actor.Emote:onEnterIdleState()
    self:show_none()

    self:processIsActive("idleState")
end

function Sexbound.Actor.Emote:onUpdateIdleState(dt)
    self:update(dt)
end

function Sexbound.Actor.Emote:onEnterSexState()
    self:show_none()

    self:processIsActive("sexState")
end

function Sexbound.Actor.Emote:onEnterClimaxState()
    self:processIsActive("climaxState")

    -- if self._isActive then self:show_climax() end
end

function Sexbound.Actor.Emote:onEnterExitState()
    self:show_none()

    self:processIsActive("exitState")
end

function Sexbound.Actor.Emote:onExitSexState()
    self:show_none()
end

function Sexbound.Actor.Emote:onUpdateClimaxState(dt)
    self:update(dt)
end

function Sexbound.Actor.Emote:onUpdateSexState(dt)
    self:update(dt)
end

function Sexbound.Actor.Emote:getEmotePool(emoteName)
    if emoteName then
        return self._config.emotePool[emoteName] or self._config.emotePool["default"]
    end
    return self._config.emotePool
end

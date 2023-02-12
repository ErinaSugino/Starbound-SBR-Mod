--- Sexbound.Actor.SexTalk Class Module.
-- @classmod Sexbound.Actor.SexTalk
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
    require("/scripts/util.lua")
end

Sexbound.Actor.SexTalk = Sexbound.Actor.Plugin:new()
Sexbound.Actor.SexTalk_mt = {
    __index = Sexbound.Actor.SexTalk
}

--- Instantiates a new instance of SexTalk.
-- @param parent
-- @param config
function Sexbound.Actor.SexTalk:new(parent, config)
    local _self = setmetatable({
        _debugColor = "red",
        _logPrefix = "SEXT",
        _config = config,
        _currentMessage = "",
        _dialogPool = {},
        _isActive = true,
        _history = {},
        _timer = 0
    }, Sexbound.Actor.SexTalk_mt)

    _self:init(parent, _self._logPrefix, function()
        _self._cooldown = util.randomInRange(_self._config.cooldown)
    end)

    _self._dialog = _self:loadDialog()
    _self._defaultDialog = _self:loadDialog("default")

    return _self
end

function Sexbound.Actor.SexTalk:onMessage(message)
    if "Sexbound:Positions:SwitchPosition" == message:getType() then
        self:handleSwitchPosition()
    end
    if "Sexbound:SexTalk:BeginClimax" == message:getType() then
        self:handleBeginClimax()
    end
    if "Sexbound:SwitchRoles" == message:getType() then
        self:handleSwitchRoles()
    end
end

--- [Helper] Handles when this actor begins to climax
function Sexbound.Actor.SexTalk:handleBeginClimax()
    -- Say random with 'climaxing' as the prioritized status for both actors.
    if self:processIsActive("climaxState") then
        self._timer = 0

        local actor = self:getParent()
        local actorStatus = actor:getStatus():findStatus("climaxing")

        local otherStatus = actor:getOtherActor():getStatus():findStatus("climaxing")

        self:sayRandom(actorStatus, otherStatus)
    end
end

--- [Helper] Handles when this actor switches its position
function Sexbound.Actor.SexTalk:handleSwitchPosition()
    self._dialog = self:loadDialog()
    self._defaultDialog = self:loadDialog("default")

    local stateName = self:getParent():getParent():getStateMachine():stateDesc()
    if self:processIsActive(stateName) then
        self:sayRandom()
    end
end

--- [Helper] Handles when this actor switches its role
function Sexbound.Actor.SexTalk:handleSwitchRoles()
    local stateName = self:getParent():getParent():getStateMachine():stateDesc()
    if self:processIsActive(stateName) then
        self:sayRandom()
    end
end

function Sexbound.Actor.SexTalk:onEnterClimaxState()
    if not self._isActive then
        return
    end
end

function Sexbound.Actor.SexTalk:onEnterExitState()
    self:processIsActive("exitState")
end

function Sexbound.Actor.SexTalk:onEnterIdleState()
    self:processIsActive("idleState")
end

function Sexbound.Actor.SexTalk:onUpdateIdleState()
    if self:getParent()._isTalking then
        self:getParent():getMouth():applyPosition()
    end
end

function Sexbound.Actor.SexTalk:onEnterSexState()
    if self:processIsActive("sexState") then
        self._timer = 0
        self._dialog = self:loadDialog()
        self._defaultDialog = self:loadDialog("default")
        self:sayRandom()
    end
end

function Sexbound.Actor.SexTalk:onUpdateClimaxState(dt)
    if not self._isActive then
        return
    end

    if self:getParent()._isTalking then
        self:getParent():getMouth():applyPosition()
    end

    self._timer = self._timer + dt

    if self._timer >= self._cooldown then
        -- Say random with 'climaxing' as the prioritized status for both actors.
        self:sayRandom("climaxing", "climaxing")

        self._timer = 0
    end
end

function Sexbound.Actor.SexTalk:onUpdateSexState(dt)
    if not self._isActive then
        return
    end

    if self:getParent()._isTalking then
        self:getParent():getMouth():applyPosition()
    end

    self._timer = self._timer + dt

    if self._timer >= self._cooldown then
        self:sayRandom()

        self._timer = 0
    end
end

function Sexbound.Actor.SexTalk:loadDialog(species)
    species = species or self:getParent():getSpecies()

    local filename = self:getPosition():getDialog(species, nil)

    if not filename then
        return
    end

    filename = util.replaceTag(filename, "species", species or "default")
    filename = util.replaceTag(filename, "gender", self:getParent():getGender() or "default")
    filename = util.replaceTag(filename, "position", self:getPosition():getName() or "default")

    -- Change to always use the 'en' language code because too much can go wrong
    -- when trying to dynamically load config file for other languages.
    filename = util.replaceTag(filename, "langcode", "en")

    local dialog

    if not pcall(function()
        dialog = root.assetJson(filename)
    end) then
        self:getLog():warn("Unable to load dialog file for species : " .. species)
    end

    return dialog
end

function Sexbound.Actor.SexTalk:processIsActive(stateName)
    self._isActive = self:thisActorIsAllowedToTalk(stateName)

    return self._isActive
end

function Sexbound.Actor.SexTalk:thisActorIsAllowedToTalk(stateName)
    local animState = self:getParent():getAnimationState(stateName)

    return animState:getAllowTalk(self:getParent():getActorNumber())
end

function Sexbound.Actor.SexTalk:helper_mergeVariant(dialog, species, gender, status)
    local d = dialog

    d = d[species] or {}
    d = d[gender] or {}
    d = d[status] or {}

    if not isEmpty(d) then
        self._dialogPool = util.mergeLists(self._dialogPool, d)
    end
end

function Sexbound.Actor.SexTalk:skipMergeDefaultDialog()
    local skipConfig = self:getConfig().skipMergeDefaultDialog or {}
    local speciesList = skipConfig.species
    local typeList = skipConfig.entityType
    local _, skipMergeDefault

    _, skipMergeDefault = util.find(speciesList, function(s)
        return s == self:getParent():getSpecies()
    end)
    if (skipMergeDefault) then
        return skipMergeDefault
    end

    _, skipMergeDefault = util.find(typeList, function(s)
        return s == self:getParent():getEntityType()
    end)
    if (skipMergeDefault) then
        return skipMergeDefault
    end

    return false
end

function Sexbound.Actor.SexTalk:refreshDialogPool(actorStatus, otherStatus)
    self._dialogPool = {}
    local dialog = self._dialog or {}

    local actor = self:getParent()
    local otherActor = actor:getOtherActor()

    if not otherActor then
        return
    end
    
    local actorNumber = actor:getActorNumber()
    local otherGender = otherActor:getGenderFutasafe()
    local otherSpecies = otherActor:getSpecies()

    otherStatus = otherActor:status():findStatus(otherStatus)
    otherStatus = otherStatus or util.randomChoice(otherActor:status():getStatusList())

    actorStatus = actor:status():findStatus(actorStatus)
    actorStatus = actorStatus or util.randomChoice(actor:status():getStatusList())

    dialog = dialog[actorNumber] or {}
    dialog = dialog[actorStatus] or dialog["default"] or dialog

    self:helper_mergeVariant(dialog, otherSpecies, otherGender, otherStatus)
    self:helper_mergeVariant(dialog, "default", otherGender, otherStatus)
    self:helper_mergeVariant(dialog, otherSpecies, "default", otherStatus)
    self:helper_mergeVariant(dialog, "default", "default", otherStatus)

    self:getLog():debug("dialog for scenario: " .. self:dump(self._dialogPool))

    if isEmpty(self._dialogPool) then
        self:helper_mergeVariant(dialog, otherSpecies, otherGender, "default")
        self:helper_mergeVariant(dialog, "default", otherGender, "default")
        self:helper_mergeVariant(dialog, otherSpecies, "default", "default")
        self:helper_mergeVariant(dialog, "default", "default", "default")
    end

    if not self:skipMergeDefaultDialog() then
        dialog = self._defaultDialog or {}

        dialog = dialog[actorNumber] or {}
        dialog = dialog[actorStatus] or dialog["default"] or dialog

        self:helper_mergeVariant(dialog, otherSpecies, otherGender, otherStatus)
        self:helper_mergeVariant(dialog, "default", otherGender, otherStatus)
        self:helper_mergeVariant(dialog, otherSpecies, "default", otherStatus)
        self:helper_mergeVariant(dialog, "default", "default", otherStatus)

        if isEmpty(self._dialogPool) then
            self:helper_mergeVariant(dialog, otherSpecies, otherGender, "default")
            self:helper_mergeVariant(dialog, "default", otherGender, "default")
            self:helper_mergeVariant(dialog, otherSpecies, "default", "default")
            self:helper_mergeVariant(dialog, "default", "default", "default")
        end
    end

    return self._dialogPool
end

function Sexbound.Actor.SexTalk:findEmoticon(dialog)
    local emoticons = self._config.emoticons
    local found

    for groupName, emoticonGroup in pairs(emoticons) do
        for _, emoticon in ipairs(emoticonGroup) do
            local s,_ = string.find(dialog, emoticon, 1, true)
            if s ~= nil then
                found = groupName
            end
        end
    end

    return found
end

function Sexbound.Actor.SexTalk:sayRandom(actorStatus, otherStatus)
    local dialogPool = self:refreshDialogPool(actorStatus, otherStatus) or {}

    if isEmpty(dialogPool) then
        return
    end

    local dialog = util.randomChoice(dialogPool)

    if "string" and type(dialog) and dialog ~= "" then
        local actor = self:getParent()
        local otherActor = actor:getOtherActor()
        local emote = self:getParent():getPlugins("emote")
        local emoticon

        if self._config.enableEmoticons then
            emoticon = self:findEmoticon(dialog)
        end

        if object then
            object.say(dialog)
        end

        actor._isTalking = true

        otherActor._isTalking = false

        if emoticon then
            if emote then
                Sexbound.Messenger.get("main"):send(self, emote, "Sexbound:Emote:ChangeEmote", emoticon)
            end
        else
            if emote then
                Sexbound.Messenger.get("main"):send(self, emote, "Sexbound:Emote:ChangeEmote", "blabber")
            end
        end
    end
end

-- Getters / Setters

function Sexbound.Actor.SexTalk:getPosition()
    return self:getParent():getPosition()
end

function Sexbound.Actor.SexTalk:dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. self:dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

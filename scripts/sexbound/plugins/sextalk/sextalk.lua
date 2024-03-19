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
        _dialogPool = {},
        _lastMessage = 0,
        _isActive = true
    }, Sexbound.Actor.SexTalk_mt)

    _self:init(parent, _self._logPrefix, function() end)

    _self._dialog = _self:loadDialog()

    return _self
end

function Sexbound.Actor.SexTalk:onMessage(message)
    if "Sexbound:Positions:SwitchPosition" == message:getType() then
        self:handleSwitchPosition()
    end
    if "Sexbound:SwitchRoles" == message:getType() then
        self:handleSwitchRoles()
    end
end

--- [Helper] Handles when this actor switches its position
function Sexbound.Actor.SexTalk:handleSwitchPosition()
    self._dialog = self:loadDialog()

    local stateName = self:getParent():getParent():getStateMachine():stateDesc()
end

--- [Helper] Handles when this actor switches its role
function Sexbound.Actor.SexTalk:handleSwitchRoles()
    -- Nothing
end

function Sexbound.Actor.SexTalk:onEnterClimaxState()
    self:processIsActive("climaxState")
end

function Sexbound.Actor.SexTalk:onEnterExitState()
    self:processIsActive("exitState")
end

function Sexbound.Actor.SexTalk:onEnterIdleState()
    self:processIsActive("idleState")
end

function Sexbound.Actor.SexTalk:onEnterSexState()
    self:processIsActive("sexState")
end

function Sexbound.Actor.SexTalk:onUpdateAnyState(dt)
    if not self._isActive then
        return
    end

    if self:getParent()._isTalking then
        self:getParent():getMouth():applyPosition()
    end
end

function Sexbound.Actor.SexTalk:loadDialog()
    species = self:getParent():getSpecies()

    local filename = self:getPosition():getDialog(species, nil)

    if not filename and self._config.useDefaultDialog then
        filename = self:getPosition():getDialog("default", nil)
    end
    if not filename then
        return
    end

    filename = util.replaceTag(filename, "species", species or "default")

    -- Fetch dialog for currently selected language
    filename = util.replaceTag(filename, "langcode", self._parent._parent:getLanguageCode())

    local dialog

    if not pcall(function()
        dialog = root.assetJson(filename)
    end) then
        self:getLog():warn("Unable to load dialog file for species: " .. species)
        return
    end
    
    if type(dialog.base) == "string" then dialog = self:helper_fetchBase(dialog) end

    return dialog
end

function Sexbound.Actor.SexTalk:helper_fetchBase(source)
    local base
    if not pcall(function()
        base = root.assetJson(source.base)
    end) then
        self:getLog():warn("Unable to load base \""..tostring(source.base).."\" for dialog file.")
        return source
    end
    
    -- Recursively check deeper base layers
    if type(base.base) == "string" then base = self:helper_fetchBase(base) end
    
    local add = not not source.add
    if add then base = util:mergeTable(base, source) else base = self:helper_mergeTableOverrideText(base, source) end
    
    return base
end

function Sexbound.Actor.SexTalk:helper_mergeTableOverrideText(t1, t2)
  for k, v in pairs(t2) do
    if k ~= "text" and type(v) == "table" and type(t1[k]) == "table" then --Override "text" list instead of merging
      self:helper_mergeTableOverrideText(t1[k] or {}, v)
    else
      t1[k] = v
    end
  end
  return t1
end

function Sexbound.Actor.SexTalk:helper_mergeTableMergeTextNoStatus(t1, t2, isStatus)
  isStatus = not not isStatus
  for k, v in pairs(t2) do
    if k == "text" then --Merge "text" list
      util.appendLists(t1[k], v)
    elseif k == "status" and type(v) == "table" and type(t1[k]) == "table" then --For "status" block, switch to full replacement mode
      self:helper_mergeTableMergeTextNoStatus(t1[k] or {}, v, true)
    elseif not isStatus and type(v) == "table" and type(t1[k]) == "table" then
      self:helper_mergeTableMergeTextNoStatus(t1[k] or {}, v, isStatus)
    else
      t1[k] = v
    end
  end
  return t1
end

function Sexbound.Actor.SexTalk:helper_getPotentialTargets()
    local actor = self:getParent()
    local position = actor:getPosition()
    local actorNum = actor:getActorNumber()
    local actorRelation = position:getActorRelation()
    local interactionTypesList = position:getInteractionType()
    local actors = self._parent._parent:getActors()
    
    local potentialTargets = {}
    local interactionTypes = {}
    if actorRelation[actorNum] ~= 0 then
        -- Only add the one targeted by this actor if this actor actually targets anyone.
        table.insert(potentialTargets, actors[actorRelation[actorNum]] or actor)
        table.insert(interactionTypes, self:helper_interactionTypeToName(actor, actors[actorRelation[actorNum] or actor, interactionTypesList, false]))
    end
    
    for i,a in ipairs(actorRelation) do
        if i ~= actorNum then
            if a == actorNum then
                table.insert(potentialTargets, actors[i])
                table.insert(interactionTypes, self:helper_interactionTypeToName(actors[i], actor, interactionTypesList, true))
            end
        end
    end
    
    if #potentialTargets == 0 then
        -- This actor is neither interacting with nor interacted with by any other actor. Assume toy/solo action and self reference with interactionType
        potentialTargets = {actor}
        interactionTypes = {self:helper_interactionTypeToName(actor, actor, interactionTypesList, false)}
    end
    
    return potentialTargets, interactionTypes
end

function Sexbound.Actor.SexTalk:helper_interactionTypeToName(actor, otherActor, types, receiving)
    local t = receiving and types[otherActor:getActorNumber()] or types[actor:getActorNumber()]
    local res
    if t == "direct" then
        if (receiving and actor:hasVagina()) or (not receiving and otherActor:hasVagina()) then res = "vaginal" else res = "anal" end
    elseif t == "toy_dick" then
        if actor:hasVagina() then return "toy_in_vagina" else return "toy_in_ass" end
    elseif t == "toy_vagina" then
        return "toy_vagina"
    elseif t == "masturbate_M" then
        return "masturbate_penis"
    elseif t == "masturbate_F" then
        return "masturbate_vagina"
    elseif t == "oral" then
        res = "oral"
    elseif t == "cunnilingus" then
        if receiving then return "r_cunnilingus" end
        if actor:hasVagina() then return "cunnilingus_vagina" else return "cunnilingus_ass" end
    elseif t == "boobjob" then
        res = "boobjob"
    else return "default" end
    
    if receiving then res = "r_"..res end
    return res
end

function Sexbound.Actor.SexTalk:helper_getActorState(actor)
    local state = actor:getParent():getStateMachine():stateDesc()
    local status = actor:getStatus()
    
    if status:findStatus("preclimaxing") then return "preclimax"
    elseif status:findStatus("climaxing") then return "climaxing"
    elseif state == "postclimaxState" then return "postclimax"
    else return "sex" end
end

function Sexbound.Actor.SexTalk:helper_getActorStatuses(actor)
    local status = actor:getStatus()
    local list, lookup = {}, {}
    
    if status:findStatus("pregnant") then table.insert(list, "pregnant") lookup["pregnant"] = true end
    if status:findStatus("sexbound_arousal_heat") then table.insert(list, "heat") lookup["heat"] = true end
    if status:findStatus("sexbound_defeated") then table.insert(list, "defeated") lookup["defeated"] = true end
    if actor._config.identity.body.hasPenis then table.insert(list, "hasPenis") lookup["hasPenis"] = true end
    if actor._config.identity.body.hasVagina then table.insert(list, "hasVagina") lookup["hasVagina"] = true end
    
    return list, lookup
end

function Sexbound.Actor.SexTalk:processIsActive(stateName)
    self._isActive = self:thisActorIsAllowedToTalk(stateName)

    return self._isActive
end

function Sexbound.Actor.SexTalk:thisActorIsAllowedToTalk(stateName)
    local animState = self:getParent():getAnimationState(stateName)

    return animState:getAllowTalk(self:getParent():getActorNumber())
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

function Sexbound.Actor.SexTalk:sayRandom()
    if self._config.roleplayMode and self:onlyPlayers() then return end

    if not self._dialog or isEmpty(self._dialog) then
        return
    end
    
    local actor = self:getParent()
    local potentialTargets, interactionTypes = self:helper_getPotentialTargets()
    local target, interactionType, l = nil, nil, #potentialTargets
    if l < 1 then return end
    if l == 1 then
        target = potentialTargets[1]
        interactionType = interactionTypes[1]
    else
        local r = math.random(l)
        target = potentialTargets[r]
        interactionType = interactionTypes[r]
    end
    
    local targetSpecies = target:getSpecies()
    
    local dialogPool = {}
    local lastLevel = self._dialog.content or {}
    
    -- interaction type
    lastLevel = lastLevel[interactionType] or lastLevel["default"] or {}
    -- our state
    lastLevel = lastLevel[self:helper_getActorState(actor)] or {}
    -- partner state
    lastLevel = lastLevel[self:helper_getActorState(target)] or {}
    -- partner species
    local specificConfig = lastLevel[targetSpecies] or {}
    local defaultConfig = lastLevel["default"] or {}
    
    local finalConfig
    if not specificConfig.override then finalConfig = self:helper_mergeTableMergeTextNoStatus(defaultConfig, specificConfig) else finalConfig = specificConfig end
    
    dialogPool = finalConfig.text or {}
    
    local statuses, statusLookup = self:helper_getActorStatuses(actor)
    local otherStatuses, otherStatusLookup = self:helper_getActorStatuses(target)
    local statusModules = finalConfig.status or {}
    local otherStatusModules = finalConfig.otherStatus or {}
    local bothStatusModules = finalConfig.bothStatus or {}
    local bothStatusBlock = {}
    local finalModules = {}
    for _,s in ipairs(statuses) do
        -- Check for both matching
        if otherStatusLookup[s] and bothStatusModules[s] then
            table.insert(finalModules, bothStatusModules[s])
            if bothStatusModules[s].overrideSoloStatus then bothStatusBlock[s] = true end -- Mark as blocked for solo status modules
        end
        
        if statusModules[s] and not bothStatusBlock[s] then table.insert(finalModules, statusModules[s]) end
    end
    for _,s in ipairs(otherStatuses) do
        if otherStatusModules[s] and not bothStatusBlock[s] then table.insert(finalModules, otherStatusModules[s]) end
    end
    table.sort(finalModules, function(a,b) return (a.priority or 0) > (b.priority or 0) end)
    for _,m in ipairs(finalModules) do
        if m.override then dialogPool = m.text or {} else util.appendLists(dialogPool, m.text or {}) end
    end
    
    local dialog = util.randomChoice(dialogPool)

    if "string" and type(dialog) and dialog ~= "" then
        local emote = self:getParent():getPlugins("emote")
        local emoticon

        if self._config.enableEmoticons then
            emoticon = self:findEmoticon(dialog)
        end

        if object then
            object.say(dialog)
        end

        actor._isTalking = true

        self:getLog():debug("Actor "..actor:getActorNumber().." triggered dialogue")

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

function Sexbound.Actor.SexTalk:getManager()
    return self:getParent():getParent():getSextalk()
end

function Sexbound.Actor.SexTalk:onlyPlayers()
    local actors = self:getParent():getParent():getActors()
    for _,a in ipairs(actors) do
        if a:getEntityType() ~= "player" then return false end
    end
    return true
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

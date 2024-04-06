--- Sexbound.NPC Module.
-- @module Sexbound.NPC
require "/scripts/sexbound/override/common.lua"

Sexbound.NPC = Sexbound.Common:new()
Sexbound.NPC_mt = {
    __index = Sexbound.NPC
}

local SexboundErrorCounter = 0

--- Hook (init)
local Sexbound_Old_Init = init
function init()
    xpcall(function()
        Sexbound_Old_Init()
        self.sb_npc = Sexbound.NPC.new()
    end, sb.logError)
end

--- Hook (update)
local Sexbound_Old_Update = update
function update(dt)
    xpcall(function()
        Sexbound_Old_Update(dt)
    end, sb.logError)

    if SexboundErrorCounter < 5 then
        xpcall(function()
            self.sb_npc:update(dt)
        end, function(err)
            SexboundErrorCounter = SexboundErrorCounter + 1
            sb.logError(err)
        end)
    end
end

--- Hook (uninit)
local Sexbound_Old_Uninit = uninit
function uninit()
    xpcall(function()
        self.sb_npc:uninit()
        
        Sexbound_Old_Uninit()
    end, sb.logError)
end

--- Overloading of crewmember related functions to make sexbound storage data persistent, and make kids unrecruitable
local Sexbound_Old_PreservedStorage = preservedStorage
function preservedStorage()
    local data = Sexbound_Old_PreservedStorage()
    data.sexbound = storage.sexbound
    return data
end

local Sexbound_Old_RecruitableInteract = recruitable.interact
function recruitable.interact(sourceEntityId)
    if self.sb_npc and self.sb_npc._isKid then return nil end
    return Sexbound_Old_RecruitableInteract(sourceEntityId)
end

local Sexbound_Old_GetCurrentStatus = getCurrentStatus
function getCurrentStatus()
    local data = Sexbound_Old_GetCurrentStatus()
    data.properties = {
        motherUuid = status.statusProperty("motherUuid", nil),
        fatherUuid = status.statusProperty("fatherUuid", nil),
        motherName = status.statusProperty("motherName", nil),
        fatherName = status.statusProperty("fatherName", nil),
        sexbound_previous_storage = status.statusProperty("sexbound_previous_storage", {}),
        generationFertility = status.statusProperty("generationFertility", 1),
        fertilityPenalty = status.statusProperty("fertilityPenalty", 1),
        kid = status.statusProperty("kid", nil)
    }
    return data
end

local Sexbound_Old_SetCurrentStatus = setCurrentStatus
function setCurrentStatus(statusSummary, statEffectCategory)
    Sexbound_Old_SetCurrentStatus(statusSummary, statEffectCategory)
    for prop,val in pairs(statusSummary.properties or {}) do
        status.setStatusProperty(prop,val)
    end
end

function Sexbound.NPC.new()
    local self = setmetatable({
        _enableLoungeTimer = true,
        _isHavingBirthday  = false,
        _isHavingSex       = false,
        _loungeId          = nil,
        _loungeTimer       = 0,
        _mindControl       = { damageSourceKind = "sexbound_mind_control" },
        _states            = { "defaultState", "havingBirthdayState", "havingSexState" },
        _isClimaxing       = false,
        _isKid             = false,
        _kidTimer          = 0,
        _behaviorData      = {excludedNodes = {}}
    }, Sexbound.NPC_mt)

    self:init(self, "npc") -- init defined in common.lua
    self:initMessageHandlers()
    self:restorePreviousStorage()
    self:initSubmodules()
    
    if self._firstInit then
        local birthSubGender = config.getParameter("subGender", nil)
        if birthSubGender then
            if self:canLog("info") then sb.logInfo("[SxB | ENT] Applying birth gender to new npc #"..entity.id()..": "..tostring(birthSubGender)) end
            self._subGender:handleSxbSubGenderChange(birthSubGender) -- handle because that method respects gender requirements
        end
        if not storage.sexbound.identity.sxbSubGender and math.random() <= (self._config.sex.subGenderChance or 0.01) then
            if self:canLog("info") then sb.logInfo("[SxB | ENT] Applying random gender to new npc #"..entity.id()) end
            self._subGender:setSxbSubGender(self._subGender:createRandomSubGender(npc.gender()))
        end
    end

    -- ensure this entity has a unique Id
    if not entity.uniqueId() then
        npc.setUniqueId(sb.makeUuid())
    end

    self:restore(true)
    self._stateMachine = self:loadStateMachine()
    
    self._hasInited = true
    self:updateTraitEffects()
    self:updateKidStatus()
    
    return self
end

function Sexbound.NPC:update(dt)
    -- Update the NPC's Statemachine
    self._stateMachine.update(dt)

    -- Always update arousal
    self:getArousal():update(dt)
    
    -- Tick kid status if active
    if self._kidTimer > 0 then self._kidTimer = self._kidTimer - dt end
    if self._isKid and self._kidTimer <= 0 then
        local worldTime = world.time()
        local kidTime = status.statusProperty('kid', -math.huge)
        if kidTime <= worldTime then self:updateKidStatus() end
        
        if self._isKid then self._kidTimer = 10 end -- Only check every 10 seconds
    end
    
    -- Progress time on temporarily excluded sexnodes for behavior script
    for c,d in pairs(self._behaviorData.excludedNodes) do
        d.time = (d.time or 0) - dt
        if d.time <= 0 then self._behaviorData.excludedNodes[c] = nil end
    end
end

function Sexbound.NPC:updateLoungeTimer(dt, callback)
    if not self._enableLoungeTimer then return end
    self._loungeTimer = self._loungeTimer + dt
    local arousal = self:getArousal()
    if self._loungeTimer >= self._loungeTimeout or (arousal:isResourceDefined() and arousal:getAmount() <= 0) then
        if self._isClimaxing then return end -- If sexnode currently is in the climaxing state, then the NPC may not leave prematurely.
        callback()
        self._loungeTimer = 0
    end
end

function Sexbound.NPC:initMessageHandlers()
    message.setHandler("Sexbound:Actor:HideName", function(_, _, args)
        return self:handleHideName(args)
    end)
    message.setHandler("Sexbound:Actor:ShowName", function(_, _, args)
        return self:handleShowName(args)
    end)
    message.setHandler("Sexbound:Actor:Respawn", function(_, _, args)
        return self:handleRespawn(args)
    end)
    message.setHandler("Sexbound:Actor:Restore", function(_, _, args)
        return self:handleRestore(args)
    end)
    message.setHandler("Sexbound:Actor:Say", function(_, _, args)
        return self:handleSay(args)
    end)
    message.setHandler("Sexbound:Config:Retrieve", function(_, _, args)
        return self:handleRetrieveConfig(args)
    end)
    message.setHandler("Sexbound:IdleState:Enter", function(_, _, args)
        return self:handleEnterIdleState(args)
    end)
    message.setHandler("Sexbound:SexState:Enter", function(_, _, args)
        return self:handleEnterSexState(args)
    end)
    message.setHandler("Sexbound:ClimaxState:Enter", function(_, _, args)
        self._isClimaxing = true
        return true
    end)
    message.setHandler("Sexbound:ClimaxState:Exit", function(_, _, args)
        self._isClimaxing = false
        return true
    end)
    message.setHandler("Sexbound:Storage:Retrieve", function(_, _, args)
        return self:handleRetrieveStorage(args)
    end)
    message.setHandler("Sexbound:Storage:Sync", function(_, _, args)
        return self:handleSyncStorage(args)
    end)
    message.setHandler("Sexbound:Pregnant:HazardAbortion", function(_, _, args)
        return self:hazardAbortion()
    end)
    message.setHandler("Sexbound:Common:UpdateFertility", function(_, _, args)
        self:updateFertility(args)
    end)
    
    --- Debug stuff
    message.setHandler("Sexbound:Debug:GetHitbox", function(_, _, args)
        sb.logInfo(self:dump(mcontroller.baseParameters()))
    end)
    message.setHandler("Sexbound:Debug:SetHitbox", function(_, _, args)
        mcontroller.controlParameters(args)
    end)
end

function Sexbound.NPC:initSubmodules()
    self._status = Sexbound.NPC.Status:new(self)
    self._subGender = Sexbound.NPC.SubGender:new(self)
    self._apparel = Sexbound.NPC.Apparel:new(self)
    self._arousal = Sexbound.NPC.Arousal:new(self)
    self._climax = Sexbound.NPC.Climax:new(self)
    self._pregnant = Sexbound.NPC.Pregnant:new(self)
    self._statistics = Sexbound.NPC.Statistics:new(self)
    self._transform = Sexbound.NPC.Transform:new(self)
    self._identity = Sexbound.NPC.Identity:new(self)
end

function Sexbound.NPC:updateKidStatus()
    local worldTime = world.time()
    local kidTime = status.statusProperty('kid', -math.huge)
    
    if kidTime <= worldTime then
        status.removeEphemeralEffect('sexbound_kid')
        status.setStatusProperty('kid', nil)
        self._isKid = false
    else
        status.addEphemeralEffect('sexbound_kid', math.huge)
        self._isKid = true
    end
end

function Sexbound.NPC:handleEnterIdleState(args)
    self:getArousal():setRegenRate("default")
    self:getClimax():setRegenRate("default")
end

function Sexbound.NPC:handleEnterSexState(args)
    self:getArousal():setRegenRate("havingSex")
    self:getClimax():setRegenRate("havingSex")
end

function Sexbound.NPC:handleRestore(args)
    if args then self:mergeStorage(args) end
    self:restore()
end

function Sexbound.NPC:handleRetrieveConfig(args)
    return config.getParameter("sexboundConfig")
end

function Sexbound.NPC:handleSay(args)
    npc.say(args.message);
end

function Sexbound.NPC:handleHideName(args)
    self:hideName()
    return true
end

function Sexbound.NPC:handleShowName(args)
    self:showName()
    return true
end

function Sexbound.NPC:handleRetrieveStorage(args)
    if args and args.name then
        return storage[args.name]
    end

    return storage
end

function Sexbound.NPC:handleSyncStorage(args)
    if self._idKid then return end
    
    args = self:fixPregnancyData(args)
    self:mergeStorage(args)
end

function Sexbound.NPC:fixPregnancyData(data)
    if type(data.sexbound.pregnant) ~= "table" then data.sexbound.pregnant = {} end
    if isEmpty(data.sexbound.pregnant) then return data end

    local filteredData = {}
    local count = 0
    for k, v in pairs(data.sexbound.pregnant) do
        count = count + 1
        table.insert(filteredData, count, v)
    end

    data.sexbound.pregnant = filteredData
    return data
end

function Sexbound.NPC:handleInteract(args, callback)
    callback(args)
end

-- [Helper] Loads the stateMachine
-- See state definitions at the bottom of the script
function Sexbound.NPC:loadStateMachine()
    self._stateDefinitions = {
        defaultState = self:defineStateDefaultState(),
        havingBirthdayState = self:defineStateHavingBirthdayState(),
        havingSexState = self:defineStateHavingSexState()
    }

    return stateMachine.create(self._states, self._stateDefinitions)
end

function Sexbound.NPC:mergeStorage(newData)
    storage = util.mergeTable(storage, newData or {})
end

function Sexbound.NPC:refreshLoungeTimeout()
    self._loungeTimeout = util.randomInRange({300, 600})
    return self._loungeTimeout
end

function Sexbound.NPC:removeAllStunningStatusEffects()
    status.removeEphemeralEffect("sexbound_stun")
    status.setResource("stunned", 0)
    status.setStatusProperty("sexbound_stun", false)
end

function Sexbound.NPC:removeWeaponsWhenShouldHaveEmptyHands()
    if config.getParameter("behaviorConfig", {}).emptyHands then
        npc.setItemSlot("primary", "")
        npc.setItemSlot("alt", "")
    end
end

-- Called via handleRestore
function Sexbound.NPC:restore(skipArousal)
    skipArousal = skipArousal or false
    self._isHavingSex = false
    npc.setInteractive(true)
    if not skipArousal then self:getArousal():instaMin() end
    self:restoreDamageTeam()
    storage.sexbound = storage.sexbound or {}
    self:getClimax():setCurrentValue(storage.sexbound.climax or 0)
    status.removeEphemeralEffect("sexbound_sex")
    status.removeEphemeralEffect("sexbound_invisible")
    self:removeAllStunningStatusEffects()
    self:removeWeaponsWhenShouldHaveEmptyHands()
end

function Sexbound.NPC:setup(entityId, params)
    if self._isKid then npc.resetLounging() return false end
    
    if not entityId then return end
    params = params or {}
    self._isHavingSex = true

    promises:add(world.sendEntityMessage(
        entityId,
        "Sexbound:Retrieve:ControllerId"
    ), function(controllerId)
        self:unload()
        storage.sexbound.climax = self:getClimax():getCurrentValue()
        storage.sexbound.fertility = 1.0
        promises:add(world.sendEntityMessage(
            controllerId,
            "Sexbound:Actor:Setup",
            util.mergeTable(self:getActorData(), params)
        ), function(isHavingSex)
            self._isHavingSex = isHavingSex or false
        end)
    end)
    return true
end

function Sexbound.NPC:hideName()
    npc.setDisplayNametag(false)
end

function Sexbound.NPC:showName()
    npc.setDisplayNametag(true)
end

function Sexbound.NPC:restoreDamageTeam()
    if storage.previousDamageTeam then
        npc.setDamageTeam(storage.previousDamageTeam)
    end
end

function Sexbound.NPC:storePreviousDamageTeam()
    storage.previousDamageTeam = storage.previousDamageTeam or world.entityDamageTeam(entity.id())
end

function Sexbound.NPC:unload()
    local defaultDuration = 300 -- 5 minutes
    self._isHavingSex = true
    self:storePreviousDamageTeam()
    npc.setDamageTeam({ type = "ghostly" })
    npc.setInteractive(false)
    local entityId = entity.id()
    world.sendEntityMessage(entityId, "applyStatusEffect", "sexbound_invisible", defaultDuration, entityId)
    world.sendEntityMessage(entityId, "applyStatusEffect", "sexbound_stun", defaultDuration, entityId)
end

-- Getters/Setters

function Sexbound.NPC:getActorData()
    if self._isKid then npc.resetLounging() return nil end
    
    local gender = npc.gender()

    local identity = self:getIdentity():build()
    if identity.sxbSubGender == nil then
        identity.sxbSubGender = self:getSubGender():getSxbSubGender()
    end

    return {
        entityId = entity.id(),
        forceRole = math.floor(status.stat("forceRole")),
        uniqueId = entity.uniqueId(),
        level = npc.level(),
        entityType = "npc",
        identity = identity,
        backwear = self:getApparel():prepareBackwear(gender),
        chestwear = self:getApparel():prepareChestwear(gender),
        groinwear = self:getApparel():prepareGroinwear(gender),
        headwear = self:getApparel():prepareHeadwear(gender),
        legswear = self:getApparel():prepareLegswear(gender),
        nippleswear = self:getApparel():prepareNippleswear(gender),
        type = npc.npcType(),
        seed = npc.seed(),
        storage = storage,
        generationFertility = status.statusProperty("generationFertility", 1.0),
        fertilityPenalty = status.statusProperty("fertilityPenalty", 1.0)
    }
end

function Sexbound.NPC:getIsHavingSex()
    return self._isHavingSex
end
function Sexbound.NPC:getIsClimaxing()
    return self._isClimaxing
end
function Sexbound.NPC:getMindControl()
    return self._mindControl
end
function Sexbound.NPC:getApparel()
    return self._apparel
end
function Sexbound.NPC:getArousal()
    return self._arousal
end
function Sexbound.NPC:getClimax()
    return self._climax
end
function Sexbound.NPC:getIdentity()
    return self._identity
end
function Sexbound.NPC:getPregnant()
    return self._pregnant
end
function Sexbound.NPC:getSubGender()
    return self._subGender
end
function Sexbound.NPC:getStatistics()
    return self._statistics
end
function Sexbound.NPC:getTransform()
    return self._transform
end

-- Legacy functions

function Sexbound.NPC:handleRespawn(args)
    return self:handleRestore(args)
end

--- State Definitions

-- State Definition : defaultState
function Sexbound.NPC:defineStateDefaultState()
    return {
        enter = function()
            if not self._isHavingSex and not self._isHavingBirthday then
                return {}
            end
        end,

        enteringState = function(stateData)
            -- Toggle regen rates to be 'default'
            self:getArousal():setRegenRate("default")

            self:getClimax():setRegenRate("default")
        end,

        update = function(dt, stateData)
            if status.statusProperty("sexbound_birthday") ~= "default" then
                self._isHavingBirthday = true
            end

            if not self._isKid and npc.isLounging() and status.statusProperty("sexbound_sex") == true then
                self._isHavingSex = true
            end

            -- Exit condition #1
            if self._isHavingSex or self._isHavingBirthday then
                return true
            end

            -- Otherwise update climax
            self:getClimax():update(dt)
        end,

        leavingState = function(stateData)
            self._loungeTimer = 0
        end
    }
end

-- State Definition : havingBirthdayState
function Sexbound.NPC:defineStateHavingBirthdayState()
    return {
        enter = function()
            if self._isHavingBirthday then
                return {
                    birthData = status.statusProperty("sexbound_birthday")
                }
            end
        end,

        enteringState = function(stateData)
            storage.sexbound = storage.sexbound or {}
            storage.sexbound.birthData = stateData.birthData

            if (notify) then
                notify({
                    type = "sexbound.birthday",
                    sourceId = entity.id()
                })
            end
        end,

        update = function(dt, stateData)
            self._isHavingBirthday = false

            return true
        end,

        leavingState = function(stateData)
            status.setStatusProperty("sexbound_birthday", "default")
        end
    }
end

-- State Definition : havingSexState
function Sexbound.NPC:defineStateHavingSexState()
    return {
        enter = function()
            if not self._idKid and self._isHavingSex then
                return {
                    isLounging = npc.isLounging(),
                    loungeId = npc.loungingIn()
                }
            end
        end,

        enteringState = function(stateData)
            self:getArousal():setRegenRate("havingSex")
            self:getClimax():setRegenRate("havingSex")

            if stateData.isLounging then
                self._loungeId = stateData.loungeId
                self:setup(self._loungeId)
                self._loungeTimer = 0
                self:refreshLoungeTimeout()
                npc.setInteractive(false)
            end
        end,

        update = function(dt, stateData)
            if stateData.isLounging and status.statusProperty("sexbound_sex") ~= true then
                self._isHavingSex = false
            end

            if npc.isLounging() then
                self:updateLoungeTimer(dt, function()
                    self:getArousal():instaMin()
                    self._isHavingSex = false
                end)
            end

            -- Exit condition #1
            if not self._isHavingSex then
                return true
            end

            self:getApparel():update(self._loungeId, npc.gender())
        end,

        leavingState = function(stateData)
            npc.setInteractive(true)
            local controllerId = self._controllerId or self._loungeId
            if controllerId then
                world.sendEntityMessage(controllerId, "Sexbound:Actor:Remove", entity.id())
            end
            self._loungeId = nil
            self._controllerId = nil
            self:restore()
        end
    }
end

function Sexbound.NPC:getGender()
    return npc.gender()
end

function Sexbound.NPC:getSpecies()
    return npc.species()
end

function Sexbound.NPC:getCompatibilityData()
    return {
        species = npc.species(),
        speciesType = self._speciesType,
        gender = npc.gender(),
        bodyTraits = self._bodyTraits,
        motherUuid = status.statusProperty("motherUuid", nil),
        fatherUuid = status.statusProperty("fatherUuid", nil),
        uuid = entity.uniqueId
    }
end

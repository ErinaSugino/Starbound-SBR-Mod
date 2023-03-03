--- Sexbound.Player Module.
-- @module Sexbound.Player
require "/scripts/sexbound/override/common.lua"

Sexbound.Player = Sexbound.Common:new()
Sexbound.Player_mt = {
    __index = Sexbound.Player
}

local SexboundErrorCounter = 0

--- Override Hook (init)
local Sexbound_Old_Init = init
function init()
    xpcall(function()
        Sexbound_Old_Init()

        self.sb_player = Sexbound.Player.new()
    end, sb.logError)
end

--- Override Hook (update)
local Sexbound_Old_Update = update
function update(dt)
    xpcall(function()
        Sexbound_Old_Update(dt)
    end, sb.logError)

    if SexboundErrorCounter < 5 then
        xpcall(function()
            self.sb_player:update(dt)
        end, function(err)
            SexboundErrorCounter = SexboundErrorCounter + 1

            sb.logError(err)
        end)
    end
end

--- Override Hook (uninit)
local Sexbound_Old_Uninit = uninit
function uninit()
    xpcall(function()
        self.sb_player:uninit()
        
        Sexbound_Old_Uninit()
    end, sb.logError)
end

function Sexbound.Player.new()
    local self = setmetatable({
        _controllerId = nil,
        _isHavingSex = false,
        _startItemsList = {"sexbound1-codex", "sexboundcustomizer"},
        _loungeId = nil,
        _states = {"defaultState", "havingSexState"},
        _isSterilized = false
    }, Sexbound.Player_mt)

    self:init(self, "player")

    -- Init. the sexboundConfig in the storage
    storage.sexboundConfig = storage.sexboundConfig or {
        hasGivenStartItems = false
    }

    self._legal = Sexbound.Player.Legal:new(self)
    self._legal:verify()

    self._identity = Sexbound.Player.Identity:new(self)

    self:initMessageHandlers()

    -- Remove Sexbound specific status effects when the player begins the game
    status.setStatusProperty("sexbound_sex", false)
    status.setStatusProperty("sexbound_abortion", false)
    status.removeEphemeralEffect("sexbound_invisible")
    status.removeEphemeralEffect("sexbound_birthing")

    -- Instantiate player override classes manually; Need to change to be dynamic
    self._status = Sexbound.Player.Status:new(self)
    self._subGender = Sexbound.Player.SubGender:new(self)
    self._apparel = Sexbound.Player.Apparel:new(self)
    self._arousal = Sexbound.Player.Arousal:new(self)
    self._climax = Sexbound.Player.Climax:new(self)
    self._pregnant = Sexbound.Player.Pregnant:new(self)
    self._statistics = Sexbound.Player.Statistics:new(self)
    self._transform = Sexbound.Player.Transform:new(self)

    -- Restore the Previous Storage
    self:restorePreviousStorage()

    -- Do not check if false because current players won't have this property set
    if not storage.sexboundConfig.hasGivenStartItems then
        storage.sexboundConfig.hasGivenStartItems = self:giveStartItems()
    end
    
    -- Add event handler to first time pregnancy event
    self._statistics:addEventHandler("pregnancyCount", function() player.giveItem("sexbound_pregnancy-codex") end, true)

    -- Set Universe Flags
    player.setUniverseFlag("sexbound_installed")

    -- Load StateMachine
    self._stateMachine = self:helper_loadStateMachine()
    
    self._isSterilized = self._status:hasStatus("sterilized")
    
    self._hasInited = true
    self:updateTraitEffects()
    
    if self:canLog("debug") then
        sb.logInfo("Player #"..entity.id().." has innate status list:")
        sb.logInfo(self:dump(self._status:getStatusList()))
        sb.logInfo(self:dump(storage.sexbound.identity.sxbNaturalStatus))
    end
    
    -- Setup event listeners to notify player about changes to the sterilization status
    self._status:addEventListener("add", function(data) self:notifySterilizationChange(data) end)
    self._status:addEventListener("remove", function(data) self:notifySterilizationChange(data) end)

    return self
end

-- [Helper] Loads the stateMachine
-- See state definitions at the bottom of the script
function Sexbound.Player:helper_loadStateMachine()
    self._stateDefinitions = {
        defaultState = self:defineStateDefaultState(),
        havingSexState = self:defineStateHavingSexState()
    }

    return stateMachine.create(self._states, self._stateDefinitions)
end

--- Updates the Player
-- @param dt
function Sexbound.Player:update(dt)
    -- Update the legal verification system
    self._legal:update(dt)

    -- Update the Player's Statemachine
    self._stateMachine.update(dt)

    -- Only the Player needs to update pregnancy via script. NPCs and Monsters update via AI.
    self._pregnant:update(dt)
end

function Sexbound.Player:handleEnterClimaxState(args)
    return
end

function Sexbound.Player:handleEnterIdleState(args)
    -- Nothing
end

function Sexbound.Player:handleEnterSexState(args)
    -- Nothing
end

function Sexbound.Player:handleLounge(args)
    self._loungeId = args.loungeId

    -- Lounge the player in the object's first anchor
    player.lounge(self._loungeId, 0)
end

function Sexbound.Player:giveStartItems()
    -- Attempt to cycle through and give the player one of each start item
    for _, _item in ipairs(self._startItemsList) do
        if not player.hasItem(_item) then
            player.giveItem(_item)
        end
    end

    -- Check that the player actually received all of the start items
    for _, _item in ipairs(self._startItemsList) do
        if not player.hasItem(_item) then
            return false
        end
    end

    return true
end

function Sexbound.Player:handleShowCustomizerUI(args)
    return self:showCustomizerUI(args)
end

function Sexbound.Player:showCustomizerUI(args)
    -- Check if player.interact is a function because some previous version of starbound did not implement it
    if "function" ~= type(player.interact) then return end
    xpcall(function()
        local _loadedConfig = root.assetJson("/interface/sexbound/customizer/customizer.config")
        _loadedConfig.config.statistics = self:getStatistics():getStatistics()
        _loadedConfig.config.currentGender = self._subGender._currentGender
        _loadedConfig.config.subGenders = self._subGender:getAllSubGenders()
        _loadedConfig.config.sterilized = self._status:hasStatus("sterilized")
        player.interact("ScriptPane", _loadedConfig, player.id())
    end, function(err)
        sb.logError("Unable to load Sexbound Customizer UI config.")
        sb.logError(err)
    end)
end

function Sexbound.Player:handleDismissUI(args)
    return not status.statusProperty("sexbound_sex")
end

function Sexbound.Player:handleShowUI(args)
    return self:showUI(args.config)
end

function Sexbound.Player:showUI(config)
    -- Check if player.interact is a function because some previous version of starbound did not implement it
    if "function" ~= type(player.interact) then return end
    local uiSettings = storage.sexbound or {}
    uiSettings = uiSettings.uiLayers or {}
    config.config.layersEnabled = uiSettings
    player.interact("ScriptPane", config, config.config.controllerId or player.id())
end

function Sexbound.Player:handleRestore(args)
    if args then
        self:mergeStorage(args)
    end

    self:restore()
end

function Sexbound.Player:restore()
    self._isHavingSex = false

    if storage and storage.sexbound then
        self:getClimax():setCurrentValue(storage.sexbound.climax)
    end

    -- Remove specific Sexbound status effects and unstun the player
    status.removeEphemeralEffect("sexbound_sex")
    status.removeEphemeralEffect("sexbound_invisible")
    status.removeEphemeralEffect("sexbound_stun")
    status.setStatusProperty("sexbound_stun", false)
end

function Sexbound.Player:handleRetrieveConfig(args)
    return nil
end

function Sexbound.Player:handleRetrieveStorage(args)
    if args and args.name then
        return storage[args.name]
    end

    return storage
end

function Sexbound.Player:notifySterilizationChange(data)
    if data.name ~= "sterilized" then return end
    
    local notifications = self:getNotifications() or {}
    notifications = notifications.events or {}
    notifications = notifications.sterilize or {}
    
    local sterilized = data.query == "add"
    sterilized = tostring(sterilized)
    
    local text = notifications[sterilized]
    if text then
        world.sendEntityMessage(entity.id(), "queueRadioMessage", {
            messageId = "sexbound_sterilization",
            unique = false,
            text = text
        })
    end
    
    self._isSterilized = sterilized
    if sterilized then status.removeEphemeralEffect("sexbound_custom_ovulating") end -- Remove ovulation cycle effect when sterilized
end

function Sexbound.Player:handleSyncStorage(newData)
    newData = self:fixPregnancyData(newData)
    storage = util.mergeTable(storage, newData or {})
end

function Sexbound.Player:handleSyncSettings(newSettings)
    storage.sexbound = storage.sexbound or {}
    storage.sexbound.uiLayers = newSettings
end

function Sexbound.Player:fixPregnancyData(data)
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

function Sexbound.Player:initMessageHandlers()
    message.setHandler("Sexbound:Actor:Restore", function(_, _, args)
        return self:handleRestore(args)
    end)
    message.setHandler("Sexbound:Actor:Respawn", function(_, _, args)
        return self:handleRespawn(args)
    end)
    message.setHandler("Sexbound:Config:Retrieve", function(_, _, args)
        return self:handleRetrieveConfig(args)
    end)
    message.setHandler("Sexbound:ClimaxState:Enter", function(_, _, args)
        return self:handleEnterClimaxState(args)
    end)
    message.setHandler("Sexbound:CustomizerUI:Show", function(_, _, args)
        return self:handleShowCustomizerUI(args)
    end)
    message.setHandler("Sexbound:Reward:Currency", function(_, _, args)
        return self:handleRewardCurrency(args)
    end)
    message.setHandler("Sexbound:IdleState:Enter", function(_, _, args)
        return self:handleEnterIdleState(args)
    end)
    message.setHandler("Sexbound:Node:Lounge", function(_, _, args)
        return self:handleLounge(args)
    end)
    message.setHandler("Sexbound:SexState:Enter", function(_, _, args)
        return self:handleEnterSexState(args)
    end)
    message.setHandler("Sexbound:Storage:Retrieve", function(_, _, args)
        return self:handleRetrieveStorage(args)
    end)
    message.setHandler("Sexbound:Storage:Sync", function(_, _, args)
        return self:handleSyncStorage(args)
    end)
    message.setHandler("Sexbound:UI:Dismiss", function(_, _, args)
        return self:handleDismissUI(args)
    end)
    message.setHandler("Sexbound:UI:Show", function(_, _, args)
        return self:handleShowUI(args)
    end)
    message.setHandler("Sexbound:UI:SyncSettings", function(_, _, args)
        return self:handleSyncSettings(args)
    end)
    message.setHandler("Sexbound:Pregnant:HazardAbortion", function(_, _, args)
        return self:hazardAbortion()
    end)
    message.setHandler("Sexbound:Common:StartSexMusic", function(_, _, args)
        return self:startSexMusic()
    end)
    message.setHandler("Sexbound:Common:StopSexMusic", function(_, _, args)
        return self:stopSexMusic()
    end)
    
    --- Simply try to forward fertility status updates to sexbound actor
    message.setHandler("Sexbound:Pregnant:AddStatus", function(_, _, args)
        local statusName = args
        if self._controllerId then world.sendEntityMessage(self._controllerId, "Sexbound:Pregnant:AddStatus", {id = entity.id(), effect = statusName}) end
        
        if statusName == "sexbound_custom_hyper_fertility" then
            -- If hyper fertility pill, also set ovulation timer to 10 seconds. Yes, this pill is *that* powerful.
            if status.statusProperty("sexbound_custom_ovulating", false) then
                -- effect currently active - refresh instead of messing up the cycle timer
                status.addEphemeralEffect("sexbound_custom_ovulating")
            else
                storage.sexbound = storage.sexbound or {}
                storage.sexbound.ovulationCycle = 10
            end
        end
    end)
    message.setHandler("Sexbound:Pregnant:RemoveStatus", function(_, _, args)
        local statusName = args
        if self._controllerId then world.sendEntityMessage(self._controllerId, "Sexbound:Pregnant:RemoveStatus", {id = entity.id(), effect = statusName}) end
    end)
    message.setHandler("Sexbound:Item:Give", function(_, _, args)
        player.giveItem(args)
    end)
    message.setHandler("Sexbound:Climax:Feed", function(_, _, args)
        if status.isResource("food") then status.giveResource("food", 0.1) end
    end)
    
    --- Debug purposes
    message.setHandler("Sexbound:Debug:ResetStats", function(_, _, args)
        return self:debugResetStats()
    end)
    message.setHandler("Sexbound:Debug:TriggerBirthing", function(_, _, args)
        return self:debugBirthing()
    end)
    message.setHandler("Sexbound:Debug:EndBirthing", function(_, _, args)
        return self:debugEndBirthing()
    end)
    message.setHandler("Sexbound:Debug:ShowPregnancyDialog", function(_, _, args)
        local baby = storage.sexbound.pregnant[1]
        if baby == nil then sb.logWarn("Player is not pregnant") return end
        self._pregnant:triggerActualPregnancy(baby)
    end)
    message.setHandler("Sexbound:Debug:Shrink", function(_, _, args)
        status.addEphemeralEffect("sexbound_test")
    end)
end

function Sexbound.Player:mergeStorage(newData)
    storage = util.mergeTable(storage, newData or {})
end

--- Setup the Player's actor data and send it to the lounge entity.
-- @param controllerId
function Sexbound.Player:setup(controllerId, params)
    self._isHavingSex = true

    if controllerId then
        local actorData = util.mergeTable(self:getActorData(), params or {})

        promises:add(world.sendEntityMessage(controllerId, "Sexbound:Actor:Setup", actorData), function(result)
            self._isHavingSex = result or false

            -- Handle the case that the Player has a quest to have sex
            world.sendEntityMessage(player.id(), "Sexbound:Quest:HaveSex")
        end)

        if self:canLog("debug") then sb.logInfo("Player "..entity.id().." generated actor data for controller "..tostring(self._controllerId)) end

        return true
    end

    return false
end

-- Getters / Setters

function Sexbound.Player:getActorData()
    local gender = player.gender()
    if self:canLog("debug") then sb.logInfo("Generating player actor "..player.id()) end

    storage.sexbound.climax = self:getClimax():getCurrentValue()

    local identity = self:getIdentity():build()
    identity.sxbSubGender = self:getSubGender():getSxbSubGender()

    return {
        entityId = player.id(),
        forceRole = math.floor(status.stat("forceRole")),
        uniqueId = player.uniqueId(),
        entityType = "player",
        identity = identity,
        backwear = self:getApparel():prepareBackwear(gender),
        chestwear = self:getApparel():prepareChestwear(gender),
        groinwear = self:getApparel():prepareGroinwear(gender),
        headwear = self:getApparel():prepareHeadwear(gender),
        legswear = self:getApparel():prepareLegswear(gender),
        nippleswear = self:getApparel():prepareNippleswear(gender),
        storage = storage,
        isFertile = status.statusProperty("sexbound_custom_fertility", false),
        isHyperFertile = status.statusProperty("sexbound_custom_hyper_fertility", false),
        isOvulating = status.statusProperty("sexbound_custom_ovulating", false),
        isDefeated = self.sexboundDefeat and self.sexboundDefeat:isDefeated()
    }
end

-- Getters/Setters

function Sexbound.Player:getApparel()
    return self._apparel
end
function Sexbound.Player:getArousal()
    return self._arousal
end
function Sexbound.Player:getClimax()
    return self._climax
end
function Sexbound.Player:getControllerId()
    return self._controllerId
end
function Sexbound.Player:getSubGender()
    return self._subGender
end
function Sexbound.Player:getIdentity()
    return self._identity
end
function Sexbound.Player:getLegal()
    return self._legal
end
function Sexbound.Player:getPregnant()
    return self._pregnant
end
function Sexbound.Player:getStatistics()
    return self._statistics
end
function Sexbound.Player:getTransform()
    return self._transform
end
function Sexbound.Player:getStatus()
    return self._status
end

--- Legacy functions

function Sexbound.Player:handleRespawn(args)
    if args then
        self:mergeStorage(args)
    end

    self:respawn()
end

function Sexbound.Player:handleRewardCurrency(args)
    player.addCurrency(args.currencyName, args.amount)
end

function Sexbound.Player:respawn()
    self:restore()
end

--- State Definitions

-- State Definition : defaultState
function Sexbound.Player:defineStateDefaultState()
    return {
        enter = function()
            if not self._isHavingSex then
                return {}
            end
        end,

        enteringState = function(stateData)
            self:getArousal():setRegenRate("default")
            self:getClimax():setRegenRate("default")
        end,

        update = function(dt, stateData)
            if player.isLounging() and status.statusProperty("sexbound_sex") == true then
                self._isHavingSex = true
            end

            -- Exit condition #1
            if self._isHavingSex then
                return true
            end

            self:getClimax():update(dt)
            self:getApparel():update(self._controllerId or self._loungeId, player.gender())
        end
    }
end

-- State Definition : havingSexState
function Sexbound.Player:defineStateHavingSexState()
    return {
        enter = function()
            if self._isHavingSex then
                return {
                    isLounging = player.isLounging(),
                    loungeId = player.loungingIn()
                }
            end
        end,

        enteringState = function(stateData)
            self:getArousal():setRegenRate("havingSex")
            self:getClimax():setRegenRate("havingSex")

            if player.isLounging() then
                self._loungeId = stateData.loungeId

                promises:add(world.sendEntityMessage(self._loungeId, "Sexbound:Retrieve:ControllerId"),
                    function(controllerId)
                        self._controllerId = controllerId

                        self:setup(self._controllerId)
                    end, function() -- Failed
                        self._isHavingSex = false
                    end)
            end
        end,

        update = function(dt, stateData)
            -- When isLounging is true then the player is probably lounging in a sexnode
            if stateData.isLounging and status.statusProperty("sexbound_sex") ~= true then
                self._isHavingSex = false
            end

            -- Exit condition #1
            if not self._isHavingSex then
                return true
            end

            -- Update the worn apparel
            self:getApparel():update(self._controllerId or self._loungeId, player.gender())
        end,

        leavingState = function(stateData)
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

function Sexbound.Player:debugResetStats()
    storage.sexbound.statistics = {}
end

function Sexbound.Player:debugBirthing()
    local oldCanTransform = self._transform._canTransform
    self._transform:setCanTransform(true)
    if self._transform:handleTransform({
        responseRequired = false,
        sexboundConfig = {position = {sex = {"birthing"}, force = 1}},
        timeout = 600,
        spawnOptions = {
            noEffect = true
        }
    }) then
        status.addEphemeralEffect("sexbound_invisible", 600)
        sb.logInfo("Player birthing transform request succeeded - controllerId = "..tostring(self._transform._controllerId))
    else sb.logInfo("Player birthing transform request failed") end
    status.addEphemeralEffect("sexbound_birthing", 600)
    self._transform:setCanTransform(oldCanTransform)
end

function Sexbound.Player:debugEndBirthing()
    status.removeEphemeralEffect("sexbound_birthing")
    status.removeEphemeralEffect("sexbound_invisible")
    self._transform:smashSexNode()
end

function Sexbound.Player:startSexMusic()
    local config = self:getConfig().sex
    if not config.useSexMusic then return end
    --local songList = config.sexMusicPool or {}
    --local song = util.randomChoice(songList)
    --world.sendEntityMessage(player.id(), "playAltMusic", {song}, 1)
    local controllerId = self._controllerId or self._loungeId
    if controllerId then world.sendEntityMessage(controllerId, "Sexbound:Common:StartSexMusic", entity.id()) end
end

function Sexbound.Player:stopSexMusic(number)
    local config = self:getConfig().sex
    if not config.useSexMusic then return end
    --world.sendEntityMessage(player.id(), "playAltMusic", {""}, 1) --Try to play a different, non existent song to reset progress of current song
    --world.sendEntityMessage(player.id(), "stopAltMusic", 1)
    local controllerId = self._controllerId or self._loungeId
    if controllerId then world.sendEntityMessage(controllerId, "Sexbound:Common:StopSexMusic", entity.id()) end
end

function Sexbound.Player:getGender()
    return player.gender()
end

function Sexbound.Player:getSpecies()
    return player.species()
end

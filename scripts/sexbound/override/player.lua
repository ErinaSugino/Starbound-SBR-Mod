require "/scripts/sexbound/override/common.lua"

--- Sexbound.Player Module.
--- @class Sexbound.Player: Sexbound.Common
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field private _startItemsList table<integer, {name: string}>
--- @field _isSterilized boolean
--- @field _isInfertile boolean
--- @field _legal Sexbound.Player.Legal
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

--- Override of core companion behavior to keep family relation status on crewmembers.
-- WARNING: Can cause issues with other mods changing the same function!
function recruitSpawner:respawnRecruit(uuid, recruit)
  self.followers[uuid] = nil
  self.shipCrew[uuid] = recruit

  recruit.uniqueId = nil
  local properties = recruit.status and recruit.status.properties or nil
  recruit.status = nil
  if properties then recruit.status = {properties = properties} end
  recruit.persistent = true
  recruit.storage = recruit.storage or {}
  recruit.storage.followingOwner = false
  recruit.storage.behaviorFollowing = false

  recruit:spawn()
end

--- Creates new player entity manager instance
--- @return Sexbound.Player # The newly created player entity manager instance
function Sexbound.Player.new()
    local self = setmetatable({
        _controllerId = nil,
        _isHavingSex = false,
        _startItemsList = {"sexbound1-codex", "sexboundcustomizer"},
        _loungeId = nil,
        _states = {"defaultState", "havingSexState"},
        _isSterilized = false,
        _isInfertile = false
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
    self._isInfertile = self._status:hasStatus("infertile")

    self._hasInited = true
    self:updateTraitEffects()

    if self:canLog("debug") then
        sb.logInfo("Player #"..entity.id().." has innate status list:")
        sb.logInfo(Sexbound.Util.dump(self._status:getStatusList()))
        sb.logInfo(Sexbound.Util.dump(storage.sexbound.identity.sxbNaturalStatus))
    end

    -- Setup event listeners to notify player about changes to the sterilization status
    self._status:addEventListener("add", function(data) self:notifySterilizationChange(data) end)
    self._status:addEventListener("remove", function(data) self:notifySterilizationChange(data) end)
    self._status:addEventListener("add", function(data) self:notifyInfertileChange(data) end)
    self._status:addEventListener("remove", function(data) self:notifyInfertileChange(data) end)

    return self
end

--- [Helper] Loads the stateMachine
--- @private
--- @return table # The vanilla state meachine
function Sexbound.Player:helper_loadStateMachine()
    self._stateDefinitions = {
        defaultState = self:defineStateDefaultState(),
        havingSexState = self:defineStateHavingSexState()
    }

    return stateMachine.create(self._states, self._stateDefinitions)
end

--- Function called each tick to update timers
--- @param dt number The delta time since last tick
function Sexbound.Player:update(dt)
    -- Update the legal verification system
    self._legal:update(dt)

    -- Update the Player's Statemachine
    self._stateMachine.update(dt);

    -- Only the Player needs to update pregnancy via script. NPCs and Monsters update via AI.
    (self._pregnant --[[@as Sexbound.Player.Pregnant]]):update(dt)

    -- Update the player's arousal module, as they, too, now can get horny
    self._arousal:update(dt)
end

--- Message handler for lounge command
--- @param args table Lounging data
function Sexbound.Player:handleLounge(args)
    self._loungeId = args.loungeId

    -- Lounge the player in the object's first anchor
    player.lounge(self._loungeId, 0)
end

--- Spawns Sexbound starting items
--- @return boolean # Whethere or not player received the items
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

--- Message handler for item triggering customizer UI open
function Sexbound.Player:handleShowCustomizerUI(_)
    self:showCustomizerUI()
end

--- Opens customizer UI script pane
function Sexbound.Player:showCustomizerUI()
    -- Check if player.interact is a function because some previous version of starbound did not implement it
    if "function" ~= type(player.interact) then return end
    xpcall(function()
        local _loadedConfig = root.assetJson("/interface/sexbound/customizer/customizer.config")
        player.interact("ScriptPane", _loadedConfig, player.id())
    end, function(err)
        sb.logError("Unable to load Sexbound Customizer UI config.")
        sb.logError(err)
    end)
end

--- Message handler for customizer UI getting entity data
--- @return table # Customizer data
function Sexbound.Player:handleGetCutomizerData(_)
    local _loadedConfig = {}
    _loadedConfig.statistics = self:getStatistics():getStatistics()
    _loadedConfig.currentGender = self._subGender._currentGender
    _loadedConfig.subGenders = self._subGender:getAllSubGenders()
    _loadedConfig.sterilized = self._status:hasStatus("sterilized")
    _loadedConfig.infertile = self._status:hasStatus("infertile")
    _loadedConfig.autoClimax = self._status:hasStatus("autoClimax")
    return _loadedConfig
end

--- Message handler for trying to close the Sex UI? Which only returns if the status is already gone?
--- @return boolean # Whethere or not the sex status effect is gone
function Sexbound.Player:handleDismissUI(_)
    return not status.statusProperty("sexbound_sex")
end

--- Message handler for sexnode actor opening Sex UI
--- @param args table UI config data
function Sexbound.Player:handleShowUI(args)
    self:showUI(args.config)
end

--- Opens the Sex UI
--- @param config table Sexnode-sided UI data
function Sexbound.Player:showUI(config)
    -- Check if player.interact is a function because some previous version of starbound did not implement it
    if "function" ~= type(player.interact) then return end
    local uiSettings = storage.sexbound or {}
    uiSettings = uiSettings.uiLayers or {}
    config.config.layersEnabled = uiSettings
    config.config.ownerId = player.id()
    player.interact("ScriptPane", config, config.config.controllerId or player.id())
end

--- Message handler for sexnode actor storage being restored
--- @param args table # The provided data
function Sexbound.Player:handleRestore(args)
    if args then
        self:mergeStorage(args)
    end

    self:restore()
end

--- Restore this monster entity
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

--- Message handler for sexnode actor requesting sexboundConfig data from this entity
--- @return any # Nothing for players
function Sexbound.Player:handleRetrieveConfig(_)
    return nil
end

--- Message handler for sexnode actor requesting entity's persistent storage data
--- @param args table? Potentially provided arguments for retrieving a specific name from storage
--- @return any # Whatever the requested storage parameter is, if it exists, or the entire storage
function Sexbound.Player:handleRetrieveStorage(args)
    if args and args.name then
        return storage[args.name]
    end

    return storage
end

--- Creates and send a notification message about sterilization state change
--- @param data table The status effect change message
function Sexbound.Player:notifySterilizationChange(data)
    if data.name ~= "sterilized" then return end

    local notifications = self:getNotifications() or {}
    notifications = notifications.events or {}
    notifications = notifications.sterilize or {}

    local sterilized = data.query == "add"
    local sterilizedText = tostring(sterilized)

    local text = notifications[sterilizedText]
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

--- Creates and send a notification message about infertility state change
--- @param data table The status effect change message
function Sexbound.Player:notifyInfertileChange(data)
    if data.name ~= "infertile" then return end

    local notifications = self:getNotifications() or {}
    notifications = notifications.events or {}
    notifications = notifications.infertility or {}

    local infertile = data.query == "add"
    local infertileText = tostring(infertile)

    local text = notifications[infertileText]
    if text then
        world.sendEntityMessage(entity.id(), "queueRadioMessage", {
            messageId = "sexbound_infertility",
            unique = false,
            text = text
        })
    end

    self._isInfertile = infertile
    if infertile then status.removeEphemeralEffect("sexbound_custom_ovulating") end -- Remove ovulation cycle effect when infertile
end

--- Message handler for sexnode actor syncing persistent storage data
--- @param newData table # The sync data
function Sexbound.Player:handleSyncStorage(newData)
    newData = self:fixPregnancyData(newData)
    storage = util.mergeTable(storage, newData or {})
end

--- Message handler for sex UI syncing POV settings
--- @param newSettings table New settings data
function Sexbound.Player:handleSyncSettings(newSettings)
    storage.sexbound = storage.sexbound or {}
    storage.sexbound.uiLayers = newSettings
end

--- Fixes pregnancy data to be a numeric array to prevent Starbound schenanigans
--- @param data table The storage data
--- @return table # The fixed storage data
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

--- Sets up entity message handlers
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
        self._isClimaxing = true
    end)
    message.setHandler("Sexbound:ClimaxState:Exit", function(_, _, args)
        self._isClimaxing = false
    end)
    message.setHandler("Sexbound:CustomizerUI:Show", function(_, _, args)
        return self:handleShowCustomizerUI(args)
    end)
    message.setHandler("Sexbound:CustomizerUI:GetData", function(_, _, args)
        return self:handleGetCutomizerData(args)
    end)
    message.setHandler("Sexbound:Reward:Currency", function(_, _, args)
        return self:handleRewardCurrency(args)
    end)
    message.setHandler("Sexbound:Node:Lounge", function(_, _, args)
        return self:handleLounge(args)
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
    message.setHandler("Sexbound:Defeat:SetPositionAndLounge", function(_, _, data)
        mcontroller.setPosition({data.x, data.y})
        player.setLounging(data.id)
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
        (self._pregnant --[[@as Sexbound.Player.Pregnant]]):triggerActualPregnancy(baby)
    end)
    message.setHandler("Sexbound:Debug:Shrink", function(_, _, args)
        status.addEphemeralEffect("sexbound_kid")
    end)
end

--- Merges given table into persistent storage
--- @param newData table? The data to merge
function Sexbound.Player:mergeStorage(newData)
    storage = util.mergeTable(storage, newData or {})
end

--- Starts actor setup, optionally with provided fixed parameters
--- @param controllerId EntityId The entity id of the sexnode controller to talk to
--- @param params table? Optional override parameters for the actor data
--- @return boolean # Whethere or not setup was successful
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

-- [[ Getters / Setters ]]

--- Returns all data relevant to build a corresponding sexnode actor
--- @return table? # The assembled actor data
function Sexbound.Player:getActorData()
    local gender = player.gender()
    if self:canLog("debug") then sb.logInfo("Generating player actor "..player.id()) end

    storage.sexbound.climax = self:getClimax():getCurrentValue()

    local identity = self:getIdentity():build()
    identity.sxbSubGender = self:getSubGender():getSxbSubGender()
    identity.sxbNaturalStatus = self:getStatus():getStatusList() or identity.sxbNaturalStatus

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
        forceCanOvulate = status.statusProperty("sexbound_override_can_ovulate", false),
        forceCanProduceSperm = status.statusProperty("sexbound_override_can_produce_sperm", false),
        birthcontrol = status.statusProperty("sexbound_birthcontrol"),
        aroused = status.statusProperty("sexbound_aroused", false),
        arousedStrong = status.statusProperty("sexbound_aroused_strong", false),
        inHeat = status.statusProperty("sexbound_aroused_heat", false),
        --- @diagnostic disable-next-line: undefined-field
        isDefeated = self.sexboundDefeat and self.sexboundDefeat:isDefeated(),
        generationFertility = status.statusProperty("generationFertility", 1.0),
        fertilityPenalty = status.statusProperty("fertilityPenalty", 1.0)
    }
end

--- Returns the player legality manager instance
--- @return Sexbound.Player.Legal # The player legality manager instance
function Sexbound.Player:getLegal()
    return self._legal
end

-- [[ Legacy functions ]]

--- Message handler for "respawning" this entity
--- @param args table The provided storage data
function Sexbound.Player:handleRespawn(args)
    if args then
        self:mergeStorage(args)
    end

    self:respawn()
end

--- Message handler for awarding passive income currency
--- @param args table # Reward data
function Sexbound.Player:handleRewardCurrency(args)
    player.addCurrency(args.currencyName, args.amount)
end

--- "Respawns" this entity
function Sexbound.Player:respawn()
    self:restore()
end

-- [[ State Definitions]]

--- Defines state machine states - default state
--- @return table<string, function> # The defined state handlers
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

--- Defines state machine states - havingSex state
--- @return table<string, function> # The defined state handlers
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

--- [DEBUG] Resets all sex statistics
function Sexbound.Player:debugResetStats()
    storage.sexbound.statistics = {}
end

--- [DEBUG] Triggers the birthing animation flow
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

--- [DEBUG] Ends the birthing animation flow
function Sexbound.Player:debugEndBirthing()
    status.removeEphemeralEffect("sexbound_birthing")
    status.removeEphemeralEffect("sexbound_invisible")
    self._transform:smashSexNode()
end

--- Triggers the playing of configured sex music
function Sexbound.Player:startSexMusic()
    local config = self:getConfig().sex
    if not config.useSexMusic then return end
    --local songList = config.sexMusicPool or {}
    --local song = util.randomChoice(songList)
    --world.sendEntityMessage(player.id(), "playAltMusic", {song}, 1)
    local controllerId = self._controllerId or self._loungeId
    if controllerId then world.sendEntityMessage(controllerId, "Sexbound:Common:StartSexMusic", entity.id()) end
end

--- Triggers the stop of sex music
function Sexbound.Player:stopSexMusic()
    local config = self:getConfig().sex
    if not config.useSexMusic then return end
    --world.sendEntityMessage(player.id(), "playAltMusic", {""}, 1) --Try to play a different, non existent song to reset progress of current song
    --world.sendEntityMessage(player.id(), "stopAltMusic", 1)
    local controllerId = self._controllerId or self._loungeId
    if controllerId then world.sendEntityMessage(controllerId, "Sexbound:Common:StopSexMusic", entity.id()) end
end

--- Returns this entity's gender
--- @return string # The player's gender
function Sexbound.Player:getGender()
    return player.gender()
end

--- Returns this entity's species
--- @return string # The player's species
function Sexbound.Player:getSpecies()
    return player.species()
end

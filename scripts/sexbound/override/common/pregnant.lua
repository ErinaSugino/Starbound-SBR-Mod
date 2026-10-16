--- Abstract shared entity pregnancy manager class
--- @class Sexbound.Common.Pregnant
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _config table
--- @field _isGivingBirth boolean
--- @field _worldTime number
Sexbound.Common.Pregnant = {}
Sexbound.Common.Pregnant_mt = {
    __index = Sexbound.Common.Pregnant
}

--- Creates new entity pregnancy manager instance
--- @return Sexbound.Common.Pregnant # The newly created entity pregnancy manager instance
function Sexbound.Common.Pregnant:new()
    local _self = setmetatable({
        _isGivingBirth = false
    }, Sexbound.Common.Pregnant_mt)

    return _self
end

--- Checks if it is time to give birth right now
function Sexbound.Common.Pregnant:updateIsTimeToGiveBirthToFunction()
    if self:getConfig().useOSTimeForPregnancies then
        self.isTimeToGiveBirthTo = self.checkTimeToGiveBirthBasedOnOSTime
    else
        if player then self.isTimeToGiveBirthTo = self.checkTimeToGiveBirthBasedOnPlayerWorldTime
        else self.isTimeToGiveBirthTo = self.checkTimeToGiveBirthBasedOnWorldTime end
    end
end

--- Loads the pregnancy plugin's config
function Sexbound.Common.Pregnant:loadPluginConfig()
    local configs = self:getParent():getConfig() or {}
    configs = configs.actor or {}
    configs = configs.plugins or {}
    configs = configs.pregnant or {}
    configs = configs.config or {}

    if "table" ~= type(configs) then
        configs = {configs}
    end

    local loadedConfig = {}

    for _, _config in pairs(configs) do
        xpcall(function()
            loadedConfig = util.mergeTable(loadedConfig, root.assetJson(_config))
        end, function(errorMessage)
            sb.logError(errorMessage)
        end)
    end

    self._config = loadedConfig
end

--- Appends relevant parts from the main sexbound config to the loaded pregnancy config
function Sexbound.Common.Pregnant:appendMainConfig()
    local mainConfig = self:getParent():getConfig() or {}
    self._config.whichGendersCanOvulate = mainConfig.sex.whichGendersCanOvulate or {"female"}
    self._config.whichGendersCanProduceSperm = mainConfig.sex.whichGendersCanProduceSperm or {"male"}
    self._config.immersionLevel = mainConfig.immersionLevel or 1
end

--- Loads notifications configuration from file
--- @return table # The fetched notification data
function Sexbound.Common.Pregnant:loadNotificationDialog()
    local notifications = self:getParent():getNotifications() or {}
    notifications.plugins = notifications.plugins or {}
    notifications.plugins.pregnant = notifications.plugins.pregnant or {}

    return notifications.plugins.pregnant
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Pregnant:init(parent)
    self._parent = parent

    -- Ensure this is always a table
    if type(storage.sexbound.pregnant) ~= "table" then
        storage.sexbound.pregnant = {}
    end

    self:loadPluginConfig()
    self:appendMainConfig()
    self:updateIsTimeToGiveBirthToFunction()

    -- Migrate previous pregnant data into new storage location
    self:dataMigrate()

    -- Always filters erroneous data after data migration
    self:dataFilter()

    -- Always refresh status effects after validating data
    self:refreshStatusEffects()

    self:initMessageHandlers()
end

--- Sets up message handlers
function Sexbound.Common.Pregnant:initMessageHandlers()
    message.setHandler("Sexbound:Pregnant:Abortion", function(_, _, args)
        return self:abortPregnancy()
    end)
    message.setHandler("Sexbound:Pregnant:GetData", function(_, _, args)
        return self:getData(args)
    end)
    message.setHandler("Sexbound:Pregnant:GetDataAndConfig", function(_, _, args)
        return self:getDataAndConfig(args)
    end)
    message.setHandler("Sexbound:Pregnant:GiveBirth", function(_, _, args)
        return self:handleGiveBirth(args)
    end)
end

--- Performs data migration to preserve pregnant data from previous versions.
function Sexbound.Common.Pregnant:dataMigrate()
    if type(storage.pregnant) ~= "table" then
        return
    end
    if isEmpty(storage.pregnant) then
        storage.pregnant = nil
        return
    end

    if storage.pregnant[1] ~= nil then -- Is Multiple Pregnancies
        util.each(storage.pregnant, function(_, pregnancy)
            table.insert(storage.sexbound.pregnant, pregnancy)
        end)
    else -- Is single pregnancy
        table.insert(storage.sexbound.pregnant, storage.pregnant)
    end

    storage.pregnant = nil
end

--- Rebuilds pregnancy data to migrate older versions
function Sexbound.Common.Pregnant:dataFilter()
    if type(storage.sexbound.pregnant) ~= "table" then
        storage.sexbound.pregnant = {}
        return
    end
    if isEmpty(storage.sexbound.pregnant) then return end

    local filteredData = {}
    local count = 0
    for k, v in pairs(storage.sexbound.pregnant) do
        if type(v) == "table" then
            v.birthOSTime = v.birthOSTime or os.time()

            -- Update old babies to use new progressive pregnancy progression
            if type(v.fullBirthOSTime) ~= "number" then v.fullBirthOSTime = os.time() end
            if type(v.fullBirthWorldTime) ~= "number" then v.fullBirthWorldTime = math.max(v.birthWorldTime, 840) end
            if type(v.delay) ~= "number" then v.delay = 0 end

            if type(v.babies) ~= "table" then
                v.babies = {}
                table.insert(v.babies, {
                    birthGender = v.birthGender or "male",
                    motherName = v.motherName or "Unknown",
                    motherId = v.motherId or "",
                    motherUuid = v.motherUuid or "",
                    motherType = v.motherType or "villager",
                    motherSpecies = v.motherSpecies or "human",
                    fatherName = v.fatherName or "Unknown",
                    fatherId = v.fatherId or "",
                    fatherUuid = v.fatherUuid or "",
                    fatherType = v.fatherType or "villager",
                    fatherSpecies = v.fatherSpecies or "human",
                    generationFertility = v.generationFertility or 1.0,
                    npcType = v.npcType or "villager",
                    birthEntityGroup = v.birthEntityGroup or "humanoid",
                    birthSpecies = v.birthSpecies or "human"
                })
                v.pregnancyType = "baby"
                v.dataVersion = 3
                v.incestLevel = 0
                v.babyCount = 1

                v.birthGender = nil
                v.motherName = nil
                v.motherId = nil
                v.motherUuid = nil
                v.motherType = nil
                v.motherSpecies = nil
                v.fatherName = nil
                v.fatherId = nil
                v.fatherUuid = nil
                v.fatherType = nil
                v.fatherSpecies = nil
                v.generationFertility = nil
                v.npcType = nil
                v.birthEntityGroup = nil
                v.birthSpecies = nil
            end
        end

        count = count + 1

        table.insert(filteredData, count, v)
    end

    storage.sexbound.pregnant = filteredData
end

-- Aborts all pregnancies by reseting storage to empty table
function Sexbound.Common.Pregnant:abortPregnancy()
    storage.sexbound.pregnant = {}

    self:refreshStatusEffects()
end

--- Checks if a pregnancy is ready for birth and returns its list index
--- @return integer? # The list index of the ready-to-birth pregnancy, if any found
function Sexbound.Common.Pregnant:findReadyBabyIndex()
    if isEmpty(storage.sexbound.pregnant or {}) then
        return nil
    end

    self:updateWorldTime()

    for index, baby in pairs(storage.sexbound.pregnant) do
        local delay = baby.delay or 0
        if delay <= 0 and self:isTimeToGiveBirthTo(baby) == true then
            return index
        end
    end
end

--- Checks if a pregnancy's birth time is due, assuming written in OS-dependent time
--- @param baby table Pregnancy data
--- @return boolean # Whethere or not real OS time is past birth time
function Sexbound.Common.Pregnant:checkTimeToGiveBirthBasedOnOSTime(baby)
    return os.time() >= baby.birthOSTime
end

--- Checks if a pregnancy's birth time is due, assuming written in world-dependent time
--- @param baby table Pregnancy data
--- @return boolean # Whethere or not world  time is past birth time
function Sexbound.Common.Pregnant:checkTimeToGiveBirthBasedOnWorldTime(baby)
    return self:updateWorldTime() >= baby.birthWorldTime
end

--- Checks if a pregnancy's birth time is due, assuming written as player countdown
--- @param baby table Pregnancy data
--- @return boolean # Whethere or not the countdown hit 0
function Sexbound.Common.Pregnant:checkTimeToGiveBirthBasedOnPlayerWorldTime(baby)
    return baby.birthWorldTime <= 0
end

--- Commence birth of a baby
--- @param babyConfig table Baby data from pregnancy
--- @param babyName string? Chosen name for the baby
--- @param incestLevel integer The level of incest that resulted in this offspring
--- @return EntityId? # The born entity's id, if successful
function Sexbound.Common.Pregnant:giveBirth(babyConfig, babyName, incestLevel)
    local roll = math.random()
    local threshold = math.max((self._config.stillbornChance or 0), 0)
    incestLevel = incestLevel or 0
    local incestModifiers = {0, 0.125, 0.25, 0.5}
    threshold = threshold + (incestModifiers[incestLevel] or 0) -- Incest chance increase: 0: 0%; 1: 12.5%; 2: 25%, 3: 50%
    if roll < threshold then
        self:notifyOfStillborn(babyConfig, babyName)
        sb.logInfo("Baby birth is a stillborn!")
        return nil
    else
        local pregnancyType = babyConfig.pregnancyType or "baby"

        -- Try loading baby class
        local r,err = pcall(require, "/scripts/sexbound/plugins/pregnant/"..pregnancyType..".lua")
        if not r then
            sb.logError("SxB: Could not load baby class \""..pregnancyType.."\" - aborting pregnancy generation.")
            sb.logError("Error: "..tostring(err))
            return nil
        end

        local babyClass
        r,err = pcall(function()
            local ucPregnancyType = pregnancyType:gsub("^%l", string.upper)
            babyClass = _ENV[ucPregnancyType]:new(self, self._config) --[[@as Sexbound.Pregnancy.Baby]]
        end)
        if not r then
            -- Can't load = can't generate baby = no pregnancy; abort
            sb.logError("SxB: Could not load baby class \""..pregnancyType.."\" - aborting pregnancy generation.")
            sb.logError("Error: "..tostring(err))
            return nil
        end

        return (babyClass --[[@as Sexbound.Pregnancy.Baby]]):birth(babyConfig, babyName)
    end
end

--- Notifies parent entities, if possible, of stillborn failure
--- @param baby table Baby config
--- @param name string? Baby's given name
function Sexbound.Common.Pregnant:notifyOfStillborn(baby, name)
    if baby.motherType ~= "player" then return end

    local notification = self:loadNotificationDialog()
    notification = notification.birth or {}

    local babyGender = baby.birthGender

    if babyGender == "male" then
        babyGender = "^blue;boy^reset;"
    end

    if babyGender == "female" then
        babyGender = "^pink;girl^reset;"
    end

    local message = notification.stillborn or ""
    message = util.replaceTag(message, "babyname", name)

    message = util.replaceTag(message, "babygender", babyGender)

    world.sendEntityMessage(baby.motherUuid, "queueRadioMessage", {
        messageId = "Sexbound_Event:Stillborn",
        unique = false,
        text = message
    })

    local motherName = baby.motherName or "UNKNOWN"
    motherName = "^green;" .. motherName .. "^reset;"

    message = notification.remoteStillborn or ""
    message = util.replaceTag(message, "name", motherName)
    message = util.replaceTag(message, "babyname", name)
    message = util.replaceTag(message, "babygender", babyGender)

    if world.players then
        for _, playerId in ipairs(world.players()) do
            if world.entityUniqueId(playerId) ~= baby.motherUuid then
                world.sendEntityMessage(playerId, "queueRadioMessage", {
                    messageId = "Sexbound_Event:Stillborn",
                    unique = false,
                    text = message
                })
            end
        end
    end
end

--- Updates pregnant status effecs based on progress
function Sexbound.Common.Pregnant:refreshStatusEffects()
    if self:getIsVisiblyPregnant() then
        self:addStatusEffects()
        return
    end

    self:removeStatusEffects()
end

--- [Helper] Adds the status effect to the entity
function Sexbound.Common.Pregnant:addStatusEffects()
    status.addEphemeralEffect("sexbound_pregnant", math.huge)
end

--- [Helper] Remove the status effect from the entity
function Sexbound.Common.Pregnant:removeStatusEffects()
    status.removeEphemeralEffect("sexbound_pregnant")
end

--- Update cached world time
--- @return number # The newly cached world time
function Sexbound.Common.Pregnant:updateWorldTime()
    self._worldTime = world.day() + world.timeOfDay()
    return self._worldTime
end

--- Returns the loaded pregnancy config
--- @return table # The loaded pregnancy config
function Sexbound.Common.Pregnant:getConfig()
    return self._config
end

--- Returns pregnancy data
--- @param index integer? Index of the pregnancy to get
--- @return table? # Requested pregnancy data, if exists, or list of all pregnancies if none requested
function Sexbound.Common.Pregnant:getData(index)
    if self._parent:canLog("debug") then sb.logInfo("Entity pregnancy data for #"..entity.id()..": "..Sexbound.Util.dump(storage.sexbound.pregnant or {})) end
    if index and storage.sexbound.pregnant then
        return storage.sexbound.pregnant[index]
    end
    return storage.sexbound.pregnant
end

--- Returns combi of pregnancies and loaded config
--- @param index integer? Index of the pregnancy to get
--- @return {pregnancies: table?, config: table} # The requested combi data
--- @see Sexbound.Common.Pregnant.getData
function Sexbound.Common.Pregnant:getDataAndConfig(index)
    if self._parent:canLog("debug") then sb.logInfo("Entity pregnancy data for #"..entity.id()..": "..Sexbound.Util.dump(storage.sexbound.pregnant or {})) end
    local pregnancies = nil
    local config = self:getConfig()
    if index and storage.sexbound.pregnant then
        pregnancies = storage.sexbound.pregnant[index]
    else pregnancies = storage.sexbound.pregnant end

    return {pregnancies = pregnancies, config = config}
end

--- Returns whethere or not this entity is pregnant
--- @return boolean # Whethere or not this entity is pregnant
function Sexbound.Common.Pregnant:getIsPregnant()
    return not isEmpty(storage.sexbound.pregnant)
end

--- Returns whethere or not this entity is visibly pregnant
--- @return boolean # Whethere or not this entity is visibly pregnant
function Sexbound.Common.Pregnant:getIsVisiblyPregnant()
    if isEmpty(storage.sexbound.pregnant) then return false end
    local visiblyPregnant = false

    local useOSTime = self:getConfig().useOSTimeForPregnancies
    local osTime = os.time()

    for i,b in pairs(storage.sexbound.pregnant) do
        if useOSTime == true and (osTime - b.fullBirthOSTime) >= ((b.birthOSTime - b.fullBirthOSTime) / 2) then
            visiblyPregnant = true
            break
        elseif useOSTime ~= true then
            -- Since players have a countdown value for the birth time and NPCs a "countup", they need different calculations to determine if half of the pregnencies time is already over
            if player and b.birthWorldTime <= (b.fullBirthWorldTime / 2) then
                visiblyPregnant = true
                break
            elseif not player and (world.day() + world.timeOfDay() - b.fullBirthWorldTime) >= ((b.birthWorldTime - b.fullBirthWorldTime) / 2) then
                visiblyPregnant = true
                break
            end
        end
    end

    return visiblyPregnant
end

--- Returns whethere or not this entity is currently giving birth
--- @return boolean
function Sexbound.Common.Pregnant:isGivingBirth()
    return self._isGivingBirth
end

--- Sets whethere or not this entity is currently giving birth
--- @param isGivingBirth boolean # Whethere or not this entity is currently giving birth
function Sexbound.Common.Pregnant:setIsGivingBirth(isGivingBirth)
    self._isGivingBirth = isGivingBirth
end

--- Returns the parent entity manager instance
--- @return Sexbound.Common # The parent entity manager instance
function Sexbound.Common.Pregnant:getParent()
    return self._parent
end

--- Returns the cached world time
--- @return number # The cached world time
function Sexbound.Common.Pregnant:getWorldTime()
    return self._worldTime or self:updateWorldTime()
end

--- Placeholder message handler. To be implemented by child classes
--- @param args any Message arguments
--- @return EntityId[]? # The entity if od the spawned baby entity, if successful
function Sexbound.Common.Pregnant:handleGiveBirth(args)
    return nil
end
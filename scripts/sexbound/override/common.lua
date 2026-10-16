require "/scripts/messageutil.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/sexbound/util.lua"
require "/scripts/stateMachine.lua"

Sexbound = Sexbound or {}
--- Sexbound.Common Module.
--- @class Sexbound.Common
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field protected _configFilePath string
--- @field protected _notificationsFilePath string
--- @field _hasInited boolean
--- @field _firstInit boolean
--- @field _parent Sexbound.Common
--- @field _config table
--- @field _notifications table
--- @field _bodyTraits table<string, boolean>
--- @field _subGender Sexbound.Common.SubGender
--- @field _pregnant Sexbound.Common.Pregnant
--- @field _status Sexbound.Common.Status
--- @field _arousal Sexbound.Common.Arousal
--- @field _climax Sexbound.Common.Climax
--- @field _identity Sexbound.Common.Identity
--- @field _statistics Sexbound.Common.Statistics
--- @field _transform Sexbound.Common.Transform
--- @field _apparel? Sexbound.Common.Apparel
--- @field _stateMachine table
--- @field _states? table
--- @field _stateDefinitions? table
--- @field _promises? PromiseKeeper
--- @field _isHavingSex boolean
--- @field _isClimaxing boolean
--- @field _controllerId EntityId?
Sexbound.Common = {}
Sexbound.Common_mt = {
    __index = Sexbound.Common
}

--- Creates new instance of the common shared entity handler
--- @return Sexbound.Common # The newly created shared entity handler
function Sexbound.Common:new()
    return setmetatable({
        _configFilePath = "/sexbound.config",
        _notificationsFilePath = "/dialog/sexbound/<langcode>/notifications.config",
        _hasInited = false,
        _firstInit = false
    }, Sexbound.Common_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent
--- @param entityType string The entity type of the entity
function Sexbound.Common:init(parent, entityType)
    if not storage.sexbound then self._firstInit = true end

    storage.sexbound = storage.sexbound or {}
    storage.sexbound.identity = storage.sexbound.identity or {}

    self._parent = parent
    self._config = self:loadConfig()
    self._notifications = self:loadNotifications()

    self:buildSubGenderList()

    if entityType ~= "monster" then self:fetchCoreIdentity() end -- Get species-gender specific subGender if none set for entity

    self._bodyTraits = {canOvulate=false,canProduceSperm=true,hasPenis=true,hasVagina=false}
    self:buildBodyTraits(storage.sexbound.identity.sxbSubGender or self:getGender()) -- get actual body traits for entity's subgender or gender

    self:loadSubscripts(entityType) -- Subscripts include SubGender, which verifies and, if needed, resets current sub-gender

    status.setStatusProperty("sexbound_birthday", status.statusProperty("sexbound_birthday", "default"))

    if status.statusProperty("generationFertility", nil) == nil then
        status.setStatusProperty("generationFertility", 1.0)
        status.setStatusProperty("fertilityPenalty", 1.0)
    end
end

--- Uninitialize this handler
function Sexbound.Common:uninit()
    if self._subGender then xpcall(function() return self._subGender:uninit() end, sb.logError) end
end

--- Placeholder tick handler. To be implemented in child classes
--- @param dt number The delta time since last tick
function Sexbound.Common.update(dt) end

--- Builds the list of all known sub-genders
--- @protected
function Sexbound.Common:buildSubGenderList()
    self._config.allGenders = { -- Define default main gender traits
        male={
            canOvulate=false,
            canProduceSperm=true,
            hasPenis=true,
            hasVagina=false
        },
        female={
            canOvulate=true,
            canProduceSperm=false,
            hasPenis=false,
            hasVagina=true
        }
    }
    self._config.allGenderIndices = {"male","female"}
    local subGenderList = self._config.sex.subGenderList or {} -- Load sub-gender config
    for _,s in ipairs(subGenderList) do
        local name = s.name or "unknown"
        s.name = nil
        if not self._config.allGenders[name] then table.insert(self._config.allGenderIndices, name) end
        self._config.allGenders[name] = s
    end
end

--- Returns the genders array index of a given species for a given target gender
--- @param speciesConfig table? The full species config
--- @param gender string The target gender
--- @return integer # The genders array index that represents the target gender
function Sexbound.Common:getGenderId(speciesConfig, gender)
    if speciesConfig then
        for _index, _gender in ipairs(speciesConfig.genders) do
            if (_gender.name == gender) then
                return _index
            end
        end
    end

    if gender == "male" then
        return 1
    else
        return 2
    end
end

--- Build this entity's core identity data
function Sexbound.Common:fetchCoreIdentity()
    local speciesConfig

    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. self:getSpecies() .. ".species")
    end) then
        sb.logWarn("SxB: Could not find species config file.")
    end

    local genderId = self:getGenderId(speciesConfig, self:getGender())
    local genderConfig = speciesConfig.genders[genderId]

    storage.sexbound.identity.sxbSubGender = storage.sexbound.identity.sxbSubGender or genderConfig.sxbSubGender
    storage.sexbound.identity.sxbSubGenderMultiplier = storage.sexbound.identity.sxbSubGenderMultiplier or genderConfig.sxbSubGenderMultiplier or 1

    self._speciesDefaultStatuses = genderConfig.sxbNaturalStatus
    if self._speciesDefaultStatuses and type(self._speciesDefaultStatuses) ~= "table" then self._speciesDefaultStatuses = {self._speciesDefaultStatuses} end

    self._speciesType = speciesConfig.sxbSpeciesType or nil

    self._usesHeat = (speciesConfig.sxbUseHeat or false) and (self._config.sex.enableHeatMechanic or false)
    self._heatDuration = speciesConfig.sxbHeatDuration or 1800
end

--- Build the sexbound body traits for this entity
--- @param gender string? The gender or sub-gender of this entity
function Sexbound.Common:buildBodyTraits(gender)
    gender = gender or self:getGender()
    if self:canLog("debug") then sb.logInfo("Building body traits for entity "..entity.id()..": "..tostring(gender)) end
    local fallback = {canOvulate=false,canProduceSperm=true,hasPenis=true,hasVagina=false}

    self._bodyTraits = self._config.allGenders[gender]
    if self._bodyTraits == nil then self._bodyTraits = fallback end
    if self._hasInited then self:updateTraitEffects() end
    -- To prevent updating too early, we do not apply trait based changes before we haven't fully inited, meaning all initial statusChanges happened
    -- E.g.: Cunboy can ovulate. But in the normal loading order we would first update a normal male, removing pregnancies, THEN load the futapatches change to cuntboy effect.
end

--- Update status effects based on body traits
function Sexbound.Common:updateTraitEffects()
    if (self._pregnant and not self._pregnant._config.enableFreeForAll) and not (self._bodyTraits.canOvulate or status.statusProperty("sexbound_override_can_ovulate", false)) then
        storage.sexbound.pregnant = {} -- If we cannot ovulate anymore, remove current pregnancies
        storage.sexbound.ovulationCycle = 0 -- If we cannot ovulate anymore, remove and reset ovulation cycle
        status.removeEphemeralEffect("sexbound_custom_ovulating")
        if self:canLog("debug") then sb.logInfo("Entity "..entity.id().." cannot ovulate (anymore), removing pregnancies and ovulation cycle logic") end
    end
end

--- Announces having given birth
--- @return boolean # Whethere or not notification was successful
function Sexbound.Common:announceBirth()
    local plugins = self._notifications.plugins or {}
    local pregnant = plugins.pregnant or {}
    local pool = pregnant.birth or {}
    local message = pool.gaveBirth or ""

    local birthData = storage.sexbound.birthData or {}
    local motherUuid = birthData.motherUuid

    local babyName = world.entityName(entity.id()) or "UNKNOWN"
    babyName = "^green;" .. babyName .. "^reset;"

    local babyGender = world.entityGender(entity.id())

    if babyGender == "male" then
        babyGender = "^blue;boy^reset;"
    end

    if babyGender == "female" then
        babyGender = "^pink;girl^reset;"
    end

    message = util.replaceTag(message, "babyname", babyName)

    message = util.replaceTag(message, "babygender", babyGender)

    if birthData.motherType == "player" and motherUuid then
        world.sendEntityMessage(motherUuid, "queueRadioMessage", {
            messageId = "Sexbound_Event:Birth",
            unique = false,
            text = message
        })
    end

    local motherName = birthData.motherName or "UNKNOWN"
    motherName = "^green;" .. motherName .. "^reset;"

    message = pool.remoteGaveBirth or ""
    message = util.replaceTag(message, "name", motherName)
    message = util.replaceTag(message, "babyname", babyName)
    message = util.replaceTag(message, "babygender", babyGender)

    if world.players then
        for _, playerId in ipairs(world.players()) do
            if world.entityUniqueId(playerId) ~= motherUuid then
                world.sendEntityMessage(playerId, "queueRadioMessage", {
                    messageId = "Sexbound_Event:Birth",
                    unique = false,
                    text = message
                })
            end
        end
    end

    return true
end

--- Loads the main sexbound config file
--- @return table # The main sexbound config JSON
function Sexbound.Common:loadConfig()
    local _, _config = xpcall(function()
        return root.assetJson(self._configFilePath)
    end, function(err)
        sb.logError("Failed to load Sexbound configuration: " .. self._configFilePath)
        return {}
    end)

    return _config
end

--- Loads the notification config file
--- @return table # The notifications config JSON
function Sexbound.Common:loadNotifications()
    local _filePath = util.replaceTag(self._notificationsFilePath, "langcode", self:getLanguageCode())

    local _, _notifications = xpcall(function()
        return root.assetJson(_filePath)
    end, function(err)
        sb.logError("Failed to load notifications configuration: " .. _filePath)
        return {}
    end)

    return _notifications
end

--- Loads all override Lua sub-scripts for the given entity type
--- @param entityType string The entity type
function Sexbound.Common:loadSubscripts(entityType)
    local _override = self._config.override[entityType] or {}
    local _overrideDir = _override.overrideDir or "/scripts/sexbound/override"

    util.each(_override.scripts, function(_, _script)
        _script = util.replaceTag(_script, "overrideDir", _overrideDir)
        _script = util.replaceTag(_script, "entityGroup", entityType)

        require(_script)
    end)
end

--- Message handler for when a node transformation attempt fails
function Sexbound.Common:failedTransformation()
    world.sendEntityMessage(entity.id(), "applyStatusEffect", "sexbound_obstructed")
end

--- Applies stored data to persistent storage
function Sexbound.Common:restorePreviousStorage()
    local _statusPropertyName = "sexbound_previous_storage"

    if ("table" == type(status.statusProperty(_statusPropertyName))) then
        storage = util.mergeTable(storage, status.statusProperty(_statusPropertyName, {}))

        status.setStatusProperty(_statusPropertyName, "default")
    end
end

--- Event handler for hazard abortions; wipes pregnancy data
function Sexbound.Common:hazardAbortion()
    storage.sexbound = storage.sexbound or {}
    storage.sexbound.pregnant = {}
end

--- Updates sub-gender statuses
--- @param old table<integer, string> The list of old subgender statuses to be removed
--- @param new table<integer, string> The list of new subgender statuses to be added
function Sexbound.Common:updateSubgenderStatus(old, new)
    if old then
        if type(old) ~= "table" then old = {old} end
        for _,s in ipairs(old) do
            self._subGender:handleRemoveStatus(s)
        end
    end
    if new then
        if type(new) ~= "table" then new = {new} end
        for _,s in ipairs(new) do
            self._subGender:handleAddStatus(s)
        end
    end
end

--- Sets this entity's fertility penalty
--- @param newFertility number The new fertility penalty
function Sexbound.Common:updateFertility(newFertility)
    status.setStatusProperty("fertilityPenalty", newFertility)
end

-- [[ Getters/Setters ]]

--- Returns the main sexbound config
--- @return table # The main sexbound config
function Sexbound.Common:getConfig()
    return self._config
end

--- Returns the parent instance
--- @return Sexbound.Common # The parent instance (self-reference)
function Sexbound.Common:getParent()
    return self._parent
end

--- Returns the notifications config
--- @return table # The notifications config
function Sexbound.Common:getNotifications()
    return self._notifications
end

--- Returns the current sub-gender of this entity
--- @return string? # The current sub-gender, if any
function Sexbound.Common:getCurrentSubGender()
    if self._subGender then return self._subGender._currentGender
    else return storage.sexbound.identity.sxbSubGender end
end

--- Returns the currently active language's code
--- @return string # The language code
function Sexbound.Common:getLanguageCode()
    local _supportedLanguages = self._config.supportedLanguages or {}
    local _language = _supportedLanguages[self._config.defaultLanguage or "english"] or {}
    return _language.languageCode or "en"
end

--- Returns whethere or not a specific logging level is enabled
--- @param level string The log level code
--- @return boolean # Whethere or not that level should log
function Sexbound.Common:canLog(level)
    level = "show"..(string.gsub(level, "^%l", string.upper))
    local logLevels = self._config or {}
    logLevels = logLevels.log or {}
    return not not logLevels[level]
end

-- [[ Getters ]]

--- Returns sexnode object entity Id
--- @return EntityId? # The controller id, if lounging in sexnode
function Sexbound.Common:getControllerId()
    return self._controllerId
end

--- Returns whethere or not this entity is currently having sex
--- @return boolean # Whethere or not this entity is currently having sex
function Sexbound.Common:getIsHavingSex()
    return self._isHavingSex
end

--- Returns whethere or not this entity is currently climaxing
--- @return boolean # Whethere or not this entity is currently climaxing
function Sexbound.Common:getIsClimaxing()
    return self._isClimaxing
end

--- Returns the apparel manager instance
--- @return Sexbound.Common.Apparel # The apparel manager instance
function Sexbound.Common:getApparel()
    return self._apparel
end

--- Returns the arousal manager instance
--- @return Sexbound.Common.Arousal # The arousal manager instance
function Sexbound.Common:getArousal()
    return self._arousal
end

--- Returns the climax manager instance
--- @return Sexbound.Common.Climax # The arousal manager instance
function Sexbound.Common:getClimax()
    return self._climax
end

--- Returns the identity builder instance
--- @return Sexbound.Common.Identity # The identity builder instance
function Sexbound.Common:getIdentity()
    return self._identity
end

--- Returns the pregnancy manager instance
--- @return Sexbound.Common.Pregnant # The pregnancy manager instance
function Sexbound.Common:getPregnant()
    return self._pregnant
end

--- Returns the statistics manager instance
--- @return Sexbound.Common.Statistics # The statistics manager instance
function Sexbound.Common:getStatistics()
    return self._statistics
end

--- Returns the status manager instance
--- @return Sexbound.Common.Status # The status manager instance
function Sexbound.Common:getStatus()
    return self._status
end

--- Returns the sub-gender manager instance
--- @return Sexbound.Common.SubGender # The sub-gender manager instance
function Sexbound.Common:getSubGender()
    return self._subGender
end

--- Returns the transformation manager instance
--- @return Sexbound.Common.Transform # The transformation manager instance
function Sexbound.Common:getTransform()
    return self._transform
end

-- [[ Abstract placeholders ]]

--- Placeholder gender fetch. To be implemented by child classes
--- @return string # The entity's gender
function Sexbound.Common:getGender()
    return ""
end

--- Placeholder species fetch. To be implemented by child classes
--- @return string # The entity's species
function Sexbound.Common:getSpecies()
    return ""
end

--- Placeholder compatibility check. To be implemented by child classes
--- @return table<string, any> # The comparison data
function Sexbound.Common:getCompatibilityData()
    return {}
end

--- Placeholder actor data fetch. To be implemented by child classes
--- @return table? # The entity's actor data
function Sexbound.Common:getActorData()
    return {}
end

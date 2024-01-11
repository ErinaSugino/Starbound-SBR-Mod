--- Sexbound.Common Module.
-- @module Sexbound.Common
require "/scripts/messageutil.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/sexbound/util.lua"
require "/scripts/stateMachine.lua"

Sexbound = Sexbound or {}
Sexbound.Common = {}
Sexbound.Common_mt = {
    __index = Sexbound.Common
}

function Sexbound.Common:new()
    return setmetatable({
        _configFilePath = "/sexbound.config",
        _notificationsFilePath = "/dialog/sexbound/<langcode>/notifications.config",
        _hasInited = false,
        _firstInit = false
    }, Sexbound.Common_mt)
end

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

function Sexbound.Common:uninit()
    if self._subGender then xpcall(function() return self._subGender:uninit() end, sb.logError) end
end

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

function Sexbound.Common:getGenderId(speciesConfig, gender)
    if not speciesConfig then
        if gender == "male" then
            return 1
        else
            return 2
        end
    end

    for _index, _gender in ipairs(speciesConfig.genders) do
        if (_gender.name == gender) then
            return _index
        end
    end
end

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
    
    self._usesHeat = (speciesConfig.sxbUsesHeat or false) and (self._config.sex.enableHeatMechanic or false)
end

function Sexbound.Common:buildBodyTraits(gender)
    gender = gender or self:getGender()
    if self:canLog("debug") then sb.logInfo("Building body traits for entity "..entity.id()..": "..tostring(gender)) end
    local fallback = {canOvulate=false,canProduceSperm=true,hasPenis=true,hasVagina=false}
    
    self._bodyTraits = self._config.allGenders[gender]
    if self._bodyTraits == nil then self._bodyTraits = fallback end
    if self._hasInited then self:updateTraitEffects() end -- To prevent updating too early, we do not apply trait based changes before we haven't fully inited, meaning all initial statusChanges happened
    -- E.g.: Cunboy can ovulate. But in the normal loading order we would first update a normal male, removing pregnancies, THEN load the futapatches change to cuntboy effect.
end

function Sexbound.Common:updateTraitEffects()
    if not self._bodyTraits.canOvulate then
        storage.sexbound.pregnant = {} -- If we cannot ovulate anymore, remove current pregnancies
        storage.sexbound.ovulationCycle = 0 -- If we cannot ovulate anymore, remove and reset ovulation cycle
        status.removeEphemeralEffect("sexbound_custom_ovulating")
        if self:canLog("debug") then sb.logInfo("Entity "..entity.id().." cannot ovulate (anymore), removing pregnancies and ovulation cycle logic") end
    end
end

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

function Sexbound.Common:loadConfig()
    local _, _config = xpcall(function()
        return root.assetJson(self._configFilePath)
    end, function(err)
        sb.logError("Failed to load Sexbound configuration: " .. self._configFilePath)
        return {}
    end)

    return _config
end

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

function Sexbound.Common:loadSubscripts(entityType)
    local _override = self._config.override[entityType] or {}
    local _overrideDir = _override.overrideDir or "/scripts/sexbound/override"

    util.each(_override.scripts, function(_, _script)
        _script = util.replaceTag(_script, "overrideDir", _overrideDir)
        _script = util.replaceTag(_script, "entityGroup", entityType)

        require(_script)
    end)
end

function Sexbound.Common:failedTransformation()
    world.sendEntityMessage(entity.id(), "applyStatusEffect", "sexbound_obstructed")
end

function Sexbound.Common:restorePreviousStorage()
    local _statusPropertyName = "sexbound_previous_storage"

    if ("table" == type(status.statusProperty(_statusPropertyName))) then
        storage = util.mergeTable(storage, status.statusProperty(_statusPropertyName, {}))

        status.setStatusProperty(_statusPropertyName, "default")
    end
end

function Sexbound.Common:hazardAbortion()
    storage.sexbound = storage.sexbound or {}
    storage.sexbound.pregnant = {}
end

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

function Sexbound.Common:updateFertility(newFertility)
    status.setStatusProperty("fertilityPenalty", newFertility)
end

-- Getters/Setters
function Sexbound.Common:getConfig()
    return self._config
end
function Sexbound.Common:getParent()
    return self._parent
end
function Sexbound.Common:getNotifications()
    return self._notifications
end
function Sexbound.Common:getSubGender()
    if self._subGender then return self._subGender._currentGender
    else return storage.sexbound.identity.sxbSubGender end
end
function Sexbound.Common:getLanguageCode()
    local _supportedLanguages = self._config.supportedLanguages or {}
    local _language = _supportedLanguages[self._config.defaultLanguage or "english"] or {}
    return _language.languageCode or "en"
end

function Sexbound.Common:canLog(level)
    level = "show"..(string.gsub(level, "^%l", string.upper))
    local logLevels = self._config or {}
    logLevels = logLevels.log or {}
    return not not logLevels[level]
end

function Sexbound.Common:dump(o)
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

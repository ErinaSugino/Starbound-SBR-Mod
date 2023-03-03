Sexbound.Common.Pregnant = {}
Sexbound.Common.Pregnant_mt = {
    __index = Sexbound.Common.Pregnant
}

function Sexbound.Common.Pregnant:new()
    local _self = setmetatable({
        _isGivingBirth = false
    }, Sexbound.Common.Pregnant_mt)

    return _self
end

function Sexbound.Common.Pregnant:updateIsTimeToGiveBirthToFunction()
    if self:getConfig().useOSTimeForPregnancies then
        self.isTimeToGiveBirthTo = self.checkTimeToGiveBirthBasedOnOSTime
    else
        if player then self.isTimeToGiveBirthTo = self.checkTimeToGiveBirthBasedOnPlayerWorldTime
        else self.isTimeToGiveBirthTo = self.checkTimeToGiveBirthBasedOnWorldTime end
    end
end

function Sexbound.Common.Pregnant:loadPluginConfig()
    --self._config = root.assetJson("/sxb_plugin.pregnant.config")
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

function Sexbound.Common.Pregnant:appendMainConfig()
    local mainConfig = self:getParent():getConfig() or {}
    self._config.whichGendersCanOvulate = mainConfig.sex.whichGendersCanOvulate or {"female"}
    self._config.whichGendersCanProduceSperm = mainConfig.sex.whichGendersCanProduceSperm or {"male"}
    self._config.immersionLevel = mainConfig.immersionLevel or 1
end

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

function Sexbound.Common.Pregnant:initMessageHandlers()
    message.setHandler("Sexbound:Pregnant:Abortion", function(_, _, args)
        return self:abortPregnancy(args)
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
            --if type(v.birthDate) == "number" and type(v.birthTime) == "number" then
            --    v.birthWorldTime = v.birthDate + v.birthTime
            --end
            
            v.birthOSTime = v.birthOSTime or os.time()
            
            -- Update old babies to use new progressive pregnancy progression
            if type(v.fullBirthOSTime) ~= "number" then v.fullBirthOSTime = os.time() end
            if type(v.fullBirthWorldTime) ~= "number" then v.fullBirthWorldTime = math.max(v.birthWorldTime, 840) end
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

function Sexbound.Common.Pregnant:findReadyBabyIndex()
    if isEmpty(storage.sexbound.pregnant or {}) then
        return
    end

    self:updateWorldTime()

    for index, baby in pairs(storage.sexbound.pregnant) do
        local delay = baby.delay or 0
        if delay <= 0 and self:isTimeToGiveBirthTo(baby) == true then
            return index
        end
    end

    return
end

function Sexbound.Common.Pregnant:checkTimeToGiveBirthBasedOnOSTime(baby)
    return os.time() >= baby.birthOSTime
end

function Sexbound.Common.Pregnant:checkTimeToGiveBirthBasedOnWorldTime(baby)
    return self:updateWorldTime() >= baby.birthWorldTime
end

function Sexbound.Common.Pregnant:checkTimeToGiveBirthBasedOnPlayerWorldTime(baby)
    return baby.birthWorldTime <= 0
end

function Sexbound.Common.Pregnant:giveBirth(babyConfig, babyName)
    babyConfig.birthEntityGroup = babyConfig.birthEntityGroup or "humanoid"

    if babyConfig.birthEntityGroup == "monsters" then
        return self:_giveBirthToMonster(babyConfig)
    else
        return self:_giveBirthToHumanoid(babyConfig, babyName)
    end
end

function Sexbound.Common.Pregnant:refreshStatusEffects()
    if self:getIsVisiblyPregnant() then
        self:addStatusEffects()
        return
    end

    self:removeStatusEffects()
end

function Sexbound.Common.Pregnant:addStatusEffects()
    status.addEphemeralEffect("sexbound_pregnant", math.huge)
end

function Sexbound.Common.Pregnant:removeStatusEffects()
    status.removeEphemeralEffect("sexbound_pregnant")
end

function Sexbound.Common.Pregnant:updateWorldTime()
    self._worldTime = world.day() + world.timeOfDay()
    return self._worldTime
end

function Sexbound.Common.Pregnant:_convertBabyConfigToSpawnableMonster(babyConfig)
    local params = {}
    params.baseParameters = {}
    params.baseParameters.uniqueId = sb.makeUuid()
    params.baseParameters.statusSettings = {}
    params.baseParameters.statusSettings.statusProperties = {
        sexbound_birthday = babyConfig
    }
    params = util.mergeTable(params, babyConfig.birthParams or {})
    return {
        params   = params,
        position = babyConfig.birthPosition or entity.position(),
        type     = babyConfig.birthSpecies  or "gleap"
    }
end

function Sexbound.Common.Pregnant:_convertBabyConfigToSpawnableNPC(babyConfig, babyName)
    local params = {}
    params.scriptConfig = {}
    params.scriptConfig.uniqueId = sb.makeUuid()
    params.statusControllerSettings = {}
    params.statusControllerSettings.statusProperties = {
        sexbound_birthday = babyConfig,
        sexbound_previous_storage = {
            previousDamageTeam = storage.previousDamageTeam
        },
        motherUuid = babyConfig.motherUuid,
        motherName = babyConfig.motherName,
        fatherUuid = babyConfig.fatherUuid,
        fatherName = babyConfig.fatherName
    }
    params.identity = {}
    params.identity.gender = babyConfig.birthGender
    if babyName and babyName ~= "" then params.identity.name = babyName end
    util.mergeTable(params, babyConfig.birthParams or {})
    
    --[[-- Apply genetic color directives
    local bodyDirectives, emoteDirectives, hairDirectives = "", "", ""
    if babyConfig.bodyColor then
        local bodyColorDirectives = "?replace"
        for k,v in pairs(babyConfig.bodyColor) do bodyColorDirectives = bodyColorDirectives..";"..k.."="..v end
        bodyDirectives = bodyColorDirectives
        emoteDirectives = bodyColorDirectives
    end
    
    if babyConfig.hairColor then
        local hairColorDirectives = "?replace"
        for k,v in pairs(babyConfig.hairColor) do hairColorDirectives = hairColorDirectives..";"..k.."="..v end
        hairDirectives = hairColorDirectives
    end
    
    if babyConfig.undyColor then
        local undyColorDirectives = "?replace"
        for k,v in pairs(babyConfig.undyColor) do undyColorDirectives = undyColorDirectives..";"..k.."="..v end
        if bodyDirectives == "" then bodyDirectives = undyColorDirectives else bodyDirectives = bodyDirectives..";"..undyColorDirectives end
        if emoteDirectives == "" then emoteDirectives = undyColorDirectives else emoteDirectives = emoteDirectives..";"..undyColorDirectives end
        if hairDirectives == "" then hairDirectives = undyColorDirectives else hairDirectives = hairDirectives..";"..undyColorDirectives end
    end
    
    if bodyDirectives ~= "" then params.identity.bodyDirectives = bodyDirectives end
    if emoteDirectives ~= "" then params.identity.emoteDirectives = emoteDirectives end
    if hairDirectives ~= "" then params.identity.hairDirectives = hairDirectives end]]
    
    -- Ensure gender-safe hair assignment
    local speciesConfig
    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. (babyConfig.species or "human") .. ".species")
    end) then
        sb.logWarn("SxB: Could not find species config file.")
    end
    
    -- Find relevant gender config
    local genderConfig = nil
    for _index, _gender in ipairs(speciesConfig.genders) do
        if (_gender.name == babyConfig.birthGender) then
            genderConfig = speciesConfig.genders[_index]
            break
        end
    end
    
    if genderConfig then
        -- If gender config was found and hair declaration exists, choose random gender specific hair style for baby
        local hairStyles = genderConfig.hair
        if hairStyles then params.identity.hairType = hairStyles[util.randomIntInRange(1,#hairStyles)] end
    end
    
    local spawnableNPC = {
        level    = babyConfig.birthLevel or 1,
        npcType  = babyConfig.npcType or "crewmembersexbound",
        params   = params,
        position = babyConfig.birthPosition or entity.position(),
        seed     = babyConfig.birthSeed,
        species  = babyConfig.birthSpecies or "human"
    }

    if npc then spawnableNPC.npcType = npc.npcType() end
    if monster then spawnableNPC.npcType = "villager" end

    return spawnableNPC
end

function Sexbound.Common.Pregnant:_giveBirthToHumanoid(babyConfig, babyName)
    local spawnableNPC = self:_convertBabyConfigToSpawnableNPC(babyConfig, babyName)
    return world.spawnNpc(
        spawnableNPC.position,
        spawnableNPC.species,
        spawnableNPC.npcType,
        spawnableNPC.level,
        spawnableNPC.seed,
        spawnableNPC.params
    )
end

function Sexbound.Common.Pregnant:_giveBirthToMonster(babyConfig)
    local spawnableMonster = self:_convertBabyConfigToSpawnableMonster(babyConfig)
    return world.spawnMonster(
        spawnableMonster.type,
        spawnableMonster.position,
        spawnableMonster.params
    )
end

function Sexbound.Common.Pregnant:getConfig()
    return self._config
end

function Sexbound.Common.Pregnant:getData(index)
    if self._parent:canLog("debug") then sb.logInfo("Entity pregnancy data for #"..entity.id()..": "..self:dump(storage.sexbound.pregnant or {})) end
    if index and storage.sexbound.pregnant then
        return storage.sexbound.pregnant[index]
    end
    return storage.sexbound.pregnant
end

function Sexbound.Common.Pregnant:getDataAndConfig(index)
    if self._parent:canLog("debug") then sb.logInfo("Entity pregnancy data for #"..entity.id()..": "..self:dump(storage.sexbound.pregnant or {})) end
    local pregnancies = nil
    local config = self:getConfig()
    if index and storage.sexbound.pregnant then
        pregnancies = storage.sexbound.pregnant[index]
    else pregnancies = storage.sexbound.pregnant end
    
    return {pregnancies = pregnancies, config = config}
end

function Sexbound.Common.Pregnant:getIsPregnant()
    return not isEmpty(storage.sexbound.pregnant)
end

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

function Sexbound.Common.Pregnant:isGivingBirth()
    return self._isGivingBirth
end

function Sexbound.Common.Pregnant:setIsGivingBirth(isGivingBirth)
    self._isGivingBirth = isGivingBirth
end

function Sexbound.Common.Pregnant:getParent()
    return self._parent
end

function Sexbound.Common.Pregnant:getWorldTime()
    return self._worldTime or self:updateWorldTime()
end

function Sexbound.Common.Pregnant:dump(o)
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

--- Baby Class Module.
-- @classmod Baby
-- @author Locuturus
-- @license GNU General Public License v3.0
Baby = {}
Baby_mt = { __index = Baby }

function Baby:new(parent, config)
  input = input or {}

  return setmetatable({
    _parent = parent,
    _config = config,
    _geneCache = {}
  }, Baby_mt)
end

--- Function to create the data of a default SBR baby
--  !This method will be called from the actor side. self._parent will point towards the parent BabyFactory, child of the mother actor's pregnancy plugin, child of the mother actor!
--  !Entity tables such as "player", "npc", "monster" will not be available and "entity" refers to the sexnode object!
function Baby:create(mother, father)
    local baby = {
        birthGender = self:createRandomBirthGender(),
        motherName = mother:getName(),
        motherId = mother:getEntityId(),
        motherUuid = mother:getUniqueId(),
        motherType = mother:getEntityType(),
        motherSpecies = mother:getSpecies(),
        fatherName = father:getName(),
        fatherId = father:getEntityId(),
        fatherUuid = father:getUniqueId(),
        fatherType = father:getEntityType(),
        fatherSpecies = father:getSpecies(),
        generationFertility = mother._config.generationFertility
    }
    
    if baby.motherType == "npc" and baby.fatherType == "npc" then
        local choices = {actor:getType(), daddy:getType()}
        baby.npcType = util.randomChoice(choices)
        baby.generationFertility = baby.generationFertility * (baby.generationFertility / 2)
    else if baby.motherType == "player" or baby.fatherType == "player" then baby.npcType = "crewmembersexbound"
    else baby.npcType = "villager"end
    
    baby.birthEntityGroup, baby.birthSpecies = self:reconcileEntityGroups(mother, father)
    
    local motherBodyColor, motherBodyColorAverage, motherUndyColor, motherUndyColorAverage, motherHairColor, motherHairColorAverage = self._parent:getGenes()
    local fatherBodyColor, fatherBodyColorAverage, fatherUndyColor, fatherUndyColorAverage, fatherHairColor, fatherHairColorAverage = otherActor:getGenes()
    local bodyColorPool, bodyColorPoolAverage, undyColorPool, undyColorPoolAverage, hairColorPool, hairColorPoolAverage
    if baby.birthEntityGroup ~= "humanoid" then return baby end -- no need to waste time on colors for monsters
    if baby.birthSpecies == mother:getSpecies() then bodyColorPool, bodyColorPoolAverage, undyColorPool, undyColorPoolAverage, hairColorPool, hairColorPoolAverage = self._parent:getGenePool() -- Baby is same species as mother - load species gene pool from cache
    elseif baby.birthSpecies == father:getSpecies() then bodyColorPool, bodyColorPoolAverage, undyColorPool, undyColorPoolAverage, hairColorPool, hairColorPoolAverage = otherActor:getGenePool() -- Baby is same species as father - load species gene pool from cache
    else
        -- Baby is third species - load species file and extract color gene pool
        if self._geneCache[baby.birthSpecies] == nil then self:fetchGenes(baby.birthSpecies) end
        if self._geneCache[baby.birthSpecies] == false then return baby end -- Genetic color data could not be fetched for this species - abort genetics and return current baby
        bodyColorPool = self._geneCache[baby.birthSpecies].bodyColorPool
        bodyColorPoolAverage = self._geneCache[baby.birthSpecies].bodyColorPoolAverage
        undyColorPool = self._geneCache[baby.birthSpecies].undyColorPool
        undyColorPoolAverage = self._geneCache[baby.birthSpecies].undyColorPoolAverage
        hairColorPool = self._geneCache[baby.birthSpecies].hairColorPool
        hairColorPoolAverage = self._geneCache[baby.birthSpecies].hairColorPoolAverage
    end
    
    -- Map parent color themes to target space
    local motherBodyIndex, d11 = self._parent:findClosestColorAverageGene(bodyColorPoolAverage, motherBodyColorAverage)
    local fatherBodyIndex, d21 = self._parent:findClosestColorAverageGene(bodyColorPoolAverage, fatherBodyColorAverage)
    local motherUndyIndex, d12 = self._parent:findClosestColorAverageGene(undyColorPoolAverage, motherUndyColorAverage)
    local fatherUndyIndex, d22 = self._parent:findClosestColorAverageGene(undyColorPoolAverage, fatherUndyColorAverage)
    local motherHairIndex, d13 = self._parent:findClosestColorAverageGene(hairColorPoolAverage, motherHairColorAverage)
    local fatherHairIndex, d23 = self._parent:findClosestColorAverageGene(hairColorPoolAverage, fatherHairColorAverage)
    
    -- Generate crossed colors for baby
    math.randomseed(os.time())
    local bodyColorLambda = Sexbound.Util.normalDist()
    local undyColorLambda = Sexbound.Util.normalDist()
    local hairColorLambda = Sexbound.Util.normalDist()
    
    local babyBodyColor = nil
    if bodyColorPool[motherBodyIndex] ~= "" then
        babyBodyColor = {}
        for i,v in pairs(bodyColorPool[motherBodyIndex]) do
            babyBodyColor[i] = Sexbound.Util.rgbToHex(self._parent:crossfade({Sexbound.Util.hexToRgb(v)}, {Sexbound.Util.hexToRgb(bodyColorPool[fatherBodyIndex][i])}, bodyColorLambda))
        end
    end
    local babyUndyColor = nil
    if undyColorPool[motherUndyIndex] ~= "" then
        babyUndyColor = {}
        for i,v in pairs(undyColorPool[motherundyIndex]) do
            babyUndyColor[i] = Sexbound.Util.rgbToHex(self._parent:crossfade({Sexbound.Util.hexToRgb(v)}, {Sexbound.Util.hexToRgb(undyColorPool[fatherUndyIndex][i])}, undyColorLambda))
        end
    end
    local babyHairColor = nil
    if hairColorPool[motherHairIndex] ~= "" then
        babyHairColor = {}
        for i,v in pairs(hairColorPool[motherHairIndex]) do
            babyHairColor[i] = Sexbound.Util.rgbToHex(self._parent:crossfade({Sexbound.Util.hexToRgb(v)}, {Sexbound.Util.hexToRgb(hairColorPool[fatherHairIndex][i])}, hairColorLambda))
        end
    end
    
    baby.bodyColor = babyBodyColor
    baby.undyColor = babyUndyColor
    baby.hairColor = babyHairColor
    
    sb.logInfo("Generated baby colors:")
    sb.logInfo("Body "..motherBodyIndex.." x "..fatherBodyIndex.." - "..Sexbound.Util.dump(baby.bodyColor))
    sb.logInfo("Undy "..motherUndyIndex.." x "..fatherUndyIndex.." - "..Sexbound.Util.dump(baby.undyColor))
    sb.logInfo("Hair "..motherHairIndex.." x "..fatherHairIndex.." - "..Sexbound.Util.dump(baby.hairColor))
    
    return baby
end

--- Function to give birth to a default SBR baby
--  !This method will be called from the mother entity upon giving birth. self._parent will point towards the mother entity's pregnancy plugin, child of the mother entity!
--  !Entity tables like "player", "npc", "monster" are available for this and every subsequently called function!
function Baby:birth(babyConfig, babyName)
    babyConfig.birthEntityGroup = babyConfig.birthEntityGroup or "humanoid"

    if babyConfig.birthEntityGroup == "monsters" then
        return self:_giveBirthToMonster(babyConfig)
    else
        return self:_giveBirthToHumanoid(babyConfig, babyName)
    end
end

--- Fetch - if possible - and cache the genetic data of a new species
function Baby:fetchGenes(species)
    local speciesConfig = {}
        
    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. species .. ".species")
    end) then
        sb.logWarn("SxB: Could not find species config file for "..species..".")
        self._geneCache[species] = false
        return -- No species file. Abort further genetics.
    end
    
    bodyColorPool = speciesConfig.bodyColor or {}
    bodyColorPoolAverage = {}
    undyColorPool = speciesConfig.undyColor or {}
    undyColorPoolAverage = {}
    hairColorPool = speciesConfig.hairColor or {}
    hairColorPoolAverage = {}
    
    -- Pre calculate color palette averages
    for i,r in ipairs(bodyColorPool) do
        if type(r) ~= "table" then break end
        local x = 0
        local avg = {0,0,0}
        local dist = 0
        -- Get average color of current checked palette from list
        for j,v in pairs(r) do
            x = x + 1
            local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
            avg[1],avg[2],avg[3] = avg[1]+r,avg[2]+g,avg[3]+b
        end
        avg[1],avg[2],avg[3] = math.floor(avg[1]/x),math.floor(avg[2]/x),math.floor(avg[3]/x)
        table.insert(bodyColorPoolAverage, avg)
    end
    for i,r in ipairs(undyColorPool) do
        if type(r) ~= "table" then break end
        local x = 0
        local avg = {0,0,0}
        local dist = 0
        -- Get average color of current checked palette from list
        for j,v in pairs(r) do
            x = x + 1
            local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
            avg[1],avg[2],avg[3] = avg[1]+r,avg[2]+g,avg[3]+b
        end
        avg[1],avg[2],avg[3] = math.floor(avg[1]/x),math.floor(avg[2]/x),math.floor(avg[3]/x)
        table.insert(undyColorPoolAverage, avg)
    end
    for i,r in ipairs(hairColorPool) do
        if type(r) ~= "table" then break end
        local x = 0
        local avg = {0,0,0}
        local dist = 0
        -- Get average color of current checked palette from list
        for j,v in pairs(r) do
            x = x + 1
            local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
            avg[1],avg[2],avg[3] = avg[1]+r,avg[2]+g,avg[3]+b
        end
        avg[1],avg[2],avg[3] = math.floor(avg[1]/x),math.floor(avg[2]/x),math.floor(avg[3]/x)
        table.insert(hairColorPoolAverage, avg)
    end
    
    self._geneCache[species] = {
        bodyColorPool = bodyColorPool,
        bodyColorPoolAverage = bodyColorPoolAverage,
        undyColorPool = undyColorPool,
        undyColorPoolAverage = undyColorPoolAverage,
        hairColorPool = hairColorPool,
        hairColorPoolAverage = hairColorPoolAverage
    }
end

--- Reconciles differences between this actor and the other actor
function Baby:reconcileEntityGroups(mother, father)
    local geneticTable = self._config.geneticTable or {}
    local species = mother:getSpecies()
    local otherSpecies = father:getSpecies()
    if geneticTable[species] and geneticTable[species][otherSpecies] then return geneticTable[species][otherSpecies][2], geneticTable[species][otherSpecies][1] end -- Defined cross-breed species.
    
    if mother:getEntityGroup() == "humanoid" and father:getEntityGroup() == "humanoid" then
        return "humanoid", self:generateBirthSpecies(mother, father)
    end

    if mother:getEntityGroup() == "monsters" and father:getEntityGroup() == "monsters" then
        return "monsters", self:generateBirthSpecies(mother, father)
    end

    if mother:getEntityGroup() == "monsters" then
        return "monsters", species
    end

    if father:getEntityGroup() == "monsters" then
        return "monsters", otherSpecies
    end
    
    -- Backup: Just copy mother
    return mother:getEntityGroup(), mother:getSpecies()
end

-- Returns a random species name based on the species of the parents
function Baby:generateBirthSpecies(mother, father)
    local actor1Species = mother:getSpecies() or "human"
    local actor2Species = father:getSpecies() or actor1Species
    if actor2Species == "sexbound_tentacleplant_v2" then return actor1Species end
    return util.randomChoice({actor1Species, actor2Species})
end

-- HELPER FUNCTIONS --
function Baby:_convertBabyConfigToSpawnableMonster(babyConfig)
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

function Baby:_convertBabyConfigToSpawnableNPC(babyConfig, babyName)
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
        fatherName = babyConfig.fatherName,
        generationFertility = babyConfig.generationFertility,
        fertilityPenalty = babyConfig.generationFertility,
        kid = 840*5 --5 days of being a kid
    }
    params.identity = {}
    params.identity.gender = babyConfig.birthGender
    if babyName and babyName ~= "" then params.identity.name = babyName end
    util.mergeTable(params, babyConfig.birthParams or {})
    
    local speciesConfig = nil
    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. (babyConfig.birthSpecies or "human") .. ".species")
    end) then
        sb.logWarn("SxB: Could not find species config file for baby - species "..(babyConfig.birthSpecies or "human"))
    end
    
    if speciesConfig then
        -- Apply genetic color directives
        local bodyDirectives, emoteDirectives, hairDirectives, facialHairDirectives, facialMaskDirectives = "", "", "", "", ""
        local bodyColorPalette, hairColorPalette, undyColorPalette = "", "", ""
        local bodyColor, hairColor, altColor, facialHairColor, facialMaskColor = "", "", "", "", ""
        
        local altOptionAsUndyColor = not not speciesConfig.altOptionAsUndyColor
        local headOptionAsHairColor = not not speciesConfig.headOptionAsHairColor
        local altOptionAsHairColor = not not speciesConfig.altOptionAsHairColor
        local hairColorAsBodySubColor = not not speciesConfig.hairColorAsBodySubColor
        local headOptionAsFacialhair = not not speciesConfig.headOptionAsFacialhair
        local altOptionAsFacialMask = not not speciesConfig.altOptionAsFacialMask
        local bodyColorAsFacialMaskSubColor = not not speciesConfig.bodyColorAsFacialMaskSubColor
        local altColorAsFacialMaskSubColor = not not speciesConfig.altColorAsFacialMaskSubColor
        
        if babyConfig.bodyColor then
            local bodyColorPalette = "?replace"
            for k,v in pairs(babyConfig.bodyColor) do bodyColorPalette = bodyColorPalette..";"..k.."="..v end
        end
        
        if babyConfig.hairColor then
            local hairColorPalette = "?replace"
            for k,v in pairs(babyConfig.hairColor) do hairColorPalette = hairColorPalette..";"..k.."="..v end
        end
        
        if babyConfig.undyColor then
            local undyColorPalette = "?replace"
            for k,v in pairs(babyConfig.undyColor) do undyColorPalette = undyColorPalette..";"..k.."="..v end
        end
        
        -- Build directives like Starbound does
        bodyDirectives = bodyColor
        if altOptionAsUndyColor then altColor = undyColorPalette
        hairColor = bodyColor
        if headOptionAsHairColor then
            hairColor = hairColorPalette
            if altOptionAsHairColor then hairColor = hairColor..undyColorPalette end
        end
        if hairColorAsBodySubColor then bodyColor = bodyColor..hairColor end
        if headOptionAsFacialhair then facialHairColor = hairColor end
        if bodyColorAsFacialMaskSubColor then facialMaskColor = facialMaskColor..bodyColor end
        if altColorAsFacialMaskSubColor then facialMaskColor = facialMaskColor..altColor end
        
        bodyDirectives = bodyColor..altColor
        emoteDirectives = bodyColor..altColor
        hairDirectives = hairColor
        facialHairDirectives = facialHairColor
        facialMaskDirectives = facialMaskColor
        
        -- Finalize
        if bodyDirectives ~= "" then params.identity.bodyDirectives = bodyDirectives end
        if emoteDirectives ~= "" then params.identity.emoteDirectives = emoteDirectives end
        if hairDirectives ~= "" then params.identity.hairDirectives = hairDirectives end
        if facialHairDirectives ~= "" then params.identity.facialHairDirectives = facialHairDirectives end
        if facialMaskDirectives ~= "" then params.identity.facialMaskDirectives = facialMaskDirectives end
        
        -- Ensure gender-safe hair assignment
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
            if hairStyles then params.identity.hairType = hairStyles[util.randomIntInRange({1,#hairStyles})] end
        end
    end
    
    local spawnableNPC = {
        level    = babyConfig.birthLevel or 1,
        npcType  = babyConfig.npcType or "crewmembersexbound",
        params   = params,
        position = babyConfig.birthPosition or entity.position(),
        seed     = babyConfig.birthSeed,
        species  = babyConfig.birthSpecies or "human"
    }

    return spawnableNPC
end

function Baby:_giveBirthToHumanoid(babyConfig, babyName)
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

function Baby:_giveBirthToMonster(babyConfig)
    local spawnableMonster = self:_convertBabyConfigToSpawnableMonster(babyConfig)
    return world.spawnMonster(
        spawnableMonster.type,
        spawnableMonster.position,
        spawnableMonster.params
    )
end
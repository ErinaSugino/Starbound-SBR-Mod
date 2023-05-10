--- BabyFactory Class Module.
-- @classmod BabyFactory
-- @author Locuturus
-- @license GNU General Public License v3.0
BabyFactory = {}
BabyFactory_mt = {
    __index = BabyFactory
}

--- Instantiates a new instance of BabyFactory.
-- @param parent
-- @param config
function BabyFactory:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, BabyFactory_mt)
    
    _self._lengthOfWorldDay = 840
    _self._secondsInOneDay = 86400

    return _self
end

function BabyFactory:make(daddy)
    local actor = self:getParent():getParent()

    local baby = {
        birthGender = self:createRandomBirthGender(),
        birthTime = self:createRandomBirthTime(),
        motherName = actor:getIdentity("name"),
        motherId = actor:getEntityId(),
        motherUuid = actor:getUniqueId(),
        motherType = actor:getEntityType(),
        motherSpecies = actor:getSpecies(),
        fatherName = daddy:getName(),
        fatherId = daddy:getEntityId(),
        fatherUuid = daddy:getUniqueId(),
        fatherType = daddy:getEntityType(),
        fatherSpecies = daddy:getSpecies(),
        generationFertility = actor._config.generationFertility
    }

    if baby.motherType == "player" then
        -- Player mothers get the actual fertilization delayed for realistic immersion purposes
        -- They also progress the pregnancy based on script time, meaning their birth timings are a countdown
        baby.birthWorldTime, baby.dayCount = self:createRandomPlayerBirthTime()
        baby.birthWorldTime = baby.birthWorldTime + (self._lengthOfWorldDay * baby.birthTime)
        baby.fullBirthWorldTime = baby.birthWorldTime
        baby.delay = self:createImpregnationDelay()
    else
        -- NPC mothers don't get a delay, as it is not necessary in any way (and they don't have script time mechanics by default)
        -- They also have their birth time bound to the actual world's time like before, because they are supposed to stay there and need to "progress" while unloaded
        baby.birthDate, baby.dayCount = self:createRandomBirthDate()
        baby.birthWorldTime = baby.birthDate + baby.birthTime
        baby.fullBirthWorldTime = world.day()
        baby.delay = 0
    end
    baby.birthOSTime = os.time() + (baby.dayCount * self._secondsInOneDay) + (baby.birthTime * self._secondsInOneDay)
    baby.fullBirthOSTime = os.time()
    
    if baby.motherType == "npc" and baby.fatherType == "npc" then
        local choices = {actor:getType(), daddy:getType()}
        baby.npcType = util.randomChoice(choices)
        baby.generationFertility = baby.generationFertility * (baby.generationFertility / 2)
    end

    return baby
end

--- Returns a random birth gender.
-- @return birthGender
function BabyFactory:createRandomBirthGender()
    -- Futanari?

    return util.randomChoice({"male", "female"})
end

--- Returns a random birth date and day count.
-- @return birthDate, dayCount
function BabyFactory:createRandomBirthDate()
    local config = self:getParent():getConfig()

    local trimesterCount = util.randomIntInRange(config.trimesterCount or 3)
    local trimesterLength = config.trimesterLength or {5, 8}

    local dayCount = 0

    for i = 1, trimesterCount do
        dayCount = dayCount + util.randomIntInRange(trimesterLength)
    end

    return (world.day() + dayCount), dayCount
end

--- Returns a random birth time
-- @return birthTime
function BabyFactory:createRandomBirthTime()
    return util.randomInRange({0.0, 1.0})
end

--- Returns a random birth time and day count for in-game time measurement
-- @return birthTime, dayCount
function BabyFactory:createRandomPlayerBirthTime()
    local config = self:getParent():getConfig()
    
    local trimesterCount = util.randomIntInRange(config.trimesterCount or 3)
    local trimesterLength = config.trimesterLength or {5, 8}
    
    local dayCount = 0
    
    for i = 1, trimesterCount do
        dayCount = dayCount + util.randomIntInRange(trimesterLength)
    end
    
    return (self._lengthOfWorldDay * dayCount), dayCount
end

--- Returns a random time representing the delay between the climax and the actual impregnation happening
-- @return delay
function BabyFactory:createImpregnationDelay()
    return util.randomInRange({60, 180})
end

--- Returns the index in a given list of color palette where there is a the smallest color distance to a target palette
-- @param list
-- @param target
-- @optional threshhold
-- @return index, totalDistance
function BabyFactory:findClosestColorGene(list, target, threshhold)
    threshhold = threshhold or 5
    local targetColor = {0,0,0}
    local x = 0
    -- Get average color of target palette in RGB
    for i,v in pairs(target) do
        x = x + 1
        local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
        targetColor[1] = targetColor[1] + r
        targetColor[2] = targetColor[2] + g
        targetColor[3] = targetColor[3] + b
    end
    targetColor[1] = math.floor(targetColor[1] / x)
    targetColor[2] = math.floor(targetColor[2] / x)
    targetColor[3] = math.floor(targetColor[3] / x)
    
    local totalDist = 0
    local index = 1
    for i,r in ipairs(list) do
        x = 0
        local compColor = {0,0,0}
        local dist = 0
        -- Get average color of current checked palette from list
        for j,v in pairs(r) do
            x = x + 1
            local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
            compColor[1] = compColor[1] + r
            compColor[2] = compColor[2] + g
            compColor[3] = compColor[3] + b
        end
        compColor[1] = math.floor(compColor[1] / x)
        compColor[2] = math.floor(compColor[2] / x)
        compColor[3] = math.floor(compColor[3] / x)
        
        -- Determine RGB color distance between target average and current average
        -- Store smallest distance index
        dist = math.sqrt((targetColor[1]-compColor[1])^2 + (targetColor[2]-compColor[2])^2 + (targetColor[3]-compColor[3])^2)
        if dist <= threshhold then return i, dist end -- Early termination condition for more than accurate enough hits
        if dist < totalDist or totalDist == 0 then totalDist = dist index = i end
    end
    return index, totalDist
end

---Same as findClosestColorGene, but takes precalculated color averages for each palette
function BabyFactory:findClosestColorAverageGene(list, targetColor, threshhold)
    threshhold = threshhold or 5
    
    local totalDist = 0
    local index = 1
    for i,compColor in ipairs(list) do
        -- Determine RGB color distance between target average and current average
        -- Store smallest distance index
        local dist = math.sqrt((targetColor[1]-compColor[1])^2 + (targetColor[2]-compColor[2])^2 + (targetColor[3]-compColor[3])^2)
        if dist <= threshhold then return i, dist end -- Early termination condition for more than accurate enough hits
        if dist < totalDist or totalDist == 0 then totalDist = dist index = i end
    end
    return index, totalDist
end

--- Returns a list of numbers where every value has been mixed between input list a and b with Lambda coefficient l
-- @param colorA
-- @param colorB
-- @param lambda
-- @return colorC
function BabyFactory:crossfade(a,b,l)
    local r = {}
    for i=1,#a do
        r[i] = math.floor((a[i] * (1-l) + b[i] * l) + 0.5)
    end
    return r
end

--- Returns a reference to the parent object
function BabyFactory:getParent()
    return self._parent
end
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
function BabyFactory:new(parent, config)
    local _self = setmetatable({
        _parent = parent,
        _config = config
    }, BabyFactory_mt)
    
    _self._lengthOfWorldDay = 840
    _self._secondsInOneDay = 86400

    return _self
end

function BabyFactory:make(actor, daddy)
    local motherSpecies = actor:getSpecies()
    local fatherSpecies = daddy:getSpecies()
    local geneticTable = self._config.geneticTable or {}
    local pregnancyTypes = self._config.pregnancyType or {}
    
    local pregnancyType = (pregnancyTypes[motherSpecies] or {})[fatherSpecies] or "baby"
    
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
        babyClass = _ENV[ucPregnancyType]:new(self, self._config)
    end)
    if not r then
        -- Can't load = can't generate baby = no pregnancy; abort
        sb.logError("SxB: Could not load baby class \""..pregnancyType.."\" - aborting pregnancy generation.")
        sb.logError("Error: "..tostring(err))
        return nil
    end
    
    local pregnancy = {
        pregnancyType = pregnancyType,
        babies = {},
        birthTime = self:createRandomBirthTime()
    }
    
    -- Apply pregnancy timings
    if actor:getEntityType() == "player" then
        -- Player mothers get the actual fertilization delayed for realistic immersion purposes
        -- They also progress the pregnancy based on script time, meaning their birth timings are a countdown
        pregnancy.birthWorldTime, pregnancy.dayCount = self:createRandomPlayerBirthTime()
        pregnancy.birthWorldTime = pregnancy.birthWorldTime + (self._lengthOfWorldDay * pregnancy.birthTime)
        pregnancy.fullBirthWorldTime = pregnancy.birthWorldTime
        pregnancy.delay = self:createImpregnationDelay()
    else
        -- NPC mothers don't get a delay, as it is not necessary in any way (and they don't have script time mechanics by default)
        -- They also have their birth time bound to the actual world's time like before, because they are supposed to stay there and need to "progress" while unloaded
        pregnancy.birthDate, pregnancy.dayCount = self:createRandomBirthDate()
        pregnancy.birthWorldTime = pregnancy.birthDate + pregnancy.birthTime
        pregnancy.fullBirthWorldTime = world.day()
        pregnancy.delay = 0
    end
    pregnancy.birthOSTime = os.time() + (pregnancy.dayCount * self._secondsInOneDay) + (pregnancy.birthTime * self._secondsInOneDay)
    pregnancy.fullBirthOSTime = os.time()
    
    local nextBaby, babyCount = true, 0
    while nextBaby and babyCount < (self._config.multiPregnancyLimit or 3) do
        r,err = pcall(function()
            table.insert(pregnancy.babies, babyClass:create(actor, daddy))
            babyCount = babyCount + 1
            nextBaby = math.random() <= (self._config.multiPregnancyChance or 0.1)
        end)
        if not r then
            sb.logError("SxB: Baby generation errored! Aborting further generation.")
            sb.logError("Error: "..tostring(err))
            nextBaby = false
        end
    end
    if babyCount <= 0 then return nil end -- No babies? No pregnancy!
    pregnancy.babyCount = babyCount

    return pregnancy
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
    local pregnancyLength = self._config.pregnancyLength or {6, 9}
    
    local dayCount = util.randomIntInRange(pregnancyLength)

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
    local pregnancyLength = self._config.pregnancyLength or {6, 9}
    
    local dayCount = util.randomIntInRange(pregnancyLength)
    
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

--- Return a reference to the factory's config
function BabyFactory:getConfig()
    return self._config
end
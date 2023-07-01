Sexbound.Common.Identity = {}
Sexbound.Common.Identity_mt = {
    __index = Sexbound.Common.Identity
}

function Sexbound.Common.Identity:new(parent)
    return setmetatable({
        _parent = parent
    }, Sexbound.Common.Identity_mt)
end

function Sexbound.Common.Identity:init(parent)
    self._parent = parent
end

function Sexbound.Common.Identity:addCustomProperties(identity, speciesConfig)
    speciesConfig = speciesConfig or {}

    local genderId = self:getGenderId(speciesConfig, identity.gender)
    local genderConfig = speciesConfig.genders[genderId]

    identity.facialHairGroup = genderConfig.facialHairGroup or ""
    identity.facialMaskGroup = genderConfig.facialMaskGroup or ""
    identity.sxbFertility = genderConfig.sxbFertility or nil
    identity.sxbMoanPitch = genderConfig.sxbMoanPitch or {1.0, 1.0}
    identity.sxbMoanInterval = genderConfig.sxbMoanInterval or {2.0, 4.0}
    identity.sxbMoanSounds = genderConfig.sxbMoanSounds or nil
    identity.sxbOrgasmPitch = genderConfig.sxbOrgasmPitch or {1.0, 1.0}
    identity.sxbOrgasmInterval = genderConfig.sxbOrgasmInterval or {2.0, 4.0}
    identity.sxbOrgasmSounds = genderConfig.sxbOrgasmSounds or nil
    identity.sxbSubGender = genderConfig.sxbSubGender or nil
    identity.sxbSubGenderMultiplier = genderConfig.sxbSubGenderMultiplier or 1
    identity.sxbShowNipples = genderConfig.sxbShowNipples or false
    identity.sxbGenitalType = genderConfig.sxbGenitalType or nil
    identity.sxbBodyType = genderConfig.sxbBodyType or nil
    identity.sxbSpeciesType = speciesConfig.sxbSpeciesType or nil
    identity.sxbNaturalStatus = genderConfig.sxbNaturalStatus or {}

    if genderConfig.sxbCanOvulate ~= nil then
        identity.sxbCanOvulate = genderConfig.sxbCanOvulate
    end

    if genderConfig.sxbCanProduceSperm ~= nil then
        identity.sxbCanProduceSperm = genderConfig.sxbCanProduceSperm
    end

    identity.motherUuid = status.statusProperty("motherUuid", nil)
    identity.fatherUuid = status.statusProperty("fatherUuid", nil)
    
    -- Cache species genetic templates
    identity.genetics = {}
    identity.genetics.bodyColorPool = speciesConfig.bodyColor or {}
    identity.genetics.bodyColorPoolAverage = {}
    identity.genetics.undyColorPool = speciesConfig.undyColor or {}
    identity.genetics.undyColorPoolAverage = {}
    identity.genetics.hairColorPool = speciesConfig.hairColor or {}
    identity.genetics.hairColorPoolAverage = {}
    
    -- Pre calculate color palette averages
    for i,r in ipairs(identity.genetics.bodyColorPool) do
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
        table.insert(identity.genetics.bodyColorPoolAverage, avg)
    end
    for i,r in ipairs(identity.genetics.undyColorPool) do
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
        table.insert(identity.genetics.undyColorPoolAverage, avg)
    end
    for i,r in ipairs(identity.genetics.hairColorPool) do
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
        table.insert(identity.genetics.hairColorPoolAverage, avg)
    end

    return identity
end

--- Returns a filtered string. Used to filter desired data out of directive strings.
-- @param image
function Sexbound.Common.Identity:filterReplace(image)
    if (string.find(image, "?addmask")) then
        if (string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')) then
            return string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')
        else
            return string.match(image, '^.*(%?replace.*)%?addmask.-$')
        end
    else
        if (string.match(image, '^.*(%?replace.*%?replace.*)')) then
            return string.match(image, '^.*(%?replace.*%?replace.*)')
        else
            return string.match(image, '^.*(%?replace.*)')
        end
    end
end

function Sexbound.Common.Identity:getGenderId(speciesConfig, gender)
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

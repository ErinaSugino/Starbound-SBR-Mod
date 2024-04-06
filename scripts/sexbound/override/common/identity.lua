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
    identity.sxbSubGender = genderConfig.sxbSubGender or nil
    identity.sxbSubGenderMultiplier = genderConfig.sxbSubGenderMultiplier or 1
    identity.sxbShowNipples = genderConfig.sxbShowNipples or false
    identity.sxbGenitalType = genderConfig.sxbGenitalType or nil
    identity.sxbBodyType = genderConfig.sxbBodyType or nil
    identity.sxbSpeciesType = speciesConfig.sxbSpeciesType or nil
    identity.sxbNaturalStatus = genderConfig.sxbNaturalStatus or {}
    identity.sxbUseAnimatedEars = speciesConfig.sxbUseAnimatedEars or nil
    identity.sxbUseAnimatedTail = speciesConfig.sxbUseAnimatedTail or nil

    if genderConfig.sxbCanOvulate ~= nil then
        identity.sxbCanOvulate = genderConfig.sxbCanOvulate
    end

    if genderConfig.sxbCanProduceSperm ~= nil then
        identity.sxbCanProduceSperm = genderConfig.sxbCanProduceSperm
    end
    
    identity.actorOffset = speciesConfig.actorOffset or nil

    identity.motherUuid = status.statusProperty("motherUuid", nil)
    identity.fatherUuid = status.statusProperty("fatherUuid", nil)

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

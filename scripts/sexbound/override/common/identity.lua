--- Abstract shared entity identity builder class
--- @class Sexbound.Common.Identity
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
Sexbound.Common.Identity = {}
Sexbound.Common.Identity_mt = {
    __index = Sexbound.Common.Identity
}

--- Creates a new entity identity builder instance
--- @return Sexbound.Common.Identity # The newly created entity identity builder instance
function Sexbound.Common.Identity:new()
    return setmetatable({}, Sexbound.Common.Identity_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Identity:init(parent)
    self._parent = parent
end

--- Adds all Sexbound actor relevant identity data
--- @param identity table The pre-built entity-specific identity data
--- @param speciesConfig table The species config data
--- @return table # The expanded identity table
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
    identity.sxbUseAnimatedEars = speciesConfig.sxbUseAnimatedEars or false
    identity.sxbEarsUseBodyColors = speciesConfig.sxbEarsUseBodyColors or false
    identity.sxbEarsOnBodyLayer = speciesConfig.sxbEarsOnBodyLayer or false
    identity.sxbUseAnimatedTail = speciesConfig.sxbUseAnimatedTail or false

    if genderConfig.sxbCanOvulate ~= nil then
        identity.sxbCanOvulate = genderConfig.sxbCanOvulate
    end

    if genderConfig.sxbCanProduceSperm ~= nil then
        identity.sxbCanProduceSperm = genderConfig.sxbCanProduceSperm
    end

    identity.actorOffset = speciesConfig.actorOffset or nil

    identity.motherUuid = status.statusProperty("motherUuid", nil)
    identity.fatherUuid = status.statusProperty("fatherUuid", nil)

    identity.genetics = {}

    return identity
end

--- Returns a filtered string. Used to filter desired data out of directive strings.
--- @param image string The image file path string
--- @return string # The filtered string
function Sexbound.Common.Identity:filterReplace(image)
    if (string.find(image, "?addmask")) then
        return string.match(image, '^.-(%?replace.*)%?addmask.-$')
    else
        return string.match(image, '^.-(%?replace.*)')
    end
end

--- comment
--- @param speciesConfig table The species config JSON
--- @param gender string The gender to find ("male" or "female")
--- @return integer # The index of where the gender's species data is
function Sexbound.Common.Identity:getGenderId(speciesConfig, gender)
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

--- Placeholder build function. To be implemented by child classes
--- @return table # The identity data
function Sexbound.Common.Identity:build() return {} end

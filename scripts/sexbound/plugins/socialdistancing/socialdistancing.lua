if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

--- Sexbound.Actor.SocialDistancing Class Module.
--- @class Sexbound.Actor.SocialDistancing: Sexbound.Actor.Plugin
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field private _socialDistancingMaskName string
Sexbound.Actor.SocialDistancing = Sexbound.Actor.Plugin:new()
Sexbound.Actor.SocialDistancing_mt = {
    __index = Sexbound.Actor.SocialDistancing
}

--- Instantiates a new instance of SocialDistancing.
--- @param parent Sexbound.Actor The calling parent actor instance
--- @param config table The plugin config
--- @return Sexbound.Actor.SocialDistancing # The newly created plugin instance
function Sexbound.Actor.SocialDistancing:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "SODI",
        _config = config,
        _socialDistancingMaskName = "socialdistancinghead"
    }, Sexbound.Actor.SocialDistancing_mt)

    _self:validateConfig()
    _self:init(parent, self._logPrefix)
    _self:tryReplaceHeadwearForThisActor()
    _self:tryLockingHeadwear()

    return _self
end

--- Replaces the headwear apparel item with the mask item
function Sexbound.Actor.SocialDistancing:replaceHeadwearForThisActor()
    local config = self:getSocialDistancingMaskConfig()
    local apparel = self:getParent():getApparel()

    if self:getConfig().enableMultipleColors == true then
        config.colors = self:getRandomSurgicalMaskColors()
    else
        config.colors = self:getDefaultMaskColors()
    end

    apparel:setItemConfig("headwear", config)

    self:getParent():getParent():resetAllActors()
end

--- Safely replaced the headwear apparel item with the mask item
function Sexbound.Actor.SocialDistancing:tryReplaceHeadwearForThisActor()
    if self:thisActorIsAlreadyWearingAMask() then
        return
    end

    self:replaceHeadwearForThisActor()
end

--- Safely tries to lock the headwear apparel
function Sexbound.Actor.SocialDistancing:tryLockingHeadwear()
    if self:getConfig().enableHeadwearLocking then
        self:getParent():getApparel():setIsLocked("headwear", true)
    end
end

--- Returns whethere or not this actor is already wearing the mask apparel
--- @return boolean # Whethere or not the actor is already wearing the mask apparel
function Sexbound.Actor.SocialDistancing:thisActorIsAlreadyWearingAMask()
    return self:getParent():getStatus():hasOneOf({"equipped_surgicalmask"})
end

--- Returns the item config of the mask apparel
--- @return table<string, any> # The assembled mask item config
function Sexbound.Actor.SocialDistancing:getSocialDistancingMaskConfig()
    return {
        addStatus = {"equipped_surgicalmask"},
        image = "/items/armors/decorative/costumes/socialdistancing/head.png",
        mask = "/items/armors/decorative/costumes/socialdistancing/mask.png"
    }
end

--- Returns an item spawn descriptor for the mask apparel
--- @return table<string, any> # The item descriptor for the mask apparel
function Sexbound.Actor.SocialDistancing:getItemDescriptorForSurgicalMask()
    return {
        parameters = {},
        name = self._socialDistancingMaskName,
        count = 1
    }
end

--- Returns the item config for the mask item
--- @return table # The mask item's JSON config
function Sexbound.Actor.SocialDistancing:getItemConfigForSurgicalMask()
    return root.itemConfig(self:getItemDescriptorForSurgicalMask())
end

--- Returns the default color palette of the mask item
--- @return table<string, string> # The color palette
function Sexbound.Actor.SocialDistancing:getDefaultMaskColors()
    return self:getItemConfigForSurgicalMask().config.colorOptions[1]
end

--- Returns a random color palette of the mask item
--- @return table<string, string> # A random color palette
function Sexbound.Actor.SocialDistancing:getRandomSurgicalMaskColors()
    return util.randomChoice(self:getItemConfigForSurgicalMask().config.colorOptions)
end

--- Validates the given plugin config
function Sexbound.Actor.SocialDistancing:validateConfig()
    self:validateEnableMultipleColors(self._config.enableMultipleColors)
    self:validateEnableHeadwearLocking(self._config.enableHeadwearLocking)
end

--- Ensures enableHeadwearLocking is set to an allowed value
--- @param value any The supplied value
function Sexbound.Actor.SocialDistancing:validateEnableHeadwearLocking(value)
    if type(value) ~= "boolean" then
        self._config.enableHeadwearLocking = true
        return
    end

    self._config.enableHeadwearLocking = value
end

--- Ensures enableMultipleColors is set to an allowed value
--- @param value any The supplied value
function Sexbound.Actor.SocialDistancing:validateEnableMultipleColors(value)
    if type(value) ~= "boolean" then
        self._config.enableMultipleColors = false
        return
    end

    self._config.enableMultipleColors = value
end

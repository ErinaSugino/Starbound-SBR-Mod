--- Sexbound.Actor.Apparel Class Module.
--- @class Sexbound.Actor.Apparel
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _item table<string, Sexbound.Actor.Apparel.Abstract>
Sexbound.Actor.Apparel = {}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/apparel/backwear.lua")
    require("/scripts/sexbound/lib/sexbound/actor/apparel/chestwear.lua")
    require("/scripts/sexbound/lib/sexbound/actor/apparel/groinwear.lua")
    require("/scripts/sexbound/lib/sexbound/actor/apparel/headwear.lua")
    require("/scripts/sexbound/lib/sexbound/actor/apparel/legswear.lua")
    require("/scripts/sexbound/lib/sexbound/actor/apparel/nippleswear.lua")
end

Sexbound.Actor.Apparel_mt = {
    __index = Sexbound.Actor.Apparel
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor Calling parent actor instance
--- @return Sexbound.Actor.Apparel # Newly created apparel manager instance
function Sexbound.Actor.Apparel:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Actor.Apparel_mt)

    _self._item = {}
    _self._item.backwear    = Sexbound.Actor.Apparel.Backwear:new( _self )
    _self._item.chestwear   = Sexbound.Actor.Apparel.Chestwear:new( _self )
    _self._item.groinwear   = Sexbound.Actor.Apparel.Groinwear:new( _self )
    _self._item.headwear    = Sexbound.Actor.Apparel.Headwear:new( _self )
    _self._item.legswear    = Sexbound.Actor.Apparel.Legswear:new( _self )
    _self._item.nippleswear = Sexbound.Actor.Apparel.Nippleswear:new( _self )

    return _self
end

--- Function called each tick to progress updates of each apparel item
--- @param dt number The delta time since last tick
function Sexbound.Actor.Apparel:update(dt)
    util.each(self._item, function(_, item)
        item:update(dt)
    end)
end

--- Synchronize actor apparel with actor config
function Sexbound.Actor.Apparel:sync()
    util.each(self._item, function(_, item)
        item:setConfig(self:getParent():getConfig()[item._name])
    end)
end

--- Toggle the next variant of a given apparel type
--- @param name string The name of the apparel slot to toggle
function Sexbound.Actor.Apparel:gotoNextVariantForApparelItem(name)
    if self._item[name] == nil then return end
    self._item[name]:gotoNextVariant()
end

--- Toggle the previous variant of a given apparel type
--- @param name string The name of the apparel slot to toggle
function Sexbound.Actor.Apparel:gotoPrevVariantForApparelItem(name)
    if self._item[name] == nil then return end
    self._item[name]:gotoPrevVariant()
end

--- Returns whethere or not a given apparel slot is locked
--- @param name string The name of the apparel slot
--- @return boolean # Whethere or not the apparel slot is locked
function Sexbound.Actor.Apparel:getIsLocked(name)
    if self._item[name] == nil then return false end
    return self._item[name]._isLocked
end

--- Sets whethere or not an apparel slot is locked
--- @param name string The name of the apparel slot
--- @param value boolean The new locked state
function Sexbound.Actor.Apparel:setIsLocked(name, value)
    if self._item[name] == nil then return end
    self._item[name]:setIsLocked(value)
end

--- Toggles the locked state of an apparel slot
--- @param name string The name of the apparel slot
--- @return boolean # Whethere or not the apparel slot is now locked
function Sexbound.Actor.Apparel:toggleIsLocked(name)
    if self._item[name] == nil then return false end
    return self._item[name]:toggleIsLocked()
end

--- Returns whethere or not a given apparel slot is visible
--- @param name string The name of the apparel slot
--- @return boolean # Whethere or not the apparel slot is visible
function Sexbound.Actor.Apparel:getIsVisible(name)
    return self._item[name]._isVisible
end

--- Sets whethere or not an apparel slot is visible
--- @param name string The name of the apparel slot
--- @param value boolean The new visibility state
function Sexbound.Actor.Apparel:setIsVisible(name, value)
    if self._item[name] == nil then return end
    self._item[name]:setIsVisible(value)
end

--- Toggles the visibility state of an apparel slot
--- @param name string The name of the apparel slot
--- @return boolean # Whethere or not the apparel slot is now visible
function Sexbound.Actor.Apparel:toggleIsVisible(name)
    if self._item[name] == nil then return false end
    return self._item[name]:toggleIsVisible()
end

--- Resets the parts for all apparel items
--- @param role string The current actor role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
function Sexbound.Actor.Apparel:resetParts(role, species, gender)
    local frameName = self:getParent():getFrameName(self:getParent():getAnimationState())
    util.each(self._item, function(_, item)
        item:resetParts(role, species, gender, frameName)
    end)
end

--- Resets the directive tags for all apparel items
--- @param prefix string? The tag name prefix for animator tags
function Sexbound.Actor.Apparel:resetAnimatorDirectives(prefix)
    util.each(self._item, function(_, item)
        item:resetAnimatorDirectives(prefix)
    end)
end

--- Resets the mask tags for all apparel items
--- @param prefix string? The tag name prefix for animator tags
function Sexbound.Actor.Apparel:resetAnimatorMasks(prefix)
    util.each(self._item, function(_, item)
        item:resetAnimatorMasks(prefix)
    end)
end

--- Resets the part tags for all apparel items
--- @param prefix string? The tag name prefix for animator tags
function Sexbound.Actor.Apparel:resetAnimatorParts(prefix)
    util.each(self._item, function(_, item)
        item:resetAnimatorParts(prefix)
    end)
end

--- Returns a requested apparel instance by name
--- @param name string The name of the apparel slot
--- @return Sexbound.Actor.Apparel.Abstract? # The apparel instance if it exists
function Sexbound.Actor.Apparel:getItem(name)
    return self._item[name]
end

--- Returns a requested apparel instance's config by name
--- @param name string The name of the apparel slot
--- @return table? # The apparel instance config if it exists
function Sexbound.Actor.Apparel:getItemConfig(name)
    return self._item[name]._config or nil
end

--- Sets a new item config for a given apparel instance
--- @param name string The name of the apparel slot
--- @param config table The new config
function Sexbound.Actor.Apparel:setItemConfig(name, config)
    self._item[name]:setConfig(config)
end

--- Returns the parent actor instance
--- @return Sexbound.Actor # The parent actor instance
function Sexbound.Actor.Apparel:getParent()
    return self._parent
end

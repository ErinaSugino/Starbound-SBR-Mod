--- Sexbound.Actor.Apparel Class Module.
-- @classmod Sexbound.Actor.Apparel
-- @author Locuturus
-- @license GNU General Public License v3.0
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
-- @param parent
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

function Sexbound.Actor.Apparel:update(dt)
    util.each(self._item, function(index, item)
        item:update(dt)
    end)
end

function Sexbound.Actor.Apparel:sync()
    sb.logInfo("Syncing apparel")
    util.each(self._item, function(index, item)
        item:setConfig(self:getParent():getConfig()[item._name])
    end)
end

function Sexbound.Actor.Apparel:gotoNextVariantForApparelItem(name)
    if self._item[name] == nil then return end
    self._item[name]:gotoNextVariant()
end

function Sexbound.Actor.Apparel:gotoPrevVariantForApparelItem(name)
    if self._item[name] == nil then return end
    self._item[name]:gotoPrevVariant()
end

function Sexbound.Actor.Apparel:getIsLocked(name)
    if self._item[name] == nil then return end
    return self._item[name]._isLocked
end

function Sexbound.Actor.Apparel:setIsLocked(name, value)
    if self._item[name] == nil then return end
    self._item[name]:setIsLocked(value)
end

function Sexbound.Actor.Apparel:toggleIsLocked(name)
    if self._item[name] == nil then return end
    return self._item[name]:toggleIsLocked()
end

function Sexbound.Actor.Apparel:getIsVisible(name)
    return self._item[name]._isVisible
end

function Sexbound.Actor.Apparel:setIsVisible(name, value)
    if self._item[name] == nil then return end
    self._item[name]:setIsVisible(value)
end

function Sexbound.Actor.Apparel:toggleIsVisible(name)
    if self._item[name] == nil then return end
    return self._item[name]:toggleIsVisible()
end

function Sexbound.Actor.Apparel:resetParts(role, species, gender)
    local frameName = self:getParent():getFrameName(self:getParent():getAnimationState())
    util.each(self._item, function(_, item)
        item:resetParts(role, species, gender, frameName)
    end)
end

function Sexbound.Actor.Apparel:resetAnimatorDirectives(prefix)
    util.each(self._item, function(index, item)
        item:resetAnimatorDirectives(prefix)
    end)
end

function Sexbound.Actor.Apparel:resetAnimatorMasks(prefix)
    util.each(self._item, function(index, item)
        item:resetAnimatorMasks(prefix)
    end)
end

function Sexbound.Actor.Apparel:resetAnimatorParts(prefix)
    util.each(self._item, function(index, item)
        item:resetAnimatorParts(prefix)
    end)
end

function Sexbound.Actor.Apparel:getItem(name)
    return self._item[name]
end

function Sexbound.Actor.Apparel:getItemConfig(name)
    return self._item[name]._config
end

function Sexbound.Actor.Apparel:setItemConfig(name, config)
    self._item[name]:setConfig(config)
end

function Sexbound.Actor.Apparel:getParent()
    return self._parent
end

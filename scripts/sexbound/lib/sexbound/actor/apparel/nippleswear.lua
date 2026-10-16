if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

--- Sexbound.Actor.Apparel.Nippleswear Class Module.
--- @class Sexbound.Actor.Apparel.Nippleswear: Sexbound.Actor.Apparel.Abstract
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _name string
Sexbound.Actor.Apparel.Nippleswear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Nippleswear_mt = {
    __index = Sexbound.Actor.Apparel.Nippleswear
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor.Apparel # The calling parent apparel manager instance
function Sexbound.Actor.Apparel.Nippleswear:new( parent )
  return setmetatable({ _parent = parent, _name   = "nippleswear" } , Sexbound.Actor.Apparel.Nippleswear_mt)
end

--- Function called each tick to update animation
--- @param dt number The delta time since last tick
function Sexbound.Actor.Apparel.Nippleswear:update(dt)
  if self._angularSpeed <= 0 then return end

  local rotateAmount = util.toRadians(self._angularSpeed * dt)

  self:rotateItem(1, rotateAmount)
  self:rotateItem(2, rotateAmount)
end

--- Function to rotate a nipple part
--- @param index integer
--- |"1" The first nipple sprite
--- |"2" The second nipple sprite
--- @param rotateAmount number The rotation amoun in radians
function Sexbound.Actor.Apparel.Nippleswear:rotateItem(index, rotateAmount)
  local slot = self:getParent():getParent():getActorNumber()
  local transformationGroupName = slot .. "Nippleswear" .. index
  if not animator.hasTransformationGroup(transformationGroupName) then return end
  animator.rotateTransformationGroup(transformationGroupName, rotateAmount)
end

--- Function to reset the apparel parts
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current frame name
function Sexbound.Actor.Apparel.Nippleswear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  self:resetImagePartForNippleswear(role, species, gender, frameName, 1)
  self:resetImagePartForNippleswear(role, species, gender, frameName, 2)
  self:resetTransformationGroupForNippleswear(role, gender, 1)
  self:resetTransformationGroupForNippleswear(role, gender, 2)
end

--- Resets the animator part tag for a nippleswear sprite
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current frame name
--- @param index integer
--- |"1" The first nipple sprite
--- |"2" The second nipple sprite
function Sexbound.Actor.Apparel.Nippleswear:resetImagePartForNippleswear(role, species, gender, frameName, index)
  local _config = self._config   or {}
  _config       = _config[index] or {}

  local part = _config.image or self._defaultImage
  part       = part .. ":default"

  animator.setGlobalTag("part-" .. role .. "-nippleswear" .. index, part)
end

--- Resets the transformation group of a nippleswear sprite
--- @param prefix string The animator part name prefix
--- @param gender string The actor's vanilla gender
--- @param index integer
--- |"1" The first nipple sprite
--- |"2" The second nipple sprite
function Sexbound.Actor.Apparel.Nippleswear:resetTransformationGroupForNippleswear(prefix, gender, index)
  local _config = self._config   or {}
  _config       = _config[index] or {}

  self._angularSpeed = _config.angularSpeed or 0
  self._startAngle   = _config.startAngle   or 0
  self._startScale   = _config.startScale   or 1

  local transformationGroupName = prefix .. "Nippleswear" .. index
  if not animator.hasTransformationGroup(transformationGroupName) then return end

  animator.resetTransformationGroup(transformationGroupName)
  animator.rotateTransformationGroup(transformationGroupName, util.toRadians(self._startAngle or 0))
  animator.scaleTransformationGroup(transformationGroupName,  self._startScale or 1)
end

--- Function to reset the animator directive tags
function Sexbound.Actor.Apparel.Nippleswear:resetAnimatorDirectives(_)
  -- Not using directives
end

--- Function to reset the animator mask tags
function Sexbound.Actor.Apparel.Nippleswear:resetAnimatorMasks(_)
  -- Not using masks
end

--- Function to reset the animator part tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Nippleswear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-nippleswear1", self._defaultImage .. ":default")
  animator.setGlobalTag("part-" .. prefix .. "-nippleswear2", self._defaultImage .. ":default")
end

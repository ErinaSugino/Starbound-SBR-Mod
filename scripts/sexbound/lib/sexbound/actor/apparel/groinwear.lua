if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

--- Sexbound.Actor.Apparel.Groinwear Class Module.
--- @class Sexbound.Actor.Apparel.Groinwear: Sexbound.Actor.Apparel.Abstract
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _name string
Sexbound.Actor.Apparel.Groinwear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Groinwear_mt = {
    __index = Sexbound.Actor.Apparel.Groinwear
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor.Apparel # The calling parent apparel manager instance
function Sexbound.Actor.Apparel.Groinwear:new( parent )
  return setmetatable({ _parent = parent, _name = "groinwear" } , Sexbound.Actor.Apparel.Groinwear_mt)
end

--- Function called each tick to update animation
--- @param dt number The delta time since last tick
function Sexbound.Actor.Apparel.Groinwear:update(dt)
  if self._angularSpeed == 0 then return end

  local rotateAmount = util.toRadians(self._angularSpeed * dt)

  self:rotateItem(1, rotateAmount)
end

--- Rotates the apparel item
--- @param index integer The variant index
--- @param rotateAmount number The rotation in radians
function Sexbound.Actor.Apparel.Groinwear:rotateItem(index, rotateAmount)
  local slot = self:getParent():getParent():getRole()
  local transformationGroupName = slot .. "Groinwear" .. index
  if not animator.hasTransformationGroup(transformationGroupName) then return end
  animator.rotateTransformationGroup(transformationGroupName, rotateAmount)
end

--- Function to reset the apparel parts
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current frame name
function Sexbound.Actor.Apparel.Groinwear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  self:resetImagePartForGroinwear(role, species, gender, frameName, 1)
  self:resetTransformationGroupForGroinwear(role, gender, 1)
end

--- Resets the groinwear animator part tags
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current animation frame name
--- @param index integer The current variant index
function Sexbound.Actor.Apparel.Groinwear:resetImagePartForGroinwear(role, species, gender, frameName, index)
  local _config = self._config   or {}
  _config       = _config[index] or {}

  local part = _config.image or self._defaultImage
  part       = part .. ":default"

  animator.setGlobalTag("part-" .. role .. "-groinwear" .. index, part)
end

--- Resets the transformation group for groinwear
--- @param prefix string The prefix of animator part names
--- @param gender string The actor's vanilla gender
--- @param index integer The current variant index
function Sexbound.Actor.Apparel.Groinwear:resetTransformationGroupForGroinwear(prefix, gender, index)
  local _config = self._config   or {}
  _config       = _config[index] or {}

  self._angularSpeed = _config.angularSpeed or 0
  self._startAngle   = _config.startAngle   or 0
  self._startScale   = _config.startScale   or 1

  local transformationGroupName = prefix .. "Groinwear" .. index
  if not animator.hasTransformationGroup(transformationGroupName) then return end

  animator.resetTransformationGroup(transformationGroupName)
  animator.rotateTransformationGroup(transformationGroupName, util.toRadians(self._startAngle or 0))
  animator.scaleTransformationGroup(transformationGroupName,  self._startScale or 1)
end

--- Function to reset the animator directive tags
function Sexbound.Actor.Apparel.Groinwear:resetAnimatorDirectives(_)
  -- Not using directives
end

--- Function to reset the animator mask tags
function Sexbound.Actor.Apparel.Groinwear:resetAnimatorMasks(_)
  -- Not using masks
end

--- Function to reset the animator part tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Groinwear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-groinwear1", self._defaultImage .. ":default")
end

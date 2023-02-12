--- Sexbound.Actor.Apparel.Nippleswear Class Module.
-- @classmod Sexbound.Actor.Apparel.Nippleswear
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

Sexbound.Actor.Apparel.Groinwear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Groinwear_mt = {
    __index = Sexbound.Actor.Apparel.Groinwear
}

--- Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Actor.Apparel.Groinwear:new( parent )
  return setmetatable({ _parent = parent, _name = "groinwear" } , Sexbound.Actor.Apparel.Groinwear_mt)
end

function Sexbound.Actor.Apparel.Groinwear:update(dt)
  if self._angularSpeed == 0 then return end

  local rotateAmount = util.toRadians(self._angularSpeed * dt)

  self:rotateItem(1, rotateAmount)
end

function Sexbound.Actor.Apparel.Groinwear:rotateItem(index, rotateAmount)
  local slot = self:getParent():getParent():getRole()
  local transformationGroupName = slot .. "Groinwear" .. index
  if not animator.hasTransformationGroup(transformationGroupName) then return end
  animator.rotateTransformationGroup(transformationGroupName, rotateAmount)
end

function Sexbound.Actor.Apparel.Groinwear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  local slot = "actor" .. self:getParent():getParent():getActorNumber()

  self:resetImagePartForGroinwear(slot, species, gender, frameName, 1)
  self:resetTransformationGroupForGroinwear(slot, gender, 1)
end

function Sexbound.Actor.Apparel.Groinwear:resetImagePartForGroinwear(slot, species, gender, frameName, index)
  local _config = self._config   or {}
  _config       = _config[index] or {}

  local part = _config.image or self._defaultImage
  part       = part .. ":default"

  animator.setGlobalTag("part-" .. slot .. "-groinwear" .. index, part)
end

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

function Sexbound.Actor.Apparel.Groinwear:resetAnimatorDirectives(prefix)
  -- Not using directives
end

function Sexbound.Actor.Apparel.Groinwear:resetAnimatorMasks(prefix)
  -- Not using masks
end

function Sexbound.Actor.Apparel.Groinwear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-groinwear1", self._defaultImage .. ":default")
end

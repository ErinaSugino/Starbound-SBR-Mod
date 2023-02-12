--- Sexbound.Actor.Apparel.Nippleswear Class Module.
-- @classmod Sexbound.Actor.Apparel.Nippleswear
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

Sexbound.Actor.Apparel.Nippleswear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Nippleswear_mt = {
    __index = Sexbound.Actor.Apparel.Nippleswear
}

--- Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Actor.Apparel.Nippleswear:new( parent )
  return setmetatable({ _parent = parent, _name   = "nippleswear" } , Sexbound.Actor.Apparel.Nippleswear_mt)
end

function Sexbound.Actor.Apparel.Nippleswear:update(dt)
  if self._angularSpeed <= 0 then return end

  local rotateAmount = util.toRadians(self._angularSpeed * dt)

  self:rotateItem(1, rotateAmount)
  self:rotateItem(2, rotateAmount)
end

function Sexbound.Actor.Apparel.Nippleswear:rotateItem(index, rotateAmount)
  local slot = self:getParent():getParent():getActorNumber()
  local transformationGroupName = slot .. "Nippleswear" .. index
  if not animator.hasTransformationGroup(transformationGroupName) then return end
  animator.rotateTransformationGroup(transformationGroupName, rotateAmount)
end

function Sexbound.Actor.Apparel.Nippleswear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  local slot = "actor" .. self:getParent():getParent():getActorNumber()

  self:resetImagePartForNippleswear(slot, species, gender, frameName, 1)
  self:resetImagePartForNippleswear(slot, species, gender, frameName, 2)
  self:resetTransformationGroupForNippleswear(slot, gender, 1)
  self:resetTransformationGroupForNippleswear(slot, gender, 2)
end

function Sexbound.Actor.Apparel.Nippleswear:resetImagePartForNippleswear(slot, species, gender, frameName, index)
  local _config = self._config   or {}
  _config       = _config[index] or {}

  local part = _config.image or self._defaultImage
  part       = part .. ":default"

  animator.setGlobalTag("part-" .. slot .. "-nippleswear" .. index, part)
end

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

function Sexbound.Actor.Apparel.Nippleswear:resetAnimatorDirectives(prefix)
  -- Not using directives
  -- animator.setGlobalTag(prefix .. "-nippleswear1", "")
  -- animator.setGlobalTag(prefix .. "-nippleswear2", "")
end

function Sexbound.Actor.Apparel.Nippleswear:resetAnimatorMasks(prefix)
  -- Not using masks
  -- animator.setGlobalTag(prefix .. "-nippleswearMask", "?addmask=" .. self._defaultMask .. ":default")
end

function Sexbound.Actor.Apparel.Nippleswear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-nippleswear1", self._defaultImage .. ":default")
  animator.setGlobalTag("part-" .. prefix .. "-nippleswear2", self._defaultImage .. ":default")
end

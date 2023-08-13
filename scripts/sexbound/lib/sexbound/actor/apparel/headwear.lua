--- Sexbound.Actor.Apparel.Headwear Class Module.
-- @classmod Sexbound.Actor.Apparel.Headwear
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

Sexbound.Actor.Apparel.Headwear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Headwear_mt = {
    __index = Sexbound.Actor.Apparel.Headwear
}

--- Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Actor.Apparel.Headwear:new( parent )
  return setmetatable({ _parent = parent, _name = "headwear" }, Sexbound.Actor.Apparel.Headwear_mt)
end

function Sexbound.Actor.Apparel.Headwear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  local index, part, directives, mask = self:loadApparel(
      self._variantIndex or 1,
      self._config,
      role,
      species,
      gender
  )

  self._variantIndex = index

  local headwear = self._config or {}

  local prefix = "actor" .. self:getParent():getParent():getActorNumber()

  if headwear.imageFrameName ~= nil then
      local headwearImageFrameName = util.replaceTag(headwear.imageFrameName, "frameName", frameName)
      part = self:finalizeFilePath(part, headwearImageFrameName)
      animator.setGlobalTag("part-" .. prefix .. "-headwear", part)
      animator.setGlobalTag(prefix .. "-headwear", directives)
  else
      part = self:finalizeFilePath(part, "normal")
      animator.setGlobalTag("part-" .. prefix .. "-headwear-static", part)
      animator.setGlobalTag(prefix .. "-headwear-static", directives)
  end

  mask = self:finalizeFilePath(mask, nil)
  animator.setGlobalTag(prefix .. "-headwearMask", "?addmask=" .. mask)
end

function Sexbound.Actor.Apparel.Headwear:resetAnimatorDirectives(prefix)
  animator.setGlobalTag(prefix .. "-headwear", "")
  animator.setGlobalTag(prefix .. "-headwear-static", "")
end

function Sexbound.Actor.Apparel.Headwear:resetAnimatorMasks(prefix)
  animator.setGlobalTag(prefix .. "-headwearMask", "?addmask=" .. self._defaultMask .. ":default")
end

function Sexbound.Actor.Apparel.Headwear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-headwear", self._defaultImage .. ":default")
  animator.setGlobalTag("part-" .. prefix .. "-headwear-static", self._defaultImage .. ":default")
end

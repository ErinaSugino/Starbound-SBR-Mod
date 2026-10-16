if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

--- Sexbound.Actor.Apparel.Backwear Class Module.
--- @class Sexbound.Actor.Apparel.Backwear: Sexbound.Actor.Apparel.Abstract
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _name string
Sexbound.Actor.Apparel.Backwear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Backwear_mt = {
  __index = Sexbound.Actor.Apparel.Backwear
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor.Apparel # The calling parent apparel manager instance
function Sexbound.Actor.Apparel.Backwear:new(parent)
  return setmetatable({ _parent = parent, _name = "backwear" }, Sexbound.Actor.Apparel.Backwear_mt)
end

--- Function to reset the apparel parts
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current frame name
function Sexbound.Actor.Apparel.Backwear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  local index, part, directives, mask = self:loadApparel(
      self._variantIndex,
      self._config,
      role,
      species,
      gender
  )

  self._variantIndex = index

  part = self:finalizeFilePath(part, frameName)
  mask = self:finalizeFilePath(mask, frameName)

  local prefix = "actor" .. self:getParent():getParent():getActorNumber()

  animator.setGlobalTag("part-" .. prefix .. "-backwear", part)
  animator.setGlobalTag(prefix .. "-backwear", directives)
  animator.setGlobalTag(prefix .. "-backwearMask", "?addmask=" .. mask)
end

--- Function to reset the animator directive tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Backwear:resetAnimatorDirectives(prefix)
  animator.setGlobalTag(prefix .. "-backwear", "")
end

--- Function to reset the animator mask tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Backwear:resetAnimatorMasks(prefix)
  animator.setGlobalTag(prefix .. "-backwearMask", "?addmask=" .. self._defaultMask .. ":default")
end

--- Function to reset the animator part tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Backwear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-backwear", self._defaultImage .. ":default")
end

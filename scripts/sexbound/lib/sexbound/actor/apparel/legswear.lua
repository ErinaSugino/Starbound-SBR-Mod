if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

--- Sexbound.Actor.Apparel.Legswear Class Module.
--- @class Sexbound.Actor.Apparel.Legswear: Sexbound.Actor.Apparel.Abstract
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _name string
Sexbound.Actor.Apparel.Legswear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Legswear_mt = {
    __index = Sexbound.Actor.Apparel.Legswear
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor.Apparel # The calling parent apparel manager instance
function Sexbound.Actor.Apparel.Legswear:new( parent )
  return setmetatable({ _parent = parent, _name = "legswear" }, Sexbound.Actor.Apparel.Legswear_mt)
end

--- Function to reset the apparel parts
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current frame name
function Sexbound.Actor.Apparel.Legswear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  local index, part, directives, mask = self:loadApparel(
      self._variantIndex or 1,
      self._config,
      role,
      species,
      gender
  )

  self._variantIndex = index

  part = self:finalizeFilePath(part, frameName)
  mask = self:finalizeFilePath(mask, frameName)

  local prefix = "actor" .. self:getParent():getParent():getActorNumber()

  animator.setGlobalTag("part-" .. prefix .. "-legswear", part)
  animator.setGlobalTag(prefix .. "-legswear", directives)
  animator.setGlobalTag(prefix .. "-legswearMask", "?addmask=" .. mask)
end

--- Function to reset the animator directive tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Legswear:resetAnimatorDirectives(prefix)
  animator.setGlobalTag(prefix .. "-legswear", "")
end

--- Function to reset the animator mask tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Legswear:resetAnimatorMasks(prefix)
  animator.setGlobalTag(prefix .. "-legswearMask", "?addmask=" .. self._defaultMask .. ":default")
end

--- Function to reset the animator part tags
--- @param prefix string The animator part prefix
function Sexbound.Actor.Apparel.Legswear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-legswear", self._defaultImage .. ":default")
end

--- Sexbound.Actor.Apparel.Legswear Class Module.
-- @classmod Sexbound.Actor.Apparel.Legswear
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

Sexbound.Actor.Apparel.Legswear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Legswear_mt = {
    __index = Sexbound.Actor.Apparel.Legswear
}

--- Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Actor.Apparel.Legswear:new( parent )
  return setmetatable({ _parent = parent, _name = "legswear" }, Sexbound.Actor.Apparel.Legswear_mt)
end

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

function Sexbound.Actor.Apparel.Legswear:resetAnimatorDirectives(prefix)
  animator.setGlobalTag(prefix .. "-legswear", "")
end

function Sexbound.Actor.Apparel.Legswear:resetAnimatorMasks(prefix)
  animator.setGlobalTag(prefix .. "-legswearMask", "?addmask=" .. self._defaultMask .. ":default")
end

function Sexbound.Actor.Apparel.Legswear:resetAnimatorParts(prefix)
  animator.setGlobalTag("part-" .. prefix .. "-legswear", self._defaultImage .. ":default")
end

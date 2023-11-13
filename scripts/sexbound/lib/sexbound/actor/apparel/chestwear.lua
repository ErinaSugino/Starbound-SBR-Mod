--- Sexbound.Actor.Apparel.Chestwear Class Module.
-- @classmod Sexbound.Actor.Apparel.Chestwear
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/apparel/abstract.lua")
end

Sexbound.Actor.Apparel.Chestwear = Sexbound.Actor.Apparel.Abstract:new()
Sexbound.Actor.Apparel.Chestwear_mt = {
    __index = Sexbound.Actor.Apparel.Chestwear
}

--- Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Actor.Apparel.Chestwear:new( parent )
  return setmetatable({ _parent = parent, _name = "chestwear" }, Sexbound.Actor.Apparel.Chestwear_mt)
end

function Sexbound.Actor.Apparel.Chestwear:resetParts(role, species, gender, frameName)
  if not self._isVisible then return end

  local index, part, directives, mask =
      self:loadChestwear("body", role, species, gender)
  self._variantIndex = index
  part = self:finalizeFilePath(part, frameName)
  mask = self:finalizeFilePath(mask, frameName)

  local prefix = "actor" .. self:getParent():getParent():getActorNumber()

  animator.setGlobalTag("part-" .. prefix .. "-chestwear", part)
  animator.setGlobalTag(prefix .. "-chestwear", directives)
  animator.setGlobalTag(prefix .. "-chestwearMask", "?addmask=" .. mask)

  self:resetChestwearSleeve1(role, species, gender, frameName)
  self:resetChestwearSleeve2(role, species, gender, frameName)
end

function Sexbound.Actor.Apparel.Chestwear:resetChestwearSleeve1(role, species, gender, frameName)
  local _, part, directives, _ =
      self:loadChestwear("backSleeve", role, species, gender)
  part = self:finalizeFilePath(part, frameName)
  local prefix = "actor" .. self:getParent():getParent():getActorNumber()
  animator.setGlobalTag("part-" .. prefix .. "-bsleeve", part)
  animator.setGlobalTag(prefix .. "-bsleeve", directives)
end

function Sexbound.Actor.Apparel.Chestwear:resetChestwearSleeve2(role, species, gender, frameName)
  local _, part, directives, _ =
      self:loadChestwear("frontSleeve", role, species, gender)
  part = self:finalizeFilePath(part, frameName)
  local prefix = "actor" .. self:getParent():getParent():getActorNumber()
  animator.setGlobalTag("part-" .. prefix .. "-fsleeve", part)
  animator.setGlobalTag(prefix .. "-fsleeve", directives)
end

--- Loads and returns a chestwear image part, directives, & mask.
-- @param name
-- @param role
-- @param species
-- @param gender
function Sexbound.Actor.Apparel.Chestwear:loadChestwear(name, role, species, gender)
    local part, directives, mask = self._defaultImage, "", self._defaultMask
    local index  = self._variantIndex or 1
    local config = self._config

    if not config or type(config.images) ~= "table" then
        index = 1
        return index, part, directives, mask
    end

  if type(config.images[name]) == "table" then
      local imageCount = #config.images[name]
      if index > imageCount then index = imageCount end

      part = config.images[name][index]
  else
      part = config.images[name] or part
      index = 1
  end

  part = self:replaceTags(part, role, species, gender)

  if not Sexbound.Util.imageExists(part) then
      return index, self._defaultImage, directives, mask
  end

  if config.colors and not isEmpty(config.colors) then
      directives = Sexbound.Util.colorMapToReplaceDirective(config.colors)
  else
      directives = config.directives or ""
  end

  mask = config.images[name .. "Mask"] or mask
  mask = self:replaceTags(mask, role, species, gender)

  if not Sexbound.Util.imageExists(mask) then
      mask = self._defaultMask
  end

  if
        not self:getParent():getParent():isVisiblyPregnant() or
        not self:getParent():getParent():isInflated() or
  not self:getParent():getParent():isEnabledPregnancyFetish() then
      return index, part, directives, mask
  end

  local altImage
  if type(config.images[name .. "Pregnant"]) == "table" then
      local imageCount = #config.images[name .. "Pregnant"]
      if index > imageCount then index = imageCount end
      altImage = config.images[name .. "Pregnant"][index]
  else
      altImage = config.images[name .. "Pregnant"] or part or ""
      index = 1
  end

  altImage = self:replaceTags(altImage, role, species, gender)

  if Sexbound.Util.imageExists(altImage) then
      part = altImage
  end

  local altMask = config.images[name .. "PregnantMask"] or ""
  altMask = self:replaceTags(altMask, role, species, gender)

  if Sexbound.Util.imageExists(altMask) then
      mask = altMask
  end

  return index, part, directives, mask
end

function Sexbound.Actor.Apparel.Chestwear:resetAnimatorDirectives(prefix)
    animator.setGlobalTag(prefix .. "-chestwear", "")
end

function Sexbound.Actor.Apparel.Chestwear:resetAnimatorMasks(prefix)
    animator.setGlobalTag(prefix .. "-chestwearMask", "?addmask=" .. self._defaultMask .. ":default")
end

function Sexbound.Actor.Apparel.Chestwear:resetAnimatorParts(prefix)
    animator.setGlobalTag("part-" .. prefix .. "-chestwear", self._defaultImage .. ":default")
    animator.setGlobalTag("part-" .. prefix .. "-bsleeve",   self._defaultImage .. ":default")
    animator.setGlobalTag("part-" .. prefix .. "-fsleeve",   self._defaultImage .. ":default")
end

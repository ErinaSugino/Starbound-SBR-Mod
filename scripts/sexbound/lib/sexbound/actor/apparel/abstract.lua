--- Sexbound.Actor.Apparel.Abstract Base Class.
--- @class Sexbound.Actor.Apparel.Abstract
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor.Apparel
--- @field _config table
--- @field protected _defaultImage string
--- @field protected _defaultMask string
--- @field _angularSpeed number
--- @field _isLocked boolean
--- @field _isVisible boolean
--- @field _maxVariants integer
--- @field _startAngle number
--- @field _startScale number
--- @field _variantIndex integer
Sexbound.Actor.Apparel.Abstract = {}
Sexbound.Actor.Apparel.Abstract_mt = {
    __index = Sexbound.Actor.Apparel.Abstract
}

--- Abstract constructor
--- @return Sexbound.Actor.Apparel.Abstract # The abstract base instance
function Sexbound.Actor.Apparel.Abstract:new()
  return setmetatable({
    _config       = {},
    _angularSpeed = 0,
    _defaultImage = "/artwork/defaults/default_image.png",
    _defaultMask  = "/artwork/defaults/default_mask.png",
    _isLocked     = false,
    _isVisible    = true,
    _maxVariants  = 1,
    _parent       = nil,
    _startAngle   = 0,
    _startScale   = 1,
    _variantIndex = 1
  }, Sexbound.Actor.Apparel.Abstract_mt)
end

--- Placeholder tick update handler. To be implemented by child classes.
--- @param dt number The delta time since last tick
function Sexbound.Actor.Apparel.Abstract:update(dt)
    -- Should be defined in classes which derive from this class
end

--- Generated a fully qualified image file path
--- @param filePath string The base filepath
--- @param frameName string? The name of the animation frame
--- @return string # The fully qualified image file path
function Sexbound.Actor.Apparel.Abstract:finalizeFilePath(filePath, frameName)
    if frameName == nil then return filePath end

    if filePath ~= self._defaultImage and filePath ~= self._defaultMask then
        return filePath .. ":" .. frameName
    end

    return filePath .. ":default"
end

--- Loads an apparel part image, directives, & mask.
--- @param index integer Variant index
--- @param apparel table Apparel config data
--- @param role string Actor role
--- @param species string Actor species
--- @param gender string Actor vanilla gender
--- @return number index The adjusted variant index
--- @return string image The fully qualified image path
--- @return string directives The directives string
--- @return string mask The fully qualified mask path
function Sexbound.Actor.Apparel.Abstract:loadApparel(index, apparel, role, species, gender)
  local image, directives, mask = self._defaultImage, "", self._defaultMask

  if not apparel then
      index = 1
      return index, image, directives, mask
  end

  if type(apparel.image) == "table" then
      local imageCount = #apparel.image
      if index > imageCount then index = imageCount end
      image = apparel.image[index]
  else
      image = apparel.image or image
      index = 1
  end

  image = self:replaceTags(image, role, species, gender)

  if not Sexbound.Util.imageExists(image) then
      return index, self._defaultImage, directives, mask
  end

  mask = apparel.mask or mask
  mask = self:replaceTags(mask, role, species, gender)

  if not Sexbound.Util.imageExists(mask) then
      mask = self._defaultMask
  end

  directives = apparel.directives or ""
  directives = directives .. Sexbound.Util.colorMapToReplaceDirective(apparel.colors)

  if not self:getParent():getParent():isVisiblyPregnant() or not self:getParent():getParent():isInflated() or not self:getParent():getParent():isEnabledPregnancyFetish() then
      return index, image, directives, mask
  end

  -- Override image part with image used for showing pregnancy
  local altImage = apparel.imagePregnant or image
  altImage = self:replaceTags(altImage, role, species, gender)

  if Sexbound.Util.imageExists(altImage) then
      image = altImage
  end

  -- Override mask with mask used for showing pregnancy
  local altMask = apparel.maskPregnant or mask
  altMask = self:replaceTags(altMask, role, species, gender)

  if Sexbound.Util.imageExists(altMask) then
      mask = altMask
  end

  return index, image, directives, mask
end

--- Replaces placeholder tags in a filepath
--- @param filepath string The template filepath
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @return string # The replaced filepath
function Sexbound.Actor.Apparel.Abstract:replaceTags(filepath, role, species, gender)
  filepath = util.replaceTag(filepath, "entityGroup", "humanoid")
  filepath = util.replaceTag(filepath, "role", role)
  filepath = util.replaceTag(filepath, "species", species)
  filepath = util.replaceTag(filepath, "gender", gender)

  return filepath
end

--- Increases the variant index
function Sexbound.Actor.Apparel.Abstract:gotoNextVariant()
    self._variantIndex = self._variantIndex + 1
end

--- Decreases the variant index
function Sexbound.Actor.Apparel.Abstract:gotoPrevVariant()
    self._variantIndex = math.max(self._variantIndex - 1, 1)
end

--- Checks specified config and attaches all specified sexbound statuses
--- @param config table The config data
function Sexbound.Actor.Apparel.Abstract:attachStatuses(config)
    if "table" ~= type(config.addStatus) then
        config.addStatus = { config.addStatus --[[@as string]] }
    end

    delay = self:getParent():getParent()._hasInited
    for _, status in pairs(config.addStatus) do
        self:getParent():getParent():getStatus():addStatus(status, nil, delay)
    end
end

--- Checks specified config and detaches all specified sexbound statuses
--- @param config table The config data
function Sexbound.Actor.Apparel.Abstract:detachStatuses(config)
    if "table" ~= type(config.addStatus) then
        config.addStatus = { config.addStatus --[[@as string]] }
    end

    delay = self:getParent():getParent()._hasInited
    for _, status in pairs(config.addStatus) do
        self:getParent():getParent():getStatus():removeStatus(status, delay)
    end
end

--- Placeholder parts reset function. To be implemented in child classes.
--- @param role string The actor's role name
--- @param species string The actor's species
--- @param gender string The actor's vanilla gender
--- @param frameName string The current frame name
function Sexbound.Actor.Apparel.Abstract:resetParts(role, species, gender, frameName)
    -- Should be defined in classes which derive from this class
end

--- Placeholder directive tags reset function. To be implemented in child classes.
--- @param role string The actor's role name
function Sexbound.Actor.Apparel.Abstract:resetAnimatorDirectives(role)
    -- Should be defined in classes which derive from this class
end

--- Placeholder mask tags reset function. To be implemented in child classes.
--- @param role string The actor's role name
function Sexbound.Actor.Apparel.Abstract:resetAnimatorMasks(role)
    -- Should be defined in classes which derive from this class
end

--- Placeholder part tags reset function. To be implemented in child classes.
--- @param role string The actor's role name
function Sexbound.Actor.Apparel.Abstract:resetAnimatorParts(role)
    -- Should be defined in classes which derive from this class
end

--- Sets a new apparel config
--- @param config table The new config data
function Sexbound.Actor.Apparel.Abstract:setConfig(config)
    self:detachStatuses(self._config)
    self._config = config
    self:attachStatuses(self._config)

    self._isVisible    = self._config.initIsVisibleValue
    self._isLocked     = self._config.initIsLockedValue
    self._angularSpeed = self._config.initAngularSpeed or self._angularSpeed
    self._startAngle   = self._config.initStartAngle   or self._startAngle
    self._startScale   = self._config.initStartScale   or self._startScale

    -- Reset variant index to beginning
    self._variantIndex = 1
end

--- Sets the visibility state
--- @param value boolean The new visibility state
function Sexbound.Actor.Apparel.Abstract:setIsVisible(value)
    if self._isLocked == true then return end

    self._isVisible = value
end

--- Sets the locked state
--- @param value boolean The new locked state
function Sexbound.Actor.Apparel.Abstract:setIsLocked(value)
    self._isLocked = value
end

--- Toggles the locked state
--- @return boolean # The new locked state
function Sexbound.Actor.Apparel.Abstract:toggleIsLocked()
    self._isLocked = not self._isLocked
    return self._isLocked
end

--- Toggles the visibility state
--- @return boolean # The new visibility state
function Sexbound.Actor.Apparel.Abstract:toggleIsVisible()
    if self._isLocked == true then return self._isVisible end
    self._isVisible = not self._isVisible
    return self._isVisible
end

--- Returns the parent apparel manager instance
--- @return Sexbound.Actor.Apparel # The parent apparel manager instance
function Sexbound.Actor.Apparel.Abstract:getParent()
    return self._parent
end
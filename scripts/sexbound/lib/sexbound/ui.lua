--- Sexbound.UI Class Module.
-- @classmod Sexbound.UI
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.UI = {}
Sexbound.UI_mt = {
  __index = Sexbound.UI
}

function Sexbound.UI.new(parent)
  local self = setmetatable({ _parent = parent }, Sexbound.UI_mt)
  self._config = self:loadConfig()
  return self
end

function Sexbound.UI:handleInteract(args)
  return { "ScriptPane", self._config }
end

function Sexbound.UI:loadConfig()
  local _,_config = xpcall(function()
    return root.assetJson("/interface/sexbound/sexui.config")
  end, function(error)
      self._parent:getLog():error("Unable to load config file for the Sexbound UI!")
  end)
  return _config or {}
end

function Sexbound.UI:refresh()
  -- Controller Id is the entity Id of the entity running Sexbound
  self._config.config.controllerId = self:getParent():getEntityId()
  local allPositions = {}
  util.each(self:getParent():getPositions():getPositions(), function(index, position)
    local button = position:getButton()
    local name = position:getFriendlyName()
    local buttonImage = button.iconImage
    local uiIndex = ((index - 1) % 8) + 1
    self._parent:getLog():debug("Preparing position #"..tostring(index).." - UI Index: "..tostring(uiIndex))
    --self._config.config.positions.buttons[index].name = name
    --self._config.config.positions.buttons[index].image = buttonImage
    --self._config.config.positions.buttons[index].imageOffset = button.iconOffsets[index]
    allPositions[index] = {name = name, image = buttonImage, imageOffset = button.iconOffsets[uiIndex]}
  end)
  self._config.config.positions.allPositions = allPositions
end

function Sexbound.UI:getConfig()
  return self._config
end

function Sexbound.UI:getParent()
  return self._parent
end
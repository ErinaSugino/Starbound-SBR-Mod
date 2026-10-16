--- Sexbound.UI Class Module.
--- @class Sexbound.UI
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound
--- @field _config table
Sexbound.UI = {}
Sexbound.UI_mt = {
  __index = Sexbound.UI
}

--- Creates a new UI manager instance
--- @param parent Sexbound The calling parent sexnode instance
--- @return Sexbound.UI # The new UI manager instance
function Sexbound.UI.new(parent)
  local self = setmetatable({ _parent = parent }, Sexbound.UI_mt)
  self._config = self:loadConfig()
  return self
end

--- Handler for when a player interaction happens
--- @return table # Interaction result for opening a script pane with the loaded config
function Sexbound.UI:handleInteract(_)
  return { "ScriptPane", self._config }
end

--- Load the base config file for the UI
--- @return table # The fetched UI config
function Sexbound.UI:loadConfig()
  local _,_config = xpcall(function()
    return root.assetJson("/interface/sexbound/sexui.config")
  end, function(error)
      self._parent:getLog():error("Unable to load config file for the Sexbound UI!")
  end)
  return _config or {}
end

--- Trigger a refresh of UI data
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
    allPositions[index] = {name = name, image = buttonImage, imageOffset = button.iconOffsets[uiIndex]}
  end)
  self._config.config.positions.allPositions = allPositions
end

--- Returns the loaded UI config
--- @return table # The loaded UI config
function Sexbound.UI:getConfig()
  return self._config
end

--- Returns parent sexnode instance
--- @return Sexbound # The parent sexnode instance
function Sexbound.UI:getParent()
  return self._parent
end
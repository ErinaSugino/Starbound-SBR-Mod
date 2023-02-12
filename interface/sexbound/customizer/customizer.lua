Customizer = {}
Customizer_mt = { __index = Customizer }

require "/interface/sexbound/customizer/customizergeneral.lua"
require "/interface/sexbound/customizer/customizeraddonmods.lua"
require "/interface/sexbound/customizer/customizerstatistics.lua"
require "/interface/sexbound/customizer/customizercredits.lua"

--- Instantiantes a new instance.
-- @param config
function Customizer.new()
  local self = setmetatable({
    tabs = {},
    tabIndices = {}
  }, Customizer_mt)

  return self
end

--- Init. all underlying classes
function Customizer:init()
  for _,button in ipairs(config.getParameter("gui.selectTab.buttons")) do
    local controller = Customizer[button.data.className]:new()

    if controller then
      self.tabs[button.data.className] = controller
      table.insert(self.tabIndices, button.data.className)
    end
  end

  for _,i in ipairs(self.tabIndices) do
    self.tabs[i]:init()
  end
end

function Customizer:update(dt)
  for _,i in ipairs(self.tabIndices) do
    self.tabs[i]:update(dt)
  end
end

function Customizer:broadcast(message)
  for _,i in ipairs(self.tabIndices) do
    self.tabs[i]:handleMessage(message)
  end
end
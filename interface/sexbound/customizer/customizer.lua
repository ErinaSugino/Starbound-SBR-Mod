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
    tabIndices = {},
    config = {},
    configPromise = nil,
    _inited = false
  }, Customizer_mt)

  return self
end

--- Init. all underlying classes
function Customizer:init()
  for _,button in ipairs(config.getParameter("gui.selectTab.buttons")) do
    local controller = Customizer[button.data.className]:new(self)

    if controller then
      self.tabs[button.data.className] = controller
      table.insert(self.tabIndices, button.data.className)
    end
  end
  
  self.configPromise = world.sendEntityMessage(pane.sourceEntity(), "Sexbound:CustomizerUI:GetData")
end

function Customizer:update(dt)
  -- Check if init data fetching is finished
  if self.configPromise ~= nil then
    if self.configPromise:finished() then
        if self.configPromise:succeeded() then
          self.config = self.configPromise:result()
        end
        for _,i in ipairs(self.tabIndices) do
          self.tabs[i]:init()
        end
        self._inited = true
        self.configPromise = nil
    end
  end
  
  if not self._inited then return end
  for _,i in ipairs(self.tabIndices) do
    self.tabs[i]:update(dt)
  end
end

function Customizer:broadcast(message)
  if not self._inited then return end
  for _,i in ipairs(self.tabIndices) do
    self.tabs[i]:handleMessage(message)
  end
end
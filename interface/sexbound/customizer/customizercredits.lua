Customizer.Credits = {}
Customizer.Credits_mt = { __index = Customizer.Credits }

--- Instantiantes a new instance.
-- @param config
function Customizer.Credits:new()
  return setmetatable({
    isActive     = false,
    creditsLabel = "creditsTab.creditsLabel",
    scrollSpeed  = 20
  }, Customizer.Credits_mt)
end

function Customizer.Credits:init()
  self.startPosition   = widget.getPosition(self.creditsLabel)
  self.currentPosition = {
    [1] = self.startPosition[1],
    [2] = self.startPosition[2]
  }
  self.creditsList     = self:loadCreditsConfig()
  self.supportersList  = self:loadSupportersConfig()

  widget.setText(self.creditsLabel, self:buildCreditsLabel())
end

function Customizer.Credits:handleMessage(message)

end

function Customizer.Credits:update(dt)
  if not self.isActive then return end

  self:scrollUp(dt)
end

function Customizer.Credits:loadCreditsConfig()
  return root.assetJson("/interface/sexbound/customizer/credits.json")
end

function Customizer.Credits:loadSupportersConfig()
  return root.assetJson("/interface/sexbound/customizer/supporters.json")
end

function Customizer.Credits:buildCreditsLabel()
  local label = "^shadow;"

  for _,item in ipairs(self.creditsList) do
    label = label .. item.name .. "\n\n"
  end

  for _,item in ipairs(self.supportersList) do
    label = label .. item.name .. "\n\n"
  end

  return label
end

function Customizer.Credits:scrollUp(dt)
  self.currentPosition[2] = self.currentPosition[2] + (dt * self.scrollSpeed)

  widget.setPosition(self.creditsLabel, self.currentPosition)
end

function Customizer.Credits:handleSelectTab(data)
  if (data.targetTabName == "creditsTab") then
    self.isActive = true

    self:reset()
  else
    self.isActive = false
  end

  widget.setVisible("creditsTab", self.isActive)
end

function Customizer.Credits:reset()
  self.currentPosition[2] = self.startPosition[2]

  widget.setPosition(self.creditsLabel, self.currentPosition)
end
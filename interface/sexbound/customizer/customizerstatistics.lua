Customizer.Statistics = {}
Customizer.Statistics_mt = { __index = Customizer.Statistics }

--- Instantiantes a new instance.
-- @param config
function Customizer.Statistics:new(parent)
  return setmetatable({
    _parent = parent,
    itemListName = "statisticsTab.statisticsList.itemList",
    isActive     = false
  }, Customizer.Statistics_mt)
end

function Customizer.Statistics:init()
  self:reset()
end

function Customizer.Statistics:handleMessage(message)

end

function Customizer.Statistics:update(dt)
  if not self.isActive then return end
end

function Customizer.Statistics:addListItem(text)
  local listItem = widget.addListItem(self.itemListName)

  listItem = string.format(self.itemListName .. ".%s", listItem)

  widget.setText(string.format("%s.itemName", listItem), text)
  widget.setFontColor(string.format("%s.itemName", listItem), { 255, 255, 255, 255 })
end

function Customizer.Statistics:handleSelectTab(data)
  if (data.targetTabName == "statisticsTab") then
    self:reset()

    self.isActive = true
  else
    self.isActive = false
  end

  widget.setVisible("statisticsTab", self.isActive)
end

function Customizer.Statistics:reset()
  widget.clearListItems(self.itemListName)

  self.statisticsConfig = self._parent.config.statistics or {}

  local haveSexCount = self.statisticsConfig.haveSexCount or 0
  self:addListItem("^shadow;> You've had sex ^green;" .. haveSexCount .. "^reset;^shadow; time(s)")
  --widget.setText("statisticsTab.statHaveSexCountLabel", "HAVE SEX COUNT : " .. haveSexCount)

  local climaxCount = self.statisticsConfig.climaxCount or 0
  self:addListItem("^shadow;> You've had ^green;" .. climaxCount .. "^reset;^shadow; orgasm(s)")
  --widget.setText("statisticsTab.statClimaxCountLabel", "CLIMAX COUNT : " .. climaxCount)

  local pregnancyCount = self.statisticsConfig.pregnancyCount or 0
  self:addListItem("^shadow;> You've had ^green;" .. pregnancyCount .. "^reset;^shadow; pregnancies")
  --widget.setText("statisticsTab.statPregnancyCountLabel", "PREGNANCY COUNT : " .. pregnancyCount)

  local impregnateOtherCount = self.statisticsConfig.impregnateOtherCount or 0
  self:addListItem("^shadow;> You've impregnated ^green;" .. impregnateOtherCount .. "^reset;^shadow; other entities")
  --widget.setText("statisticsTab.statImpregnateOtherCountLabel", "IMPREGNATE OTHER COUNT : " .. impregnateOtherCount)
end
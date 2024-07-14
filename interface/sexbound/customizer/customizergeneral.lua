Customizer.General = {}
Customizer.General_mt = { __index = Customizer.General }

--- Instantiantes a new instance.
-- @param config
function Customizer.General:new(parent)
  return setmetatable({
    _parent = parent,
    isActive = true,
    currentSexbux = 0,
    currentSubGender = "None",
    currentSubGenderIndex = 1,
    subGenderList = {},
    sterilized = false,
    infertile = false
  }, Customizer.General_mt)
end

function Customizer.General:init()
  self.subGenderList = self._parent.config.subGenders or {}
  table.insert(self.subGenderList, 1, {name="None",available=true})
  self.maxSubGenderIndex = #self.subGenderList
  
  local currentSubGender = self._parent.config.currentGender or "None"
  if currentSubGender ~= "male" and currentSubGender ~= "female" then self.currentSubGender = currentSubGender end
  
  self:updateSexbuxAmount()
  widget.setText("generalTab.subGenderLabel", self.currentSubGender)
  for i,v in ipairs(self.subGenderList) do
    if v.name == self.currentSubGender then self.currentSubGenderIndex = i break end
  end
  
  self.sterilized = self._parent.config.sterilized
  if self.sterilized == nil then self.sterilized = false end
  if self.sterilized then widget.setText("generalTab.sterilizeLabel", "^shadow;You currently ^orange;are^reset;^shadow; sterilized.") end
  
  self.infertile = self._parent.config.infertile
  if self.infertile == nil then self.infertile = false end
  if self.infertile then widget.setText("generalTab.infertileLabel", "^shadow;You currently ^orange;are^reset;^shadow; infertile.")
  else widget.setButtonEnabled("generalTab.infertileConfirm", false) end
end

function Customizer.General:handleMessage(message)

end

function Customizer.General:update(dt)
  if not self.isActive then return end

  self:updateSexbuxAmount()
end

function Customizer.General:handleSelectTab(data)
  if (data.targetTabName == "generalTab") then
    self.isActive = true
  else
    self.isActive = false
  end

  widget.setVisible("generalTab", self.isActive)

  self:updateSexbuxAmount()
end

function Customizer.General:updateSexbuxAmount()
  self.currentSexbux = player.currency("sexbux")
  widget.setText("generalTab.sexbuxValue", "^shadow;" .. self.currentSexbux)
end

function Customizer.General:nextSubGender()
  self.currentSubGenderIndex = self.currentSubGenderIndex + 1
  if self.currentSubGenderIndex > self.maxSubGenderIndex then self.currentSubGenderIndex = 1 end
  
  local subgender = self.subGenderList[self.currentSubGenderIndex] or {}
  self:changeSubGender(subgender)
end

function Customizer.General:prevSubGender()
  self.currentSubGenderIndex = self.currentSubGenderIndex - 1
  if self.currentSubGenderIndex <= 0 then self.currentSubGenderIndex = self.maxSubGenderIndex end
  
  local subgender = self.subGenderList[self.currentSubGenderIndex] or {}
  self:changeSubGender(subgender)
end

function Customizer.General:applySubGender()
    local target = self.subGenderList[self.currentSubGenderIndex] or {}
    target = target.name or ""
    
    if target == "" or target == self.currentSubGender then
      widget.playSound("/sfx/interface/clickon_error.ogg")
      return false
    end
    
    local res = player.consumeCurrency("sexbux", 2500)
    if not res then
      widget.playSound("/sfx/interface/clickon_error.ogg")
      return false
    end
    
    self.currentSubGender = target
    if target == "None" then target = nil end
    world.sendEntityMessage(player.id(), "Sexbound:SubGender:Change", target)
    widget.setVisible("generalTab.subGenderConfirm", false)
    widget.setButtonEnabled("generalTab.subGenderConfirm", false)
    widget.setVisible("generalTab.subGenderPriceIcon", false)
    widget.setVisible("generalTab.subGenderPrice", false)
end

function Customizer.General:changeSubGender(subgender)
    local name = subgender.name or "Unknown"
    local enabled = subgender.available or false
    
    widget.setText("generalTab.subGenderLabel", "^shadow;"..name)
    if name == self.currentSubGender then
      widget.setVisible("generalTab.subGenderConfirm", false)
      widget.setVisible("generalTab.subGenderPriceIcon", false)
      widget.setVisible("generalTab.subGenderPrice", false)
    else
      widget.setVisible("generalTab.subGenderConfirm", true)
      widget.setVisible("generalTab.subGenderPriceIcon", true)
      widget.setVisible("generalTab.subGenderPrice", true)
    end
    
    if enabled then
      widget.setButtonEnabled("generalTab.subGenderConfirm", true)
    else
      widget.setButtonEnabled("generalTab.subGenderConfirm", false)
    end
end

function Customizer.General:sterilize()
    local res = player.consumeCurrency("sexbux", 1000)
    if not res then
        widget.playSound("/sfx/interface/clickon_error.ogg")
        return false
    end
    
    if self.sterilized then
        widget.setText("generalTab.sterilizeLabel", "^shadow;You currently ^orange;are not^reset;^shadow; sterilized.")
        world.sendEntityMessage(player.id(), "Sexbound:Status:RemoveStatus", "sterilized")
    else
        widget.setText("generalTab.sterilizeLabel", "^shadow;You currently ^orange;are^reset;^shadow; sterilized.")
        world.sendEntityMessage(player.id(), "Sexbound:Status:AddStatus", "sterilized")
    end
    self.sterilized = not self.sterilized
end

function Customizer.General:makeFertile()
    if not self.infertile then
        widget.playSound("/sfx/interface/clickon_error.ogg")
        return false
    end
    
    local res = player.consumeCurrency("sexbux", 2000)
    if not res then
        widget.playSound("/sfx/interface/clickon_error.ogg")
        return false
    end
    
    widget.setText("generalTab.infertileLabel", "^shadow;You currently ^orange;are not^reset;^shadow; infertile.")
    world.sendEntityMessage(player.id(), "Sexbound:Status:RemoveStatus", "infertile")
    
    self.infertile = false
end
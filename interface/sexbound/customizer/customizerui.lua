require "/scripts/util.lua"

function init()
  self.customizer = Customizer.new()

  self.customizer:init()
end

function update(dt)
  self.customizer:update(dt)
end

function addonModItemSelected(...)
  self.customizer:broadcast({
    name = "addonModItemSelected",
    args = { ... }
  })
end

function selectTab(index, data)
  for _,i in ipairs(self.customizer.tabIndices) do
    self.customizer.tabs[i]:handleSelectTab(data)
  end
end

subGenderSelector = {}
function subGenderSelector.up()
    self.customizer.tabs["General"]:nextSubGender()
end

function subGenderSelector.down()
    self.customizer.tabs["General"]:prevSubGender()
end

function subGenderConfirm()
    self.customizer.tabs["General"]:applySubGender()
end

function sterilizeConfirm()
    self.customizer.tabs["General"]:sterilize()
end
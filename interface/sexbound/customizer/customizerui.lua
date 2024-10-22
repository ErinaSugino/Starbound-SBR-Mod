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
  if not self.customizer._inited then return end
  for _,i in ipairs(self.customizer.tabIndices) do
    self.customizer.tabs[i]:handleSelectTab(data)
  end
end

subGenderSelector = {}
function subGenderSelector.up()
    if not self.customizer._inited then return end
    self.customizer.tabs["General"]:nextSubGender()
end

function subGenderSelector.down()
    if not self.customizer._inited then return end
    self.customizer.tabs["General"]:prevSubGender()
end

function subGenderConfirm()
    if not self.customizer._inited then return end
    self.customizer.tabs["General"]:applySubGender()
end

function sterilizeConfirm()
    if not self.customizer._inited then return end
    self.customizer.tabs["General"]:sterilize()
end

function canBeDefeatedConfirm()
    if not self.customizer._inited then return end
    self.customizer.tabs["General"]:toggleCanBeDefeated()
end

function canDefeatOthersConfirm()
    if not self.customizer._inited then return end
    self.customizer.tabs["General"]:toggleCanDefeatOthers()
end
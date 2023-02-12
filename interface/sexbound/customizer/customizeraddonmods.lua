Customizer.AddonMods = {}
Customizer.AddonMods_mt = { __index = Customizer.AddonMods }

--- Instantiantes a new instance.
-- @param config
function Customizer.AddonMods:new()
  return setmetatable({
    isActive       = false,
    itemListName   = "addonModsTab.addonModsList.itemList",
    itemAuthorName = "addonModsTab.authorName",
    itemModDesc    = "addonModsTab.modDesc",
    itemModLink    = "addonModsTab.modLink",
    itemModName    = "addonModsTab.modName",
    listItems      = {},
    maxLengthDisplayName = 20
  }, Customizer.AddonMods_mt)
end

function Customizer.AddonMods:init()
  self.modsList = self:loadModsListConfig()

  self:refreshModsList()
end

function Customizer.AddonMods:handleMessage(message)
  if message.name == "addonModItemSelected" then
    self:handleItemSelected(message.args)
  end
end

function Customizer.AddonMods:update(dt)
  if not self.isActive then return end
end

function Customizer.AddonMods:addListItem(modItem)
  if modItem.skip == true then return end

  local displayName = self:formatDisplayName(modItem.name)

  local listItem = widget.addListItem(self.itemListName)

  table.insert(self.listItems, listItem)

  listItem = string.format(self.itemListName .. ".%s", listItem)

  widget.setText(string.format("%s.itemName", listItem), "^shadow;" .. displayName)
  widget.setFontColor(string.format("%s.itemName", listItem), { 255, 255, 255, 255 })

  if modItem.icon then
    widget.setImage(string.format("%s.itemIcon", listItem), modItem.icon)

    -- widget.setImageScale(`String` widgetName, `float` imageScale)
  end

  -- Store mod item data into the list item
  widget.setData((listItem), modItem)
end

function Customizer.AddonMods:formatDisplayName(displayName)
  if string.len(displayName) > self.maxLengthDisplayName then
    return string.sub(displayName, 0, self.maxLengthDisplayName) .. ".."
  else
    return displayName
  end
end

function Customizer.AddonMods:handleItemSelected(...)
  local selected = widget.getListSelected(self.itemListName)

  self.selectedItem = widget.getData(string.format("%s.%s", self.itemListName, selected))

  widget.setText(self.itemModName, "^shadow;" .. self.selectedItem.name)
  widget.setText(self.itemModLink, self.selectedItem.link)
  widget.setText(self.itemAuthorName, "^shadow;" .. self.selectedItem.author.name)
  widget.setText(self.itemModDesc, "^shadow;" .. self.selectedItem.desc)
end

function Customizer.AddonMods:loadModsListConfig()
  return root.assetJson("/interface/sexbound/customizer/addonmods.json")
end

function Customizer.AddonMods:refreshModsList()
  widget.clearListItems(self.itemListName)

  self.listItems = {}

  for _,modItem in ipairs(self.modsList) do
    self:addListItem(modItem)
  end

  -- Select the first list item
  widget.setListSelected(self.itemListName, self.listItems[1])
end

function Customizer.AddonMods:handleSelectTab(data)
  if (data.targetTabName == "addonModsTab") then
    self.isActive = true
  else
    self.isActive = false
  end

  widget.setVisible("addonModsTab", self.isActive)
end
local ApplyApparel = {}
local ApplyApparel_mt = {
    __index = ApplyApparel
}

require "/scripts/util.lua"

--- Instantiate a new instance.
function ApplyApparel.new()
  return setmetatable({
    _config = config.getParameter("applyConfig")
  }, ApplyApparel_mt)
end

--- Used by activate hook to handle the activate event.
-- @param fireMode
-- @param shiftHeld
function ApplyApparel:handleActivate(fireMode, shiftHeld)
  if self._config.itemName ~= nil then self:attachToOne() end
  if self._config.itemName == nil then self:attachToAll() end
end

--- Attach one item to wornType part specified in the item's config
function ApplyApparel:attachToOne()
  local wornType = self._config.wornType
  local target   = self._config.target or 1
  local params   = { item_name = self._config.itemName }
  local message  = self:buildSendEntityMessage(wornType, false)
  if message == nil then return end
  world.sendEntityMessage(entity.id(), message .. target, params)
  world.sendEntityMessage(entity.id(), "applyStatusEffect", "sexbound_applyapparel")
  item.consume(1)
end

--- Attach multiple items to wornType part specified in the item's config
function ApplyApparel:attachToAll()
  local params = {}
  for k,v in ipairs(self._config) do
    table.insert(params, { item_name = v.itemName })
  end
  local message = self:buildSendEntityMessage(self._config[1].wornType, true)
  if message == nil then return end
  world.sendEntityMessage(entity.id(), message, params)
  world.sendEntityMessage(entity.id(), "applyStatusEffect", "sexbound_applyapparel")
  item.consume(1)
end

-- Builds message to send to remote entity
-- @param wornType
-- @param isMultiple
function ApplyApparel:buildSendEntityMessage(wornType, isMultiple)
  wornType = wornType or "nipple" -- default to nipple to ensure backwards compatibility
  if wornType == "nipple" then
    if isMultiple then
      return "Sexbound:Apparel:AttachToNipples"
    else
      return "Sexbound:Apparel:AttachToNipple"
    end
  end
  if wornType == "back" then
    return "Sexbound:Apparel:AttachToBack"
  end
  if wornType == "chest" then
    return "Sexbound:Apparel:AttachToChest"
  end
  if wornType == "groin" then
    return "Sexbound:Apparel:AttachToGroin"
  end
  if wornType == "head" then
    return "Sexbound:Apparel:AttachToHead"
  end
  if wornType == "legs" then
    if isMultiple then
      return "Sexbound:Apparel:AttachToLegs"
    else
      return "Sexbound:Apparel:AttachToLeg"
    end
  end
end

-- Active Item Hooks
function init() self.applyApparel = ApplyApparel.new() end
function activate(fireMode, shiftHeld) self.applyApparel:handleActivate(fireMode, shiftHeld) end

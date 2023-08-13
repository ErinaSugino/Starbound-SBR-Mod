if SXB_RUN_TESTS ~= true then
  require "/scripts/util.lua"
  require "/scripts/messageutil.lua"
  require "/scripts/sexbound/util.lua"
end

local PregnancyTestBox = {}
local PregnancyTestBox_mt = { __index = PregnancyTestBox }

function PregnancyTestBox:new()
  local _self = setmetatable({
    entityId = activeItem.ownerEntityId(),
    maxUses = config.getParameter("durability", 10)
  }, PregnancyTestBox_mt)
  
  _self:init()
  
  return _self
end

function PregnancyTestBox:init()
    activeItem.setTwoHandedGrip(true)
    local currentUses = config.getParameter("durabilityHit", self.maxUses)
    self:updateIcon(currentUses)
end

function PregnancyTestBox:update(dt)
  --promises:update()
end

function PregnancyTestBox:activate(fireMode, shiftHeld)
  local oldAmount = config.getParameter("durabilityHit", 10)
  local newAmount = oldAmount - 1
  activeItem.setInstanceValue("durabilityHit", newAmount)
  world.sendEntityMessage(self.entityId, "Sexbound:Item:Give", "lox_pregnancytest")
  if newAmount <= 0 then item.consume(1)
  else self:updateIcon(newAmount) end
end

function PregnancyTestBox:updateIcon(usesLeft)
    usesLeft = usesLeft or self.maxUses
    if usesLeft < self.maxUses then
        activeItem.setInventoryIcon("/items/active/sxb_pregnancytestbox/pregnancytestbox_modern_open.png")
    end
end

-- Active Item Hooks --

function init()
  self.pregnancyTestBox = PregnancyTestBox:new()
end

function update(dt)
  self.pregnancyTestBox:update(dt)
end

function activate(fireMode, shiftHeld)
  self.pregnancyTestBox:activate(fireMode, shiftHeld)
end
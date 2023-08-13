require "/scripts/messageutil.lua"

function update(dt) promises:update() end

function activate(fireMode, shiftHeld)
  if not player then return end -- Limit this item to only work for players

  if activeItem.ownerEntityId() then
    world.sendEntityMessage(player.id(), "Sexbound:CustomizerUI:Show")
  end
end
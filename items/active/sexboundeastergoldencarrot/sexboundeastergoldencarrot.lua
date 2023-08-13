-- Gives the player the value of the item's price.
-- This script is overridden by the SxB Easter Mod.
function activate(fireMode, shiftHeld)
  item.consume(1)
  player.giveItem({ "sexboundeasteregg", 100 })
end
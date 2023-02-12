function activate(fireMode, shiftHeld)
  world.sendEntityMessage(entity.id(), "Sexbound:Apparel:ResetNipples", {})
  world.sendEntityMessage(entity.id(), "applyStatusEffect", "sexbound_applyapparel")
  item.consume(1)
end
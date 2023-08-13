function activate(fireMode, shiftHeld)
  if not storage.firing then
    item.consume(1)
    player.warp("instanceworld:sexscape", "beam")
  end
end
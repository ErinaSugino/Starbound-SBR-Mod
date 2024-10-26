require "/scripts/messageutil.lua"

function init()
  self.config = config.getParameter("config")
  self.canvas = widget.bindCanvas("interface")
  widget.focus("interface")
end

function update(dt)
  if not status.statusProperty("sexbound_defeated") then
    pane.dismiss()
  end

  self.canvas:clear()
end

function canvasClickEvent(position, button, isButtonDown)

end

function canvasKeyEvent(key, isKeyDown)

end

function dismissed()
  world.sendEntityMessage(player.id(), "SexboundDefeat:Breakout")
end
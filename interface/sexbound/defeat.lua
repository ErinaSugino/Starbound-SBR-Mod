require "/scripts/messageutil.lua"

function init()
  self.config = config.getParameter("config")
  self.canvas = widget.bindCanvas("interface")
  self.promise = PromiseKeeper.new()
  widget.focus("interface")
end

function update(dt)
  self.promise:add(
    world.findUniqueEntity(self.config.nodeUniqueId),
    function(result) return end,
    function()
      pane.dismiss()
    end
  )

  self.promise:update()

  self.canvas:clear()
end

function canvasClickEvent(position, button, isButtonDown)

end

function canvasKeyEvent(key, isKeyDown)

end

function dismissed()
  world.sendEntityMessage(player.id(), "SexboundDefeat:Breakout")
end
-- Hook - init
function init()
  self.sourceId = config.getParameter("sourceId")
end

function clickConfirm()
  world.sendEntityMessage(self.sourceId, "Sexbound:UI:Confirm", { result = true })
  pane.dismiss()
end

function clickCancel()
  world.sendEntityMessage(self.sourceId, "Sexbound:UI:Confirm", { result = false })
  pane.dismiss()
end
require "/scripts/messageutil.lua"

function init()
  self.containerEntityId = pane.containerEntityId()
end

function update(dt)
  promises:update()
end

function dismissed()
  if not self.isCrafting then clear() end
end

function clear()
  local entityId = self.containerEntityId or pane.containerEntityId()

  local contents = world.containerItems(entityId)
  
  for i=1,2 do
    if contents[i] then
      player.giveItem(contents[i])
    end
  end
  
  world.containerTakeAll(entityId)
end

function craft()
  promises:add(world.sendEntityMessage(pane.containerEntityId(), "craft", {playerId = player.id()}), function(result)
    if result == "pass" then
      self.isCrafting = true
    
      pane.dismiss()
    else
      if result == "busy" then
        world.sendEntityMessage(pane.playerEntityId(), "queueRadioMessage", {
          messageId = "craftaphroditesbowfailed",
          unique    = false,
          text      = config.getParameter("messageProcessing")
        })
      else
        world.sendEntityMessage(pane.playerEntityId(), "queueRadioMessage", {
          messageId = "craftaphroditesbowfailed",
          unique    = false,
          text      = config.getParameter("messageMissing")
        })
      end
    end
  end)
end


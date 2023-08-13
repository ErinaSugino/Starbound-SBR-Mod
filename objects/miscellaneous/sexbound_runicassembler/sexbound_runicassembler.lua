require "/scripts/messageutil.lua"

function init()
  self.myPromises = PromiseKeeper.new()

  resetIngredients()

  message.setHandler("craft", function(_,_,args) return craft(args) end)
end

function checkIngredients()
  local contents = world.containerItems(entity.id())
  
  if contents[1] and contents[1].name and self.ingredients[contents[1].name] ~= nil then
    self.ingredients[contents[1].name] = true
  end
  
  if contents[2] and contents[2].name and self.ingredients[contents[2].name] ~= nil then
    self.ingredients[contents[2].name] = true
  end
  
  return self.ingredients.sexbound_runic_cube and self.ingredients.sexbound_keystonechain
end

function resetIngredients()
  self.ingredients = {
    sexbound_runic_cube = false,
    sexbound_keystonechain = false
  }
end

function craft(args)
  if animator.animationState("main") ~= "idling" then
	return "busy"  
  end
  
  self.craftPlayerId = args.playerId

  if checkIngredients() then
    animator.setAnimationState("main", "crafting", true)
    self.craftingTimer = 0
    world.containerTakeAll(entity.id())
    return "pass"
  end
  
  return "fail"
end

function update(dt)
  self.myPromises:update()

  if animator.animationState("main") == "craftingEnd" then
    return
  end

  if animator.animationState("main") == "craftingLoop" then
    self.craftingTimer = self.craftingTimer + dt
    
    if self.craftingTimer >= 5 then
      animator.setAnimationState("main", "craftingEnd", true)
    end
    
    return
  end

  if animator.animationState("main") == "crafting" then return end

  if animator.animationState("main") == "finished" then
    animator.setAnimationState("main", "idling", true)
    
    hideStaff()
    hideTwine()
    
    world.spawnItem("sexbound_runic_cache", object.toAbsolutePosition(animator.partPoint("spawn", "offset")))
	
    self.craftPlayerId = nil
  end

  checkIngredients()

  if self.ingredients.sexbound_runic_cube then
    showStaff()
  else hideStaff() end
  
  if self.ingredients.sexbound_keystonechain then
    showTwine()
  else hideTwine() end
  
  resetIngredients()
end

function showStaff()
  animator.setGlobalTag("part-bow", config.getParameter("animationParts.bow"))
end

function hideStaff()
  animator.setGlobalTag("part-bow", config.getParameter("animationParts.empty"))
end

function showTwine()
  animator.setGlobalTag("part-string", config.getParameter("animationParts.string"))
end

function hideTwine()
  animator.setGlobalTag("part-string", config.getParameter("animationParts.empty"))
end

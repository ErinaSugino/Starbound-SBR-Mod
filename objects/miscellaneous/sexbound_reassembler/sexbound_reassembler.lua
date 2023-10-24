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
	amounttoprint = contents[1].count or 0
  end
  
  return self.ingredients.sexbound_sexbox or 
  self.ingredients.sexbound_dildo_v2 or 
  self.ingredients.sexbound_fleshlight_v2 or
  self.ingredients.sexbound_tentacleplant_v2 or
  self.ingredients.sexbound_keystoneE or
  self.ingredients.sexbound_keystoneF or
  self.ingredients.sexbound_keystoneH or
  self.ingredients.sexbound_keystoneI or
  self.ingredients.sexbound_keystoneS
end

function resetIngredients()
  self.ingredients = {
    sexbound_sexbox = false,
    sexbound_keystoneE = false,
    sexbound_keystoneF = false,
    sexbound_keystoneH = false,
    sexbound_keystoneI = false,
    sexbound_keystoneS = false,
    sexbound_dildo_v2 = false,
    sexbound_fleshlight_v2 = false,
    sexbound_tentacleplant_v2 = false,
    sexbound_keystones = false
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
	hideKeystoneE()
	hideKeystoneF()
	hideKeystoneH()
	hideKeystoneI()
	hideKeystoneS()
	hideDildo()
	hideFleshlight()
	hideTentacleplant()
    hideTwine()
    
	if self.ingredients.sexbound_sexbox then
      world.spawnItem("sexbound_sexboxplus", object.toAbsolutePosition(animator.partPoint("spawn", "offset")), amounttoprint)
	elseif self.ingredients.sexbound_keystoneE or self.ingredients.sexbound_keystoneF or self.ingredients.sexbound_keystoneH or self.ingredients.sexbound_keystoneI or self.ingredients.sexbound_keystoneS then
	  world.spawnItem("sexbound_keystoneT", object.toAbsolutePosition(animator.partPoint("spawn", "offset")), amounttoprint)
	elseif self.ingredients.sexbound_dildo_v2 then
	  world.spawnItem("sexbound_dildo_v2", object.toAbsolutePosition(animator.partPoint("spawn", "offset")), amounttoprint)
	elseif self.ingredients.sexbound_fleshlight_v2 then
	  world.spawnItem("sexbound_fleshlight_v2", object.toAbsolutePosition(animator.partPoint("spawn", "offset")), amounttoprint)
	elseif self.ingredients.sexbound_tentacleplant_v2 then
	  world.spawnItem("sexbound_tentacleplant_v2", object.toAbsolutePosition(animator.partPoint("spawn", "offset")), amounttoprint)
	end
	
    self.craftPlayerId = nil
  end

  checkIngredients()

  if self.ingredients.sexbound_sexbox then
    showStaff()
  else hideStaff() end
  
  if self.ingredients.sexbound_keystoneE then
    showKeystoneE()
  else hideKeystoneE() end
  
  if self.ingredients.sexbound_keystoneF then
    showKeystoneF()
  else hideKeystoneF() end
  
  if self.ingredients.sexbound_keystoneH then
    showKeystoneH()
  else hideKeystoneH() end
  
  if self.ingredients.sexbound_keystoneI then
    showKeystoneI()
  else hideKeystoneI() end
  
  if self.ingredients.sexbound_keystoneS then
    showKeystoneS()
  else hideKeystoneS() end
  
  if self.ingredients.sexbound_dildo_v2 then
    showDildo()
  else hideDildo() end
  
  if self.ingredients.sexbound_fleshlight_v2 then
    showFleshlight()
  else hideFleshlight() end
  
  if self.ingredients.sexbound_tentacleplant_v2 then
    showTentacleplant()
  else hideTentacleplant() end
  
  resetIngredients()
end

function showStaff()
  animator.setGlobalTag("part-bow", config.getParameter("animationParts.bow"))
end

function hideStaff()
  animator.setGlobalTag("part-bow", config.getParameter("animationParts.empty"))
end

function showKeystoneE()
  animator.setGlobalTag("part-keystoneE", config.getParameter("animationParts.keystoneE"))
end

function hideKeystoneE()
  animator.setGlobalTag("part-keystoneE", config.getParameter("animationParts.empty"))
end

function showKeystoneF()
  animator.setGlobalTag("part-keystoneF", config.getParameter("animationParts.keystoneF"))
end

function hideKeystoneF()
  animator.setGlobalTag("part-keystoneF", config.getParameter("animationParts.empty"))
end

function showKeystoneH()
  animator.setGlobalTag("part-keystoneH", config.getParameter("animationParts.keystoneH"))
end

function hideKeystoneH()
  animator.setGlobalTag("part-keystoneH", config.getParameter("animationParts.empty"))
end

function showKeystoneI()
  animator.setGlobalTag("part-keystoneI", config.getParameter("animationParts.keystoneI"))
end

function hideKeystoneI()
  animator.setGlobalTag("part-keystoneI", config.getParameter("animationParts.empty"))
end

function showKeystoneS()
  animator.setGlobalTag("part-keystoneS", config.getParameter("animationParts.keystoneS"))
end

function hideKeystoneS()
  animator.setGlobalTag("part-keystoneS", config.getParameter("animationParts.empty"))
end

function showDildo()
  animator.setGlobalTag("part-dildo", config.getParameter("animationParts.dildo"))
end

function hideDildo()
  animator.setGlobalTag("part-dildo", config.getParameter("animationParts.empty"))
end

function showFleshlight()
  animator.setGlobalTag("part-fleshlight", config.getParameter("animationParts.fleshlight"))
end

function hideFleshlight()
  animator.setGlobalTag("part-fleshlight", config.getParameter("animationParts.empty"))
end

function showTentacleplant()
  animator.setGlobalTag("part-tentacleplant", config.getParameter("animationParts.tentacleplant"))
end

function hideTentacleplant()
  animator.setGlobalTag("part-tentacleplant", config.getParameter("animationParts.empty"))
end

function showTwine()
  animator.setGlobalTag("part-string", config.getParameter("animationParts.string"))
end

function hideTwine()
  animator.setGlobalTag("part-string", config.getParameter("animationParts.empty"))
end

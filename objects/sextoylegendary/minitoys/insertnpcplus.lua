require("/scripts/sexbound/utils/generateactorplus.lua")

sexbound_insert_gnome_init = init
function init()
  storage.sexboundjar = storage.sexboundjar or  { actors = {} }

  tryRetrievingActorsFromObjectConfig()
  tryGeneratingActors()
  updateObjectSexboundConfig()
  
  sexbound_insert_gnome_init()

  loadActorsIntoSexbound()
  
  
  -- Animation bullshit. 
  -- Required properties in the object:
  -- -- VITAL: isAnimated(boolean), TRUE for it to work at all!
  -- -- animationCycle(float), frames(int), animationType(string) where "string" -> "loop", "boomerang" or "catch".
  -- -- Optional: extraWait(int) for catch type, default 2.
  animaframe = 0
  animamode = 1
  concurrentDt = 0
  animationLength = 0
  animationLength = (config.getParameter("animationCycle", 1))
  framesAmount = (config.getParameter("frames", 1)-1)
  extraWait = config.getParameter("extraWait", 2)
  frameLength = (animationLength / framesAmount)
  animator.setGlobalTag("animaFrame", "default." .. tostring(animaframe))
end

-- main animation update is snuck in here.
function update(dt)
  Sexbound.API.update(dt)
  if (config.getParameter("isAnimated", nil) == "true") then
    if (config.getParameter("animationType", "loop") == "loop") then animationUpdateLoop(dt) end
    if (config.getParameter("animationType", "loop") == "boomerang") then animationUpdateBoomerang(dt) end
    if (config.getParameter("animationType", "loop") == "catch") then animationUpdateCatch(dt) end
  end
end

-- Animation update: loop. 
-- When it ends, it goes back to the start. Simple.
function animationUpdateLoop(dt)
    concurrentDt = (concurrentDt + (dt*2))
    animaframe = math.floor(concurrentDt / frameLength)
    if animaframe > framesAmount then animaframe = 0 concurrentDt = 0 end
    animator.setGlobalTag("animaFrame", "default." .. tostring(animaframe))
end

-- Animation update: boomerang. 
-- When it ends, it runs backwards towards frame 0. 
-- For animations that loop inverted, without adding extra frames.
function animationUpdateBoomerang(dt)
    if animamode == 1 then
        concurrentDt = (concurrentDt + (dt*2))
        animaframe = math.floor(concurrentDt / frameLength)
        if animaframe > framesAmount then 
            animaframe = framesAmount 
            concurrentDt = (framesAmount * frameLength)
            animamode  = -1
        end
    end
    if animamode == -1 then
        concurrentDt = (concurrentDt - (dt*2))
        animaframe = math.floor(concurrentDt / frameLength)
        if animaframe < 0 then 
            animaframe = 0 
            concurrentDt = 0 
            animamode  = 1
        end
    end
    animator.setGlobalTag("animaFrame", "default." .. tostring(animaframe))
end

-- Animation update: catch.
-- Similar to boomerang, will take a pause when it reaches either end of the animation.
-- Pause length is defined in extraWait(int) as frame-duration.
function animationUpdateCatch(dt)
    if animamode == 1 then
        concurrentDt = (concurrentDt + (dt*2))
        animaframe = math.floor(concurrentDt / frameLength)
        if animaframe > framesAmount then 
            animaframe = framesAmount 
            concurrentDt = 0
            animamode  = 0
        end
    end
    if animamode == 0 then
        concurrentDt = (concurrentDt + (dt*2))
        if ((concurrentDt * frameLength) >= (extraWait * frameLength)) then
            if animaframe == 0 then animamode = 1 end
            if animaframe == framesAmount then animamode = -1 end
        end
    end
    if animamode == -1 then
        concurrentDt = (concurrentDt - (dt*2))
        animaframe = math.floor(concurrentDt / frameLength)
        if animaframe < 0 then 
            animaframe = 0
            concurrentDt = 0 
            animamode  = 0
        end
    end
    animator.setGlobalTag("animaFrame", "default." .. tostring(animaframe))
end

function loadActorsIntoSexbound()
  for _,actor in pairs(storage.sexboundjar.actors or {}) do
    Sexbound.API.Actors.addActor(actor, false)
  end
end

function tryRetrievingActorsFromObjectConfig()
  if not isEmpty(storage.sexboundjar.actors) then return end
  local sexboundConfig = config.getParameter("sexboundConfig", {})
  storage.sexboundjar.actors = sexboundConfig.actors or {}
end

function tryGeneratingActors()
  local mainSxBConfig = root.assetJson("/sexbound.config")
  if not isEmpty(storage.sexboundjar.actors) then return end
  
  local raceName = config.getParameter("actorRace", nil)
  local actor = GenerateActor.makeRandomNPC(raceName)
  
  actor.backwear  = applyBackwear()
  actor.chestwear = applyChestwear()
  actor.headwear  = applyHeadwear(actor.identity)
  actor.legswear  = applyLegswear()

  local defaultSoundPitch = {1.5, 1.5}
  actor.identity.sxbMoanPitch   = config.getParameter("actorSxbMoanPitch",   defaultSoundPitch)
  actor.identity.sxbOrgasmPitch = config.getParameter("actorSxbOrgasmPitch", defaultSoundPitch)

  local futanariPluginConfig = mainSxBConfig.actor.plugins.futanari or {}
  if futanariPluginConfig.enable == true then
    local chance = config.getParameter("actorChanceToSpawnWithGenderAsFutanari", 0.05)
    if util.randomInRange({0.0, 1.0}) <= chance then
      identity.gender = "female"
      identity.sxbSubGender = "futanari"
    end
  end

  table.insert(storage.sexboundjar.actors, actor)
end

function updateObjectSexboundConfig()
  local sexboundConfig = config.getParameter("sexboundConfig", {})

  sexboundConfig.actors = storage.sexboundjar.actors

  object.setConfigParameter("sexboundConfig", sexboundConfig)

  updateObjectShortDescription(sexboundConfig.actors)
end

function updateObjectShortDescription(actors)
  if isEmpty(actors) then return end

  local actor  = actors[1]
  local name   = actor.identity.name
  local gender = actor.identity.gender

  if gender == "male"   then gender = "M" end
  if gender == "female" then gender = "F" end
  if actor.identity.sxbSubGender ~= nil then gender = "?" end

  local shortdescription = config.getParameter("shortdescriptionPrefix", "X.I.A.J.")
  shortdescription = util.split(shortdescription, " ")[1] .. " (" .. name .. " - " .. gender .. ")"
  object.setConfigParameter("shortdescription", shortdescription)
end

function applyBackwear()
  local backwearItemName = config.getParameter("actorBackwear", nil)
  local backwearItemNameType = type(backwearItemName)
  if backwearItemNameType ~= "string" and backwearItemNameType ~= "table" then return nil end
  return buildBackwearItemConfig(backwearItemName)
end

function applyChestwear()
  local chestwearItemName = config.getParameter("actorChestwear", nil)
  local chestwearItemNameType = type(chestwearItemName)
  if chestwearItemNameType ~= "string" and chestwearItemNameType ~= "table" then return nil end
  return buildChestwearItemConfig(chestwearItemName)
end

function applyHeadwear(identity)
  local headwearItemName = config.getParameter("actorHeadwear", nil)
  local headwearItemNameType = type(headwearItemName)
  if headwearItemNameType ~= "string" and headwearItemNameType ~= "table" then return nil end
  return buildHeadwearItemConfig(identity, headwearItemName)
end

function applyLegswear()
  local legswearItemName = config.getParameter("actorLegswear", nil)
  local legswearItemNameType = type(legswearItemName)
  if legswearItemNameType ~= "string" and legswearItemNameType ~= "table" then return nil end
  return buildLegswearItemConfig(legswearItemName)
end

function buildBackwearItemConfig(itemName)
  local itemConfig = getItemConfig(itemName)
  local itemSexboundConfig = itemConfig.config.sexboundConfig or {}
  return {
    addStatus = itemSexboundConfig.addStatus,
    image     = itemSexboundConfig.image,
    colors    = util.randomChoice(itemConfig.config.colorOptions)
  }
end

function buildChestwearItemConfig(itemName)
  local itemConfig = getItemConfig(itemName)
  local itemSexboundConfig = itemConfig.config.sexboundConfig or {}
  return {
    addStatus    = itemSexboundConfig.addStatus,
    body         = itemSexboundConfig.body,
    bodyPregnant = itemSexboundConfig.bodyPregnant,
    backSleeve   = itemSexboundConfig.backSleeve,
    frontSleeve  = itemSexboundConfig.frontSleeve,
    colors       = util.randomChoice(itemConfig.config.colorOptions)
  }
end

function buildLegswearItemConfig(itemName)
  local itemConfig = getItemConfig(itemName)
  local itemSexboundConfig = itemConfig.config.sexboundConfig or {}
  return {
    addStatus = itemSexboundConfig.addStatus,
    image     = itemSexboundConfig.image,
    colors    = util.randomChoice(itemConfig.config.colorOptions)
  }
end

function buildHeadwearItemConfig(identity, itemName)
  local itemConfig = getItemConfig(itemName)
  local itemSexboundConfig = itemConfig.config.sexboundConfig or {}
  local defaultImage = itemConfig.directory .. itemConfig.config[identity.gender .. "Frames"]
  local defaultMask  = itemConfig.directory .. itemConfig.config.mask
  return {
    addStatus = itemSexboundConfig.addStatus,
    image     = itemSexboundConfig.image or defaultImage,
    mask      = itemSexboundConfig.mask  or defaultMask,
    colors    = util.randomChoice(itemConfig.config.colorOptions)
  }
end

function getItemConfig(itemName)
  if type(itemName) == "table" then itemName = util.randomChoice(itemName) end
  return root.itemConfig(buildItemDescriptorForItem(itemName))
end

function buildItemDescriptorForItem(itemName)
  return { parameters = {}, name = itemName, count = 1 }
end
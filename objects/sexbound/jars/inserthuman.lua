require("/scripts/sexbound/utils/generateactor.lua")

local function loadActorsIntoSexbound()
  for _,actor in pairs(storage.sexboundjar.actors or {}) do
    Sexbound.API.Actors.addActor(actor, false)
  end
end

local function buildItemDescriptorForItem(itemName)
  return { parameters = {}, name = itemName, count = 1 }
end

local function getItemConfig(itemName)
  if type(itemName) == "table" then itemName = util.randomChoice(itemName) end
  return root.itemConfig(buildItemDescriptorForItem(itemName))
end

local function tryRetrievingActorsFromObjectConfig()
  if not isEmpty(storage.sexboundjar.actors) then return end
  local sexboundConfig = config.getParameter("sexboundConfig", {})
  storage.sexboundjar.actors = sexboundConfig.actors or {}
end

local function buildBackwearItemConfig(itemName)
  local itemConfig = getItemConfig(itemName)
  local itemSexboundConfig = itemConfig.config.sexboundConfig or {}
  return {
    addStatus = itemSexboundConfig.addStatus,
    image     = itemSexboundConfig.image,
    colors    = util.randomChoice(itemConfig.config.colorOptions)
  }
end

local function applyBackwear()
  local backwearItemName = config.getParameter("actorBackwear", nil)
  local backwearItemNameType = type(backwearItemName)
  if backwearItemNameType ~= "string" and backwearItemNameType ~= "table" then return nil end
  return buildBackwearItemConfig(backwearItemName)
end

local function buildChestwearItemConfig(itemName)
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

local function applyChestwear()
  local chestwearItemName = config.getParameter("actorChestwear", nil)
  local chestwearItemNameType = type(chestwearItemName)
  if chestwearItemNameType ~= "string" and chestwearItemNameType ~= "table" then return nil end
  return buildChestwearItemConfig(chestwearItemName)
end

local function buildHeadwearItemConfig(identity, itemName)
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

local function applyHeadwear(identity)
  local headwearItemName = config.getParameter("actorHeadwear", nil)
  local headwearItemNameType = type(headwearItemName)
  if headwearItemNameType ~= "string" and headwearItemNameType ~= "table" then return nil end
  return buildHeadwearItemConfig(identity, headwearItemName)
end

local function buildLegswearItemConfig(itemName)
  local itemConfig = getItemConfig(itemName)
  local itemSexboundConfig = itemConfig.config.sexboundConfig or {}
  return {
    addStatus = itemSexboundConfig.addStatus,
    image     = itemSexboundConfig.image,
    colors    = util.randomChoice(itemConfig.config.colorOptions)
  }
end

local function applyLegswear()
  local legswearItemName = config.getParameter("actorLegswear", nil)
  local legswearItemNameType = type(legswearItemName)
  if legswearItemNameType ~= "string" and legswearItemNameType ~= "table" then return nil end
  return buildLegswearItemConfig(legswearItemName)
end

local function tryGeneratingActors()
  local mainSxBConfig = root.assetJson("/sexbound.config")
  if not isEmpty(storage.sexboundjar.actors) then return end
  local actor = GenerateActor.makeRandomHuman()

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
      actor.identity.gender = "female"
      actor.identity.sxbSubGender = "futanari"
    end
  end

  table.insert(storage.sexboundjar.actors, actor)
end

local function updateObjectShortDescription(actors)
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

local function updateObjectSexboundConfig()
  local sexboundConfig = config.getParameter("sexboundConfig", {})

  sexboundConfig.actors = storage.sexboundjar.actors

  object.setConfigParameter("sexboundConfig", sexboundConfig)

  updateObjectShortDescription(sexboundConfig.actors)
end

local sexbound_insert_gnome_init = init
function init()
  storage.sexboundjar = storage.sexboundjar or  { actors = {} }

  tryRetrievingActorsFromObjectConfig()
  tryGeneratingActors()
  updateObjectSexboundConfig()

  sexbound_insert_gnome_init()

  loadActorsIntoSexbound()
end
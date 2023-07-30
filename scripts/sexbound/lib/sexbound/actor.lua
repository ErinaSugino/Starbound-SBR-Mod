--- Sexbound.Actor Class Module.
-- @classmod Sexbound.Actor
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor = {}
Sexbound.Actor_mt = { __index = Sexbound.Actor }

if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/apparel.lua")
	require("/scripts/sexbound/lib/sexbound/actor/mouth.lua")
	require("/scripts/sexbound/lib/sexbound/actor/status.lua")
	require("/scripts/sexbound/lib/sexbound/actor/storage.lua")
	require("/scripts/sexbound/lib/sexbound/actor/pluginmgr.lua")
end

--- Returns a reference to a new instance of this class.
-- @param parent
-- @param actorConfig
function Sexbound.Actor:new(parent, actorConfig)
  local self = setmetatable({
    _parent    = parent,
    _syncTimer = 0
  }, Sexbound.Actor_mt)
  
	-- Add ref. to this instance into the main messenger channel.
  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  -- Initialize new instance of Log with prefix set to "ACTR".
  self._log = Sexbound.Log:new("ACTR", self._parent:getConfig())
  
  -- Initialize the actor's config.
  self._config = copy(self._parent:getConfig().actor)
  
  -- Create new instance of apparel.
  self._apparel = Sexbound.Actor.Apparel:new( self )

  -- Create new instance of mouth.
  self._mouth = Sexbound.Actor.Mouth:new( self )
  
  -- Create new instance of status.
  self._status = Sexbound.Actor.Status:new( self )
  
  -- Create new instance of storage.
  self._storage = Sexbound.Actor.Storage:new( self )
  
  -- Initialize sync delta used for how often storage is synced
  self._syncDelta = self._config.syncDelta or 1

  -- Setup the actor.
  self:setup(actorConfig)
  
  return self
end

--- Processes received messages from the message queue. Messages are directed into each plugin automatically.
-- @param message
function Sexbound.Actor:onMessage(message)
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onMessage(message)
  end)
end

--- Resets this actor.
function Sexbound.Actor:reset(stateName)
  stateName = stateName or self:getParent():getStateMachine():stateDesc()
  
  local animState = self:setAnimationState(stateName)
  
  if animState == nil then return end
  
  local actorNumber = self:getActorNumber()
	
  self:resetGlobalAnimatorTags()
  
  self:resetTransformations()
  
	if not animState:getEnabled(actorNumber) or not animState:getVisible(actorNumber) then return end
	
  -- Apply rotations to actor's head
  self:rotatePart("Head", animState:getRotateHead(actorNumber))
  
  -- Apply rotations to actor's body
  self:rotatePart("Body", animState:getRotateBody(actorNumber))
  
  -- Resets the actor's image parts and directives
  if self:getEntityType() == "player" or self:getEntityType() == "npc" then
    self:resetParts(animState, self:validateSpecies(self:getSpecies()), self:validateGender(self:getGender()), self:resetDirectives(actorNumber))
  else
    self:resetParts(animState, self:getSpecies(), self:getGender(), self:resetDirectives(actorNumber))
  end
  
  -- Apply flip to head directives
  if self:getAnimationState():getFlipHead(actorNumber) then self:flipPart("Head") end
	
	-- Apply flip to body directives
	if self:getAnimationState():getFlipBody(actorNumber) then self:flipPart("Body") end
end

function Sexbound.Actor:resetDirectives(actorNumber)
  local directives = {
    body       = self:getIdentity("bodyDirectives")       or "",
    head       = self:getIdentity("bodyDirectives")       or "",
    emote      = self:getIdentity("emoteDirectives")      or "",
    hair       = self:getIdentity("hairDirectives")       or "",
    facialHair = self:getIdentity("facialHairDirectives") or "",
    facialMask = self:getIdentity("facialMaskDirectives") or ""
  }
  
  -- Merge in user defined directives
  directives.body = directives.body .. self._config.bodyDirectives or ""
  directives.head = directives.head .. self._config.headDirectives or ""
  
  directives.body, directives.head = directives.body .. directives.hair, directives.head .. directives.hair

	local eyepatchMask = "?submask=/items/armors/decorative/hats/eyepatch/mask.png"

  -- Filter out the eyepatch submask from custom hats
  directives.head = string.gsub(directives.head, eyepatchMask, "")
  directives.body = string.gsub(directives.body, eyepatchMask, "")

  return directives
end

function Sexbound.Actor:resetParts(animState, species, gender, directives)
  local entityGroup, parts, role = self:getEntityGroup(), {}, self:getRole()

  parts.armBack    = self:loadArmBackPart(animState, entityGroup, role, species)
  parts.armFront   = self:loadArmFrontPart(animState, entityGroup, role, species)
  parts.body       = self:loadBodyPart(animState, entityGroup, role, species, gender)
  parts.facialHair = self:loadFacialHairPart(entityGroup, species, directives)
  parts.facialMask = self:loadFacialMaskPart(entityGroup, species, directives)
  parts.hair       = self:loadHairPart(entityGroup, species, directives)
  parts.head       = self:loadHeadPart(entityGroup, role, species, gender, directives)
  parts.emote      = self:loadEmotePart(animState, entityGroup, role, species)

  parts.groin, directives.groin, directives.groinMask = self:loadGroin(entityGroup, role, species, gender)
  
	parts.overlay1 = self:loadOverlayPart(1) -- Load Overlay 1
  parts.overlay2 = self:loadOverlayPart(2) -- Load Overlay 2
	parts.overlay3 = self:loadOverlayPart(3) -- Load Overlay 3
	
  -- Set global animator tags.
  
  -- tags : gender
  animator.setGlobalTag(role .. "-gender", gender)
  
  -- tags : species
  animator.setGlobalTag(role .. "-species", species)

  -- tags : arm-front
  animator.setGlobalTag("part-" .. role .. "-arm-front", parts.armFront)
  
  -- tags : arm-back
  animator.setGlobalTag("part-" .. role .. "-arm-back", parts.armBack)

  -- tags : body
  animator.setGlobalTag("part-" .. role .. "-body", parts.body)
  animator.setGlobalTag(role .. "-bodyDirectives", directives.body)
  
  -- tags : emote
  animator.setGlobalTag("part-" .. role .. "-emote", parts.emote)
  animator.setGlobalTag(role .. "-emoteDirectives", directives.emote)

  -- tags : facial-hair
  animator.setGlobalTag("part-" .. role .. "-facial-hair", parts.facialHair)
  
  -- tags : facial-mask
  animator.setGlobalTag("part-" .. role .. "-facial-mask", parts.facialMask)
  
  -- tags : hair
  animator.setGlobalTag("part-" .. role .. "-hair", parts.hair)  
  animator.setGlobalTag(role .. "-hairDirectives", directives.hair)
  
  -- tags : head
  animator.setGlobalTag("part-" .. role .. "-head", parts.head)
  
  -- tags : groin
  animator.setGlobalTag("part-" .. role .. "-groin", parts.groin)
  animator.setGlobalTag(role .. "-groin", directives.groin)
  animator.setGlobalTag(role .. "-groinMask", directives.groinMask)
  
  -- tags : overlay 1, 2, 3
	animator.setGlobalTag("part-overlay1", parts.overlay1)
	animator.setGlobalTag("part-overlay2", parts.overlay2)
  animator.setGlobalTag("part-overlay3", parts.overlay3)
  
  -- Reset apparel separately
  self:getApparel():resetParts(role, species, gender)
end

function Sexbound.Actor:getFrameName(animState)
	if type(animState:getFrameName()) == "table" then
		return animState:getFrameName()[ self:getActorNumber() ]
	end
	
	return animState:getFrameName()
end

function Sexbound.Actor:loadArmBackPart(animState, entityGroup, role, species)
  return self:getSprite(animState, "armBack", {entityGroup = entityGroup, role = role, species = species}) .. ":" .. self:getFrameName(animState)
end

function Sexbound.Actor:loadArmFrontPart(animState, entityGroup, role, species)
  return self:getSprite(animState, "armFront", {entityGroup = entityGroup, role = role, species = species}) .. ":" .. self:getFrameName(animState)
end

function Sexbound.Actor:loadBodyPart(animState, entityGroup, role, species, gender)
  return self:getSprite(animState, "body", {entityGroup = entityGroup, gender = gender, role = role, species = species}) .. ":" .. self:getFrameName(animState)
end

function Sexbound.Actor:loadEmotePart(animState, entityGroup, role, species)
  if entityGroup == "monsters" then return "/artwork/defaults/default_image.png" end

  return self:getSprite(animState, "emote", {entityGroup = entityGroup, role = role, species = species})
end

function Sexbound.Actor:loadOverlayPart(index)
	local containerOverlay = self:getPosition():getContainerOverlay(index)
	
	if containerOverlay ~= nil then
		return containerOverlay.imagePath .. ":" .. containerOverlay.frameName
  end
	
	return self:getDefaultContainerImage()
end

function Sexbound.Actor:loadFacialHairPart(entityGroup, species, directives)
  local facialHairType = self:getIdentity("facialHairType") or ""
  if facialHairType ~= "" then
    return "/" .. entityGroup .. "/" .. species .. "/" .. self:getIdentity("facialHairFolder") .. "/" .. facialHairType .. ".png:normal" .. directives.facialHair
  end
  
  return self:getDefaultPartImage()
end

function Sexbound.Actor:loadFacialMaskPart(entityGroup, species, directives)
  local facialMaskType = self:getIdentity("facialMaskType") or ""
  if facialMaskType ~= "" then
    return "/" .. entityGroup .. "/" .. species .. "/" .. self:getIdentity("facialMaskFolder") .. "/" .. facialMaskType .. ".png:normal" .. directives.facialMask
  end
  
  return self:getDefaultPartImage()
end

function Sexbound.Actor:loadHairPart(entityGroup, species, directives)
  local hairType = self:getIdentity("hairType") or ""
  if hairType ~= "" then
    return "/" .. entityGroup .. "/" .. species .. "/" .. self:getIdentity("hairFolder") .. "/" .. hairType .. ".png:normal" .. directives.head
  end
  
  return self:getDefaultPartImage()
end

function Sexbound.Actor:loadHeadPart(entityGroup, role, species, gender, directives)
  return self:getSprite(self:getAnimationState(), "head", {entityGroup = entityGroup, gender = gender, role = role, species = species}) .. ":normal" .. directives.head
end

function Sexbound.Actor:loadGroin(entityGroup, role, species, gender)
  local animState  = self:getAnimationState()
  local frameName  = self:getFrameName(animState)
  
  local image, directives, mask = self:getDefaultGlobalTagSet()
  
  local subGender = self:getSubGender()

  if self:isPregnant() and self:isEnabledPregnancyFetish() then
    if ( ( ( gender == "male" and not (subGender == "cuntboy") ) or subGender == "futanari" ) ) then
      image = self:getSprite(animState, "groinGenitalPregnancy", {entityGroup = entityGroup, species = species, role = role}) .. ":" .. frameName
      
      mask  = "?addmask=" .. self:getSprite(animState, "maskGroinGenitalPregnancy", {entityGroup = entityGroup, species = species, role = role}) .. ":" .. frameName
    else
      image = self:getSprite(animState, "groinPregnancy", {entityGroup = entityGroup, species = species, role = role}) .. ":" .. frameName
      
      mask  = "?addmask=" .. self:getSprite(animState, "maskGroinPregnancy", {entityGroup = entityGroup, species = species, role = role}) .. ":" .. frameName
    end
    
    return image, directives, mask
  end
  
  if ( ( ( gender == "male" and not (subGender == "cuntboy") ) or subGender == "futanari" ) ) then
    image = self:getSprite(animState, "groinGenital", {entityGroup = entityGroup, species = species, role = role}) .. ":" .. frameName
    
    mask  = "?addmask=" .. self:getSprite(animState, "maskGroinGenital", {entityGroup = entityGroup, species = species, role = role}) .. ":" .. frameName
  end
  
  return image, directives, mask
end

function Sexbound.Actor:replaceAllImageTags(apparelConfig, imagePairs, tagPairs)
  local newConfig = copy(apparelConfig)
  
  util.each(imagePairs, function(imageKey,imageValue)
    if apparelConfig[imageValue] ~= nil then
      util.each(tagPairs, function(tagKey,tagValue)
        newConfig[imageValue] = util.replaceTag(newConfig[imageValue], tagKey, tagValue)
      end)
    end
  end)
  
  return newConfig
end

--- Resets the Actor's global animator tags.
-- @param role
function Sexbound.Actor:resetGlobalAnimatorTags(role)
  role = role or self:getRole()

  -- Reset animation parts related to actor body parts
  self:resetAnimatorParts(role)
  self:resetAnimatorMasks(role)

  -- Reset animation parts related to apparel
  self:getApparel():resetAnimatorParts(role)
  self:getApparel():resetAnimatorDirectives(role)
	self:getApparel():resetAnimatorMasks(role)
end

--- Resets animator masks.
-- @param role
function Sexbound.Actor:resetAnimatorMasks(role)
  animator.setGlobalTag(role .. "-groinMask", "?addmask=" .. self:getDefaultMaskImage())
end

--- Resets animator parts.
-- @param role
function Sexbound.Actor:resetAnimatorParts(role)
  -- Reset each actor part
  for _,part in ipairs({
    "arm-back",
    "arm-front", 
    "body", 
    "climax",
    "head",
    "hair",
    "facial-hair", 
    "facial-mask",
    "groin"
  }) do 
    animator.setGlobalTag("part-" .. role .. "-" .. part, self:getDefaultPartImage())
  end
	
	-- Reset emote tag
	animator.setGlobalTag("part-" .. role .. "-emote", self:getDefaultPartImage())
  
  -- Reset the overlays
	animator.setGlobalTag("part-overlay1", self:getDefaultContainerImage())
	animator.setGlobalTag("part-overlay2", self:getDefaultContainerImage())
	animator.setGlobalTag("part-overlay3", self:getDefaultContainerImage())
end

--- Resets all transformations for this Actor.
-- @param[opt] role
function Sexbound.Actor:resetTransformations(role)
  role = role or self:getRole()
	
  for _,part in ipairs({"Body", "Head"}) do
    local group = role .. part
    
    if animator.hasTransformationGroup(group) then
      animator.resetTransformationGroup(group)
    end
  end
end

--- Rotates a specified animator part.
-- @param part
-- @param angle
-- @param[opt] role
function Sexbound.Actor:rotatePart(part, angle, role)
  role = role or self:getRole()

  local group = role .. part

  if animator.hasTransformationGroup(group) then
    local radians = util.toRadians(angle or 0)
    local rotationCenter = { 2.6875, 2.6875 }
    if self:getParent():getAnimationPartsCentered() == true then
      rotationCenter = nil
    end
    animator.rotateTransformationGroup(group, radians, rotationCenter)
  end
end

--- Setup new actor.
-- @param actor
function Sexbound.Actor:setup(actor)
  -- Store actor data.
  self._config = util.mergeTable(self._config, actor)
  
  -- Ensure storage object exists in the config
  self._config.storage = self._config.storage or {}

  -- Ensure storage has the sexbound property
  self._config.storage.sexbound = self._config.storage.sexbound or {}

  local index = self:getParent():getActorCount()
  
  self:setActorNumber(index)
  
  self:setId(index)
  
  self:setRole(index)
  
  world.sendEntityMessage(self:getEntityId(), "Sexbound:Statistics:Add", {
    name   = "haveSexCount",
    amount = 1
  })

  if actor.entityType == "npc" or actor.entityType == "player" then
    -- Initialize hair identities.
    self._config.identity.hairFolder = self:getHairFolder()
    self._config.identity.hairType   = self:getHairType()
    
    -- Initialize facial hair identities.
    self._config.identity.facialHairFolder = self:getFacialHairFolder()
    self._config.identity.facialHairType   = self:getFacialHairType()
    
    -- Initialize facial mask identities.
    self._config.identity.facialMaskFolder = self:getFacialMaskFolder()
    self._config.identity.facialMaskType   = self:getFacialMaskType()
  end

  self:addInnateStatusNames()
end

function Sexbound.Actor:addInnateStatusNames()
  local entityType = self:getEntityType() or ""
  self:getStatus():addStatus("entity_type_" .. entityType)

  local type = self:getType() or ""
  self:getStatus():addStatus("type_" .. type)
end

function Sexbound.Actor:initPlugins()
  -- Create new plugin manager.
  self._pluginmgr = Sexbound.Actor.PluginMgr:new( self )
end

--- Flips a specified animator part.
-- @param part
-- @param[opt] role
function Sexbound.Actor:flipPart(part, role)
  role = role or self:getRole()
  local group = role .. part

	-- (43 pixels / 2) / 8 = 2.6875; (2.6875, 2.6875) is the center point of a 43 x 43 pixel image.

  if (animator.hasTransformationGroup(group)) then
    local scaleCenter = { 2.6875, 2.6875 }
    if self:getParent():getAnimationPartsCentered() == true then
      scaleCenter = nil
    end
    animator.scaleTransformationGroup(group, {-1, 1}, scaleCenter)
  end
end

--- Translates a specified animator part.
-- @param part
-- @param offset
-- @param[opt] role
function Sexbound.Actor:translatePart(part, offset, role)
  role = role or self:getRole()
  local group = role .. part
  
  if (animator.hasTransformationGroup(group)) then
    animator.resetTransformationGroup(group)
    animator.translateTransformationGroup(group, offset)
  end
end

--- Uninitializes this instance.
function Sexbound.Actor:uninit()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:uninit()
  end)
end

--- Processes gender value.
-- @param gender male, female, or something else (future)
function Sexbound.Actor:validateGender(gender)
  local validatedGender = util.find(self:getParent():getConfig().sex.supportedPlayerGenders, function(v)
    if (gender == v) then return v end
  end)
  
  return validatedGender or self:getParent():getConfig().sex.defaultPlayerGender -- default is 'male'
end

--- Processes species value.
-- @param species name of species
function Sexbound.Actor:validateSpecies(species)
  local validatedSpecies = util.find(self:getParent():getConfig().sex.supportedPlayerSpecies, function (v)
   if (species == v) then return v end
  end)
  
  return validatedSpecies or self:getParent():getConfig().sex.defaultPlayerSpecies -- default is 'human'
end

--- Executes the specifed callback function for each actor plugin.
-- @param callback
function Sexbound.Actor:forEachPlugin(callback)	
	util.each(self:getPlugins(), function(index, plugin)
		callback(index, plugin)
	end)
end

function Sexbound.Actor:onEnterAnyState()
  self:forEachPlugin(function(index, plugin)
    plugin:onEnterAnyState()
  end)
end

--- Calls onEnterClimaxState for every loaded plugin.
function Sexbound.Actor:onEnterClimaxState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:ClimaxState:Enter")
  
  self:forEachPlugin(function(index, plugin)
    plugin:onEnterClimaxState()
  end)
end

--- Calls onEnterExitState for every loaded plugin.
function Sexbound.Actor:onEnterExitState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:ExitState:Enter")
  
  self:forEachPlugin(function(index, plugin)
    plugin:onEnterExitState()
  end)
end

--- Calls onEnterIdleState for every loaded plugin.
function Sexbound.Actor:onEnterIdleState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:IdleState:Enter")

  self:forEachPlugin(function(index, plugin)
    plugin:onEnterIdleState()
  end)
end

--- Calls onEnterSexState for every loaded plugin.
function Sexbound.Actor:onEnterSexState()
  -- Notify the actor that it is entering the sex state
  world.sendEntityMessage(self:getEntityId(), "Sexbound:SexState:Enter")
  
  self:forEachPlugin(function(index, plugin)
    plugin:onEnterSexState()
  end)
end

function Sexbound.Actor:onExitAnyState()
  self:forEachPlugin(function(index, plugin)
    plugin:onExitAnyState()
  end)
end

--- Calls onExitClimaxState for every loaded plugin.
function Sexbound.Actor:onExitClimaxState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:ClimaxState:Exit")

  self:forEachPlugin(function(index, plugin)
    plugin:onExitClimaxState()
  end)
end

--- Calls onExitExitState for every loaded plugin.
function Sexbound.Actor:onExitExitState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:ExitState:Exit")

  self:forEachPlugin(function(index, plugin)
    plugin:onExitExitState()
  end)
end

--- Calls onExitIdleState for every loaded plugin.
function Sexbound.Actor:onExitIdleState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:IdleState:Exit")

  self:forEachPlugin(function(index, plugin)
    plugin:onExitIdleState()
  end)
end

--- Calls onExitSexState for every loaded plugin.
function Sexbound.Actor:onExitSexState()
  world.sendEntityMessage(self:getEntityId(), "Sexbound:SexState:Exit")

  self:forEachPlugin(function(index, plugin)
    plugin:onExitSexState()
  end)
end

function Sexbound.Actor:onUpdateAnyState(dt)
  self:getMouth():update(dt)
  
  self:getStatus():update(dt)

  self:forEachPlugin(function(index, plugin)
    plugin:onUpdateAnyState(dt)
  end)

  -- Periodically Sync Storage
  self._syncTimer = self._syncTimer + dt

  if self._syncTimer >= self._syncDelta then
    self:getStorage():sync()

    self._syncTimer = 0
  end
end

--- Calls onUpdateExitState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateExitState(dt)
  self:forEachPlugin(function(index, plugin)
    plugin:onUpdateExitState(dt)
  end)
end

--- Calls onUpdateClimaxState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateClimaxState(dt)
  self:forEachPlugin(function(index, plugin)
    plugin:onUpdateClimaxState(dt)
  end)
end

--- Calls onUpdateIdleState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateIdleState(dt)
  self:forEachPlugin(function(index, plugin)
    plugin:onUpdateIdleState(dt)
  end)
end

--- Calls onUpdateSexState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateSexState(dt)
  self:forEachPlugin(function(index, plugin)
    plugin:onUpdateSexState(dt)
  end)
end

--[Getters / Setters]-------------------------------------------------------------------------

--- Returns the actor number for this Actor instance.
function Sexbound.Actor:getActorNumber()
  return self._actorNumber
end

--- Sets the actor number to the specified value.
-- @param value
function Sexbound.Actor:setActorNumber(value)
  self._actorNumber = value
  return self._actorNumber
end

function Sexbound.Actor:setAnimationState(stateName)
  self._animationState = self:getPosition():getAnimationState(stateName)
	
  return self._animationState
end

function Sexbound.Actor:getAnimationState()
  return self._animationState
end

function Sexbound.Actor:getApparel()
  return self._apparel
end

--- Legacy
function Sexbound.Actor:getMouthOffset()
  return self:getMouth():getOffset();
end

--- Legacy
function Sexbound.Actor:getMouthPosition()
  return self:getMouth():getPosition();
end

function Sexbound.Actor:getClimaxSpawnOffset()
  local nextPart, offset = self:getRole() .. "-body", {0,0}
  
  while (nextPart ~= nil) do
    offset = vec2.add(offset, animator.partProperty(nextPart, "offset") or {0,0})
  
    nextPart = animator.partProperty(nextPart, "anchorPart")
  end
  local groinTerm = ""
  if self:getGender() == "male" then 
    groinTerm = "with-penis" end
  if self:getGender() == "female" then 
    groinTerm = "with-vagina" end
  
  local lastPart = self:getRole() .. "-climax-" .. groinTerm
  
  return vec2.add(offset, animator.partProperty(lastPart, "offset") or {0, 0})
end

function Sexbound.Actor:getClimaxSpawnPosition()
  local offset = vec2.mul(self:getClimaxSpawnOffset(), {object.direction(), 1})

  return object.toAbsolutePosition(offset)
end

function Sexbound.Actor:getBodyCenterOffset()
  local nextPart, offset = self:getRole() .. "-body-center", {0,0}
  
  while (nextPart ~= nil) do
    offset = vec2.add(offset, animator.partProperty(nextPart, "offset") or {0,0})
  
    nextPart = animator.partProperty(nextPart, "anchorPart")
  end
  
  return offset
end

function Sexbound.Actor:getBodyCenterPosition()
  local offset = vec2.mul(self:getBodyCenterOffset(), {object.direction(), 1})

  return object.toAbsolutePosition(offset)
end

function Sexbound.Actor:getDefaultGlobalTagSet()
  return self:getDefaultPartImage(), "", "?addmask=" .. self:getDefaultMaskImage()
end

--- Returns the running configuration for this Actor instance.
function Sexbound.Actor:getConfig()
  return self._config
end

function Sexbound.Actor:getDefaultArtwork(name)
  if name then return self._config.defaultArtwork[name] end
	
  return self._config.defaultArtwork
end

function Sexbound.Actor:getDefaultMaskImage(frameName)
  local path = "/artwork/defaults/default_mask.png"
  if frameName then return path .. ":" .. frameName else return path .. ":default" end
end

function Sexbound.Actor:getDefaultContainerImage(frameName)
  local path = "/artwork/container.png"
  if frameName then return path .. ":" .. frameName else return path .. ":default" end
end

function Sexbound.Actor:getDefaultPartImage(frameName)
  local path = "/artwork/defaults/default_image.png"
  if frameName then return path .. ":" .. frameName else return path .. ":default" end
end

function Sexbound.Actor:getEntityGroup()
  local entityType = self:getEntityType()

  if entityType == "npc" or entityType == "player" then
    return "humanoid"
  elseif entityType == "object" then
    return "objects"
  elseif entityType == "monster" then
    return "monsters"
  end
  
  return entityType
end

--- Returns the entity id of this actor instance.
function Sexbound.Actor:getEntityId()
  return self._config.entityId
end

--- Returns the entity type of this Actor instance.
function Sexbound.Actor:getEntityType()
  return self._config.entityType
end

--- Returns the validated facial hair folder name for this Actor instance.
function Sexbound.Actor:getFacialHairFolder()
  return self:getIdentity("facialHairFolder") or self:getIdentity("facialHairGroup") or ""
end

--- Returns the validated facial hair type for this Actor instance.
function Sexbound.Actor:getFacialHairType()
  return self:getIdentity("facialHairType") or "1"
end

--- Returns the validated facial mask folder name for this Actor instance.
function Sexbound.Actor:getFacialMaskFolder()
  return self:getIdentity("facialMaskFolder") or self:getIdentity("facialMaskGroup") or ""
end

--- Returns the validated facial mask type for this Actor instance.
function Sexbound.Actor:getFacialMaskType()
  return self:getIdentity("facialMaskType") or "1"
end

--- Returns the forced role for this actor.
function Sexbound.Actor:getForceRole()
	return self._config.forceRole or 0
end

function Sexbound.Actor:getFacingDirection()
 return self._parent._facingDirection
end

--- Returns the gender of this actor instance.
function Sexbound.Actor:getGender()
  return self:getIdentity().gender
end

--- Returns the sub-gender of this actor instance.
function Sexbound.Actor:getSubGender()
  if ( (self:getIdentity().sxbSubGender == "futanari" or self:getIdentity().sxbSubGender == "cuntboy") and self:getPlugins("futanari") == nil ) then
    return nil
  end

  return self:getIdentity().sxbSubGender
end

--- Returns the validated hair folder of this actor instance.
function Sexbound.Actor:getHairFolder()
  return self:getIdentity().hairFolder or self:getIdentity("hairGroup") or "hair"
end

--- Returns the validated hair type of this actor instance.
function Sexbound.Actor:getHairType()
  return self:getIdentity("hairType") or "1"
end

function Sexbound.Actor:getCurrentFrame()
  return animator.partProperty("actors", "currentFrame") or "1"
end

--- Returns the id of this actor instance.
function Sexbound.Actor:getId()
  return self._id
end

function Sexbound.Actor:setId(value)
  self._id = value
  return self._id
end

--- Returns a reference to this Actor identifiers.
-- @param[opt] param
function Sexbound.Actor:getIdentity(param)
  if param then return self._config.identity[param] end

  return self._config.identity
end

--- Returns a reference to the log for this Actor instance.
function Sexbound.Actor:getLog()
  return self._log
end

--- Returns a reference to this instance's Mouth.
function Sexbound.Actor:getMouth()  return self._mouth end

--- Returns the name of this Actor instance.
function Sexbound.Actor:getName()
  return self._config.identity.name
end

--- Returns reference to targeted other actor.
function Sexbound.Actor:getOtherActor()
  for _,actor in pairs(self:getParent():getActors()) do
    if actor:getRole() ~= self:getRole() then return actor end
  end
end

function Sexbound.Actor:getOtherActorRole()
  return Sexbound.Util.ternary(self:getActorNumber() ~= 1, "actor1", "actor2")
end

--- Returns the parent class of this Actor instance.
function Sexbound.Actor:getParent()
  return self._parent
end

--- Returns the plugin manager of this Actor instance.
function Sexbound.Actor:getPluginMgr()
  return self._pluginmgr
end

--- Returns a reference to this Actor instance's plugins as a table.
-- @param pluginName
function Sexbound.Actor:getPlugins(pluginName)
  if self:getPluginMgr() == nil then return end

  if pluginName then return self:getPluginMgr():getPlugins(pluginName) end

  return self:getPluginMgr():getPlugins()
end

-- Returns a reference to the current position.
function Sexbound.Actor:getPosition()
  return self._parent:getPositions():getCurrentPosition()
end

--- Returns the role of this actor instance.
function Sexbound.Actor:getRole()
  return self._role
end

--- Sets the role for this actor with the specifed number.
-- @param number
function Sexbound.Actor:setRole(number)
  self._role = "actor" .. number
  return self._role
end

--- Returns the species value.
function Sexbound.Actor:getSpecies()
  return self:getIdentity().species
end

function Sexbound.Actor:getSprite(animState, partName, tags)
  local defaultArtwork = self:getDefaultArtwork(partName)
  local filename = animState:getSprite(partName, defaultArtwork)
  
	if type(filename) == "table" then
		filename = filename[self:getActorNumber()] or defaultArtwork
	end
	
  filename = util.replaceTag(filename, "entityGroup", tags.entityGroup or "humanoid")
  filename = util.replaceTag(filename, "gender",      tags.gender      or "default" )
  filename = util.replaceTag(filename, "framename",   tags.frameName   or "default" )
  filename = util.replaceTag(filename, "role",        tags.role        or "default" )
  filename = util.replaceTag(filename, "species",     tags.species     or "default" )
  
  self:getLog():info("GET SPRITE => " .. filename .. " [ PART := " .. partName .. " ]")

  if Sexbound.Util.imageExists(filename) then
    return filename
  else
    return self:getDefaultPartImage()
  end
end

--- Returns a reference to the state machine
function Sexbound.Actor:getStateMachine()
  return self._parent:getStateMachine()
end

--- Returns a reference to this instance's Status.
function Sexbound.Actor:getStatus() return self._status end
function Sexbound.Actor:status()    return self._status end

--- Returns a reference to the storage interface
function Sexbound.Actor:getStorage()
  return self._storage
end

function Sexbound.Actor:getType()
  return self._config.type
end

function Sexbound.Actor:getUniqueId()
  return self._config.uniqueId
end

function Sexbound.Actor:isPregnant()
  local plugin = self:getPlugins("pregnant")

  if plugin == nil then return false end

  return plugin:isPregnant()
end

function Sexbound.Actor:isEnabledPregnancyFetish()
  local plugin = self:getPlugins("pregnant")
  
  if plugin == nil then return false end

  return plugin:getConfig().enablePregnancyFetish
end

--- Legacy

function Sexbound.Actor:getBackwear()
  return self:getApparel():getBackwear()
end

function Sexbound.Actor:getChestwear()
  return self:getApparel():getChestwear()
end

function Sexbound.Actor:getHeadwear()
  return self:getApparel():getHeadwear()
end

function Sexbound.Actor:getLegswear()
  return self:getApparel():getLegswear()
end
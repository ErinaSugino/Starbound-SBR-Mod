--- Sexbound.Actor Class Module.
-- @classmod Sexbound.Actor
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor = {}
Sexbound.Actor_mt = {
    __index = Sexbound.Actor
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/apparel.lua")
    require("/scripts/sexbound/lib/sexbound/actor/head.lua")
    require("/scripts/sexbound/lib/sexbound/actor/mouth.lua")
    require("/scripts/sexbound/lib/sexbound/actor/nipples.lua")
    require("/scripts/sexbound/lib/sexbound/actor/status.lua")
    require("/scripts/sexbound/lib/sexbound/actor/storage.lua")
    require("/scripts/sexbound/lib/sexbound/actor/pluginmgr.lua")
end

--- Returns a reference to a new instance of this class.
-- @param parent
-- @param actorConfig
function Sexbound.Actor:new(parent, actorConfig, id, number)
    local _self = setmetatable({
        _parent = parent,
        _syncTimer = 0,
        _hasInited = false
    }, Sexbound.Actor_mt)

    -- Add ref. to this instance into the main messenger channel.
    Sexbound.Messenger.get("main"):addBroadcastRecipient(_self)

    -- Initialize new instance of Log with prefix set to "ACTR".
    _self._log = Sexbound.Log:new("ACTR", _self._parent:getConfig())

    -- Initialize the actor's config. It must be copied.
    _self._config = copy(_self._parent:getConfig().actor)

    -- Create new instance of apparel.
    _self._apparel = Sexbound.Actor.Apparel:new(_self)

    -- Create new instance of nipples.
    _self._nipples = Sexbound.Actor.Nipples:new(_self)

    -- Create new instance of head.
    _self._head = Sexbound.Actor.Head.new(_self)

    -- Create new instance of mouth.
    _self._mouth = Sexbound.Actor.Mouth:new(_self)

    -- Create new instance of status.
    _self._status = Sexbound.Actor.Status:new(_self)

    -- Create new instance of storage.
    _self._storage = Sexbound.Actor.Storage:new(_self)

    -- Initialize sync delta used for how often storage is synced
    _self._syncDelta = _self._config.syncDelta or 1
    
    _self:setId(id or 1)
    _self:setActorNumber(number or 1)

    -- Setup the actor.
    _self:setup(actorConfig)

    return _self
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
    if animState == nil then
        return
    end
    local actorNumber = self:getActorNumber()
    self:resetGlobalAnimatorTags()
    self:resetTransformations()
    self:getHead():setSpeedMultiplier(animState:getHeadBangSpeedMultiplier(actorNumber))
    if not animState:getEnabled(actorNumber) or not animState:getVisible(actorNumber) then
        return
    end
    -- Apply rotations to actor's head
    self:rotatePart("Head", animState:getRotateHead(actorNumber))

    -- Apply rotations to actor's body
    self:rotatePart("Body", animState:getRotateBody(actorNumber))

    -- Resets the actor's image parts and directives
    if self:getEntityType() == "player" or self:getEntityType() == "npc" then
        self:resetParts(animState, self:validateSpecies(self:getSpecies()), self:validateGender(self:getGender()),
            self:resetDirectives(actorNumber))
    else
        self:resetParts(animState, self:getSpecies(), self:getGender(), self:resetDirectives(actorNumber))
    end

    -- Apply flip to head directives
    if self:getAnimationState():getFlipHead(actorNumber) then
        self:flipPart("Head")
    end

    -- Apply flip to body directives
    if self:getAnimationState():getFlipBody(actorNumber) then
        self:flipPart("Body")
    end
end

function Sexbound.Actor:resetDirectives(actorNumber)
    local directives = {
        body = self:getIdentity("bodyDirectives") or "",
        head = self:getIdentity("headDirectives") or self:getIdentity("bodyDirectives") or "",
        emote = self:getIdentity("emoteDirectives") or "",
        hair = self:getIdentity("hairDirectives") or "",
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
    local entityGroup = self:getEntityGroup()
    local parts = {}
    local role = self:getRole()
    local slot = "actor" .. self:getActorNumber()
    parts.armBack = self:loadArmBackPart(animState, entityGroup, role, species)
    parts.armFront = self:loadArmFrontPart(animState, entityGroup, role, species)
    parts.body = self:loadBodyPart(animState, entityGroup, role, species, gender)
    parts.facialHair = self:loadFacialHairPart(entityGroup, species, directives)
    parts.facialMask = self:loadFacialMaskPart(entityGroup, species, directives)
    parts.hair = self:loadHairPart(entityGroup, species, directives)
    parts.head = self:loadHeadPart(entityGroup, role, species, gender, directives)
    parts.emote = self:loadEmotePart(animState, entityGroup, role, species)

    parts.groin, directives.groin, directives.groinMask = self:loadGroin(entityGroup, role, species, gender)

    parts.overlay1 = self:loadOverlayPart(animState, 1) -- Load Overlay 1
    parts.overlay2 = self:loadOverlayPart(animState, 2) -- Load Overlay 2
    parts.overlay3 = self:loadOverlayPart(animState, 3) -- Load Overlay 3

    -- Set global animator tags.

    -- tags : gender
    animator.setGlobalTag(slot .. "-gender", gender)

    -- tags : species
    animator.setGlobalTag(slot .. "-species", species)

    -- tags : arm-front
    animator.setGlobalTag("part-" .. slot .. "-arm-front", parts.armFront)

    -- tags : arm-back
    animator.setGlobalTag("part-" .. slot .. "-arm-back", parts.armBack)

    -- tags : body
    animator.setGlobalTag("part-" .. slot .. "-body", parts.body)
    animator.setGlobalTag(slot .. "-bodyDirectives", directives.body)

    -- tags : emote
    animator.setGlobalTag("part-" .. slot .. "-emote", parts.emote)
    animator.setGlobalTag(slot .. "-emoteDirectives", directives.emote)

    -- tags : facial-hair
    animator.setGlobalTag("part-" .. slot .. "-facial-hair", parts.facialHair)

    -- tags : facial-mask
    animator.setGlobalTag("part-" .. slot .. "-facial-mask", parts.facialMask)

    -- tags : hair
    animator.setGlobalTag("part-" .. slot .. "-hair", parts.hair)
    animator.setGlobalTag(slot .. "-hairDirectives", directives.hair)

    -- tags : head
    animator.setGlobalTag("part-" .. slot .. "-head", parts.head)

    -- tags : groin
    animator.setGlobalTag("part-" .. slot .. "-groin", parts.groin)
    animator.setGlobalTag(slot .. "-groin", directives.groin)
    animator.setGlobalTag(slot .. "-groinMask", directives.groinMask)

    -- tags : overlay 1, 2, 3
    animator.setGlobalTag("part-overlay1", parts.overlay1)
    animator.setGlobalTag("part-overlay2", parts.overlay2)
    animator.setGlobalTag("part-overlay3", parts.overlay3)

    -- Reset apparel separately
    self:getApparel():resetParts(role, species, gender)

    -- Reset nipples separately
    self:getNipples():resetParts(entityGroup, role, species, gender)
end

function Sexbound.Actor:getFrameName(animState)
    if type(animState:getFrameName()) == "table" then
        return animState:getFrameName()[self:getActorNumber()]
    end

    return animState:getFrameName()
end

function Sexbound.Actor:loadArmBackPart(animState, entityGroup, role, species)
    return self:getSprite(animState, "armBack", {
        entityGroup = entityGroup,
        role = role,
        species = species
    }) .. ":" .. self:getFrameName(animState)
end

function Sexbound.Actor:loadArmFrontPart(animState, entityGroup, role, species)
    return self:getSprite(animState, "armFront", {
        entityGroup = entityGroup,
        role = role,
        species = species
    }) .. ":" .. self:getFrameName(animState)
end

function Sexbound.Actor:loadBodyPart(animState, entityGroup, role, species, gender)
    return self:getSprite(animState, "body", {
        entityGroup = entityGroup,
        gender = gender,
        role = role,
        species = species
    }) .. ":" .. self:getFrameName(animState)
end

function Sexbound.Actor:loadEmotePart(animState, entityGroup, role, species)
    if entityGroup == "monsters" then
        return "/artwork/defaults/default_image.png"
    end
    return self:getSprite(animState, "emote", {
        entityGroup = entityGroup,
        role = role,
        species = species
    })
end

function Sexbound.Actor:loadOverlayPart(animState, index)
    local containerOverlay = self:getPosition():getContainerOverlay(index)
    if containerOverlay ~= nil then
        return containerOverlay.imagePath .. ":" .. self:getFrameName(animState)
    end
    return self:getDefaultContainerImage()
end

function Sexbound.Actor:loadFacialHairPart(entityGroup, species, directives)
    local facialHairType = self:getIdentity("facialHairType") or ""
    if facialHairType ~= "" then
        return "/" .. entityGroup .. "/" .. species .. "/" .. self:getIdentity("facialHairFolder") .. "/" ..
                   facialHairType .. ".png:normal" .. directives.facialHair
    end
    return self:getDefaultPartImage()
end

function Sexbound.Actor:loadFacialMaskPart(entityGroup, species, directives)
    local facialMaskType = self:getIdentity("facialMaskType") or ""
    if facialMaskType ~= "" then
        return "/" .. entityGroup .. "/" .. species .. "/" .. self:getIdentity("facialMaskFolder") .. "/" ..
                   facialMaskType .. ".png:normal" .. directives.facialMask
    end
    return self:getDefaultPartImage()
end

function Sexbound.Actor:loadHairPart(entityGroup, species, directives)
    local hairType = self:getIdentity("hairType") or ""
    if hairType ~= "" then
        return "/" .. entityGroup .. "/" .. species .. "/" .. self:getIdentity("hairFolder") .. "/" .. hairType ..
                   ".png:normal" .. directives.hair
    end
    return self:getDefaultPartImage()
end

function Sexbound.Actor:loadHeadPart(entityGroup, role, species, gender, directives)
    local forceUseOriginalHeadArtwork = self._parent._config.actor.forceUseOriginalHeadArtwork or false
    if forceUseOriginalHeadArtwork and entityGroup == "humanoid" then
        return "/" .. entityGroup .. "/" .. species .. "/" .. gender .. "head.png:normal" .. directives.head
    end
    return self:getSprite(self:getAnimationState(), "head", {
        entityGroup = entityGroup,
        gender = gender,
        role = role,
        species = species
    }) .. ":normal" .. directives.head
end

function Sexbound.Actor:loadGroin(entityGroup, role, species, gender)
    local animState = self:getAnimationState()
    local frameName = self:getFrameName(animState)

    local image, directives, mask = self:getDefaultGlobalTagSet()

    local subGender = self:getSubGender()

    if (self:isVisiblyPregnant() and self:isEnabledPregnancyFetish()) or self:isInflated() then
        if self:getGenitalType() == "male" then
            image = self:getSprite(animState, "groinGenitalPregnancy", {
                entityGroup = entityGroup,
                species = species,
                role = role
            }) .. ":" .. frameName

            mask = "?addmask=" .. self:getSprite(animState, "maskGroinGenitalPregnancy", {
                entityGroup = entityGroup,
                species = species,
                role = role
            }) .. ":" .. frameName
        else
            image = self:getSprite(animState, "groinPregnancy", {
                entityGroup = entityGroup,
                species = species,
                role = role
            }) .. ":" .. frameName

            mask = "?addmask=" .. self:getSprite(animState, "maskGroinPregnancy", {
                entityGroup = entityGroup,
                species = species,
                role = role
            }) .. ":" .. frameName
        end

        return image, directives, mask
    end

    if self:getGenitalType() == "male" then
        image = self:getSprite(animState, "groinGenital", {
            entityGroup = entityGroup,
            species = species,
            role = role
        }) .. ":" .. frameName

        mask = "?addmask=" .. self:getSprite(animState, "maskGroinGenital", {
            entityGroup = entityGroup,
            species = species,
            role = role
        }) .. ":" .. frameName
    end

    return image, directives, mask
end

--- Resets the Actor's global animator tags.
function Sexbound.Actor:resetGlobalAnimatorTags(prefix)
    prefix = prefix or "actor" .. self:getActorNumber()

    -- Reset animation parts related to actor body parts
    self:resetAnimatorParts(prefix)
    self:resetAnimatorMasks(prefix)

    -- Reset animation parts related to apparel
    self:getApparel():resetAnimatorParts(prefix)
    self:getApparel():resetAnimatorDirectives(prefix)
    self:getApparel():resetAnimatorMasks(prefix)

    -- Reset animation parts related to nipples
    self:getNipples():resetAnimatorParts(prefix)
    self:getNipples():resetAnimatorDirectives(prefix)
end

--- Resets animator masks.
-- @param role
function Sexbound.Actor:resetAnimatorMasks(prefix)
    animator.setGlobalTag(prefix .. "-groinMask", "?addmask=" .. self:getDefaultMaskImage())
end

--- Resets animator parts.
-- @param role
function Sexbound.Actor:resetAnimatorParts(prefix)
    -- Reset each actor part
    for _, part in ipairs({"arm-back", "arm-front", "body", "climax", "head", "hair", "facial-hair", "facial-mask",
                           "groin"}) do
        animator.setGlobalTag("part-" .. prefix .. "-" .. part, self:getDefaultPartImage())
    end

    -- Reset emote tag
    animator.setGlobalTag("part-" .. prefix .. "-emote", self:getDefaultPartImage())

    -- Reset the overlays
    animator.setGlobalTag("part-overlay1", self:getDefaultContainerImage())
    animator.setGlobalTag("part-overlay2", self:getDefaultContainerImage())
    animator.setGlobalTag("part-overlay3", self:getDefaultContainerImage())
end

--- Resets all transformations for this Actor.
function Sexbound.Actor:resetTransformations(prefix)
    prefix = prefix or "actor" .. self:getActorNumber()

    for _, partName in ipairs({"Body", "Head"}) do
        local transformationGroupName = prefix .. partName
        if animator.hasTransformationGroup(transformationGroupName) then
            animator.resetTransformationGroup(transformationGroupName)
        end
    end
end

--- Rotates a specified animator part.
-- @param part
-- @param angle
function Sexbound.Actor:rotatePart(part, angle)
    local prefix = "actor" .. self:getActorNumber()
    local transformationGroupName = prefix .. part

    if animator.hasTransformationGroup(transformationGroupName) then
        local radians = util.toRadians(angle or 0)
        local rotationCenter = {2.6875, 2.6875}
        if self:getParent():getAnimationPartsCentered() == true then
            rotationCenter = nil
        end
        animator.rotateTransformationGroup(transformationGroupName, radians, rotationCenter)
    end
end

--- Setup new actor.
-- @param actorConfig
function Sexbound.Actor:setup(actorConfig)
    self._config = util.mergeTable(self._config, actorConfig)
    self._config.storage = self._config.storage or {}
    self._config.storage.sexbound = self._config.storage.sexbound or {}

    -- local index = self:getParent():getActorCount()

    self:setAnimationState(self:getParent():getStateMachine():stateDesc())
    
    self:setRole(self:getActorNumber())

    world.sendEntityMessage(self:getEntityId(), "Sexbound:Statistics:Add", {
        name = "haveSexCount",
        amount = 1
    })

    if actorConfig.entityType == "npc" or actorConfig.entityType == "player" then
        -- Initialize hair identities.
        self._config.identity.hairFolder = self:getHairFolder()
        self._config.identity.hairType = self:getHairType()

        -- Initialize facial hair identities.
        self._config.identity.facialHairFolder = self:getFacialHairFolder()
        self._config.identity.facialHairType = self:getFacialHairType()

        -- Initialize facial mask identities.
        self._config.identity.facialMaskFolder = self:getFacialMaskFolder()
        self._config.identity.facialMaskType = self:getFacialMaskType()
    end
    
    self._config.identity.body = {canOvulate=false, canProduceSperm=true, hasPenis=true, hasVagina=false} -- init default male body traits
    self:buildSubGenderList()

    local actorStatus = self:getStatus()
    if actorConfig.isFertile then actorStatus:addStatus("sexbound_custom_fertility") end
    if actorConfig.isHyperFertile then actorStatus:addStatus("sexbound_custom_hyper_fertility") end
    if actorConfig.isOvulating then actorStatus:addStatus("sexbound_custom_ovulating") end
    if actorConfig.isDefeated then actorStatus:addStatus("sexbound_defeated") end
    
    if self._config.identity.sxbNaturalStatus then
        for _,s in ipairs(self._config.identity.sxbNaturalStatus) do
            actorStatus:addStatus(s)
        end
    end
    
    self:getLog():debug("Actor "..self:getName().." setup fertility: fertile "..tostring(actorConfig.isFertile).." - hyperFertile "..tostring(actorConfig.isHyperFertile).." - ovulating "..tostring(actorConfig.isOvulating).." - defeated "..tostring(actorConfig.isDefeated))
    
    self:initPlugins()
    self:getApparel():sync() -- initial fetching of apparel to determine initial gender

    self:addInnateStatusNames()
    
    self._hasInited = true
    self:buildBodyTraits()
end

function Sexbound.Actor:buildSubGenderList()
    self._config.allGenders = { -- Define default main gender traits
        male={
            canOvulate=false,
            canProduceSperm=true,
            hasPenis=true,
            hasVagina=false
        },
        female={
            canOvulate=true,
            canProduceSperm=false,
            hasPenis=false,
            hasVagina=true
        }
    }
    self._config.allGenderIndices = {"male","female"}
    local subGenderList = self:getParent():getConfig().sex.subGenderList or {} -- Load sub-gender config
    for _,s in ipairs(subGenderList) do
        local sCopy = copy(s)
        local name = sCopy.name or "unknown"
        sCopy.name = nil
        if not self._config.allGenders[name] then table.insert(self._config.allGenderIndices, name) end
        self._config.allGenders[name] = sCopy
    end
end

function Sexbound.Actor:addInnateStatusNames()
    local entityType = self:getEntityType() or ""
    self:getStatus():addStatus("entity_type_" .. entityType)

    local type = self:getType() or ""
    self:getStatus():addStatus("type_" .. type)
end

function Sexbound.Actor:buildBodyTraits()
    if not self._hasInited then return end
    local gender = self:getGender()
    local subGender = self:getSubGender()
    local genderTraits = self._config.allGenders or {}
    
    if genderTraits[subGender] then self._config.identity.body = copy(genderTraits[subGender]) -- set body traits of defined subgender if exists
    elseif genderTraits[gender] then self._config.identity.body = copy(genderTraits[gender]) -- set body traits of defined gender instead if exists
    else self._config.identity.body = {canOvulate=false, canProduceSperm=true, hasPenis=true, hasVagina=false} end -- else, reset to fallback male
    self:getLog():debug("Rebuilding actor gender for "..self:getName().." - "..tostring(gender).."/"..tostring(subGender).." => "..Sexbound.Util.shallowDump(self._config.identity.body))
end

function Sexbound.Actor:initPlugins()
    -- Create new plugin manager.
    self._pluginmgr = Sexbound.Actor.PluginMgr:new(self)
end

function Sexbound.Actor:openUI()
    if self:getEntityType() ~= "player" then return end
    local uiConfig = self:getParent()._UI:handleInteract() or {}
    uiConfig = uiConfig[2] or {}
    world.sendEntityMessage(self:getEntityId(), "Sexbound:UI:Show", {
        controllerId = entity.id(),
        config = uiConfig
    })
end

--- Flips a specified animator part.
-- @param part
function Sexbound.Actor:flipPart(part)
    local prefix = "actor" .. self:getActorNumber()
    local transformationGroupName = prefix .. part

    -- (43 pixels / 2) / 8 = 2.6875; (2.6875, 2.6875) is the center point of a 43 x 43 pixel image.

    if (animator.hasTransformationGroup(transformationGroupName)) then
        local scaleCenter = {2.6875, 2.6875}
        if self:getParent():getAnimationPartsCentered() == true then
            scaleCenter = nil
        end
        animator.scaleTransformationGroup(transformationGroupName, {-1, 1}, scaleCenter)
    end
end

--- Translates a specified animator part.
-- @param part
-- @param offset
function Sexbound.Actor:translatePart(part, offset)
    local prefix = "actor" .. self:getActorNumber()
    local transformationGroupName = prefix .. part

    if (animator.hasTransformationGroup(transformationGroupName)) then
        animator.resetTransformationGroup(transformationGroupName)
        animator.translateTransformationGroup(transformationGroupName, offset)
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
        if (gender == v) then
            return v
        end
    end)

    return validatedGender or self:getParent():getConfig().sex.defaultPlayerGender -- default is 'male'
end

--- Processes species value.
-- @param species name of species
function Sexbound.Actor:validateSpecies(species)
    local validatedSpecies = util.find(self:getParent():getConfig().sex.supportedPlayerSpecies, function(v)
        if (species == v) then
            return v
        end
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
    self:getApparel():update(dt)

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
    self:getHead():onUpdateSexState(dt)
end

-- [Getters / Setters]-------------------------------------------------------------------------

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

function Sexbound.Actor:getHead()
    return self._head
end

function Sexbound.Actor:getNipples()
    return self._nipples
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
    local prefix = "actor" .. self:getActorNumber()
    local nextPart, offset = prefix .. "-body", {0, 0}

    while (nextPart ~= nil) do
        offset = vec2.add(offset, animator.partProperty(nextPart, "offset") or {0, 0})

        nextPart = animator.partProperty(nextPart, "anchorPart")
    end

    local groinTerm = ""
    if self:getGender() == "male" then
        groinTerm = "with-penis"
    end
    if self:getGender() == "female" then
        groinTerm = "with-vagina"
    end

    local lastPart = prefix .. "-climax-" .. groinTerm
    return vec2.add(offset, animator.partProperty(lastPart, "offset") or {0, 0})
end

function Sexbound.Actor:getClimaxSpawnPosition()
    local offset = vec2.mul(self:getClimaxSpawnOffset(), {object.direction(), 1})

    return object.toAbsolutePosition(offset)
end

function Sexbound.Actor:getBodyCenterOffset()
    local prefix = "actor" .. self:getActorNumber()
    local nextPart, offset = prefix .. "-body-center", {0, 0}

    while (nextPart ~= nil) do
        offset = vec2.add(offset, animator.partProperty(nextPart, "offset") or {0, 0})

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
    if name then
        return self._config.defaultArtwork[name]
    end

    return self._config.defaultArtwork
end

function Sexbound.Actor:getDefaultMaskImage(frameName)
    local path = "/artwork/defaults/default_mask.png"
    if frameName then
        return path .. ":" .. frameName
    else
        return path .. ":default"
    end
end

function Sexbound.Actor:getDefaultContainerImage(frameName)
    local path = "/artwork/container.png"
    if frameName then
        return path .. ":" .. frameName
    else
        return path .. ":default"
    end
end

function Sexbound.Actor:getDefaultPartImage(frameName)
    local path = "/artwork/defaults/default_image.png"
    if frameName then
        return path .. ":" .. frameName
    else
        return path .. ":default"
    end
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

function Sexbound.Actor:buildBodyType()
    --local gender = self:getSubGender() or self:getGender()
    --local targetGenders = self:getParent():getConfig().sex.whichGendersHaveBoobs or {"female", "futanari"}
    --for _,g in pairs(targetGenders) do
    --    if g == gender then return "female" end
    --end
    
    --return "male"
    return self:getGender()
end

function Sexbound.Actor:buildGenitalType()
    local gender = self:getSubGender() or self:getGender()
    self:getLog():warn("OLD Building genital type for "..self:getName().." - is "..tostring(gender).." - THIS SHOULD NOT FIRE")
    local targetGenders = self:getParent():getConfig().sex.whichGendersCanProduceSperm or {"male", "futanari"}
    for _,g in pairs(targetGenders) do
        if g == gender then return "male" end
    end
    
    return "female"
end

--- Returns the body type of this actor instance.
function Sexbound.Actor:getBodyType()
    return self:getIdentity().sxbBodyType or self:buildBodyType()
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

--- Returns the gender of this actor instance, dynamically accounting for futas in respect to the calling partner
function Sexbound.Actor:getGenderFutasafe(diffNum)
    -- TODO
    local actNum = self:getActorNumber() or 0
    local id  = self:getIdentity()
    diffNum = diffNum or 0
    local actGender = id.gender
    if id.sxbSubGender == "futanari" or id.sxbSubGender == "cuntboy" then
       if actNum == 1 then actGender = "male" else actGender = "female" end
       local positionRelation = self:getPosition():getConfig().actorRelation or {}
       local thisFucks = positionRelation[actNum] or 0
       local thatFucks = positionRelation[diffNum] or 0
       if thisFucks ~= 0 and thisFucks == diffNum then actGender = "male"
       elseif thatFucks ~= 0 and thatFucks == actNum then actGender = "female" end
    end
    
    return actGender
end

--- Returns the visible genital type of this actor.
function Sexbound.Actor:getGenitalType()
    --return self:getIdentity().sxbGenitalType or self:buildGenitalType()
    local id = self:getIdentity()
    local genitalType = "female"
    if id.body.hasPenis then genitalType = "male" end
    return self:getIdentity().sxbGenitalType or genitalType
end

--- Returns a list of available genital types on this actor
function Sexbound.Actor:getGenitalTypes()
    --[[local genitals = {}
    local gender = self:getSubGender() or self:getGender()
    local mainConfig = self:getParent():getConfig().sex
    local maleGenders = mainConfig.whichGendersCanProduceSperm or {"male", "futanari"}
    local femaleGenders = mainConfig.whichGendersCanOvulate or {"female", "futanari", "cuntboy"}
    
    for _,g in pairs(maleGenders) do
        if g == gender then table.insert(genitals, "male") break end
    end
    for _,g in pairs(femaleGenders) do
        if g == gender then table.insert(genitals, "female") break end
    end
    
    return genitals]]
    local genitals = {}
    local id = self:getIdentity()
    if id.body.hasPenis then table.insert(genitals, "male") end
    if id.body.hasVagina then table.insert(genitals, "female") end
    return genitals
end

--- Returns if this actor has the given genital type (e.g. Futas have a dick and a vagina, but on the sprite only the dick counts)
-- getGenitalType returns the main visible type (dick > no dick) for sprite rendering purposes
-- This method checks if the actor logically has a given gender type, for climax and pregnancy logic reasons
function Sexbound.Actor:hasGenitalType(gtype)
    --[[local gender = self:getSubGender() or self:getGender()
    local targetGenders
    if gtype == "male" then targetGenders = self:getParent():getConfig().sex.whichGendersCanProduceSperm or {"male", "futanari"}
    elseif gtype == "female" then targetGenders = self:getParent():getConfig().sex.whichGendersCanOvulate or {"female", "futanari", "cuntboy"} end
    
    for _,g in pairs(targetGenders) do
        if g == gender then return true end
    end
    
    return false]]
    local id = self:getIdentity()
    if gtype == "male" then return id.body.hasPenis or false
    elseif gtype == "female" then return id.body.hasVagina or false end
    return false
end

--- Returns the sub-gender of this actor instance.
function Sexbound.Actor:getSubGender()
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
    if param then
        return self._config.identity[param]
    end

    return self._config.identity
end

--- Returns a reference to the log for this Actor instance.
function Sexbound.Actor:getLog()
    return self._log
end

--- Returns a reference to this instance's Mouth.
function Sexbound.Actor:getMouth()
    return self._mouth
end

--- Returns the name of this Actor instance.
function Sexbound.Actor:getName()
    return self._config.identity.name
end

--- Returns reference to targeted other actor.
function Sexbound.Actor:getOtherActor()
    for _, actor in pairs(self:getParent():getActors()) do
        if actor:getActorNumber() ~= self:getActorNumber() then
            return actor
        end
    end
end

--- Returns actual reference to targeted other actor, based on fuck hierarchy.
function Sexbound.Actor:getOtherActorPositionsafe(prioSub)
    prioSub = prioSub or false
    local actNum = self:getActorNumber()
    local positionTable = self:getPosition():getConfig().actorRelation or {}
    local thisFucks = positionTable[actNum] or 0
    local thatFucks = 0
    for i, target in ipairs(positionTable) do 
        if target == actNum then thatFucks = i end
    end
    local dom, sub = nil, nil
    local target = nil
    local actors = self:getParent():getActors()
    
    dom = actors[thatFucks]
    sub = actors[thisFucks]

    if dom == nil and sub == nil then target = self:getOtherActor()
    elseif dom ~= nil and sub ~= nil then
        if prioSub then target = sub
        else target = dom end
    elseif dom ~= nil then target = dom
    else target = sub end
    
    return target
end

--- Returns list of all actors fucking this actor.
function Sexbound.Actor:getImpregnatorList()
    local list = {}
    local relations = self:getPosition():getConfig().actorRelation
    local actorNum = self:getActorNumber()
    
    for i, target in ipairs(relations) do
        if target == actorNum then 
            local targetActor = self:getParent():getActors()[i] or nil
            if targetActor then table.insert(list, targetActor) end
        end
    end
    
    return list
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
    if self:getPluginMgr() == nil then
        return
    end

    if pluginName then
        return self:getPluginMgr():getPlugins(pluginName)
    end

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

--- Sets the role for this actor with the specifed index.
-- @param index
function Sexbound.Actor:setRole(index)
    local role = self:getAnimationState():getOverrideRoles(index)
    self._role = role or "actor" .. index
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
    filename = util.replaceTag(filename, "gender", tags.gender or "default")
    filename = util.replaceTag(filename, "framename", tags.frameName or "default")
    filename = util.replaceTag(filename, "role", tags.role or "default")
    filename = util.replaceTag(filename, "species", tags.species or "default")

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
function Sexbound.Actor:getStatus()
    return self._status
end

function Sexbound.Actor:status()
    return self._status
end

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

function Sexbound.Actor:getGenes()
    local g = self:getIdentity() or {}
    g = g.genetics or {}
    return g.bodyColor, g.bodyColorAverage, g.undyColor, g.undyColorAverage, g.hairColor, g.hairColorAverage
end

function Sexbound.Actor:getGenePool()
    local g = self:getIdentity() or {}
    g = g.genetics or {}
    return g.bodyColorPool, g.bodyColorPoolAverage, g.bodyAllowBlending, g.undyColorPool, g.undyColorPoolAverage, g.undyAllowBlending, g.hairColorPool, g.hairColorPoolAverage, g.hairAllowBlending
end

function Sexbound.Actor:isPregnant()
    local plugin = self:getPlugins("pregnant")

    if plugin == nil then
        return false
    end

    return plugin:isPregnant()
end

function Sexbound.Actor:isInflated()
    local plugin = self:getPlugins("climax")

    if plugin == nil then return false end

    return plugin:isInflated()
end

function Sexbound.Actor:isVisiblyPregnant()
    local plugin = self:getPlugins("pregnant")

    if plugin == nil then return false end

    return plugin:isVisiblyPregnant()
end

function Sexbound.Actor:getPregnancyStage()
    local plugin = self:getPlugins("pregnant")
    
    if plugin == nil then return false end
    
    return plugin:getPregnancyStage()
end

function Sexbound.Actor:isEnabledPregnancyFetish()
    local plugin = self:getPlugins("pregnant")

    if plugin == nil then
        return false
    end

    return plugin:getConfig().enablePregnancyFetish
end

--- Returns if this actor is capable of ovulating
function Sexbound.Actor:canOvulate()
    return self:getIdentity().body.canOvulate or false
end
--- Returns if this actor is capable of producing sperm
function Sexbound.Actor:canProduceSperm()
    return self:getIdentity().body.canProduceSperm or false
end
--- Returns if this actor has means to penetrate another actor
function Sexbound.Actor:canPenetrate()
    return self:getStatus():hasStatus("equipped_strapon") or self:getGenitalType() == "male"
end
--- Returns if this actor has a biological penis
function Sexbound.Actor:hasPenis()
    return self:hasGenitalType("male")
end
--- Returns if this actor has a vagina
function Sexbound.Actor:hasVagina()
    return self:hasGenitalType("female")
end

--- Checks if an actor has a given set of traits
function Sexbound.Actor:hasTraits(traits)
    if traits == nil then return true end
    if type(traits) ~= "table" then return true end
    for _,t in ipairs(traits) do
        if t == "boobs" and self:getBodyType() ~= "female" then return false end
        if t == "insert" and not self:canPenetrate() then return false end
        if t == "dick" and not self:hasGenitalType("male") then return false end
        if t == "vagina" and not self:hasGenitalType("female") then return false end
    end
    return true
end

--- Checks if the actor is currently in a role in the current position that has the interaction type given
function Sexbound.Actor:hasInteractionType(type)
    local interactionTypes = self:getPosition()._config.interactionType
    local actorList = self:getImpregnatorList()
    for i,a in ipairs(actorList) do
        local actorNum = a._actorNumber
        if interactionTypes[actorNum] == type then return true end
    end
    return false
end

--- Retrieves the data for UI syncing for this actor
function Sexbound.Actor:getUIData(args)
    local data = {
        actorSlot       = "actor" .. self:getActorNumber(),
        bodyDirectives  = self:getIdentity("bodyDirectives"),
        bodyType        = self:getBodyType(),
        hairID          = self:getIdentity("hairType"),
        hairDirectives  = self:getIdentity("hairDirectives"),
        showBackwear    = self:getApparel():getIsVisible("backwear"),
        showChestwear   = self:getApparel():getIsVisible("chestwear"),
        showHeadwear    = self:getApparel():getIsVisible("headwear"),
        showLegswear    = self:getApparel():getIsVisible("legswear"),
        showNippleswear = self:getApparel():getIsVisible("nippleswear"),
        frameName       = self:getFrameName(self:getAnimationState()),
        gender          = self:getGender(),
        subGender       = self:getSubGender(),
        entityType      = self:getEntityGroup(),
        genitalType     = self:getGenitalTypes(),
        species         = self:getSpecies(),
        status          = {
            isPregnant          = self:isVisiblyPregnant(),
            isInflated          = self:isInflated(),
            isClimaxing         = self._isClimaxing or false,
            isPreClimaxing      = self._isPreClimaxing or false,
            isScriptedClimaxing = self._isScriptedClimaxing or false
        }
    }

    if self:getPlugins("climax") then
        data.climax = {
            currentPoints = self:getPlugins("climax"):getCurrentPoints(),
            maxPoints = self:getPlugins("climax"):getMaxPoints()
        }
    end
    
    return data
end

--- Legacy

function Sexbound.Actor:getBackwear()
    return self:getApparel():getItemConfig("backwear")
end

function Sexbound.Actor:getChestwear()
    return self:getApparel():getItemConfig("chestwear")
end

function Sexbound.Actor:getHeadwear()
    return self:getApparel():getItemConfig("headwear")
end

function Sexbound.Actor:getLegswear()
    return self:getApparel():getItemConfig("legswear")
end

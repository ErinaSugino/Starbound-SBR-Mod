--- Sexbound Class Module.
-- @classmod Sexbound
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound = {}
Sexbound_mt = {
    __index = Sexbound
}

if not SXB_RUN_TESTS then
    require("/scripts/util.lua")
    require("/scripts/vec2.lua")
    require("/scripts/messageutil.lua")
    require("/scripts/sexbound/util.lua")
    require("/scripts/sexbound/lib/sexbound/actor.lua")
    require("/scripts/sexbound/lib/sexbound/compatibility.lua")
    require("/scripts/sexbound/lib/sexbound/log.lua")
    require("/scripts/sexbound/lib/sexbound/messenger.lua")
    require("/scripts/sexbound/lib/sexbound/event.lua")
    require("/scripts/sexbound/lib/sexbound/object/SmashObjectController.lua")
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsPositionController.lua")
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsRotationController.lua")
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsScaleController.lua")
    require("/scripts/sexbound/lib/sexbound/node.lua")
    require("/scripts/sexbound/lib/sexbound/positions.lua")
    require("/scripts/sexbound/lib/sexbound/statemachine.lua")
    require("/scripts/sexbound/lib/sexbound/ui.lua")
end

--- Returns a reference to a new instance of Sexbound.
function Sexbound.new(maxActors)
    local self = setmetatable({
        _maxAllowedActors = maxActors or 1,
        _actors = {},
        _actorsOrdered = {},
        _currentOrderIndex = 1,
        _currentOrderId = "",
        _animationRate = 1,
        _entityId = entity.id(),
        _entityType = entity.entityType(),
        _nodes = {},
        _promises = PromiseKeeper.new(),
        _timers = {},
        _globalActorId = 0,
        _uiSyncTokens = {positions=0},
        _containsPlayer = false
    }, Sexbound_mt)

    -- Store UUID of the entity running this instance of Sexbound.
    storage.uniqueId = storage.uniqueId or entity.uniqueId()

    -- Load global configuration.
    self._config = self:loadConfig()

    -- Initialize new instance of Log with prefix set to "MAIN".
    self._log = Sexbound.Log:new("MAIN", self._config)

    -- Initialize new instance of Compatibility
    self._compatibility = Sexbound.Compatibility.new(self)

    -- Display incompatibility when this mod is not compatible with the current version of Sexbound
    if not self._compatibility:isCompatible() then
        self._compatibility:incompatibleVersion()
    end

    -- Create new internal messenger using 'main' channel.
    Sexbound.Messenger.new("main")

    -- Add self as message broadcast recipient.
    Sexbound.Messenger.get("main"):addBroadcastRecipient(self)

    self._adjustActorsPositionController = Sexbound.AdjustActorsPositionController:new()
    self._adjustActorsRotationController = Sexbound.AdjustActorsRotationController:new()
    self._adjustActorsScaleController = Sexbound.AdjustActorsScaleController:new()

    -- Initialize new instance of Positions (before instantiating the StateMachine).
    self._positions = Sexbound.Positions:new(self)

    -- Initialize new instance of StateMachine.
    self._stateMachine = Sexbound.StateMachine.new(self)

    -- Initialize the Facing Direction of this instance.
    self:initFacingDirection()

    -- Initialize message handlers.
    self:initMessageHandlers()

    -- Sets this object to be interactive when its interactive configuration parameter is set to true.
    if object then
        object.setInteractive(config.getParameter("interactive", false))
    end

    self._UI = Sexbound.UI.new(self)

    self:getLog():info("Initialized.")

    self._event = Sexbound.Event.new(self)

    self._timers = {
        emitAnimationRateEvent = 0
    }
    
    self:loadSubscripts()

    self:getLog():debug("Initing Sexbound instance "..entity.id())

    return self
end

--- [Helper] Initializes message handlers.
function Sexbound:initMessageHandlers()
    message.setHandler("Sexbound:Actor:Climax", function(_, _, args)
        return self:handleClimax(args)
    end)

    message.setHandler("Sexbound:Actor:ScriptedClimax", function(_, _, args)
        return self:handleScriptedClimax(args)
    end)

    message.setHandler("Sexbound:Node:Init", function(_, _, args)
        return self:handleNodeInit(args)
    end)

    message.setHandler("Sexbound:Node:Uninit", function(_, _, args)
        return self:handleNodeUninit(args)
    end)

    message.setHandler("Sexbound:Backwear:Change", function(_, _, args)
        return self:handleChangeBackwear(args)
    end)

    message.setHandler("Sexbound:Chestwear:Change", function(_, _, args)
        return self:handleChangeChestwear(args)
    end)

    message.setHandler("Sexbound:Groinwear:Change", function(_, _, args)
        return self:handleChangeGroinwear(args)
    end)

    message.setHandler("Sexbound:Headwear:Change", function(_, _, args)
        return self:handleChangeHeadwear(args)
    end)

    message.setHandler("Sexbound:Legswear:Change", function(_, _, args)
        return self:handleChangeLegswear(args)
    end)

    message.setHandler("Sexbound:Nippleswear:Change", function(_, _, args)
        return self:handleChangeNippleswear(args)
    end)

    message.setHandler("Sexbound:Actor:Remove", function(_, _, args)
        return self:handleRemoveActor(args)
    end)

    message.setHandler("Sexbound:Actor:Setup", function(_, _, args)
        return self:handleSetupActor(args)
    end)

    message.setHandler("Sexbound:Actor:Store", function(_, _, args)
        return self:handleStoreActor(args)
    end)

    message.setHandler("Sexbound:Actor:SwitchRole", function(_, _, args)
        return self:handleSwitchRole(args)
    end)

    message.setHandler("Sexbound:Backwear:Toggle", function(_, _, args)
        return self:handleToggleBackwear(args)
    end)

    message.setHandler("Sexbound:Chestwear:Toggle", function(_, _, args)
        return self:handleToggleChestwear(args)
    end)

    message.setHandler("Sexbound:Backwear:NextVariant", function(_, _, args)
        return self:handleNextVariantBackwear(args)
    end)

    message.setHandler("Sexbound:Backwear:PrevVariant", function(_, _, args)
        return self:handlePrevVariantBackwear(args)
    end)

    message.setHandler("Sexbound:Chestwear:NextVariant", function(_, _, args)
        return self:handleNextVariantChestwear(args)
    end)

    message.setHandler("Sexbound:Chestwear:PrevVariant", function(_, _, args)
        return self:handlePrevVariantChestwear(args)
    end)

    message.setHandler("Sexbound:Headwear:NextVariant", function(_, _, args)
        return self:handleNextVariantHeadwear(args)
    end)

    message.setHandler("Sexbound:Headwear:PrevVariant", function(_, _, args)
        return self:handlePrevVariantHeadwear(args)
    end)

    message.setHandler("Sexbound:Legswear:NextVariant", function(_, _, args)
        return self:handleNextVariantLegswear(args)
    end)

    message.setHandler("Sexbound:Legswear:PrevVariant", function(_, _, args)
        return self:handlePrevVariantLegswear(args)
    end)

    message.setHandler("Sexbound:Headwear:Toggle", function(_, _, args)
        return self:handleToggleHeadwear(args)
    end)

    message.setHandler("Sexbound:Legswear:Toggle", function(_, _, args)
        return self:handleToggleLegswear(args)
    end)

    message.setHandler("Sexbound:Retrieve:ControllerId", function(_, _, args)
        return self:handleRetrieveControllerId(args)
    end)

    message.setHandler("Sexbound:Retrieve:UIConfig", function(_, _, args)
        return self:handleRetrieveUIConfig(args)
    end)

    message.setHandler("Sexbound:UI:Sync", function(_, _, args)
        return self:handleSyncUI(args)
    end)

    message.setHandler("Sexbound:Smash", function(_, _, args)
        args = args or {}
        if args.storage and storage.actor then
            storage.actor.storage = util.mergeTable(storage.actor.storage, args.storage)
        end
        return Sexbound.SmashObjectController:new():smashObject()
    end)
    
    message.setHandler("Sexbound:Common:StartSexMusic", function(_, _, args)
        return self:startSexMusicForEntity(args)
    end)
    message.setHandler("Sexbound:Common:StopSexMusic", function(_, _, args)
        return self:stopSexMusicForEntity(args)
    end)
end

function Sexbound:loadSubscripts()
    local _override = self._config.override["actor"] or {}

    util.each(_override.scripts, function(_, _script)
        require(_script)
    end)
end

--- [Helper] Initializes the Facing Direction of this instance
function Sexbound:initFacingDirection()
    if object then
        self._facingDirection = object.direction()
        return
    end

    if mcontroller then
        self._facingDirection = mcontroller.facingDirection()
        return
    end

    self._facingDirection = util.randomChoice({-1, 1})
end

--- Uninitializes this instance.
function Sexbound:uninit()
    self:getLog():info("Uniniting..")

    local result1 = self:uninitActors()
    local result2 = self:uninitNodes()

    animator.setAnimationState("props", "none", true)
    animator.setAnimationState("actors", "none", true)

    return result1 and result2
end

--- Updates this instance.
-- @param dt The delta time
function Sexbound:update(dt)
    self:getPromises():update()

    if self._compatibility:isCompatible() then
        self:getStateMachine():update(dt)

        Sexbound.Messenger.get("main"):dispatch()

        self:forEachNode(function(index, node)
            node:update(dt)
        end)
        
        if self._doClock then self:tickClock() end
    end
end

--- Handles interally received message.
-- @param message A Message
function Sexbound:onMessage(message) --[[ Currently not handling any internal messages for this class. --]]
end

--- Adds a new instance of Actor to the actors table.
-- @param actorConfig
-- @param store
function Sexbound:addActor(actorConfig, store)
    -- Return false when adding another actor would exceed the max allowed actors for current position
    if #self._actors >= self._maxAllowedActors then
        return false
    end

    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:Event:Create", {
        eventName = "ACTOR_ADD",
        eventArgs = actorConfig
    })
    
    self._globalActorId = self._globalActorId + 1 -- Loc, an ID should be universally unique, and not redundant crap.
    --actor:setId(self._globalActorId)
    
    -- Try to retain current role composition by just adding new actor last
    local newMax = #self._actors + 1
    self._currentOrderId = self._currentOrderId..newMax
    
    --actor:setActorNumber(newMax)
    --actor:setRole(newMax)

    local actor = Sexbound.Actor:new(self, actorConfig, self._globalActorId, newMax)

    if store then
        storage.actor = actor:getConfig()
    end

    self:getLog():info("Adding Actor: " .. actor:getName())

    -- Insert new actor into actors table
    table.insert(self._actors, actor)
    table.insert(self._actorsOrdered, actor)
    self:getLog():debug("Actor added to list. Length now: "..#self._actors)

    --actor:getApparel():sync()

    --actor:initPlugins()
    
    if actor:getEntityType() == "player" then self._containsPlayer = true end
    
    self._positions:filterPositions(self._actors)
    
    self._UI:refresh()
    actor:openUI()

    -- Resort actors based on changed environment
    self:helper_reassignAllRoles()
    
    -- If we only have NPCs, try to initiate sex (switch from idle to a random available position)
    if not self._containsPlayer and self._config.sex.npcStartSex then
        self._positions:switchRandomSexPosition(true)
    end
    
    -- Reset all actors to refresh their appearances
    self:resetAllActors()

    -- Broadcast message "Sexbound:AddActor" to all receivers immediately
    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:AddActor", {}, true)

    return true
end

--- Removes an actor from the actors table when it has a matching entityId
-- @param entityId
function Sexbound:removeActor(entityId)
    self:getLog():debug("Got remove request for actor - eid: "..tostring(entityId))
    local index, orderedIndex, actor = self:helper_prepareToRemoveActor(entityId)
    if index ~= nil and actor ~= nil then
        actor:uninit()

        table.remove(self._actors, index)
        if orderedIndex ~= nil then table.remove(self._actorsOrdered, orderedIndex) end
        self:getLog():debug("Officially removed actor for entity "..tostring(entityId).." - new count: "..#self._actors)
        
        local containsPlayer = false
        for _,a in ipairs(self._actors) do
            if a:getEntityType() == "player" then containsPlayer = true break end
        end
        self._containsPlayer = containsPlayer
        
        self._positions:filterPositions(self._actors)
        self:helper_reassignAllRoles()
        
        if not self._containsPlayer and self._config.sex.npcStartSex then
            self._positions:switchRandomSexPosition(true)
        end
        
        self:resetAllActors()

        -- Broadcast message "Sexbound:RemoveActor" to all receivers immediately
        Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:RemoveActor", {}, true)
    end
end

--- Uninitializes each instance of Actor in the actors table.
function Sexbound:uninitActors()
    self:getLog():info("Uniniting Actors.")

    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:PrepareRemoveActor", {}, true)

    self:forEachActor(function(index, actor)
        actor:resetGlobalAnimatorTags()

        actor:resetTransformations()

        actor:uninit()
    end)

    self._actors = {}
    self._actorsOrdered = {}

    return true
end

--- Adds a new instance of Node to the nodes table.
-- @param tilePosition
-- @param sitPosition
function Sexbound:addNode(tilePosition, sitPosition, params)
    table.insert(self._nodes, Sexbound.Node.new(self, tilePosition, sitPosition, true))

    self._nodes[#self._nodes]:create(params)
end

--- Adds a new instance of Node to the nodes table and tracks it as being this object.
-- @param sitPosition
function Sexbound:becomeNode(sitPosition)
    table.insert(self._nodes, Sexbound.Node.new(self, {0, 0}, sitPosition, false))
end

--- Uninitializes each instance of Node in the nodes table.
function Sexbound:uninitNodes()
    self:getLog():info("Uniniting Nodes.")

    for _, _node in ipairs(self:getNodes()) do
        _node:uninit()
    end

    self._nodes = {}

    return true
end

--- Changes the Backwear of the actor with the specified entity ID.
-- @param entityId A valid entity ID
-- @param backwearConfig A table of backwear config
function Sexbound:changeBackwear(entityId, backwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("backwear", backwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Chestwear of the actor with the specified entity ID.
-- @param entityId A valid entity ID
-- @param chestwearConfig A table of chestwear config
function Sexbound:changeChestwear(entityId, chestwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("chestwear", chestwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Groinwear of the actor with the specified entity ID.
-- @param entityId A valid entity ID
-- @param groinwearConfig A table of groinwear config
function Sexbound:changeGroinwear(entityId, groinwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("groinwear", groinwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Headwear of the actor with the specified entity ID.
-- @param entityId A valid entity ID
-- @param headwearConfig A table of headwear config
function Sexbound:changeHeadwear(entityId, headwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("headwear", headwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Legswear of the actor with the specified entity ID.
-- @param entityId A valid entity ID
-- @param legswearConfig A table of legswear config
function Sexbound:changeLegswear(entityId, legswearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("legswear", legswearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Nippleswear of the actor with the specified entity ID.
-- @param entityId A valid entity ID
-- @param nippleswearConfig A table of legswear config
function Sexbound:changeNippleswear(entityId, nippleswearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("nippleswear", nippleswearConfig)
        end
    end)

    self:resetAllActors()
end

--- Executes a callback for each actor.
-- @param callback A function assigned arguments as index and actor, respectively.
function Sexbound:forEachActor(callback)
    for index, actor in ipairs(self._actorsOrdered) do
        callback(index, actor)
    end
end

function Sexbound:forEachOriginalActor(callback)
    for index,actor in ipairs(self._actors) do
        callback(index, actor)
    end
end

--- Executes a callback for each node.
-- @param callback A function assigned arguments as index and node, respectively.
function Sexbound:forEachNode(callback)
    for index, node in ipairs(self._nodes) do
        callback(index, node)
    end
end

--- Handles a player interaction request.
-- @param args interact arguments
function Sexbound:handleInteract(args)
    if not self._compatibility:isCompatible() then
        self._compatibility:incompatibleVersion()
        return
    end

    -- Refresh the UI module beforehand
    --self._UI:refresh()

    -- Lounge-in next available node.
    for _, node in ipairs(self._nodes) do
        if not node:occupied() then
            node:lounge(args.sourceId)

            --return self._UI:handleInteract(args)
        end
    end
end

-- [Helper] Returns a table that consists of settings to use to spawn an NPC.
-- @param actor Actor configuration represented as a Lua table
function Sexbound:helper_convertActorToNPC(actor)
    return {
        entityType = actor.type,
        level = actor.level,
        params = {
            scriptConfig = {
                uniqueId = actor.uniqueId
            },
            statusControllerSettings = {
                statusProperties = {
                    sexbound_previous_storage = actor.storage
                }
            }
        },
        position = vec2.add(object.position(), {0, 3}),
        seed = actor.seed,
        species = actor.identity.species
    }
end

-- [Helper] Returns Actor ID and a reference to an Actor. Prepares an actor with matching specified entity ID to be removed.
-- @param entityId A valid entity ID
-- @return[1] Actor ID
-- @return[2] Reference to Actor instance
function Sexbound:helper_prepareToRemoveActor(entityId)
    local targetActor = {}

    -- For each actor, reset all plugins and animation settings.
    self:forEachOriginalActor(function(i, actor)
        actor:forEachPlugin(function(j, plugin)
            plugin:reset()
        end)

        actor:resetTransformations()

        actor:resetGlobalAnimatorTags()

        if entityId == actor:getEntityId() then
            targetActor.id = i
            targetActor.aid = actor:getId()
            targetActor.ref = actor
        end
    end)
    self:forEachActor(function(i,actor)
        if targetActor.aid == actor:getId() then targetActor.oid = i end
    end)

    return targetActor.id, targetActor.oid, targetActor.ref
end

-- [Helper] Swaps the slots of all currently loaded actors.
function Sexbound:helper_reassignAllRoles()
    if #self._actors == 0 then return end
    local sexConfig = self:getConfig().sex or {}

    --[[if sexConfig.allowSwitchRoles and self:getActorCount() == 2 then
        -- Switch actors when actor 1 is female and actor 2 is male when actor 1 is not wearing a strapon.
        if not self._actors[1]:getStatus():hasStatus("equipped_strapon") and self._actors[1]:getGender() == "female" and
            (self._actors[2]:getGender() == "male" or self._actors[2]:getSubGender() == "futanari") then
            self:switchActorRoles()

            -- An actor wearing a strapon should be switched to be actor 1.
        elseif self._actors[2]:getStatus():hasStatus("equipped_strapon") then
            self:switchActorRoles()
        end
    end

    -- Check if any actor needs to have its role forced
    self:forEachActor(function(index, actor)
        if actor:getForceRole() > 0 and actor:getForceRole() ~= index then
            self:helper_forceActorRole(actor, index)
        end
    end)]]
    
    local curIndices, curPerms = self._positions:getCurrentPosition():getAvailableRoles()
    if curPerms[self._currentOrderId] then
        -- Expected composition ID does exist - fetch new index
        for i,v in ipairs(curIndices) do if v==self._currentOrderId then self._currentOrderIndex = i break end end
    else
        -- Expected composition ID does not exist anymore. Fetch first available as fallback
        self._currentOrderIndex = 1
        self._currentOrderId = curIndices[1]
    end
    
    local targetPerm = curPerms[self._currentOrderId]
    local newOrder = {}
    self:getLog():debug("Rearraging - current permutation: "..self._currentOrderId.." - "..Sexbound.Util.dump(targetPerm))
    for _,a in ipairs(targetPerm) do table.insert(newOrder, self._actors[a]) self:getLog():debug("Adding actor #"..a) end
    self._actorsOrdered = newOrder
end

--- [Helper] Swap an actor to be in its forced role.
-- @param actor
-- @param currentRole
function Sexbound:helper_forceActorRole(actor, currentRole)
    local forceRole = actor:getForceRole()

    if forceRole > #self._actors then
        return
    end

    Sexbound.Util.swap(self._actors, currentRole, forceRole)

    self:resetAllActors()
end

--- Loads and returns the global configuration.
function Sexbound:loadConfig()
    local _, _config = xpcall(function()
        return util.mergeTable(root.assetJson("/sexbound.config"), config.getParameter("sexboundConfig", {}))
    end, function(error)
        self:getLog():error("Unable to load global sexbound config file!")
    end)

    return _config
end

--- Resets all instances of Actor in the actors table.
function Sexbound:resetAllActors(stateName)
    if animator.hasTransformationGroup("actors") then
        animator.resetTransformationGroup("actors")
    end

    self:forEachActor(function(index, actor)
        actor:setActorNumber(index)
        actor:setRole(index)
        actor:reset(stateName)
    end)

    if self._config.actor.mirrorArtwork == true then
        self:mirrorActorsHorizonally()
    end

    self:applyConstantScaleToActors()
end

function Sexbound:applyConstantScaleToActors()
    local constantScale = self:getPositions():getCurrentPosition():getConstantScale()
    if constantScale ~= nil then
        self._adjustActorsScaleController:adjustActorsScale(constantScale)
    end
end

function Sexbound:mirrorActorsHorizonally()
    self._adjustActorsScaleController:adjustActorsScale({-1, 1})
end

--- Respawns the stored actor if it exists in this object's storage.
function Sexbound:respawnStoredActor()
    local actor = storage.actor

    if actor and actor.uniqueId then
        world.sendEntityMessage(actor.uniqueId, "Sexbound:Actor:Respawn", actor.storage)
    end
end

--- Shifts all actors in the actors table one element to the right.
function Sexbound:switchActorRoles(direction)
    if not self:getStateMachine():isClimaxing() then
        --table.insert(self._actors, 1, table.remove(self._actors, #self._actors))
        
        local curIndices, curPerms = self:getPositions():getCurrentPosition():getAvailableRoles()
        local maxIndex = #curIndices
        
        if maxIndex <= 1 then return false end -- We only have one (or no?) available composition. Switching disabled, return false for UI
        
        self:getLog():info("Actors are switching roles. Direction "..tostring(direction))
        
        -- Apply index shift
        self._currentOrderIndex = self._currentOrderIndex + direction
        if self._currentOrderIndex <= 0 then self._currentOrderIndex = maxIndex
        elseif self._currentOrderIndex > maxIndex then self._currentOrderIndex = 1 end
        -- Fetch new id
        self._currentOrderId = curIndices[self._currentOrderIndex]
        
        -- Resort actors
        local targetPerm = curPerms[self._currentOrderId]
        local newOrder = {}
        for _,a in ipairs(targetPerm) do table.insert(newOrder, self._actors[a]) end
        self._actorsOrdered = newOrder

        self:resetAllActors()

        Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:SwitchRoles", {}, true)

        return true
    end

    return false
end

-- [Hidden] Updates the animation rate of the animator based on the delta time.
-- @param stateName
-- @param dt The delta time
function Sexbound:updateAnimationRate(stateName, dt)
    --[[self._temp = self._temp or 0
    self._temp = self._temp + dt
    self._temp2 = self._temp2 or 0.1
    if self._temp > 5 then
        self._temp2 = self._temp2 * 10
        if self._temp2 > 1 then self._temp2 = 0.1 end
        self._temp = 0
    end
    animator.setAnimationRate(self._temp2)
    return]]
    local _animState = self:getPositions():getCurrentPosition():getAnimationState(stateName)

    local _minTempo = self._overrideMinTempo or _animState:getMinTempo()
    local _maxTempo = self._overrideMaxTempo or _animState:getMaxTempo()
    local _sustainedInterval = self._overrideSustainedInterval or _animState:getSustainedInterval()

    self._animationRate =
        util.clamp(self._animationRate + (_maxTempo / (_sustainedInterval / dt)), _minTempo, _maxTempo)

    -- Set the animator's animation rate
    animator.setAnimationRate(self._animationRate)

    local actors = {}
    for _, actor in ipairs(self._actors) do
        table.insert(actors, {
            name = actor:getName(),
            uniqueId = actor:getUniqueId()
        })
    end

    self._timers.emitAnimationRateEvent = self._timers.emitAnimationRateEvent + dt

    if self._timers.emitAnimationRateEvent >= 0.5 then
        self._timers.emitAnimationRateEvent = 0

        --[[Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:Event:Create", {
            eventName = "ANIMATION_RATE",
            eventArgs = {
                actors = actors,
                animation_rate = self._animationRate
            }
        })]]--
    end

    if (self._animationRate >= _maxTempo) then
        self._animationRate = _animState:nextMinTempo()

        _animState:nextMaxTempo()

        _animState:nextSustainedInterval()
    end
end

--- Function to trigger an update for a sync token
function Sexbound:tickToken(tokenName)
    local val = self._uiSyncTokens[tokenName] or 0
    val = val + 1
    self._uiSyncTokens[tokenName] = val
end

-- Handlers

-- [Helper] Handles received message to change an actor's backwear.
-- @param args A Lua table where entityId is defined.
function Sexbound:handleChangeBackwear(args)
    self:changeBackwear(args.entityId, args.backwear)
end

-- [Helper] Handles received message to change an actor's chestwear.
-- @param args A Lua table where entityId is defined.
function Sexbound:handleChangeChestwear(args)
    self:changeChestwear(args.entityId, args.chestwear)
end

-- [Helper] Handles received message to change an actor's groinwear.
-- @param args A Lua table where entityId is defined.
function Sexbound:handleChangeGroinwear(args)
    self:changeGroinwear(args.entityId, args.groinwear)
end

-- [Helper] Handles received message to change an actor's headwear.
-- @param args A Lua table where entityId is defined.
function Sexbound:handleChangeHeadwear(args)
    self:changeHeadwear(args.entityId, args.headwear)
end

-- [Helper] Handles received message to change an actor's legswear.
-- @param args A Lua table where entityId is defined.
function Sexbound:handleChangeLegswear(args)
    self:changeLegswear(args.entityId, args.legswear)
end

-- [Helper] Handles received message to change an actor's Nippleswear.
-- @param args A Lua table where entityId is defined.
function Sexbound:handleChangeNippleswear(args)
    self:changeNippleswear(args.entityId, args.nippleswear)
end

-- [Helper] Handles received message to command an actor to begin climaxing.
-- @param args A Lua table where actorId is defined.
function Sexbound:handleClimax(args)
    if self:getStateMachine():isHavingSex() then
        Sexbound.Messenger.get("main"):send(self, self._actorsOrdered[args.actorId], "Sexbound:Climax:BeginClimax", {})
        return true
    end

    return false
end

-- [Helper] Handles retrieving the controller ID.
function Sexbound:handleRetrieveControllerId(args)
    return self:getEntityId()
end

-- [Helper] Handles retrieving the UI Config.
function Sexbound:handleRetrieveUIConfig(args)
    return self._UI:getConfig()
end

-- [Helper] Handles received message to command all actors to begin scripted climax.
-- @param args A Lua table
function Sexbound:handleScriptedClimax(args)
    self:forEachActor(function(index, actor)
        Sexbound.Messenger.get("main"):send(self, actor, "Sexbound:Climax:BeginScriptedClimax", {})
    end)

    return true
end

-- [Helper] Handles received message to finish initializing a sex node.
-- @param args A Lua table where entityId and uniqueId is defined.
function Sexbound:handleNodeInit(args)
    for _, node in ipairs(self:getNodes()) do
        if node:getUniqueId() == args.uniqueId then
            node:setEntityId(args.entityId)
        end
    end
end

-- [Helper] Handles received message to finish uninitializing a sex node.
-- @param args A Lua table where uniqueId is defined.
function Sexbound:handleNodeUninit(args)
    if not args then
        return
    end

    util.each(self:getNodes(), function(index, node)
        if node:getUniqueId() == args.uniqueId then
            node:uninit()
        end
    end)

    self:removeActor(args.actorId)
end

-- [Helper] Handles received message to remove an actor.
-- @param entityId A valid entity ID
function Sexbound:handleRemoveActor(entityId)
    self:removeActor(entityId)
end

-- [Helper] Handles received message to setup a new actor.
-- @param args Actor settings represented as a Lua table.
function Sexbound:handleSetupActor(args)
    return self:addActor(args, false)
end

-- [Helper] Handles received message to setup and store a new actor.
-- @param args Actor settings represented as a Lua table.
function Sexbound:handleStoreActor(args)
    return self:addActor(args, true)
end

-- [Helper] Handles received message to switch the roles of all actors.
-- @param args[opt] Not used currently.
function Sexbound:handleSwitchRole(args)
    local config = self:getConfig()
    if config.allowSwitchRoles ~= nil then
        config.sex.allowSwitchRoles = config.allowSwitchRoles
    end

    if self:getConfig().sex.allowSwitchRoles ~= true then
        return
    end
    
    local direction = args.val or 1
    return self:switchActorRoles(direction)
end

-- Temp until Lustbound is fixed
function Sexbound:getBodyType(actor)
    return actor:getIdentity().sxbBodyType or self:buildBodyType(actor)
end

-- Temp until Lustbound is fixed
function Sexbound:getGenitalType(actor)
    return actor:getIdentity().sxbGenitalType or self:buildGenitalType(actor)
end

-- Temp until Lustbound is fixed
function Sexbound:buildBodyType(actor)
    local gender = actor:getSubGender() or actor:getGender()
    if gender == "female" or gender == "futanari" then
        return "female"
    else
        return "male"
    end
end

-- Temp until Lustbound is fixed
function Sexbound:buildGenitalType(actor)
    local gender = actor:getSubGender() or actor:getGender()
    if gender == "male" or gender == "futanari" then
        return "male"
    else
        return "female"
    end
end

-- [Helper] Handles received message to sync with the default UI overlay.
-- @param args[opt] Not used currently.
function Sexbound:handleSyncUI(args)
    args = args or {}
    local remoteTokens = args.tokens or {["positions"]=0}
    local data = {
        actors = {},
        animationRate = self:getAnimationRate(),
        updateTokens = self._uiSyncTokens
    }
    
    local curPos = self:getPositions():getCurrentPosition()

    data.position = {
        friendlyName = curPos:getFriendlyName(),
        switchingEnabled = curPos:getCompositionCount() > 1
    }

    self:forEachActor(function(index, actor)
        table.insert(data.actors, {
            actorSlot       = "actor" .. actor:getActorNumber(),
            bodyDirectives  = actor:getIdentity("bodyDirectives"),
            bodyType        = actor:getBodyType(),
            hairID          = actor:getIdentity("hairType"),
            hairDirectives  = actor:getIdentity("hairDirectives"),
            showBackwear    = actor:getApparel():getIsVisible("backwear"),
            showChestwear   = actor:getApparel():getIsVisible("chestwear"),
            showHeadwear    = actor:getApparel():getIsVisible("headwear"),
            showLegswear    = actor:getApparel():getIsVisible("legswear"),
            showNippleswear = actor:getApparel():getIsVisible("nippleswear"),
            frameName       = actor:getFrameName(actor:getAnimationState()),
            gender          = actor:getGender(),
            subGender       = actor:getSubGender(),
            entityType      = actor:getEntityGroup(),
            genitalType     = actor:getGenitalTypes(),
            species         = actor:getSpecies(),
            status          = {
                isPregnant  = actor:isVisiblyPregnant(),
                isClimaxing = actor._isClimaxing or false,
                isPreClimaxing = actor._isPreClimaxing or false,
                isScriptedClimaxing = actor._isScriptedClimaxing or false
            }
        })

        if actor:getPlugins("climax") then
            data.actors[index].climax = {
                currentPoints = actor:getPlugins("climax"):getCurrentPoints(),
                maxPoints = actor:getPlugins("climax"):getMaxPoints()
            }
        end
    end)
    
    if remoteTokens.positions ~= self._uiSyncTokens.positions then
        data.positions = {}
        local allPositions = {}
        util.each(self:getPositions():getPositions(), function(index, position)
            local button = position:getButton()
            local name = position:getFriendlyName()
            local buttonImage = button.iconImage
            local uiIndex = ((index - 1) % 8) + 1
            allPositions[index] = {name = name, image = buttonImage, imageOffset = button.iconOffsets[uiIndex]}
        end)
        data.positions.allPositions = allPositions
    end

    return data
end

-- [Helper] Handles received message to show/hide an actor's backwear.
-- @param args A Lua table where actorId is defined.
function Sexbound:handleToggleBackwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    local backwearConfig = actor:getConfig().backwear or {}
    if backwearConfig.isLocked == true then
        return nil
    end

    actor:getApparel():toggleIsVisible("backwear")

    self:resetAllActors()

    return actor:getApparel():getIsVisible("backwear")
end

-- [Helper] Handles received message to show/hide an actor's chestwear.
-- @param args A Lua table where actorId is defined.
function Sexbound:handleToggleChestwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    local chestwearConfig = actor:getConfig().chestwear or {}
    if chestwearConfig.isLocked == true then
        return nil
    end

    actor:getApparel():toggleIsVisible("chestwear")

    self:resetAllActors()

    return actor:getApparel():getIsVisible("chestwear")
end

function Sexbound:handleNextVariantBackwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("backwear")

    self:resetAllActors()

    return true
end

function Sexbound:handlePrevVariantBackwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("backwear")

    self:resetAllActors()

    return true
end

function Sexbound:handleNextVariantChestwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("chestwear")

    self:resetAllActors()

    return true
end

function Sexbound:handlePrevVariantChestwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("chestwear")

    self:resetAllActors()

    return true
end

function Sexbound:handleNextVariantHeadwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("headwear")

    self:resetAllActors()

    return true
end

function Sexbound:handlePrevVariantHeadwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("headwear")

    self:resetAllActors()

    return true
end

function Sexbound:handleNextVariantLegswear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("legswear")

    self:resetAllActors()

    return true
end

function Sexbound:handlePrevVariantLegswear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("legswear")

    self:resetAllActors()

    return true
end

-- [Helper] Handles received message to show/hide an actor's headwear.
-- @param args A Lua table where actorId is defined.
function Sexbound:handleToggleHeadwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    local headwearConfig = actor:getConfig().headwear or {}
    if headwearConfig.isLocked == true then
        return nil
    end

    actor:getApparel():toggleIsVisible("headwear")

    self:resetAllActors()

    return actor:getApparel():getIsVisible("headwear")
end

-- [Helper] Handles received message to show/hide an actor's legswear.
-- @param args A Lua table where actorId is defined.
function Sexbound:handleToggleLegswear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    local legswearConfig = actor:getConfig().legswear or {}
    if legswearConfig.isLocked == true then
        return nil
    end

    actor:getApparel():toggleIsVisible("legswear")

    self:resetAllActors()

    return actor:getApparel():getIsVisible("legswear")
end

function Sexbound:startSexMusicForEntity(entityId)
    if self._config.noMusic then return end
    local songList = self._config.sex.sexMusicPool or {}
    local song = util.randomChoice(songList)
    world.sendEntityMessage(entityId, "playAltMusic", {song}, 1)
end

function Sexbound:stopSexMusicForEntity(entityId)
    if self._config.noMusic then return end
    world.sendEntityMessage(entityId, "playAltMusic", {""}, 1) --Try to play a different, non existent song to reset progress of current song
    world.sendEntityMessage(entityId, "stopAltMusic", 1)
end

-- Getters / Setters

--- Returns a reference to this instance's ordered actors table.
function Sexbound:getActors()
    return self._actorsOrdered
end

--- Returns a reference to this instance's actors table.
function Sexbound:getActorsOriginal()
    return self._actors
end

--- Sets this instance's actors table to a specified table.
-- @param newActors
function Sexbound:setActors(newActors)
    self._actors = newActors
end

--- Returns the current count of actors in the actors table.
function Sexbound:getActorCount()
    return #self._actors
end

--- Returns that current animation rate for this object's animator.
function Sexbound:getAnimationRate()
    return self._animationRate
end

--- Sets the animation rate for this object's animator.
-- @param newRate
function Sexbound:setAnimationRate(newRate)
    self._animationRate = newRate
end

--- Returns a reference to this instance's running configuration.
function Sexbound:getConfig()
    return self._config
end

--- Returns the name of the mod that created this instance of Sexbound.
function Sexbound:getModName()
    if self._config.modName then
        return self._config.modName
    end

    if object then
        return object.name()
    end

    return "undefined"
end

-- Returns a reference to the current version.
function Sexbound:getVersion()
    return self:getConfig().version
end

function Sexbound:getAnimationPartsCentered()
    return self._config.animationPartsCentered
end

--- Returns this object's entityId.
function Sexbound:getEntityId()
    return self._entityId or entity.id()
end

--- Returns this object's entityType.
function Sexbound:getEntityType()
    return self._entityType
end

--- Returns the facing direction of this entity.
function Sexbound:getFacingDirection()
    return self._facingDirection
end

--- Returns a reference to the current default langauge.
function Sexbound:getLanguage()
    return self:getConfig().sex.defaultLanguage
end

--- Returns a reference to the current language settings.
function Sexbound:getLanguageSettings()
    return self:getConfig().sex.supportedLanguages[self:getLanguage()]
end

--- Returns a reference to this instance's log utility.
function Sexbound:getLog()
    return self._log
end

--- Returns this instance's entity name.
function Sexbound:getEntityName()
    return world.entityName(self:getEntityId())
end

--- Returns the web url of the mod running this instance.
function Sexbound:getModLink()
    return self:getConfig().modLink
end

--- [Legacy] Returns this instance's entity name.
function Sexbound:getName()
    return world.entityName(self:getEntityId())
end

--- Returns a reference to this instance's nodes table.
function Sexbound:getNodes()
    return self._nodes
end

--- Sets this instance's nodes table to a specified table.
-- @param newNodes
function Sexbound:setNodes(newNodes)
    self._nodes = newNodes
end

--- Returns the current count of nodes in the nodes table.
function Sexbound:getNodeCount()
    return #self._nodes
end

--- Returns a reference to this instance's Positions component.
function Sexbound:getPositions()
    return self._positions
end

--- Returns a reference to this instance's PromiseKeeper.
function Sexbound:getPromises()
    return self._promises
end

--- Returns this required version for the mod running this instance.
function Sexbound:getRequiredVersion()
    return self:getConfig().requiredVersion
end

--- Returns a reference to this instance's State Machine component.
function Sexbound:getStateMachine()
    return self._stateMachine
end

--- Returns the storage of the entity running this instance
function Sexbound:getStorage()
    return storage
end

--- Returns a reference to UI
function Sexbound:getUI()
    return self._UI
end

--- Returns the store UUID
function Sexbound:getUniqueId()
    return storage.uniqueId
end

--- Returns the maximum allowed actors for this object
function Sexbound:getMaxActors()
    return self._maxAllowedActors
end

--- Returns if the node currently contains a player actor
function Sexbound:getContainsPlayer()
    return self._containsPlayer
end



--- DEBUG ---
function Sexbound:startClock()
    self._doClock = true
    self._lastClockState = "none"
    self:tickClock()
end
function Sexbound:stopClock()
    self._doClock = false
    self._lastClockState = "none"
end
function Sexbound:tickClock()
    local curState = animator.animationState("clock") or "none"
    if curState ~= self._lastClockState then
        self._lastClockState = curState
        --animator.playSound("ping")
    end
end
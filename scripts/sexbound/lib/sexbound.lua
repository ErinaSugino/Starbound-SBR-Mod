--- @alias PromiseKeeper table

--- Sexbound Class Module.
--- @class Sexbound
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _maxAllowedActors integer,
--- @field _actors table<integer, Sexbound.Actor>,
--- @field _actorsOrdered table<integer, Sexbound.Actor>,
--- @field _currentOrderIndex integer,
--- @field _currentOrderId string,
--- @field _animationRate number,
--- @field _entityId EntityId,
--- @field _entityType string,
--- @field _promises PromiseKeeper,
--- @field _timers table,
--- @field _globalActorId integer,
--- @field _uiSyncTokens table<string, integer>,
--- @field _containsPlayer boolean,
--- @field _sexMusicListeners table,
--- @field _config table
--- @field _log Sexbound.Log
--- @field _compatibility Sexbound.Compatibility
--- @field _adjustActorsPositionController Sexbound.AdjustActorsPositionController
--- @field _adjustActorsRotationController Sexbound.AdjustActorsRotationController
--- @field _adjustActorsScaleController Sexbound.AdjustActorsScaleController
--- @field _positions Sexbound.Positions
--- @field _stateMachine Sexbound.StateMachine
--- @field _sextalk Sexbound.Sextalk
--- @field _UI Sexbound.UI
--- @field _overrideMinTempo integer
--- @field _overrideMaxTempo integer
--- @field _overrideSustainedInterval integer
--- @field _overrideClimaxAnimation ?boolean
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
    require("/scripts/sexbound/lib/sexbound/object/SmashObjectController.lua")
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsPositionController.lua")
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsRotationController.lua")
    require("/scripts/sexbound/lib/sexbound/transformations/AdjustActorsScaleController.lua")
    require("/scripts/sexbound/lib/sexbound/node.lua")
    require("/scripts/sexbound/lib/sexbound/positions.lua")
    require("/scripts/sexbound/lib/sexbound/statemachine.lua")
    require("/scripts/sexbound/lib/sexbound/ui.lua")
    require("/scripts/sexbound/lib/sexbound/sextalk.lua")
end

--- Returns a reference to a new instance of Sexbound.
--- @param maxActors number The amount of available actor slots in this instance. Ideally the same as the object's seats.
--- @return Sexbound # The Sexbound instance
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
        _containsPlayer = false,
        _sexMusicListeners = {},
        _config = {}
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

    -- Initialize new instance of the global sextalk manager
    self._sextalk = Sexbound.Sextalk.new(self)

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

    self:loadSubscripts()

    self:getLog():debug("Initing Sexbound instance "..entity.id())

    return self
end

--- [Helper] Initializes message handlers.
--- @private
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

    message.setHandler("Sexbound:Retrieve:NodeCompatibility", function(_, _, args)
        return self:checkNodeCompatibility(args)
    end)

    message.setHandler("Sexbound:Retrieve:IsFull", function(_, _, args)
        return self:isFullyOccupied()
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

--- Function to require additional subscripts to override prototypes post-setup from config
function Sexbound:loadSubscripts()
    local _override = self._config.override["actor"] or {}

    util.each(_override.scripts, function(_, _script)
        require(_script)
    end)
end

--- [Helper] Initializes the Facing Direction of this instance
--- @private
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

    self:forceStopSexMusic() --Stop sex music for all still listening actors

    return result1 and result2
end

--- Updates this instance.
--- @param dt number The delta time
function Sexbound:update(dt)
    self:getPromises():update()

    if self._compatibility:isCompatible() then
        self:getStateMachine():update(dt)
        self:getSextalk():update(dt)

        Sexbound.Messenger.get("main"):dispatch()

        self:forEachNode(function(index, node)
            node:update(dt)
        end)
    end
end

--- Handles interally received message.
--- @param message table A Message
function Sexbound:onMessage(message) end --[[ Currently not handling any internal messages for this class. --]]

--- Adds a new instance of Actor to the actors table.
--- @param actorConfig table The full setup configuration of this actor
--- @param store boolean? Whethere or not to store this actor's config in the global storage
--- @return boolean # Whethere or not actor was successfully added
function Sexbound:addActor(actorConfig, store)
    -- Return false when adding another actor would exceed the max allowed actors for current position
    if #self._actors >= self._maxAllowedActors then
        return false
    end

    self._globalActorId = self._globalActorId + 1 -- Loc, an ID should be universally unique, and not redundant crap.

    -- Try to retain current role composition by just adding new actor last
    local newMax = #self._actors + 1
    self._currentOrderId = self._currentOrderId..newMax

    local actor = Sexbound.Actor:new(self, actorConfig, self._globalActorId, newMax)

    if store then
        storage.actor = actor:getConfig()
    end

    self:getLog():info("Adding Actor: " .. actor:getName())

    -- Insert new actor into actors table
    table.insert(self._actors, actor)
    table.insert(self._actorsOrdered, actor)
    self:getLog():debug("Actor added to list. Length now: "..#self._actors)

    if actor:getEntityType() == "player" then self._containsPlayer = true end

    self._positions:filterPositions(self._actors)

    self._UI:refresh()
    actor:openUI()

    -- Resort actors based on changed environment
    self:helper_reassignAllRoles()

    if self._config.position.forceJoin then
        self._positions:switchPosition(self._config.position.forceJoin)
    -- If we only have NPCs, try to initiate sex (switch from idle to a random available position)
    elseif not self._containsPlayer and self._config.sex.npcStartSex then
        self._positions:switchRandomSexPosition(true)
    end

    -- Reset all actors to refresh their appearances
    self:resetAllActors()

    -- Broadcast message "Sexbound:AddActor" to all receivers immediately
    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:AddActor", {}, true)

    return true
end

--- Removes an actor from the actors table when it has a matching entityId
--- @param entityId EntityId The entity ID of the entity whose actor is to be removed by reference
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
    if not self._actors[1] then return true end -- No need to uninit anything if noone was here to begin with. Reduces log spam.

    self:getLog():info("Uniniting Actors.")

    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:PrepareRemoveActor", {}, true)

    self:forEachActor(function(index, actor)
        actor:resetGlobalAnimatorTags()

        actor:resetTransformations()

        actor:uninit()
    end)

    self._actors = {}
    self._actorsOrdered = {}

    self._positions:filterPositions(self._actorsOrdered) --Reset positions as this bypasses normal "actor leaves" check and we need to be in idle for when someone else joins
    self._currentOrderId = ""
    self._currentOrderIndex = 1

    return true
end

--- Adds a new instance of Node to the nodes table.
--- @param tilePosition Vec2F X and Y coordinate offset for the tile to be spawned
--- @param sitPosition Vec2F X and Y coordinate offset for the seat offset to apply to the spawned node
--- @param params table? Setup parameters for the node
function Sexbound:addNode(tilePosition, sitPosition, params)
    local newNode = Sexbound.Node.new(self, tilePosition, sitPosition, true)
    table.insert(self._nodes, newNode)
    newNode:create(params)
end

--- Adds a new instance of Node to the nodes table and tracks it as being this object.
--- @param sitPosition Vec2F X and Y coordinate offset for the seat position to apply to this object as node
function Sexbound:becomeNode(sitPosition)
    table.insert(self._nodes, Sexbound.Node.new(self, {0, 0}, sitPosition, false))

    --If we become a node ourselves, try to insert controller ID retrieval function for behavior script.
    if not _ENV["returnControllerId"] then _ENV["returnControllerId"] = function() return entity.id() end end
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
--- @param entityId EntityId A valid entity ID
--- @param backwearConfig table A table of backwear config
function Sexbound:changeBackwear(entityId, backwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("backwear", backwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Chestwear of the actor with the specified entity ID.
--- @param entityId EntityId A valid entity ID
--- @param chestwearConfig table A table of chestwear config
function Sexbound:changeChestwear(entityId, chestwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("chestwear", chestwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Groinwear of the actor with the specified entity ID.
--- @param entityId EntityId A valid entity ID
--- @param groinwearConfig table A table of groinwear config
function Sexbound:changeGroinwear(entityId, groinwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("groinwear", groinwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Headwear of the actor with the specified entity ID.
--- @param entityId EntityId A valid entity ID
--- @param headwearConfig table A table of headwear config
function Sexbound:changeHeadwear(entityId, headwearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("headwear", headwearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Legswear of the actor with the specified entity ID.
--- @param entityId EntityId A valid entity ID
--- @param legswearConfig table A table of legswear config
function Sexbound:changeLegswear(entityId, legswearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("legswear", legswearConfig)
        end
    end)

    self:resetAllActors()
end

--- Changes the Nippleswear of the actor with the specified entity ID.
--- @param entityId EntityId A valid entity ID
--- @param nippleswearConfig table A table of nippleswear config
function Sexbound:changeNippleswear(entityId, nippleswearConfig)
    self:forEachActor(function(index, actor)
        if entityId == actor:getEntityId() then
            actor:getApparel():setItemConfig("nippleswear", nippleswearConfig)
        end
    end)

    self:resetAllActors()
end

--- Executes a callback for each actor in sorted actor number order.
--- @param callback function<integer, Sexbound.Actor> A function to execute on each actor, given index in list and actor instance
function Sexbound:forEachActor(callback)
    for index, actor in ipairs(self._actorsOrdered) do
        callback(index, actor)
    end
end

--- Executes a callback for each actor in original join order.
--- @param callback function<integer, Sexbound.Actor> A function to execute on each actor, given index in list and actor instance
function Sexbound:forEachOriginalActor(callback)
    for index,actor in ipairs(self._actors) do
        callback(index, actor)
    end
end

--- Executes a callback for each node.
--- @param callback function<integer, Sexbound.Node> A function to execute on each node, given index in list and node instance
function Sexbound:forEachNode(callback)
    for index, node in ipairs(self._nodes) do
        callback(index, node)
    end
end

--- Handles a player interaction request.
--- @param args table Interact arguments
function Sexbound:handleInteract(args)
    if not self._compatibility:isCompatible() then
        self._compatibility:incompatibleVersion()
        return
    end

    -- Lounge-in next available node.
    for _, node in ipairs(self._nodes) do
        if not node:occupied() then
            node:lounge(args.sourceId)
        end
    end
end

--- [Helper] Returns a table that consists of settings to use to spawn an NPC.
--- @protected
--- @param actor table Actor configuration represented as a Lua table
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

--- [Helper] Returns Actor ID and a reference to an Actor. Prepares an actor with matching specified entity ID to be removed.
--- @protected
--- @param entityId EntityId A valid entity ID
--- @return integer # Actor index in original sorting
--- @return integer # Actor index in ordered sorting
--- @return Sexbound.Actor # The actor instance
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

--- [Helper] Swaps the slots of all currently loaded actors.
function Sexbound:helper_reassignAllRoles()
    if #self._actors == 0 then return end
    local sexConfig = self:getConfig().sex or {}

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
--- @protected
--- @param actor Sexbound.Actor The actor to force
--- @param currentRole integer Current actor role number
function Sexbound:helper_forceActorRole(actor, currentRole)
    local forceRole = actor:getForceRole()

    if forceRole > #self._actors then
        return
    end

    Sexbound.Util.swap(self._actors, currentRole, forceRole)

    self:resetAllActors()
end

--- Loads and returns the global configuration.
--- @return table # The loaded config JSON
function Sexbound:loadConfig()
    local _, _config = xpcall(function()
        return util.mergeTable(root.assetJson("/sexbound.config"), config.getParameter("sexboundConfig", {}))
    end, function(error)
        self:getLog():error("Unable to load global sexbound config file!")
    end)

    return _config
end

--- Resets all instances of Actor in the actors table.
--- @param stateName ?string The name of the animation state to reset the actors to
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

--- Apply a scale factor to all actors from the current position
function Sexbound:applyConstantScaleToActors()
    local constantScale = self:getPositions():getCurrentPosition():getConstantScale()
    if constantScale ~= nil then
        self._adjustActorsScaleController:adjustActorsScale(constantScale)
    end
end

--- Mirror all actors horizontally
function Sexbound:mirrorActorsHorizonally()
    self._adjustActorsScaleController:adjustActorsScale({-1, 1})
end

--- Respawns the stored actor if it exists in this object's storage.
function Sexbound:respawnStoredActor()
    if self._config.position.noSync then return end

    local actor = storage.actor

    if actor and actor.uniqueId then
        world.sendEntityMessage(actor.uniqueId, "Sexbound:Actor:Respawn", actor.storage)
    end
end

--- Arranges actor roles based on the next or previous combination in the list
--- @param direction integer
--- |"1" # Shift to the right (next combination)
--- |"-1" # Shift to the left (previous combination)
--- @return boolean # Whethere or not the combination was actually changed
function Sexbound:switchActorRoles(direction)
    if not self:getStateMachine():isClimaxing() then
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

--- [Hidden] Updates the animation rate of the animator based on the delta time.
--- @param stateName string The name of the current animation state to update speed of
--- @param dt number The delta time since last tick
function Sexbound:updateAnimationRate(stateName, dt)
    local _animState = self:getPositions():getCurrentPosition():getAnimationState(stateName)
    if _animState == nil then return end

    local _minTempo = self._overrideMinTempo or _animState:getMinTempo()
    local _maxTempo = self._overrideMaxTempo or _animState:getMaxTempo()
    local _sustainedInterval = self._overrideSustainedInterval or _animState:getSustainedInterval()

    self._animationRate =
        util.clamp(self._animationRate + (_maxTempo / (_sustainedInterval / dt)), _minTempo, _maxTempo)

    -- Set the animator's animation rate
    animator.setAnimationRate(self._animationRate)

    if (self._animationRate >= _maxTempo) then
        self._animationRate = _animState:nextMinTempo()

        _animState:nextMaxTempo()

        _animState:nextSustainedInterval()
    end
end

--- Function to trigger an update for a sync token
--- @param tokenName string The name of token category to increment
function Sexbound:tickToken(tokenName)
    local val = self._uiSyncTokens[tokenName] or 0
    val = val + 1
    self._uiSyncTokens[tokenName] = val
end

-- [[ Handlers ]]

--- [Helper] Handles received message to change an actor's backwear.
--- @param args table Arguments table where entityId is defined.
--- @protected
function Sexbound:handleChangeBackwear(args)
    self:changeBackwear(args.entityId, args.backwear)
end

--- [Helper] Handles received message to change an actor's chestwear.
--- @param args table Arguments table where entityId is defined.
--- @protected
function Sexbound:handleChangeChestwear(args)
    self:changeChestwear(args.entityId, args.chestwear)
end

--- [Helper] Handles received message to change an actor's groinwear.
--- @param args table Arguments table where entityId is defined.
--- @protected
function Sexbound:handleChangeGroinwear(args)
    self:changeGroinwear(args.entityId, args.groinwear)
end

--- [Helper] Handles received message to change an actor's headwear.
--- @param args table Arguments table where entityId is defined.
--- @protected
function Sexbound:handleChangeHeadwear(args)
    self:changeHeadwear(args.entityId, args.headwear)
end

--- [Helper] Handles received message to change an actor's legswear.
--- @param args table Arguments table where entityId is defined.
--- @protected
function Sexbound:handleChangeLegswear(args)
    self:changeLegswear(args.entityId, args.legswear)
end

--- [Helper] Handles received message to change an actor's Nippleswear.
--- @param args table Arguments table where entityId is defined.
--- @protected
function Sexbound:handleChangeNippleswear(args)
    self:changeNippleswear(args.entityId, args.nippleswear)
end

--- [Helper] Handles received message to command an actor to begin climaxing.
--- @protected
--- @param args table Arguments table where actorId is defined.
--- @return boolean # Whethere or not climax was triggered
function Sexbound:handleClimax(args)
    if self:getStateMachine():isHavingSex() then
        Sexbound.Messenger.get("main"):send(self, self._actorsOrdered[args.actorId], "Sexbound:Climax:BeginClimax", {})
        return true
    end

    return false
end

--- [Helper] Handles retrieving the controller ID.
--- @protected
--- @return EntityId # The instance's entity ID
function Sexbound:handleRetrieveControllerId(_)
    return self:getEntityId()
end

--- [Helper] Handles retrieving the UI Config.
--- @protected
--- @return table # UI configuration JSON for script pane
function Sexbound:handleRetrieveUIConfig(_)
    return self._UI:getConfig()
end

--- [Helper] Handles received message to command all actors to begin scripted climax.
--- @protected
--- @return boolean # True only, for some reason
function Sexbound:handleScriptedClimax(_)
    self:forEachActor(function(_, actor)
        Sexbound.Messenger.get("main"):send(self, actor, "Sexbound:Climax:BeginScriptedClimax", {})
    end)

    return true
end

--- [Helper] Handles received message to finish initializing a sex node.
--- @param args table Arguments table where entityId and uniqueId are defined.
--- @protected
function Sexbound:handleNodeInit(args)
    for _, node in ipairs(self:getNodes()) do
        if node:getUniqueId() == args.uniqueId then
            node:setEntityId(args.entityId)
        end
    end
end

--- [Helper] Handles received message to finish uninitializing a sex node.
--- @param args table Arguments table where uniqueId is defined.
--- @protected
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

--- [Helper] Handles received message to remove an actor.
--- @param entityId EntityId A valid entity ID
--- @protected
function Sexbound:handleRemoveActor(entityId)
    self:removeActor(entityId)
end

--- [Helper] Handles received message to setup a new actor.
--- @protected
--- @param args table Actor setup config
--- @return boolean # Whethere or not actor was successfully added
function Sexbound:handleSetupActor(args)
    return self:addActor(args, false)
end

--- [Helper] Handles received message to setup and store a new actor.
--- @protected
--- @param args table Actor setup config
--- @return boolean # Whethere or not actor was successfully added
function Sexbound:handleStoreActor(args)
    return self:addActor(args, true)
end

--- [Helper] Handles received message to switch the roles of all actors.
--- @protected
--- @param args table Arguments table containing "val", 1 or -1 to determine what direction to swap actor combination in
--- @return boolean # Whethere or not the roles were successfully switched
function Sexbound:handleSwitchRole(args)
    local config = self:getConfig()
    if config.allowSwitchRoles ~= nil then
        config.sex.allowSwitchRoles = config.allowSwitchRoles
    end

    if self:getConfig().sex.allowSwitchRoles ~= true then
        return false
    end
    
    local direction = args.val or 1
    return self:switchActorRoles(direction)
end

--- [Legacy] Get the vanilla gender of an actor
--- @param actor Sexbound.Actor The actor to check
--- @return string # "male" or "female" to represent the vanilla gender of the actor
function Sexbound:getBodyType(actor)
    return actor:getIdentity().sxbBodyType or self:buildBodyType(actor)
end

--- [Legacy] Get the genital gender of an actor
--- @param actor Sexbound.Actor The actor to check
--- @return string # "male" or "female" to represent the genital gender of the actor
function Sexbound:getGenitalType(actor)
    return actor:getIdentity().sxbGenitalType or self:buildGenitalType(actor)
end

--- [Legacy] Map an actor's sexbound subgender to a vanilla gender body type
--- @param actor Sexbound.Actor The actor to check
--- @return string "male" or "female"
function Sexbound:buildBodyType(actor)
    local gender = actor:getSubGender() or actor:getGender()
    if gender == "female" or gender == "futanari" then
        return "female"
    else
        return "male"
    end
end

--- [Legacy] Map an actor's sexbound subgender to a vanilla gender's expected genital type
--- @param actor Sexbound.Actor The actor to check
--- @return string # "male" for show penis sprite, "female" for not
function Sexbound:buildGenitalType(actor)
    local gender = actor:getSubGender() or actor:getGender()
    if gender == "male" or gender == "futanari" then
        return "male"
    else
        return "female"
    end
end

--- [Helper] Handles received message to sync with the default UI overlay.
--- @protected
--- @param args table Arguments table containing "tokens", a table listing all last known sync token values as token = number pairs
--- @return table # The newly synced data for all modules that changed, new update tokens, animation rate and actor sorting
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

    self:forEachActor(function(index, actor) table.insert(data.actors, actor:getUIData(args)) end)

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

--- [Helper] Handles received message to show/hide an actor's backwear.
--- @protected
--- @param args table Arguments table where actorId is defined.
--- @return boolean|nil # nil if the slot is locked and whethere toggling was successful otherwise
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

--- [Helper] Handles received message to show/hide an actor's chestwear.
--- @protected
--- @param args table Arguments table where actorId is defined.
--- @return boolean|nil # nil if the slot is locked and whethere toggling was successful otherwise
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

--- [Helper] Handle received message to switch to the next variant of an actor's backwear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handleNextVariantBackwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("backwear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the previous variant of an actor's backwear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handlePrevVariantBackwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("backwear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the next variant of an actor's chestwear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handleNextVariantChestwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("chestwear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the previous variant of an actor's chestwear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handlePrevVariantChestwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("chestwear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the next variant of an actor's headwear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handleNextVariantHeadwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("headwear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the previous variant of an actor's headwear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handlePrevVariantHeadwear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("headwear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the next variant of an actor's legswear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handleNextVariantLegswear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoNextVariantForApparelItem("legswear")

    self:resetAllActors()

    return true
end

--- [Helper] Handle received message to switch to the previous variant of an actor's legswear, if any
--- @protected
--- @param args table Arguments table where actorId is defined
--- @return boolean # Whethere or not switching was successful
function Sexbound:handlePrevVariantLegswear(args)
    local actor = self._actorsOrdered[args.actorId]
    if not actor then
        return false
    end

    actor:getApparel():gotoPrevVariantForApparelItem("legswear")

    self:resetAllActors()

    return true
end

--- [Helper] Handles received message to show/hide an actor's headwear.
--- @protected
--- @param args table Arguments table where actorId is defined.
--- @return boolean|nil # nil if the slot is locked and whethere toggling was successful otherwise
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

--- [Helper] Handles received message to show/hide an actor's legswear.
--- @protected
--- @param args table Arguments table where actorId is defined.
--- @return boolean|nil # nil if the slot is locked and whethere toggling was successful otherwise
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

--- [Helper] Send entity message to start sex music for a given entity
--- @protected
--- @param entityId EntityId The ID of the entity
function Sexbound:startSexMusicForEntity(entityId)
    if self._config.noMusic then return end
    local songList = self._config.sex.sexMusicPool or {}
    local song = util.randomChoice(songList)
    world.sendEntityMessage(entityId, "playAltMusic", {song}, 1)

    -- Cache who is currently listening, but only once, so we can forcibly end the music on uninit
    for _,id in ipairs(self._sexMusicListeners) do
        if id == entityId then return end
    end

    table.insert(self._sexMusicListeners, entityId)
end

--- [Helper] Send an entity message to stop sex music for a given entity
--- @protected
--- @param entityId EntityId The ID of the entity
function Sexbound:stopSexMusicForEntity(entityId)
    if self._config.noMusic then return end
    world.sendEntityMessage(entityId, "playAltMusic", {""}, 1) --Try to play a different, non existent song to reset progress of current song
    world.sendEntityMessage(entityId, "stopAltMusic", 1)
    
    -- Remove from cache
    for i,id in ipairs(self._sexMusicListeners) do
        if id == entityId then table.remove(self._sexMusicListeners, i) return end
    end
end

--- Send an entity message to stop sex music to all known entities
function Sexbound:forceStopSexMusic()
    if self._config.noMusic then return end
    for _,id in ipairs(self._sexMusicListeners) do
        world.sendEntityMessage(id, "playAltMusic", {""}, 1) --Try to play a different, non existent song to reset progress of current song
        world.sendEntityMessage(id, "stopAltMusic", 1)
    end
end

--- Get a node compatibility score for the data of a given requesting NPC against all actors in the node
--- @param args table The NPCs node compatibility data
--- @return number # A priority score. Higher number means higher priority for this node. Negative score means node is to be ignored
function Sexbound:checkNodeCompatibility(args)
    if self._config.position.noCompatibility then return 0 end --If the "noCompatibility" flag is set (like on the birthing node for players), always return 0 to disable NPCs from targeting this.

    local motherUuid = args.motherUuid or nil
    local fatherUuid = args.fatherUuid or nil
    local otherUuid = args.uuid or nil
    local multiplier = self._config.behaviour or {}
    multiplier = multiplier.multiplier or {
        incest=-1,
        twoactor=1,
        gender=1,
        compatible=1
    }
    local allowIncest = (self._config.behaviour or {}).allowIncest
    local compatibility = 10

    if #self._actors == 1 then compatibility = compatibility + multiplier.twoactor end

    local genderBonus = 0
    local compatibleBonus = 0
    for i,a in ipairs(self._actors) do
        -- Check for incest level first because it can be an abortion criterium
        local identity = a:getIdentity() --[[@as table<string,any>]]
        local uuid = a._config.uniqueId
        local incestLevel = -1
        if motherUuid ~= nil or fatherUuid ~= nil then
            if (identity.motherUuid == nil and identity.fatherUuid == nil) or (motherUuid == nil and fatherUuid == nil) then incestLevel = 0 end -- Orphan, can't have (known) incest
            if identity.motherUuid == otherUuid or identity.fatherUuid == otherUuid or motherUuid == uuid or fatherUuid == uuid then incestLevel = 3 end -- Level 3 incest - sex with your parent
            if incestLevel == -1 then
                local thisPair = {identity.motherUuid, identity.fatherUuid}
                local thatPair = {motherUuid, fatherUuid}
                local matches = 0
                for _,v1 in ipairs(thisPair) do
                    for _,v2 in ipairs(thatPair) do
                        if v1==v2 then matches = matches + 1 break end
                    end
                end

                -- Number of matches between this actor's parents and given actor's parents
                -- 1 match = level 1 incest - Sex with half-sibling
                -- 2 matches = level 2 incest - Sex with full-sibling
                incestLevel = matches
            end
        else incestLevel = 0 end

        if incestLevel > 0 and not allowIncest then return 0 end -- Abort if unallowed incest

        compatibility = compatibility + (incestLevel * multiplier.incest)

        local bodyTraits = a._config.identity.body
        if args.bodyTraits then
            if (args.bodyTraits.hasPenis and bodyTraits.hasVagina) or (args.bodyTraits.hasVagina and bodyTraits.hasPenis) then genderBonus = 1 end
        end

        if genderBonus then compatibility = compatibility + multiplier.gender end

        local pregnancy = a:getPlugins("pregnant")
        if args.species and pregnancy and compatibleBonus == 0 then
            -- Check if conditions immediately bypass this check
            if pregnancy._config.enableFreeForAll == true or pregnancy._config.enableCompatibleSpeciesOnly == false or a:getSpecies() == args.species then
                compatibleBonus = 1
            else
                -- Check if species types are compatible
                if args.speciesType then
                    local thisSpeciesType, thatSpeciesType = a:getIdentity("sxbSpeciesType"), args.speciesType
                    if thisSpeciesType == "universal" or thatSpeciesType == "universal" or (thisSpeciesType == thatSpeciesType and thisSpeciesType ~= nil) then compatibleBonus = 1 end -- "nil" (aka. not set) is treated as universal incompatibility, so nil x nil == incompatible
                end

                local speciesList
                local ownSpecies
                if compatibleBonus == 0 then
                    -- Alternatively check if whitelist exists for species - present actors on this NPC
                    speciesList = pregnancy._config.compatibleSpecies[args.species]
                    if speciesList == "all" then compatibleBonus = 1
                    else
                        ownSpecies = a:getSpecies()
                        for _, species in ipairs(speciesList or {}) do
                            if ownSpecies == species then
                                compatibleBonus = 1
                                break
                            end
                        end
                    end
                end

                if compatibleBonus == 0 then
                    -- Alternatively check if whitelist exists for species - this NPC on present actors
                    speciesList = pregnancy._config.compatibleSpecies[a:getSpecies()]
                    if speciesList == "all" then compatibleBonus = 1
                    else
                        ownSpecies = args.species
                        for _, species in ipairs(speciesList or {}) do
                            if ownSpecies == species then
                                compatibleBonus = 1
                                break
                            end
                        end
                    end
                end
            end
        end

        if compatibleBonus then compatibility = compatibility + multiplier.compatible end
    end

    return compatibility
end

-- [[ Getters / Setters ]]

--- Returns a reference to this instance's ordered actors table.
--- @return table<integer, Sexbound.Actor> # The ordered actors list
function Sexbound:getActors()
    return self._actorsOrdered
end

--- Returns a reference to this instance's actors table.
--- @return table<integer, Sexbound.Actor> # The original actors list
function Sexbound:getActorsOriginal()
    return self._actors
end

--- Sets this instance's actors table to a specified table.
--- @param newActors table<integer, Sexbound.Actor> The new actors list
function Sexbound:setActors(newActors)
    self._actors = newActors
end

--- Returns the current count of actors in the actors table.
--- @return integer # Number of actors currently in the sexnode
function Sexbound:getActorCount()
    return #self._actors
end

--- Returns that current animation rate for this object's animator.
--- @return number # The current animation rate
function Sexbound:getAnimationRate()
    return self._animationRate
end

--- Sets the animation rate for this object's animator.
--- @param newRate number The new animation rate to set
function Sexbound:setAnimationRate(newRate)
    self._animationRate = newRate
end

--- Returns a reference to this instance's running configuration.
--- @return table # The config table
function Sexbound:getConfig()
    return self._config
end

--- Returns the name of the mod that created this instance of Sexbound.
--- @return string # The name of the sexbound addon if known, or the object's name otherwise
function Sexbound:getModName()
    if self._config.modName then
        return self._config.modName
    end

    if object then
        return object.name()
    end

    return "undefined"
end

--- Returns a reference to the current version.
--- @return string # The current sexbound version number
function Sexbound:getVersion()
    return self:getConfig().version
end

--- Returns the centered animation parts
--- @return table|nil # Actually, I don't know
function Sexbound:getAnimationPartsCentered()
    return self._config.animationPartsCentered
end

--- Returns this object's entityId.
--- @return EntityId # The object's entity ID
function Sexbound:getEntityId()
    return self._entityId or entity.id()
end

--- Returns this object's entityType.
--- @return string # The object's entity type
function Sexbound:getEntityType()
    return self._entityType
end

--- Returns the facing direction of this entity.
--- @return integer # 1 for right or -1 for left
function Sexbound:getFacingDirection()
    return self._facingDirection
end

--- Returns a reference to the current default langauge.
--- @return string # The name of the currently loaded sextalk language
function Sexbound:getLanguage()
    return self:getConfig().sex.defaultLanguage or "english"
end

--- Returns the language code of the currently selected language.
--- @return string # The code of the currently loaded sextalk language
function Sexbound:getLanguageCode()
    return (self:getLanguageSettings() or {}).languageCode or "en"
end

--- Returns a reference to the current language settings.
--- @return table # Data for the current language
function Sexbound:getLanguageSettings()
    return self:getConfig().sex.supportedLanguages[self:getLanguage()]
end

--- Returns a reference to this instance's log utility.
--- @return Sexbound.Log # The instance logger
function Sexbound:getLog()
    return self._log
end

--- Returns this instance's entity name.
--- @return string # The name, if any, of the current node object
function Sexbound:getEntityName()
    return world.entityName(self:getEntityId())
end

--- Returns the web url of the mod running this instance.
--- @return string # The URL to the mod download
function Sexbound:getModLink()
    return self:getConfig().modLink
end

--- [Legacy] Returns this instance's entity name.
--- @return string # The name, if any, of the current node object
function Sexbound:getName()
    return self:getEntityName()
end

--- Returns a reference to this instance's nodes table.
--- @return table<integer, Sexbound.Node> # The list of seat nodes
function Sexbound:getNodes()
    return self._nodes
end

--- Sets this instance's nodes table to a specified table.
--- @param newNodes table<integer, Sexbound.Node> The new list of nodes
function Sexbound:setNodes(newNodes)
    self._nodes = newNodes
end

--- Returns the current count of nodes in the nodes table.
--- @return integer # The number of seat nodes loaded
function Sexbound:getNodeCount()
    return #self._nodes
end

--- Returns a reference to this instance's Positions component.
--- @return Sexbound.Positions # The positions manager
function Sexbound:getPositions()
    return self._positions
end

--- Returns a reference to this instance's PromiseKeeper.
--- @return PromiseKeeper # The promise manager
function Sexbound:getPromises()
    return self._promises
end

--- Returns this required version for the mod running this instance.
--- @return string|nil # The version code this addon has defined as minimum compatibility requirement, if any
function Sexbound:getRequiredVersion()
    return self:getConfig().requiredVersion
end

--- Returns a reference to this instance's State Machine component.
--- @return Sexbound.StateMachine # The instance's state machine
function Sexbound:getStateMachine()
    return self._stateMachine
end

--- Returns the storage of the entity running this instance
--- @return table # The instance's persistent storage
function Sexbound:getStorage()
    return storage
end

--- Returns a reference to UI
--- @return Sexbound.UI # The instance's UI manager
function Sexbound:getUI()
    return self._UI
end

--- Returns the stored UUID
--- @return string # The unique entity ID of this object
function Sexbound:getUniqueId()
    return storage.uniqueId
end

--- Returns the maximum allowed actors for this object
--- @return integer # The maximum number of allowed actors
function Sexbound:getMaxActors()
    return self._maxAllowedActors
end

--- Returns if the node currently contains a player actor
--- @return boolean # Whethere or not the sexnode currently tracks having a player actors
function Sexbound:getContainsPlayer()
    return self._containsPlayer
end

--- Returns a reference to this instance's sextalk manager
--- @return Sexbound.Sextalk # The instance's sextalk coordinator
function Sexbound:getSextalk()
    return self._sextalk
end

--- Returns if this sexnode is at its defined actor cap or not
--- @return boolean # Whethere or not this sexnode has as many actors as allowed
function Sexbound:isFullyOccupied()
    return #self._actors >= self._maxAllowedActors
end


-- [[ BEHAVIOR REMOTE CALL ]]

--- API-safe handler for remote behavior calls from NPCs to get node compatibility score, if possible
--- @param args table The arguments for the node compatibility check
--- @return number # The compatibility score
function checkNodeCompatibility(args)
    if not self._sexbound then return 0 end
    return self._sexbound:checkNodeCompatibility(args)
end

--- API-safe handler for remote behavior calls from NPCs to check if the sexnode is fully occupied
--- @return boolean # Whethere or not the node is fully occupied
function isFullyOccupied(_)
    if not self._sexbound then return world.loungeableOccupied(entity.id()) end
    return self._sexbound:isFullyOccupied()
end
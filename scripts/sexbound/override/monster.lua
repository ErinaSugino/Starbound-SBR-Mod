require "/scripts/sexbound/override/common.lua"

--- Sexbound.Monster Module.
--- @class Sexbound.Monster: Sexbound.Common
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _gender integer
--- @field _subGen string?
Sexbound.Monster = Sexbound.Common:new()
Sexbound.Monster_mt = {
    __index = Sexbound.Monster
}

local SexboundErrorCounter = 0

--- Hook (init)
local Sexbound_Old_Init = init
function init()
    xpcall(function()
        Sexbound_Old_Init()

        self.sb_monster = Sexbound.Monster.new()
    end, sb.logError)
end

--- Hook (update)
local Sexbound_Old_Update = update
function update(dt)
    xpcall(function()
        Sexbound_Old_Update(dt)
    end, sb.logError)

    if SexboundErrorCounter < 5 then
        xpcall(function()
            self.sb_monster:update(dt)
        end, function(err)
            SexboundErrorCounter = SexboundErrorCounter + 1

            sb.logError(err)
        end)
    end
end

--- Creates a new monster entity handler instance
--- @return Sexbound.Monster # The newly created monster entity handler
function Sexbound.Monster.new()
    local self = setmetatable({
        _isHavingSex = false,
        _mindControl = {
            damageSourceKind = "sexbound_mind_control"
        },
        _promises = PromiseKeeper.new(),
        _states = {"defaultState", "havingSexState"}
    }, Sexbound.Monster_mt)

    if status.isResource("gender") == false then
        status.giveResource("gender", 0)
    end

    if status.resource("gender") == 0 or (status.resource("gender") > 3 or status.resource("gender") < 0) then
        math.randomseed(os.time())
        status.giveResource("gender", (math.random(1, 2)))
    end

    self._gender = status.resource("gender") or 1

    self:init(self, "monster")

    self:initMessageHandlers()

    self:restorePreviousStorage()

    self._status = Sexbound.Monster.Status:new(self)
    self._arousal = Sexbound.Monster.Arousal:new(self)
    self._climax = Sexbound.Monster.Climax:new(self)
    self._identity = Sexbound.Monster.Identity:new(self)
    self._pregnant = Sexbound.Monster.Pregnant:new(self)
    self._statistics = Sexbound.Monster.Statistics:new(self)
    self._subGender = Sexbound.Monster.SubGender:new(self)
    self._transform = Sexbound.Monster.Transform:new(self)

    -- Check that the monster is not capturable by Red3dred
    --- @diagnostic disable-next-line: undefined-global
    if not entity.uniqueId() and not (isCapturable or capturable.ownerUuid() or storage.respawner) then
        monster.setUniqueId(sb.makeUuid())
    end

    self._stateMachine = self:helper_loadStateMachine()

    self._hasInited = true
    self:updateTraitEffects()

    return self
end

--- [Helper] Loads the stateMachine
--- @private
--- @return table # The vanilla state meachine
function Sexbound.Monster:helper_loadStateMachine()
    self._stateDefinitions = {
        defaultState = self:defineStateDefaultState(),
        havingSexState = self:defineStateHavingSexState()
    }

    return stateMachine.create(self._states, self._stateDefinitions)
end

--- Function called each tick to progress timers
--- @param dt number The delta time since last tick
function Sexbound.Monster:update(dt)
    -- Monster script doesn't have a promises handler by default
    self._promises:update()

    self:getArousal():update(dt)
end

--- Setup entity message handlers
function Sexbound.Monster:initMessageHandlers()
    message.setHandler("Sexbound:Actor:Restore", function(_, _, args)
        return self:handleRestore(args)
    end)
    message.setHandler("Sexbound:Actor:Respawn", function(_, _, args)
        return self:handleRespawn(args)
    end)
    message.setHandler("Sexbound:Actor:Say", function(_, _, args)
        return self:handleSay(args)
    end)
    message.setHandler("Sexbound:Config:Retrieve", function(_, _, args)
        return self:handleRetrieveConfig(args)
    end)
    message.setHandler("Sexbound:IdleState:Enter", function(_, _, args)
        return self:handleEnterIdleState(args)
    end)
    message.setHandler("Sexbound:SexState:Enter", function(_, _, args)
        return self:handleEnterSexState(args)
    end)
    message.setHandler("Sexbound:Storage:Retrieve", function(_, _, args)
        return self:handleRetrieveStorage(args)
    end)
    message.setHandler("Sexbound:Storage:Sync", function(_, _, args)
        return self:handleSyncStorage(args)
    end)
    message.setHandler("Sexbound:Common:UpdateFertility", function(_, _, args)
        self:updateFertility(args)
    end)
end

--- Message handler for sexnode idle state being entered
function Sexbound.Monster:handleEnterIdleState(_)
    self:getArousal():setRegenRate("default")
end

--- Message handler for sexnode sex state being entered
--- @param _ any
function Sexbound.Monster:handleEnterSexState(_)
    self:getArousal():setRegenRate("havingSex")
end

--- Message handler for sexnode actor storage being restored
--- @param args table # The provided data
function Sexbound.Monster:handleRestore(args)
    if args then
        self:mergeStorage(args)
    end

    self:getArousal():instaMin()

    self:restore()
end

--- Restore this monster entity
function Sexbound.Monster:restore()
    self._isHavingSex = false

    if storage.previousDamageTeam then
        monster.setDamageTeam(storage.previousDamageTeam)
    end

    if storage and storage.sexbound then
        self:getClimax():setCurrentValue(storage.sexbound.climax)
    end

    monster.setInteractive(true)

    local entityId = entity.id()

    if entityId then
        world.sendEntityMessage(entityId, "Sexbound:removeStatusEffect", "sexbound_invisible")
        world.sendEntityMessage(entityId, "Sexbound:removeStatusEffect", "sexbound_stun")
    end
end

--- Message handler for sexnode actor requesting sexboundConfig data from this entity
--- @return any # Whatever may or may not be defined for this monster
function Sexbound.Monster:handleRetrieveConfig(_)
    return config.getParameter("sexboundConfig")
end

--- Message handler for making the entity say something
--- @param args table # The message data to say
function Sexbound.Monster:handleSay(args)
    monster.say(args.message);
end

--- Message handler for sexnode actor requesting entity's persistent storage data
--- @param args table? Potentially provided arguments for retrieving a specific name from storage
--- @return any # Whatever the requested storage parameter is, if it exists, or the entire storage
function Sexbound.Monster:handleRetrieveStorage(args)
    if args and args.name then
        return storage[args.name]
    end

    return storage
end

--- Message handler for sexnode actor syncing persistent storage data
--- @param args table # The sync data
function Sexbound.Monster:handleSyncStorage(args)
    self:mergeStorage(args)
end

--- Merges given table into persistent storage
--- @param newData table? The data to merge
function Sexbound.Monster:mergeStorage(newData)
    storage = util.mergeTable(storage, newData or {})
end

--- Unloads this monster entity. Probably to emulate "lounging"
function Sexbound.Monster:unload()
    local duration = 300 -- 5 minutes
    local entityId = entity.id()

    storage.previousDamageTeam = storage.previousDamageTeam or world.entityDamageTeam(entityId)

    monster.setDamageTeam({
        type = "ghostly"
    })
    monster.setInteractive(false)

    if entityId then
        world.sendEntityMessage(entityId, "applyStatusEffect", "sexbound_invisible", duration, entityId)
        world.sendEntityMessage(entityId, "applyStatusEffect", "sexbound_stun", duration, entityId)
    end
end

--- Starts actor setup, optionally with provided fixed parameters
--- @param controllerId EntityId The entity id of the sexnode controller to talk to
--- @param params table? Optional override parameters for the actor data
--- @return boolean # Whethere or not setup was successful
function Sexbound.Monster:setup(controllerId, params)
    self._isHavingSex = true

    self:unload()

    if controllerId then
        local actorData = util.mergeTable(self:getActorData(), params or {})

        self._promises:add(world.sendEntityMessage(controllerId, "Sexbound:Actor:Setup", actorData), function(result)
            self._isHavingSex = result or false
        end)

        return true
    end

    return false
end

--- Returns all data relevant to build a corresponding sexnode actor
--- @return table? # The assembled actor data
function Sexbound.Monster:getActorData()
    local identity = self:getIdentity():build()
    if identity.sxbSubGender == nil then
        identity.sxbSubGender = self:getSubGender():getSxbSubGender()
    end

    return {
        entityId = entity.id(),
        forceRole = math.floor(status.stat("forceRole")),
        uniqueId = entity.uniqueId(),
        level = monster.level(),
        entityType = "monster",
        identity = identity,
        type = monster.type(),
        seed = monster.seed(),
        storage = storage,
        generationFertility = status.statusProperty("generationFertility", 1.0),
        fertilityPenalty = status.statusProperty("fertilityPenalty", 1.0)
    }
end

-- [[ Legacy functions ]]

--- Message handler for "respawning" this entity
--- @param args table The provided storage data
function Sexbound.Monster:handleRespawn(args)
    if args then
        self:mergeStorage(args)
    end

    self:getArousal():instaMin()

    self:respawn()
end

--- "Respawns" this entity
function Sexbound.Monster:respawn()
    self:restore()
end

-- [[ State Definitions ]]

--- Defines state machine states - default state
--- @return table<string, function> # The defined state handlers
function Sexbound.Monster:defineStateDefaultState()
    return {
        enter = function()
            if not self._isHavingSex then
                return {}
            end
        end,

        enteringState = function(stateData)
            self:getArousal():setRegenRate("default")
            self:getClimax():setRegenRate("default")
        end,

        update = function(dt, stateData)
            -- Exit condition #1
            if self._isHavingSex then
                return true
            end

            self:getClimax():update(dt)
        end
    }
end

--- Defines state machine states - havingSex state
--- @return table<string, function> # The defined state handlers
function Sexbound.Monster:defineStateHavingSexState()
    return {
        enter = function()
            if self._isHavingSex then
                return {}
            end
        end,

        enteringState = function(stateData)
            self:getArousal():setRegenRate("havingSex")
            self:getClimax():setRegenRate("havingSex")
        end,

        update = function(dt, stateData)
            -- Exit condition #1
            if not self._isHavingSex then
                return true
            end
        end,

        leavingState = function(stateData)
            local controllerId = self._controllerId or self._loungeId

            if controllerId then
                world.sendEntityMessage(controllerId, "Sexbound:Actor:Remove", entity.id())
            end

            self._loungeId = nil

            self._controllerId = nil

            self:restore()
        end
    }
end

-- [[ Abstract implementations ]]

--- Returns this entity's gender
--- @return string # The monster's gender
function Sexbound.Monster:getGender()
    local binGenders = {"male", "female", "female"} -- Gender 3 is for sub-gender fem-futa [Red3Red]

    return binGenders[self._gender or 1]
end

--- Returns this entity's species
--- @return string # The monster's species
function Sexbound.Monster:getSpecies()
    return monster.type()
end

--- Returns necessary data for sexnode compatibility comparison
--- @return table<string, any> # The comparison data
function Sexbound.Monster:getCompatibilityData()
    return {
        species = monster.type(),
        speciesType = nil,
        gender = self:getGender(),
        bodyTraits = self._bodyTraits,
        motherUuid = nil,
        fatherUuid = nil
    }
end

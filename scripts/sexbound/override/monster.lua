--- Sexbound.Monster Module.
-- @module Sexbound.Monster
require "/scripts/sexbound/override/common.lua"

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
    if not entity.uniqueId() and not (isCapturable or capturable.ownerUuid() or storage.respawner) then
        monster.setUniqueId(sb.makeUuid())
    end

    self._stateMachine = self:helper_loadStateMachine()

    self._hasInitied = true
    self:updateTraitEffects()

    return self
end

-- [Helper] Loads the stateMachine
-- See state definitions at the bottom of the script
function Sexbound.Monster:helper_loadStateMachine()
    self._stateDefinitions = {
        defaultState = self:defineStateDefaultState(),
        havingSexState = self:defineStateHavingSexState()
    }

    return stateMachine.create(self._states, self._stateDefinitions)
end

function Sexbound.Monster:update(dt)
    -- Monster script doesn't have a promises handler by default
    self._promises:update()

    self:getArousal():update(dt)
end

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
    message.setHandler("Sexbound:Actor:GetActorData", function(_, _, args)
        return self:getActorData(), args
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

function Sexbound.Monster:handleEnterIdleState(args)
    self:getArousal():setRegenRate("default")
    -- self:getClimax():setRegenRate("default")
end

function Sexbound.Monster:handleEnterSexState(args)
    self:getArousal():setRegenRate("havingSex")
    -- self:getClimax():setRegenRate("havingSex")
end

function Sexbound.Monster:handleRestore(args)
    if args then
        self:mergeStorage(args)
    end

    self:getArousal():instaMin()

    self:restore()
end

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
        world.sendEntityMessage(entityId, "Sexbound:removeStatusEffect", "sexbound_defeat_stun")
    end
end

function Sexbound.Monster:handleRetrieveConfig(args)
    return config.getParameter("sexboundConfig"), args
end

function Sexbound.Monster:handleSay(args)
    monster.say(args.message);
end

function Sexbound.Monster:handleRetrieveStorage(args)
    if args and args.name then
        return storage[args.name]
    end

    return storage
end

function Sexbound.Monster:handleSyncStorage(args)
    self:mergeStorage(args)
end

function Sexbound.Monster:mergeStorage(newData)
    storage = util.mergeTable(storage, newData or {})
end

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

function Sexbound.Monster:getActorData()
    -- storage.sexbound.climax = self:getClimax():getCurrentValue()
    -- storage.sexbound.fertility = 1.0

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

-- Getters

function Sexbound.Monster:getIsHavingSex()
    return self._isHavingSex
end
function Sexbound.Monster:getArousal()
    return self._arousal
end
function Sexbound.Monster:getClimax()
    return self._climax
end
function Sexbound.Monster:getIdentity()
    return self._identity
end
function Sexbound.Monster:getPregnant()
    return self._pregnant
end
function Sexbound.Monster:getStatistics()
    return self._statistics
end
function Sexbound.Monster:getSubGender()
    return self._subGender
end
function Sexbound.Monster:getTransform()
    return self._transform
end

-- Legacy functions

function Sexbound.Monster:handleRespawn(args)
    if args then
        self:mergeStorage(args)
    end

    self:getArousal():instaMin()

    self:respawn()
end

function Sexbound.Monster:respawn()
    self:restore()
end

-- State Definitions

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

function Sexbound.Monster:getGender()
    local binGenders = {"male", "female", "female"} -- Gender 3 is for sub-gender fem-futa [Red3Red]
    
    return binGenders[self._gender or 1]
end

function Sexbound.Monster:getSpecies()
    return monster.type()
end

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

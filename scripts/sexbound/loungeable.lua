--- Loungeable Module.
-- @module Loungeable
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/v2/api.lua")
    require("/scripts/stateMachine.lua")
end

local Loungeable = {}
local Loungeable_mt = {
    __index = Loungeable
}

function Loungeable.new()
    local self = setmetatable({
        _addonConfig = config.getParameter("addonConfig", {}),
        _states = {"commonState", "occupiedState", "fullState"},
        _interactive = config.getParameter("interactive")
    }, Loungeable_mt)

    self:init()

    return self
end

function Loungeable:init()
    ObjectAddons:init(self._addonConfig, function()
        self:handleConnection()
    end)

    self._stateDefinitions = {
        -- STATE [COMMON]
        commonState = {
            enter = function()
                if not self:isOccupied() and not self:isAtMinRequiredCapacity() then
                    return {}
                end
            end,

            enteringState = function(stateData)
                if self._addonId then
                    world.sendEntityMessage(self._addonId, "show")
                end
            end,

            update = function(dt, stateData)
                -- Exit condition : When the loungeable is occupied it is no longer idle.
                if self:isOccupied() or self:isAtMinRequiredCapacity() then
                    return true
                end
            end
        },

        -- STATE [OCCUPIED]
        occupiedState = {
            enter = function()
                if self:isOccupied() then
                    return {}
                end
            end,

            enteringState = function(stateData)
                if self._addonId then
                    world.sendEntityMessage(self._addonId, "hide")
                    Sexbound.API.uninit()
                end
            end,

            update = function(dt, stateData)
                -- Exit condition : When the loungeable is unoccupied then no one is sleeping in it.
                if not self:isOccupied() then
                    return true
                end
            end,

            leavingState = function(stateData)
                if self._addonId then
                    Sexbound.API.uninit()
                    self:initSexbound()
                end
            end
        },

        -- STATE [FULL]
        fullState = {
            enter = function()
                if self:isAtMinRequiredCapacity() then
                    return {}
                end
            end,

            enteringState = function(stateData)
                if self._addonId then
                    world.sendEntityMessage(self._addonId, "hide")
                end
            end,

            update = function(dt, stateData)
                -- Exit condition : When the amount of actor's is below max capicity for the current sex position.
                if self:isOccupied() or not self:isAtMinRequiredCapacity() then
                    return true
                end
            end
        }
    }

    self._stateMachine = stateMachine.create(self._states, self._stateDefinitions)

    message.setHandler("addoninteract", function(_, _, args)
        self:handleInteractAddon(args)
    end)
end

function Loungeable:handleConnection()
    self._addonId = nil

    for _, _addon in ipairs(self._addonConfig.usesAddons) do
        self._addonId = ObjectAddons:isConnectedTo(_addon.name)

        if self._addonId then
            self._addon = _addon

            self:initSexbound()
            return
        end
    end

    if not self._addonId then
        self._addon = nil

        Sexbound.API.uninit()
    end
end

function Loungeable:handleInteractAddon(args)
    if world.loungeableOccupied(entity.id()) then
        return
    end

    local result = Sexbound.API.handleInteract(args)

    --if args.sourceId and result then
    --    world.sendEntityMessage(args.sourceId, "Sexbound:UI:Show", {
    --        controllerId = entity.id(),
    --        config = result[2]
    --    })
    --end
end

function Loungeable:initSexbound()
    local maxActors = self._addon.addonData.maxActors or 2

    if self._addon.name ~= "sexboundLoungeableAddon" and not self._addon.addonData.enabled then
        object.say("Sorry, but this object does not support upto ^green;" .. maxActors .. "^reset; actors!")
        return
    end

    Sexbound.API.init()

    local nPositions = config.getParameter("sexboundConfig.nodePositions", {})
    local sPositions = config.getParameter("sexboundConfig.sitPositions", {})

    maxActors = self._addon.addonData.maxActors or 2

    for i = 1, maxActors do
        Sexbound.API.Nodes.addNode(nPositions[i] or {0, 0}, sPositions[i] or {0, 0}) -- Add next node
    end
end

function Loungeable:isAtMinRequiredCapacity()
    local currentPosition = Sexbound.API.Positions.getCurrentPosition()

    if currentPosition then
        return Sexbound.API.Actors.getActorCount() >= currentPosition:getMinRequiredActors()
    end

    return false
end

function Loungeable:isOccupied()
    return world.loungeableOccupied(entity.id())
end

function Loungeable:update(dt)
    self._stateMachine.update(dt)

    if self._addonId then
        Sexbound.API.update(dt)
    end
end

function Loungeable:uninit(dt)
    if ObjectAddons then
        ObjectAddons:uninit()
    end

    Sexbound.API.uninit()
end

--- Object hooks ---

function init()
    self.loungeable = Loungeable.new()

    self.loungeable:init()
end

function update(dt)
    self.loungeable:update(dt)
end

function uninit()
    self.loungeable:uninit()
end
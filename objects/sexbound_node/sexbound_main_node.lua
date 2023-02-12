--- Used by entities transformed in a Sex Node by "mindcontrol".
require "/scripts/sexbound/v2/api.lua"

local SexNode = {}
local SexNode_mt = {
    __index = SexNode
}

function SexNode:new()
    return setmetatable({
        _timers = {}
    }, SexNode_mt)
end

function SexNode:init()
    Sexbound.API.init()

    if not self:setupMindControl() then
        self:handleSmash()
        return
    end

    self:setupRespawner()

    self:setupActor()
end

function SexNode:addToTimer(name, amount)
    self._timers[name] = self._timers[name] + amount
end

function SexNode:getTimer(name)
    return self._timers[name]
end

function SexNode:resetTimer(name)
    self._timers[name] = 0
end

function SexNode:setupMindControl()
    -- Check if mindControl is in storage before setting it.
    if storage.mindControl then
        return false
    end

    self:resetTimer("mindControl")

    storage.mindControl = config.getParameter("mindControl")

    if storage.mindControl then
        Sexbound.API.Nodes.becomeNode(config.getParameter("sitPosition", {0, 20}))
    end

    return true
end

function SexNode:setupRespawner()
    local respawner = config.getParameter("respawner")

    if respawner then
        world.sendEntityMessage(respawner, "Sexbound:Respawner:Sync", {
            entityId = entity.id()
        })
    end
end

function SexNode:setupActor()
    local storedActor = config.getParameter("storedActor")

    if storedActor then
        Sexbound.API.Actors.addActor(storedActor, true)
    end
end

function SexNode:update(dt)
    if self._isSmashing then
        return
    end

    Sexbound.API.update(dt)

    self:addToTimer("mindControl", dt)

    if storage.mindControl then
        if not Sexbound.API.StateMachine:getStatus("havingSex") and self:getTimer("mindControl") >=
            storage.mindControl.timeout then
            smash()
        end
    end
end

function SexNode:handleOnInteraction(args)
    return Sexbound.API.handleInteract(args)
end

function SexNode:handleSmash()
    if not self._isSmashing then
        self._isSmashing = true

        object.smash(true)

        return true
    end

    return false
end

function SexNode:handleDie()
    Sexbound.API.respawnStoredActor()
end

function SexNode:uninit()
    Sexbound.API.uninit()
end

--- Object hooks ---
function init()
    self.node = SexNode:new()
    self.node:init()
end

function update(dt)
    self.node:update(dt)
end

function onInteraction(args)
    return self.node:handleOnInteraction(args)
end

function smash()
    self.node:handleSmash()
end

function die()
    self.node:handleDie()
end

function uninit()
    self.node:uninit()
end
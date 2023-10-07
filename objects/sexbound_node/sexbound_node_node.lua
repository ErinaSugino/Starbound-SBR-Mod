require "/scripts/util.lua"
require "/scripts/messageutil.lua"

--- Init hook
function init()
    util.setDebug(true)

    self.bounds = object.boundBox()

    -- The 'controllerId' parameter is set by Sexbound API upon placement.
    self.controllerId = config.getParameter("controllerId")

    -- A sex node should always smash itself on the next init.
    if storage.smashOnInit or self.controllerId == nil then
        object.smash(true)
        return
    end

    storage.smashOnInit = true

    object.setInteractive(config.getParameter("interactive", false))

    -- Handle Uninit Node
    message.setHandler("Sexbound:Node:Uninit", function(_, _, args)
        object.smash(true)
    end)

    -- Relay messages to the controller entity
    message.setHandler("Sexbound:Retrieve:ControllerId", function(_, _, args)
        return self.controllerId
    end)

    message.setHandler("Sexbound:Backwear:Change", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Backwear:Change", args)
    end)
    message.setHandler("Sexbound:Chestwear:Change", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Chestwear:Change", args)
    end)
    message.setHandler("Sexbound:Groinwear:Change", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Groinwear:Change", args)
    end)
    message.setHandler("Sexbound:Headwear:Change", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Headwear:Change", args)
    end)
    message.setHandler("Sexbound:Legswear:Change", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Legswear:Change", args)
    end)
    message.setHandler("Sexbound:Nippleswear:Change", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Nippleswear:Change", args)
    end)
    message.setHandler("Sexbound:Actor:Remove", function(_, _, args)
        world.sendEntityMessage(self.controllerId, "Sexbound:Actor:Remove", args)
    end)
end

--- Update hook
function update(dt)
    promises:update()

    util.debugRect(self.bounds, "blue")

    if not self.sent then
        -- This is done in the update after all other entites have inited.
        world.sendEntityMessage(self.controllerId, "Sexbound:Node:Init", {
            entityId = entity.id(),
            uniqueId = entity.uniqueId()
        })

        self.sent = true
    end
end

--- The node is preparing to be removed from the world
function die()
    -- Placeholder
end

--- The node has been removed from the world
function uninit()
    if self.controllerId then
        world.sendEntityMessage(self.controllerId, "Sexbound:Node:Uninit", {
            actorId = storage.actorId,
            entityId = entity.id(),
            uniqueId = entity.uniqueId()
        })
    end
end

function returnControllerId()
    return self.controllerId
end

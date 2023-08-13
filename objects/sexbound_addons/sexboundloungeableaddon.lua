local function connectionCallback()
    storage.connected = ObjectAddons:isConnectedAsAny()
    storage.connectedTo = ObjectAddons:isConnectedAs("sexboundLoungeableAddon") or
                              ObjectAddons:isConnectedAs("sexboundLoungeableAddon1") or
                              ObjectAddons:isConnectedAs("sexboundLoungeableAddon2") or
                              ObjectAddons:isConnectedAs("sexboundLoungeableAddon3")
end

local function handleShow(messageName, isLocal, args)
  animator.setAnimationState("hearts", "on", true)
  return true
end

local function handleHide(messageName, isLocal, args)
  animator.setAnimationState("hearts", "off", true)
  return true
end

function init()
    object.setInteractive(config.getParameter("interactive"))

    ObjectAddons:init(config.getParameter("addonConfig", {}), connectionCallback)

    message.setHandler("show", handleShow)
    message.setHandler("hide", handleHide)
end

function onInteraction(args)
    if storage.connectedTo then
        world.sendEntityMessage(storage.connectedTo, "addoninteract", args)
    end
end

function uninit()
    ObjectAddons:uninit()
end

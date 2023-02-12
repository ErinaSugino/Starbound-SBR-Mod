--- Sexbound.Log Class Module.
-- @classmod Sexbound.Log
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Event = {}
Sexbound.Event_mt = {
    __index = Sexbound.Event
}

function Sexbound.Event.new(parent)
    local self = setmetatable({
        _parent = parent,
        _config = parent._config.events or {}
    }, Sexbound.Event_mt)

    self.isEnabled   = self._config.enable or false
    self.eventPrefix = self._config.prefix or "REDSHIFT_EVENT"

    Sexbound.Messenger.get("main"):addBroadcastRecipient(self)

    return self
end

--- Processes received messages from the message queue.
-- @param message
function Sexbound.Event:onMessage(message)
    if message:getType() ~= "Sexbound:Event:Create" then
        return
    end

    self:send(message:getData().eventName, message:getData().eventArgs)
end

function Sexbound.Event:send(eventName, eventArgs)
    if not self.isEnabled then
        return
    end

    sb.logInfo(self.eventPrefix .. "::" .. eventName .. "::" .. sb.printJson(eventArgs or {}))
end

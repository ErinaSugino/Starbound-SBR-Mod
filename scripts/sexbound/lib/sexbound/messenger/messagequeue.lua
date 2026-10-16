--- Sexbound.MessageQueue Class Module.
--- @class Sexbound.MessageQueue
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _messages table<integer, Sexbound.Message>
--- @field _messageCount number
--- @field _recipients table<integer, table>
Sexbound.MessageQueue = {}
Sexbound.MessageQueue_mt = {
    __index = Sexbound.MessageQueue
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/messenger/message.lua")
end

--- Returns new instance of MessageQueue
--- @return Sexbound.MessageQueue # The new instance
function Sexbound.MessageQueue:new()
    return setmetatable({
        _messages = {},
        _messageCount = 0,
        _recipients = {}
    }, Sexbound.MessageQueue_mt)
end

--- Add a new broadcast recipient to this queue
--- @param instance table A reciver instance that has "onMessage" handler
function Sexbound.MessageQueue:addBroadcastRecipient(instance)
    table.insert(self._recipients, instance)
end

--- Broadcast a new message to all registered receivers
--- @param mFrom table The sender instance
--- @param mType string The message type
--- @param mData any The data of the message
--- @param delay ?boolean Whethere or not to send the message on the next tick or immediately (Default: true)
function Sexbound.MessageQueue:broadcast(mFrom, mType, mData, delay)
    if delay == nil then delay = true end

    for _, recipient in ipairs(self:getRecipients()) do
        if delay then
            self:send(mFrom, recipient, mType, mData)
        else
            self:immediateSend(mFrom, recipient, mType, mData)
        end
    end
end

--- Dispatch an assembled message
--- @private
--- @param message table The assembled message
function Sexbound.MessageQueue:immediateDispatch(message)
    local entity = message:getTo()

    -- Deliver message when entity exists
    if entity and type(entity.onMessage) == "function" then
        entity:onMessage(message)
    end
end

--- Assemble a message and dispatch it immediately
--- @param mFrom table The sender instance
--- @param mTo table The receiver instance
--- @param mType string The message type
--- @param mData any The data of the message
function Sexbound.MessageQueue:immediateSend(mFrom, mTo, mType, mData)
    self:immediateDispatch(Sexbound.Message:new(mFrom, mTo, mType, mData))
end

--- Dispatch pending messages
--- @private
function Sexbound.MessageQueue:dispatch()
    for _, m in ipairs(self._messages) do
        if m then
            self:immediateDispatch(m)
        end
    end

    -- Remove message from the queue
    self._messages = {}

    self._messageCount = 0
end

--- Send a message to a target
--- @param mFrom table The sender instance
--- @param mTo table The receiver instance, needs to have "onMessage" handler
--- @param mType string The type of the message
--- @param mData any The data of the message
--- @param delay ?boolean Whethere or not to send the message on the next tick or not (Default: true)
function Sexbound.MessageQueue:send(mFrom, mTo, mType, mData, delay)
    if delay == nil then delay = true end

    if delay then
        table.insert(self._messages, Sexbound.Message:new(mFrom, mTo, mType, mData))

        self._messageCount = self._messageCount + 1
    else
        self:immediateSend(mFrom, mTo, mType, mData)
    end
end

-- [[ Getters / Setters ]]

--- Returns all pending messages
--- @return table<integer, Sexbound.Message>
function Sexbound.MessageQueue:getMessages()
    return self._messages
end

--- Returns all registered broadcast recipients
--- @return table<integer, table>
function Sexbound.MessageQueue:getRecipients()
    return self._recipients
end

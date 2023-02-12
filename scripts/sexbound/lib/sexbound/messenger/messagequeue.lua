--- Sexbound.MessageQueue Class Module.
-- @classmod Sexbound.MessageQueue
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.MessageQueue = {}
Sexbound.MessageQueue_mt = {
    __index = Sexbound.MessageQueue
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/messenger/message.lua")
end

--- Returns new instance of MessageQueue
function Sexbound.MessageQueue:new()
    return setmetatable({
        _messages = {},
        _messageCount = 0,
        _recipients = {}
    }, Sexbound.MessageQueue_mt)
end

function Sexbound.MessageQueue:addBroadcastRecipient(instance)
    table.insert(self._recipients, instance)
end

function Sexbound.MessageQueue:broadcast(mFrom, mType, mData, delay)
    delay = delay or true

    for _, recipient in ipairs(self:getRecipients()) do
        if delay then
            self:send(mFrom, recipient, mType, mData)
        else
            self:immediateSend(mFrom, recipient, mType, mData)
        end
    end
end

function Sexbound.MessageQueue:immediateDispatch(message)
    local entity = message:getTo()

    -- Deliver message when entity exists
    if entity and type(entity.onMessage) == "function" then
        entity:onMessage(message)
    end
end

function Sexbound.MessageQueue:immediateSend(mFrom, mTo, mType, mData)
    self:immediateDispatch(Sexbound.Message:new(mFrom, mTo, mType, mData))
end

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

function Sexbound.MessageQueue:send(mFrom, mTo, mType, mData, delay)
    if delay == nil then delay = true end

    if delay then
        table.insert(self._messages, Sexbound.Message:new(mFrom, mTo, mType, mData))

        self._messageCount = self._messageCount + 1
    else
        self:immediateSend(mFrom, mTo, mType, mData)
    end
end

-- Getters / Setters

function Sexbound.MessageQueue:getMessages()
    return self._messages
end

function Sexbound.MessageQueue:getRecipients()
    return self._recipients
end

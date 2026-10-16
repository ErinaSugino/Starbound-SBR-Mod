--- Sexbound.Message Class Module.
--- @class Sexbound.Message
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _from table
--- @field _to table
--- @field _type string
--- @field _data any
Sexbound.Message = {}
Sexbound.Message_mt = {
    __index = Sexbound.Message
}

--- Create new message instance
--- @param mFrom table The sender instance
--- @param mTo table The receiver instance
--- @param mType string The message type
--- @param mData any The message content
function Sexbound.Message:new(mFrom, mTo, mType, mData)
    return setmetatable({
        _from = mFrom,
        _to = mTo,
        _type = mType,
        _data = mData
    }, Sexbound.Message_mt)
end

--- Returns this message's sender instance
--- @return table # The sender instance
function Sexbound.Message:getFrom()
    return self._from
end

--- Returns this message's receiver
--- @return table # The receiver instance
function Sexbound.Message:getTo()
    return self._to
end

--- Returns this message's type
--- @return string # The message type
function Sexbound.Message:getType()
    return self._type
end

--- Returns this message's content
--- @return any # The message content
function Sexbound.Message:getData()
    return self._data
end

--- Returns whethere or not this message is from a given instance
--- @param mFrom table The instance to compare
--- @return boolean # Whethere or not this message is from the given instance
function Sexbound.Message:isFrom(mFrom)
    return mFrom == self._from
end

--- Returns whethere or not this message is for a given instance
--- @param mTo table The instance to compare
--- @return boolean # Whethere or not this message is for the given instance
function Sexbound.Message:isTo(mTo)
    return mTo == self._to
end

--- Returns whethere or not this message is of given type
--- @param mType string The target type
--- @return boolean # Whethere or not this message is of given type
function Sexbound.Message:isType(mType)
    return mType == self._type
end

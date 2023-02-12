--- Sexbound.Message Class Module.
-- @classmod Sexbound.Message
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Message = {}
Sexbound.Message_mt = {
    __index = Sexbound.Message
}

function Sexbound.Message:new(mFrom, mTo, mType, mData)
    return setmetatable({
        _from = mFrom,
        _to = mTo,
        _type = mType,
        _data = mData
    }, Sexbound.Message_mt)
end

function Sexbound.Message:getFrom()
    return self._from
end

function Sexbound.Message:getTo()
    return self._to
end

function Sexbound.Message:getType()
    return self._type
end

function Sexbound.Message:getData()
    return self._data
end

function Sexbound.Message:isFrom(mFrom)
    return mFrom == self._form
end

function Sexbound.Message:isTo(mTo)
    return mTo == self._to
end

function Sexbound.Message:isType(mType)
    return mType == self._type
end

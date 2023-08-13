require "/scripts/sexbound/override/common/identity.lua"

Sexbound.Monster.Identity = Sexbound.Common.Identity:new()
Sexbound.Monster.Identity_mt = {
    __index = Sexbound.Monster.Identity
}

function Sexbound.Monster.Identity:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Identity_mt)

    _self:init(parent)

    return _self
end

--- Returns a table consisting of identifying information about the entity.
-- @param portraitData
function Sexbound.Monster.Identity:build(target, portraitData)
    if self._parent._gender == 3 then self._parent._subGen = "futanari" end

    return {
        -- Set the name of the monster by checking capturable data by Red3dred
        name = capturable.optName() or "???",
        species = monster.type(),
        gender = self._parent:getGender() or "male",
        sxbSubGender = self._parent._subGen or nil,
        subGender = self._parent._subGen or nil
    }
end

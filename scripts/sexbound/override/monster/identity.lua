require "/scripts/sexbound/override/common/identity.lua"

--- Monster identity builder class
--- @class Sexbound.Monster.Identity: Sexbound.Common.Identity
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Monster
Sexbound.Monster.Identity = Sexbound.Common.Identity:new()
Sexbound.Monster.Identity_mt = {
    __index = Sexbound.Monster.Identity
}

--- Creates new monster identity builder instance
--- @param parent Sexbound.Monster The calling parent monster manager class
--- @return Sexbound.Monster.Identity # The newly created monster identity builder instance
function Sexbound.Monster.Identity:new(parent)
    local _self = setmetatable({}, Sexbound.Monster.Identity_mt)

    _self:init(parent)

    return _self
end

--- Returns a table consisting of identifying information about the entity.
--- @return table # The entity's actor identity data
function Sexbound.Monster.Identity:build()
    if self._parent._gender == 3 then self._parent._subGen = "futanari" end

    return {
        -- Set the name of the monster by checking capturable data by Red3dred
        name = capturable.optName() or "???",
        species = monster.type(),
        gender = self._parent:getGender() or "male",
        sxbSubGender = self._parent._subGen or nil,
        subGender = self._parent._subGen or nil,
		actorOffset = config.getParameter("actorOffsets") or nil
    }
end

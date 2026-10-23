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

-- Fetches monster colors, if possible. Cannot fetch recolors done by swapping monster parts.
-- returns bodyDirectives.
function Sexbound.Monster.Identity:getDirectives()
	local portrait = world.entityPortrait(entity.id(), "full")
	if not portrait then return nil end
	for key, value in ipairs(portrait) do
		if portrait[key].image and string.find(portrait[key].image,".png") then
			local body_image = portrait[key].image
			local directive_location = string.find(body_image, "?replace")
			if not directive_location then return nil end
			local directives = string.sub(body_image,directive_location)
			return directives
		end
	end
	return nil
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
        subGender = self._parent._subGen or nil,
		actorOffset = config.getParameter("actorOffsets") or nil,
		bodyDirectives = self:getDirectives() or nil
    }
end

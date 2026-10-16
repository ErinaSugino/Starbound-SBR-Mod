--- Sexbound.Position Class Module.
--- @class Sexbound.Position
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound
--- @field _config table
--- @field _availableRoleIndex table<integer,string>
--- @field _availableRoles table<string, table<integer, integer>>
--- @field _animationStates Sexbound.Position.AnimationState
Sexbound.Position = {}
Sexbound.Position_mt = {
    __index = Sexbound.Position
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/position/animationstate.lua")
end

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Positions Calling parent position manager instance
--- @param positionConfig table Position configuration JSON
--- @return Sexbound.Position # New position instance
function Sexbound.Position:new(parent, positionConfig)
    local _self = setmetatable({
        _parent = parent,
        _config = positionConfig,
        _availableRoleIndex = {"1234"},
        _availableRoles = {["1234"]={1,2,3,4}}
    }, Sexbound.Position_mt)

    _self._animationStates = Sexbound.Position.AnimationState:new(_self, _self._config.animationState)

    return _self
end

--- Returns the animation state for the specied state machine state.
--- @param stateName string The name of the animation state to get
--- @return table<string, Sexbound.Position.AnimationState.State>|Sexbound.Position.AnimationState.State|nil # The requested animation state, nil if not existent or the list of all states if none requested
function Sexbound.Position:getAnimationState(stateName)
    if stateName then
        return self._animationStates:getStates()[stateName]
    end

    return self._animationStates:getStates()
end

--- Returns a reference to this instance's position config.
--- @return table # This position's config
function Sexbound.Position:getConfig()
    return self._config
end

--- Returns this position's button image path as a string.
--- @return string # This position's button image path
function Sexbound.Position:getButton()
    local configPath = self:getConfig().button or "/interface/sexbound/sexui/submodule/positions/buttons.config:default"

    local buttonsConfig = util.split(configPath, ":")

    local _, result = xpcall(function()
        return root.assetJson(buttonsConfig[1]) or {}
    end, function(err)
        sb.logError("Unable to load position button.")
    end)

    return result[buttonsConfig[2]] or result["default"] or ""
end

--- Returns this position's climax configuration for a given role and gender
--- @param role integer The actor's role number
--- @param gender string "male" or "female"
--- @return table # The climax config data for the requested role and gender
function Sexbound.Position:getClimaxConfig(role, gender)
    local climaxConfig = self._config.climaxConfig or {}

    if nil ~= role then
        climaxConfig = climaxConfig[role] or {}
    end
    if nil ~= gender then
        climaxConfig = climaxConfig[gender] or {}
    end

    return climaxConfig
end

--- Returns this position's climax particle name for a given role and gender
--- @param role integer The actor's role number
--- @param gender string "male" or "female"
--- @return string|nil # The climax particle name data for the requested role and gender
function Sexbound.Position:getClimaxParticleName(role, gender)
    local climaxConfig = self._config.climaxConfig or {}

    if nil ~= role then
        climaxConfig = climaxConfig[role] or {}
    end
    if nil ~= gender then
        climaxConfig = climaxConfig[gender] or {}
    end

    return climaxConfig.particleName
end

--- Returns this position's climax projectile name for a given role and gender
--- @param role string The actor's role name
--- @param gender string "male" or "female"
--- @return string|nil # The climax projectile name data for the requested role and gender
function Sexbound.Position:getClimaxProjectileName(role, gender)
    local climaxConfig = self._config.climaxConfig or {}

    if nil ~= role then
        climaxConfig = climaxConfig[role] or {}
    end
    if nil ~= gender then
        climaxConfig = climaxConfig[gender] or {}
    end

    return climaxConfig.projectileName
end

--- Returns constant scale data of current position, optionally for a given index
--- @param index ?integer The actor role index
--- @return table|integer|nil # The constant scale for the given index or nil, or the list of all constant scales if none requested
function Sexbound.Position:getConstantScale(index)
    local constantScale = self._config.constantScale or {}

    if index == nil then
        return constantScale
    end

    return constantScale[index]
end

--- Returns container overlay data of current position, optionally for a given index
--- @param index ?integer The actor role index
--- @return table|integer|nil # The container overlay for the given index or nil, or the list of all constant scales if none requested
function Sexbound.Position:getContainerOverlay(index)
    local containerOverlay = self._config.containerOverlay or {}

    if index == nil then
        return containerOverlay
    end

    return containerOverlay[index]
end

--- Returns a reference to this instance's dialog config, optionally for a given species
--- @param species string The species of the target actor
--- @param default ?string Default dialog file to use if requested species has none set
--- @return table<string, string>|string|nil # The dialog file path for the requested species, nil if no default given and not existent, or table of all if non requested
function Sexbound.Position:getDialog(species, default)
    local dialog = self:getConfig().dialog or {}

    if species then
        return dialog[species] or default
    end

    return dialog
end

--- Returns the friendly name of this instance.
--- @return string # The friendly name of this position
function Sexbound.Position:getFriendlyName()
    return self:getConfig().friendlyName
end

--- Returns the maxAllowedActors of this instance.
--- @return integer # The maximum number of actors this position is allowed for
function Sexbound.Position:getMaxAllowedActors()
    return self:getConfig().maxAllowedActors
end

--- Returns the minRequiredActors of this instance.
--- @return integer # The minimum number of actors this position needs
function Sexbound.Position:getMinRequiredActors()
    return self:getConfig().minRequiredActors
end

--- Returns the name of this instance.
--- @return string # The internal name of this position
function Sexbound.Position:getName()
    return self:getConfig().name
end

--- Returns this position's actorRelation table
--- @return table<integer, integer|nil> # List of actor relations
function Sexbound.Position:getActorRelation()
    return self:getConfig().actorRelation or {}
end

--- Returns this position's actor-based interactionType table
--- @return table<integer, string|nil> # List of interaction types per actor role index
function Sexbound.Position:getInteractionType()
    return self:getConfig().interactionType or {}
end

--- Returns the currently available actor compositions
--- @return table<integer, string> availableRoleIndex The list of all available compositions
--- @return table<string, table<integer, integer>> availableRoles List of all available roles per composition
function Sexbound.Position:getAvailableRoles()
    return self._availableRoleIndex, self._availableRoles
end

--- Iterator factory for actor compositions
--- @return fun(): string, table<integer, integer> # Current iteration of role data
function Sexbound.Position:forEachAvailableRole()
    local i, n = 0, #self._availableRoleIndex
    return function() if i<=n then i=i+1 end return self._availableRoleIndex[i], self._availableRoles[self._availableRoleIndex[i]] end
end

--- Set new available actor compositions
--- @param indices table<integer, string> The new list of all composition indices
--- @param roles table<string, table<integer, integer>> The new list of all roles per composition
function Sexbound.Position:setAvailableRoles(indices, roles)
    if type(roles) ~= "table" then return end
    self._availableRoleIndex = indices
    self._availableRoles = roles
    self._parent:getLog():debug("New position composition list for "..self._config.name..": Length "..#self._availableRoleIndex)
    self._parent:getLog():debug(Sexbound.Util.dump(self._availableRoleIndex))
    self._parent:getLog():debug(Sexbound.Util.dump(self._availableRoles))
end

--- Returns the amount of available actor compositions for this position
--- @return integer # Amount of compositions
function Sexbound.Position:getCompositionCount()
    return #self._availableRoleIndex or 0
end
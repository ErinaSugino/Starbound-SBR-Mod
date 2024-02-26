--- Sexbound.Position Class Module.
-- @classmod Sexbound.Position
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Position = {}
Sexbound.Position_mt = {
    __index = Sexbound.Position
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/position/animationstate.lua")
end

---Returns a reference to a new instance of this class.
-- @param positionConfig
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
-- @param stateName
function Sexbound.Position:getAnimationState(stateName)
    if stateName then
        return self._animationStates:getStates()[stateName]
    end

    return self._animationStates:getStates()
end

--- Returns a reference to this instance's position config.
function Sexbound.Position:getConfig()
    return self._config
end

--- Returns this position's button image path as a string.
function Sexbound.Position:getButton()
    local configPath = self:getConfig().button or "/interface/sexbound/sexui/submodule/positions/buttons.config:default"

    local buttonsConfig = util.split(configPath, ":")

    local _, result = xpcall(function()
        return root.assetJson(buttonsConfig[1]) or {}
    end, function(err)
        sb.logError("Unable to load position button.")
    end)

    return result[buttonsConfig[2]] or result["default"] or {}
end

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

function Sexbound.Position:getConstantScale(index)
    local constantScale = self._config.constantScale or {}

    if index == nil then
        return constantScale
    end

    return constantScale[index]
end

function Sexbound.Position:getContainerOverlay(index)
    local containerOverlay = self._config.containerOverlay or {}

    if index == nil then
        return containerOverlay
    end

    return containerOverlay[index]
end

--- Returns a reference to this instance's dialog config.
-- @param species
-- @param default
function Sexbound.Position:getDialog(species, default)
    local dialog = self:getConfig().dialog or {}

    if species then
        return dialog[species] or default
    end

    return self:getConfig().dialog
end

--- Returns the friendly name of this instance.
function Sexbound.Position:getFriendlyName()
    return self:getConfig().friendlyName
end

--- Returns the maxAllowedActors of this instance.
function Sexbound.Position:getMaxAllowedActors()
    return self:getConfig().maxAllowedActors
end

--- Returns the minRequiredActors of this instance.
function Sexbound.Position:getMinRequiredActors()
    return self:getConfig().minRequiredActors
end

--- Returns the name of this instance.
function Sexbound.Position:getName()
    return self:getConfig().name
end

--- Returns this position's actorRelation table
function Sexbound.Position:getActorRelation()
    return self:getConfig().actorRelation or {}
end

--- Returns this position's actor-based interactionType table
function Sexbound.Position:getInteractionType()
    return self:getConfig().interactionType or {}
end

--- Returns the currently available actor compositions
function Sexbound.Position:getAvailableRoles()
    return self._availableRoleIndex, self._availableRoles
end

--- Iterator factory for actor compositions
function Sexbound.Position:forEachAvailableRole()
    local i, n = 0, #self._availableRoleIndex
    return function() i=i+1 if i<=n then return self._availableRoleIndex[i], self._availableRoles[self._availableRoleIndex[i]] end end
end

--- Set new available actor compositions
function Sexbound.Position:setAvailableRoles(indices, roles)
    if type(roles) ~= "table" then return end
    self._availableRoleIndex = indices
    self._availableRoles = roles
    self._parent:getLog():debug("New position composition list for "..self._config.name..": Length "..#self._availableRoleIndex)
    self._parent:getLog():debug(Sexbound.Util.dump(self._availableRoleIndex))
    self._parent:getLog():debug(Sexbound.Util.dump(self._availableRoles))
end

--- Returns the amount of available actor compositions for this position
function Sexbound.Position:getCompositionCount()
    return #self._availableRoleIndex or 0
end
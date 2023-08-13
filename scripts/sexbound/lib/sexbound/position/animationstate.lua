--- Sexbound.Position.AnimationState Class Module.
-- @classmod Sexbound.Position.AnimationState
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Position.AnimationState = {}
Sexbound.Position.AnimationState_mt = {
    __index = Sexbound.Position.AnimationState
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/position/animationstate/state.lua")
end

--- Returns a reference to a new instance of this class.
function Sexbound.Position.AnimationState:new(parent, config)
    local _self = setmetatable({
        _config = config,
        _parent = parent
    }, Sexbound.Position.AnimationState_mt)

    _self._states = _self:loadStates()

    return _self
end

function Sexbound.Position.AnimationState:getConfig()
    return self._config
end

function Sexbound.Position.AnimationState:getStates()
    return self._states
end

function Sexbound.Position.AnimationState:loadStates()
    local properties = self:getConfig().properties
    local states     = self:getConfig().states or {}

    states.nullState   = states.nullState or { properties = {} }
    states.idleState   = states.idleState or { properties = {} }
    states.sexState    = states.sexState or { properties = {} }
    states.climaxState = states.climaxState or { properties = {} }
    states.postclimaxState = states.postclimaxState or {properties = {}}
    states.exitState   = states.exitState or { properties = {} }

    local animStates = {}

    -- Copy default property values into each animation state when they are not already set.
    if properties and states then
        util.each(states, function(stateKey, state)
            util.each(properties, function(propKey, propVal)
                if not state.properties[propKey] then
                    state.properties[propKey] = propVal;
                end
            end)

            -- Add state to animation states list
            animStates[stateKey] = Sexbound.Position.AnimationState.State:new(self, state)
        end)
    end

    return animStates
end

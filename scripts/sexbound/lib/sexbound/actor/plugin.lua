--- Sexbound.Actor.Plugin Class Module.
-- @classmod Sexbound.Actor.Plugin
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor.Plugin = {}
Sexbound.Actor.Plugin_mt = {
    __index = Sexbound.Actor.Plugin
}

function Sexbound.Actor.Plugin:new()
   return setmetatable({
        _config = {},
        _logPrefix = "UNKN",
        _log = {},
        _parent = {}
    }, Sexbound.Actor.Plugin_mt)
end

--- Initializes the plugin for use.
-- @param parent
-- @param logPrefix
-- @param[opt] callback
function Sexbound.Actor.Plugin:init(parent, logPrefix, callback)
    self._parent = parent or self._parent
    self._logPrefix = logPrefix or self._logPrefix
    self._log = Sexbound.Log:new(self._logPrefix, self:getRoot():getConfig())

    if type(callback) == "function" then
        callback()
    end
end

function Sexbound.Actor.Plugin:onMessage(message)
    -- Do nothing
end

function Sexbound.Actor.Plugin:update(dt)
    -- Do nothing
end

function Sexbound.Actor.Plugin:onEnterAnyState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onEnterClimaxState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onEnterExitState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onEnterIdleState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onEnterSexState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onExitAnyState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onExitClimaxState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onExitExitState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onExitIdleState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onExitSexState()
    -- Do nothing
end

function Sexbound.Actor.Plugin:onUpdateAnyState(dt)
    -- Do nothing
end

function Sexbound.Actor.Plugin:onUpdateClimaxState(dt)
    -- Do nothing
end

function Sexbound.Actor.Plugin:onUpdateExitState(dt)
    -- Do nothing
end

function Sexbound.Actor.Plugin:onUpdateIdleState(dt)
    -- Do nothing
end

function Sexbound.Actor.Plugin:onUpdateSexState(dt)
    -- Do nothing
end

function Sexbound.Actor.Plugin:reset()
    -- Do nothing
end

function Sexbound.Actor.Plugin:uninit()
    -- Do nothing
end

-- Getters / Setters

--- Returns a reference to this instance's config object.
function Sexbound.Actor.Plugin:getConfig()
    return self._config
end

--- Returns a reference to this instance's Log object.
function Sexbound.Actor.Plugin:getLog()
    return self._log
end

--- Returns a reference to this instance's module name.
function Sexbound.Actor.Plugin:getLogPrefix()
    return self._logPrefix
end

--- Returns a reference to this instance's parent object.
function Sexbound.Actor.Plugin:getParent()
    return self._parent
end

--- Returns a reference to a plugin
-- @param name
function Sexbound.Actor.Plugin:getPlugin(name)
    return self._parent:getPlugins(name)
end

--- Returns a reference to the root object.
function Sexbound.Actor.Plugin:getRoot()
    return self._parent:getParent()
end

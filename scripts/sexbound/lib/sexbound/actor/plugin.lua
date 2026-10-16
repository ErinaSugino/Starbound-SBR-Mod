--- Sexbound.Actor.Plugin Class Module.
--- @class Sexbound.Actor.Plugin
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _config table
--- @field protected _logPrefix string
--- @field _log Sexbound.Log
Sexbound.Actor.Plugin = {}
Sexbound.Actor.Plugin_mt = {
    __index = Sexbound.Actor.Plugin
}

--- Creates a new plugin instance
--- @return Sexbound.Actor.Plugin # The newly created, partially setup plugin instance
function Sexbound.Actor.Plugin:new()
   return setmetatable({
        _config = {},
        _logPrefix = "UNKN",
        _log = {},
        _parent = {}
    }, Sexbound.Actor.Plugin_mt)
end

--- Initializes the plugin for use - called by child class
--- @protected
--- @param parent Sexbound.Actor True parent actor instance
--- @param logPrefix string The logging prefix for this plugin
--- @param callback function? Callback to execute once plugin is initialized
function Sexbound.Actor.Plugin:init(parent, logPrefix, callback)
    self._parent = parent or self._parent
    self._logPrefix = logPrefix or self._logPrefix
    self._log = Sexbound.Log:new(self._logPrefix, self:getRoot():getConfig())

    if type(callback) == "function" then
        callback()
    end
end

--- Placeholder message receiver. To be implemented by children
--- @param message Sexbound.Message The received message
function Sexbound.Actor.Plugin:onMessage(message)
    -- Do nothing
end

--- Placeholder update tick handler. To be implemented by children
--- @param dt number The delta time since last tick
function Sexbound.Actor.Plugin:update(dt)
    -- Do nothing
end

--- Placeholder state enter handler. To be implemented by children
function Sexbound.Actor.Plugin:onEnterAnyState()
    -- Do nothing
end

--- Placeholder state enter handler. To be implemented by children
function Sexbound.Actor.Plugin:onEnterClimaxState()
    -- Do nothing
end

--- Placeholder state enter handler. To be implemented by children
function Sexbound.Actor.Plugin:onEnterExitState()
    -- Do nothing
end

--- Placeholder state enter handler. To be implemented by children
function Sexbound.Actor.Plugin:onEnterIdleState()
    -- Do nothing
end

--- Placeholder state enter handler. To be implemented by children
function Sexbound.Actor.Plugin:onEnterSexState()
    -- Do nothing
end

--- Placeholder state exit handler. To be implemented by children
function Sexbound.Actor.Plugin:onExitAnyState()
    -- Do nothing
end

--- Placeholder state exit handler. To be implemented by children
function Sexbound.Actor.Plugin:onExitClimaxState()
    -- Do nothing
end

--- Placeholder state exit handler. To be implemented by children
function Sexbound.Actor.Plugin:onExitExitState()
    -- Do nothing
end

--- Placeholder state exit handler. To be implemented by children
function Sexbound.Actor.Plugin:onExitIdleState()
    -- Do nothing
end

--- Placeholder state exit handler. To be implemented by children
function Sexbound.Actor.Plugin:onExitSexState()
    -- Do nothing
end

--- Placeholder state tick handler. To be implemented by children
--- @param dt number The delta time since last tick
function Sexbound.Actor.Plugin:onUpdateAnyState(dt)
    -- Do nothing
end

--- Placeholder state tick handler. To be implemented by children
--- @param dt number The delta time since last tick
function Sexbound.Actor.Plugin:onUpdateClimaxState(dt)
    -- Do nothing
end

--- Placeholder state tick handler. To be implemented by children
--- @param dt number The delta time since last tick
function Sexbound.Actor.Plugin:onUpdateExitState(dt)
    -- Do nothing
end

--- Placeholder state tick handler. To be implemented by children
--- @param dt number The delta time since last tick
function Sexbound.Actor.Plugin:onUpdateIdleState(dt)
    -- Do nothing
end

--- Placeholder state tick handler. To be implemented by children
--- @param dt number The delta time since last tick
function Sexbound.Actor.Plugin:onUpdateSexState(dt)
    -- Do nothing
end

--- Placeholder reset function. To be implemented by children
function Sexbound.Actor.Plugin:reset()
    -- Do nothing
end

--- Placeholder uninit function. To be implemented by children
function Sexbound.Actor.Plugin:uninit()
    -- Do nothing
end

-- [[ Getters / Setters ]]

--- Returns a reference to this instance's config object.
--- @return table # The plugin config
function Sexbound.Actor.Plugin:getConfig()
    return self._config
end

--- Returns a reference to this instance's Log object.
--- @return Sexbound.Log # The logging instance
function Sexbound.Actor.Plugin:getLog()
    return self._log
end

--- Returns a reference to this instance's module name.
--- @return string # The plugin's log prefix
function Sexbound.Actor.Plugin:getLogPrefix()
    return self._logPrefix
end

--- Returns a reference to this instance's parent object.
--- @return Sexbound.Actor # The plugin's parent actor instance
function Sexbound.Actor.Plugin:getParent()
    return self._parent
end

--- Returns a reference to a plugin
--- @param name string Plugin name
--- @return Sexbound.Actor.Plugin? # The reference plugin
function Sexbound.Actor.Plugin:getPlugin(name)
    return self._parent:getPlugins(name)
end

--- Returns a reference to the root object.
--- @return Sexbound # The root sexnode instance
function Sexbound.Actor.Plugin:getRoot()
    return self._parent:getParent()
end

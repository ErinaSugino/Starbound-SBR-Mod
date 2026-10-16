--- Sexbound.Actor.PluginMgr Class Module.
--- @class Sexbound.Actor.PluginMgr
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _config table
--- @field _root Sexbound
--- @field private _logPrefix string
--- @field _plugins table<string, Sexbound.Actor.Plugin>
--- @field _log Sexbound.Log
Sexbound.Actor.PluginMgr = {}
Sexbound.Actor.PluginMgr_mt = {
    __index = Sexbound.Actor.PluginMgr
}

--- Creates new plugin manager instance
--- @param parent Sexbound.Actor The calling parent actor instance
--- @return Sexbound.Actor.PluginMgr # The newly created plugin manager instance
function Sexbound.Actor.PluginMgr:new(parent)
    local _self = setmetatable({
        _logPrefix = "PMGR",
        _parent = parent,
        _root = parent:getParent()
    }, Sexbound.Actor.PluginMgr_mt)

    _self._config = _self:getParent():getConfig().plugins

    _self._plugins = _self:_loadPlugins()

    _self._log = Sexbound.Log:new(_self._logPrefix, _self._root:getConfig())

    return _self
end

--- [Helper] Checks if all requirements from a given plugin load requirement set are fulfilled
--- @private
--- @param req table The plugin's requirements table
--- @return boolean # Whethere or not all requirements are met
function Sexbound.Actor.PluginMgr:_checkLoadRequirements(req)
    req = req or {}
    return self:_checkRequirementForEntityType(req) and self:_checkRequirementForGender(req) and
               self:_checkRequirementForName(req) and self:_checkRequirementForSpecies(req) and
               self:_checkRequirementForUniqueId(req)
end

--- [Helper] Lods the config data for a plugin
--- @private
--- @param plugin table The full plugin data
--- @return table # The config of the plugin
function Sexbound.Actor.PluginMgr:_loadConfig(plugin)
    if "table" ~= type(plugin.config) then
        plugin.config = {plugin.config --[[@as string]]}
    end

    local loadedConfig = {}

    for _, _config in pairs(plugin.config) do
        xpcall(function()
            loadedConfig = util.mergeTable(loadedConfig, root.assetJson(_config))
        end, function(errorMessage)
            self._log:error(errorMessage)
        end)
    end

    return loadedConfig
end

--- [Helper] Requires all scripts for a given plugin
--- @private
--- @param plugin table The full plugin data
function Sexbound.Actor.PluginMgr:_requireScripts(plugin)
    if SXB_RUN_TESTS then
        return
    end

    if "string" == type(plugin.script) then
        require(plugin.script)
        return
    end

    for _, script in pairs(plugin.scripts) do
        require(script)
    end
end

--- Loads the config for all plugins from the parent actor
--- @return table # The full plugin data set
function Sexbound.Actor.PluginMgr:loadConfig()
    return self:getParent():getConfig().plugins
end

--- [Helper] Loads all plugins
--- @private
--- @return table<string, Sexbound.Actor.Plugin> # The named list of all loaded plugins
function Sexbound.Actor.PluginMgr:_loadPlugins()
    local plugins = {}

    util.each(self._config, function(_, plugin)
        plugin.loaded = false

        local canLoad = plugin.enable and self:_checkLoadRequirements(plugin.loadRequirements)

        if not canLoad then
            return
        end

        self:_initPlugin(plugins, plugin)
    end)

    return plugins
end

--- [Helper] Initializes the plugin instace from its config
--- @private
--- @param plugins table<string, Sexbound.Actor.Plugin> The list of plugins by name
--- @param plugin table The plugin's config
function Sexbound.Actor.PluginMgr:_initPlugin(plugins, plugin)
    self:_requireScripts(plugin)

    if Sexbound.Actor[plugin.name] then
        local key = string.lower(plugin.name)

        plugin.loaded = true

        plugins[key] = Sexbound.Actor[plugin.name]:new(self:getParent(), self:_loadConfig(plugin))
    end
end

--- [Helper] Returns whethere or not entity type requirements are met for a plugin
--- @private
--- @param req table The full requirements table
--- @return boolean # Whethere or not entity type requirements are met
function Sexbound.Actor.PluginMgr:_checkRequirementForEntityType(req)
    if req.entityType then
        if "table" ~= type(req.entityType) then
            req.entityType = {req.entityType}
        end
        if not isEmpty(req.entityType) and util.count(req.entityType, self:getParent():getEntityType()) <= 0 then
            return false
        end
    end

    return true
end

--- [Helper] Returns whethere or not gender requirements are met for a plugin
--- @private
--- @param req table The full requirements table
--- @return boolean # Whethere or not gender requirements are met
function Sexbound.Actor.PluginMgr:_checkRequirementForGender(req)
    if req.gender then
        if "table" ~= type(req.gender) then
            req.gender = {req.gender}
        end
        if not isEmpty(req.gender) and util.count(req.gender, self:getParent():getGender()) <= 0 then
            return false
        end
    end

    return true
end

--- [Helper] Returns whethere or not entity name requirements are met for a plugin
--- @private
--- @param req table The full requirements table
--- @return boolean # Whethere or not entity name requirements are met
function Sexbound.Actor.PluginMgr:_checkRequirementForName(req)
    if req.name then
        if "table" ~= type(req.name) then
            req.name = {req.name}
        end
        if not isEmpty(req.name) and util.count(req.name, self:getParent():getName()) <= 0 then
            return false
        end
    end

    return true
end

--- [Helper] Returns whethere or not species requirements are met for a plugin
--- @private
--- @param req table The full requirements table
--- @return boolean # Whethere or not species requirements are met
function Sexbound.Actor.PluginMgr:_checkRequirementForSpecies(req)
    if req.species then
        if "table" ~= type(req.species) then
            req.species = {req.species}
        end
        if not isEmpty(req.species) and util.count(req.species, self:getParent():getSpecies()) <= 0 then
            return false
        end
    end

    return true
end

--- [Helper] Returns whethere or not entity uuid requirements are met for a plugin
--- @private
--- @param req table The full requirements table
--- @return boolean # Whethere or not entity uuid requirements are met
function Sexbound.Actor.PluginMgr:_checkRequirementForUniqueId(req)
    if req.uniqueId then
        if "table" ~= type(req.uniqueId) then
            req.uniqueId = {req.uniqueId}
        end
        if not isEmpty(req.uniqueId) and util.count(req.uniqueId, self:getParent():getUniqueId()) <= 0 then
            return false
        end
    end

    return true
end

--- Returns the full plugin config set
--- @return table # The full plugin config set
function Sexbound.Actor.PluginMgr:getConfig()
    return self._config
end

--- Returns a given plugin by name, if defined, or a list of plugins if none requested
--- @param name string? The name of the plugin to get
--- @return table<string, Sexbound.Actor.Plugin>|Sexbound.Actor.Plugin|nil # The requested plugin or nil if not defined, or all plugins if none requested
function Sexbound.Actor.PluginMgr:getPlugins(name)
    if name then
        return self._plugins[name]
    end

    return self._plugins
end

--- Returns if a given plugin by name is loaded
--- @param name string The name of the plugin to get
--- @return boolean # Whethere or not the requested plugin is loaded
function Sexbound.Actor.PluginMgr:getLoaded(name)
    if name then
        return self:getConfig()[name].loaded or false
    end

    return false
end

--- Returns this instance's logger
--- @return Sexbound.Log # The logging instance
function Sexbound.Actor.PluginMgr:getLog()
    return self._log
end

--- Returns parent actor instance
--- @return Sexbound.Actor # The parent actor instance
function Sexbound.Actor.PluginMgr:getParent()
    return self._parent
end

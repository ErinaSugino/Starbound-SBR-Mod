--- Sexbound.Actor.PluginMgr Class Module.
-- @classmod Sexbound.Actor.PluginMgr
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor.PluginMgr = {}
Sexbound.Actor.PluginMgr_mt = {
    __index = Sexbound.Actor.PluginMgr
}

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

function Sexbound.Actor.PluginMgr:_checkLoadRequirements(req)
    req = req or {}
    return self:_checkRequirementForEntityType(req) and self:_checkRequirementForGender(req) and
               self:_checkRequirementForName(req) and self:_checkRequirementForSpecies(req) and
               self:_checkRequirementForUniqueId(req)
end

function Sexbound.Actor.PluginMgr:_loadConfig(plugin)
    if "table" ~= type(plugin.config) then
        plugin.config = {plugin.config}
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

function Sexbound.Actor.PluginMgr:loadConfig()
    return self:getParent():getConfig().plugins
end

function Sexbound.Actor.PluginMgr:_loadPlugins()
    local plugins = {}

    util.each(self._config, function(index, plugin)
        plugin.loaded = false

        local canLoad = plugin.enable and self:_checkLoadRequirements(plugin.loadRequirements)

        if not canLoad then
            return
        end

        self:_initPlugin(plugins, plugin)
    end)

    return plugins
end

function Sexbound.Actor.PluginMgr:_initPlugin(plugins, plugin)
    self:_requireScripts(plugin)

    if Sexbound.Actor[plugin.name] then
        local key = string.lower(plugin.name)

        plugin.loaded = true

        plugins[key] = Sexbound.Actor[plugin.name]:new(self:getParent(), self:_loadConfig(plugin))
    end
end

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

function Sexbound.Actor.PluginMgr:getConfig()
    return self._config
end

function Sexbound.Actor.PluginMgr:getPlugins(name)
    if name then
        return self._plugins[name]
    end

    return self._plugins
end

function Sexbound.Actor.PluginMgr:getLoaded(name)
    if name then
        return self:getConfig()[name].loaded
    end

    return nil
end

function Sexbound.Actor.PluginMgr:getLog()
    return self._log
end

function Sexbound.Actor.PluginMgr:getParent()
    return self._parent
end

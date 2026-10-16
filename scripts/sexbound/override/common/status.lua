--- Entity status manager class
--- @class Sexbound.Common.Status
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _config table
--- @field _listeners {add: function[], remove: function[]}
--- @field _listenerIDs {add: integer[], remove: integer[]}
--- @field _listenerIDMax integer
Sexbound.Common.Status = {}
Sexbound.Common.Status_mt = {
    __index = Sexbound.Common.Status
}

--- Creates new entity status manager instance
--- @return Sexbound.Common.Status # The newly created entity status manager instance
function Sexbound.Common.Status:new()
    return setmetatable({
        _config = {
            statusList = {}
        },
        _listeners = {add={}, remove={}},
        _listenerIDs = {add={}, remove={}},
        _listenerIDMax = 0
    }, Sexbound.Common.Status_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Status:init(parent)
    self._parent = parent

    self._config.statusList = self:getParent()._speciesDefaultStatuses or {}

    storage.sexbound = storage.sexbound or {}
    storage.sexbound.identity = storage.sexbound.identity or {}
    local modifiers = storage.sexbound.identity.sxbNaturalStatus

    self:applyDiff(modifiers)

    self:setupMessageHandlers()
end

--- Sets up entity message handlers
function Sexbound.Common.Status:setupMessageHandlers()
    message.setHandler("Sexbound:Status:AddStatus", function(_, _, args)
        return self:addStatus(args)
    end)
    message.setHandler("Sexbound:Status:RemoveStatus", function(_, _, args)
        return self:removeStatus(args)
    end)
end

--- Changes the status list based off of a list of difference modifiers
--- @param mods string[]|string name or list of string names
function Sexbound.Common.Status:applyDiff(mods)
    if not mods then return end
    if type(mods) ~= "table" then mods = {mods} end

    for _,m in ipairs(mods) do
        local add = true
        if m:sub(1,1) == "-" then m = m:sub(2,-1) add = false end
        if add then self:addStatus(m, false) else self:removeStatus(m, false) end
    end
end

--- Adds a new status to this actor's status list.
--- @param statusName string Name of the status effect
--- @return boolean # True, cause why not
function Sexbound.Common.Status:addStatus(statusName, persistent)
    if persistent == nil then persistent = true end

    -- If status already exists, delete it first to re-insert it at the end (freshest status)
    local list = self:getStatusList() or {}
    local j,n = 0,#list
    for i=1,n do
        local s = list[i]
        if s == statusName then list[i] = nil
        else
            j = j + 1
            if i ~= j then list[j] = list[i] end
        end
    end
    list[j+1] = statusName

    if persistent then self:addPersistent(statusName) end

    for i,n in ipairs(self._listenerIDs.add) do
        local l = self._listeners.add[n]
        xpcall(function() l({query="add", name=statusName, isPersistent=persistent}) end, function(err) sb.logWarn("Error in #"..entity.id().."'s status listener") sb.logWarn(err) end)
    end

    return true
end

--- Adds a new persistent status
--- @param statusName string The name of the status
function Sexbound.Common.Status:addPersistent(statusName)
    local list = storage.sexbound.identity.sxbNaturalStatus or {}
    local j,n = 0,#list
    for i=1,n do
        local s = list[i]
        if s == statusName or s == "-"..statusName then list[i] = nil
        else
            j = j + 1
            if i ~= j then list[j] = list[i] end
        end
    end
    list[j+1] = statusName
    storage.sexbound.identity.sxbNaturalStatus = list
end

--- Returns whethere or not this entity has any one of the given statuses
--- @param statusNames string[] The list of status names to check for
--- @return boolean # Whethere or not any one of the statuses are present
function Sexbound.Common.Status:hasOneOf(statusNames)
    local statusList = self:getStatusList()

    for _, statusName in pairs(statusNames) do
        if util.count(statusList, statusName) >= 1 then
            return true
        end
    end

    return false
end

--- Returns wether or not this actor has specified statuses in its status list.
--- @param ... string The names of the statuses
--- @return boolean # Whethere or not all given statuses are present
function Sexbound.Common.Status:hasStatus(...)
    local args = {...}
    local statusList = self:getStatusList()

    for _, statusName in pairs(args) do
        if util.count(statusList, statusName) == 0 then
            return false
        end
    end

    return true
end

--- Returns a specified status name if it is found.
--- @param statusName string The name of the status
--- @return string? # The status name if it exists, nil if not
function Sexbound.Common.Status:findStatus(statusName)
    if self:hasStatus(statusName) then
        return statusName
    end
end

--- Removes a specified status from this actor's status list.
--- @param statusName string The status name to remove
--- @param persistent boolean? Whethere or not this is a persistent removal (Default: true)
--- @return boolean # Whethere or not status was successfully removed
function Sexbound.Common.Status:removeStatus(statusName, persistent)
    if persistent == nil then persistent = true end

    for index, status in ipairs(self:getStatusList()) do
        if (status == statusName) then
            table.remove(self._config.statusList, index)
            if persistent then self:removePersistent(statusName) end
            for i,n in ipairs(self._listenerIDs.remove) do
                local l = self._listeners.remove[n]
                xpcall(function() l({query="remove", name=statusName, isPersistent=persistent}) end, function(err) sb.logWarn("Error in #"..entity.id().."'s status listener") sb.logWarn(err) end)
            end
            return true
        end
    end

    return false
end

--- Persistently removes a status
--- @param statusName string The name of the status to remove
function Sexbound.Common.Status:removePersistent(statusName)
    local list = storage.sexbound.identity.sxbNaturalStatus or {}
    local j,n = 0,#list
    for i=1,n do
        local s = list[i]
        if s == statusName or s == "-"..statusName then list[i] = nil
        else
            j = j + 1
            if i ~= j then list[j] = list[i] end
        end
    end
    list[j+1] = "-"..statusName
    storage.sexbound.identity.sxbNaturalStatus = list
end

--- Adds a callback to be called when a status is changed
--- @param query string "add" or "remove", where it should be triggered
--- @param callback fun(table) The callback to register as event handler
--- @return integer? # The callback ID to later remove, if successfully added
function Sexbound.Common.Status:addEventListener(query, callback)
    if type(query) ~= "string" or type(callback) ~= "function" then return end
    if not self._listeners[query] then return end
    self._listenerIDMax = self._listenerIDMax + 1
    self._listeners[query][self._listenerIDMax] = callback
    table.insert(self._listenerIDs[query], self._listenerIDMax)

    return self._listenerIDMax
end

--- Removes a callback registered as status change handler
--- @param query string "add" or "name", where the callback was registered
--- @param id number ID of the callback when it was registered
--- @return boolean # Whethere or not the callback was successfully removed
function Sexbound.Common.Status:removeEventListener(query, id)
    if type(query) ~= "string" or type(id) ~= "number" then return false end
    if not self._listeners[query] then return false end
    if not self._listeners[query][id] then return false end

    self._listeners[query][id] = nil
    for i,j in ipairs(self._listenerIDs[query]) do
        if j == id then table.remove(self._listenerIDs[query], i) break end
    end

    return true
end

--- Function called each tick to do nothing
--- @param dt number The delta time since last tick
function Sexbound.Common.Status:update(dt) end

--- Returns the parent entity handler instance
--- @return Sexbound.Common # The parent entity handler instance
function Sexbound.Common.Status:getParent()
    return self._parent or {}
end

--- Returns a reference to this actor's status list as a table.
--- @return table # All currently applied statuses
function Sexbound.Common.Status:getStatusList()
    return self._config.statusList
end

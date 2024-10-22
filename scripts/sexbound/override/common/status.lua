Sexbound.Common.Status = {}
Sexbound.Common.Status_mt = {
    __index = Sexbound.Common.Status
}

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

--- Initializes the plugin for use.
-- @param parent
-- @param[opt] callback
function Sexbound.Common.Status:init()
    self._config.statusList = self:getParent()._speciesDefaultStatuses or {}
    
    storage.sexbound = storage.sexbound or {}
    storage.sexbound.identity = storage.sexbound.identity or {}
    local modifiers = storage.sexbound.identity.sxbNaturalStatus
    
    self:applyDiff(modifiers)
    
    self:setupMessageHandlers()
end

function Sexbound.Common.Status:setupMessageHandlers()
    message.setHandler("Sexbound:Status:AddStatus", function(_, _, args)
        return self:addStatus(args)
    end)
    message.setHandler("Sexbound:Status:RemoveStatus", function(_, _, args)
        return self:removeStatus(args)
    end)
end

--- Changes the status list based off of a list of difference modifiers
-- @param mods String name or list of string names
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
-- @param statusName As a string.
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

    if statusName == "canBeDefeated" or statusName == "canDefeatOthers" then
        status.setStatusProperty(statusName, true)
    end
    
    return true
end

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

function Sexbound.Common.Status:hasOneOf(statusNames)
    local statusList = self:getStatusList()

    for _, statusName in pairs(statusNames) do
        if util.count(statusList, statusName) >= 1 then
            return true
        end
    end

    return false
end

--- Returns wether or not this actor has a specified status in its status list.
-- @param statusName
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
-- @param statusName
function Sexbound.Common.Status:findStatus(statusName)
    if self:hasStatus(statusName) then
        return statusName
    end
end

--- Removes a specified status from this actor's status list.
-- @param statusName
function Sexbound.Common.Status:removeStatus(statusName, persistent)
    if persistent == nil then persistent = true end

    if statusName == "canBeDefeated" or statusName == "canDefeatOthers" then
        status.setStatusProperty(statusName, false)
    end
    
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

function Sexbound.Common.Status:addEventListener(query, callback)
    if type(query) ~= "string" or type(callback) ~= "function" then return end
    if not self._listeners[query] then return end
    self._listenerIDMax = self._listenerIDMax + 1
    self._listeners[query][self._listenerIDMax] = callback
    table.insert(self._listenerIDs[query], self._listenerIDMax)
    
    return self._listenerIDMax
end

function Sexbound.Common.Status:removeEventListener(query, id)
    if type(query) ~= "string" or type(callback) ~= "function" then return false end
    if not self._listeners[query] then return false end
    if not self._listeners[query][id] then return false end
    
    self._listeners[query][id] = nil
    for i,j in ipairs(self._listenerIDs[query]) do
        if j == id then table.remove(self._listenerIDs[query], i) break end
    end
    
    return true
end

function Sexbound.Common.Status:update(dt)
    
end

function Sexbound.Common.Status:getParent()
    return self._parent or {}
end

--- Returns a reference to this actor's status list as a table.
function Sexbound.Common.Status:getStatusList()
    return self._config.statusList
end

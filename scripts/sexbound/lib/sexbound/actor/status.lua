--- Sexbound.Actor.Status Class Module.
-- @classmod Sexbound.Actor.Status
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor.Status = {}
Sexbound.Actor.Status_mt = {
    __index = Sexbound.Actor.Status
}

function Sexbound.Actor.Status:new(parent)
    return setmetatable({
        _config = {
            statusList = {"default"}
        },
        _parent = parent,
        _timers = {}
    }, Sexbound.Actor.Status_mt)
end

--- Initializes the plugin for use.
-- @param parent
-- @param[opt] callback
function Sexbound.Actor.Status:init(parent, callback)
    self._parent = parent or {}

    if type(callback) == "function" then
        callback()
    end
end

--- Adds a new status to this actor's status list.
-- @param statusName As a string.
-- @param[opt] duration As a number.
function Sexbound.Actor.Status:addStatus(statusName, duration, delay)
    local orgDelay = delay
    if delay == nil then delay = true end
    if duration then
        self._timers[statusName] = duration
    end

    -- If status already exists, delete it first to re-insert it at the end (freshest status)
    
    --[[for index, status in ipairs(self:getStatusList()) do
        if (status == statusName) then
            table.remove(self._config.statusList, index)
            break
        end
    end]]

    --table.insert(self._config.statusList, statusName)
    
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

    Sexbound.Messenger.get("main"):send(self, self._parent, "Sexbound:Status:AddStatus", statusName, delay)
end

function Sexbound.Actor.Status:hasOneOf(statusNames)
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
function Sexbound.Actor.Status:hasStatus(...)
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
function Sexbound.Actor.Status:findStatus(statusName)
    if self:hasStatus(statusName) then
        return statusName
    end
end

--- Removes a specified status from this actor's status list.
-- @param statusName
function Sexbound.Actor.Status:removeStatus(statusName, delay)
    if delay == nil then delay = true end
    for index, status in ipairs(self:getStatusList()) do
        if (status == statusName) then
            Sexbound.Messenger.get("main"):send(self, self._parent, "Sexbound:Status:RemoveStatus", statusName, delay)
            table.remove(self._config.statusList, index)
            return true
        end
    end

    return false
end

function Sexbound.Actor.Status:forEachTimer(callback)
    for statusName, statusTime in pairs(self._timers) do
        callback(statusName, statusTime)
    end
end

function Sexbound.Actor.Status:update(dt)
    if isEmpty(self._timers) then
        return
    end

    self:forEachTimer(function(statusName, statusTime)
        if statusTime ~= nil and statusTime > 0 then
            self._timers[statusName] = statusTime - dt
        end
    end)

    self:forEachTimer(function(statusName, statusTime)
        if statusTime ~= nil and statusTime <= 0 then
            self:removeStatus(statusName)
            self._timers[statusName] = nil
        end
    end)
end

function Sexbound.Actor.Status:getParent()
    return self._parent or {}
end

--- Returns a reference to this actor's status list as a table.
function Sexbound.Actor.Status:getStatusList()
    return self._config.statusList
end

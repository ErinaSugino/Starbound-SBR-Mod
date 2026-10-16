--- Sexbound.Actor.Status Class Module.
--- @class Sexbound.Actor.Status
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _config table
--- @field private _timers table<string, number>
Sexbound.Actor.Status = {}
Sexbound.Actor.Status_mt = {
    __index = Sexbound.Actor.Status
}

--- Creates new status manager instance
--- @param parent Sexbound.Actor The calling parent actor instance
--- @return Sexbound.Actor.Status # The newly creates status manager instance
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
--- @param parent Sexbound.Actor No clue why we reset this again, Loc
--- @param callback function? A callback to call when init is done
function Sexbound.Actor.Status:init(parent, callback)
    self._parent = parent or {}

    if type(callback) == "function" then
        callback()
    end
end

--- Adds a new status to this actor's status list.
--- @param statusName string The name of the status to set
--- @param duration number? Duration of the status effect or nil if forever
--- @param delay boolean? Whethere or not to delay notifying about the status effect (Default: true)
function Sexbound.Actor.Status:addStatus(statusName, duration, delay)
    if delay == nil then delay = true end
    if duration then
        self._timers[statusName] = duration
    end

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

    Sexbound.Messenger.get("main"):send(self, self._parent, "Sexbound:Status:AddStatus", statusName, delay)
end

--- Returns whethere any one of the given list of status effects is present
--- @param statusNames table<integer|string, string>
--- @return boolean # Whethere or not any one of the given names is present
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
--- @param ... string The list of status names
--- @return boolean # Whethere or not all given statuses are set
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
--- @param statusName string The requested status effect
--- @return string? # The name if found or nil if not
function Sexbound.Actor.Status:findStatus(statusName)
    if self:hasStatus(statusName) then
        return statusName
    end
end

--- Removes a specified status from this actor's status list.
--- @param statusName string The status name to remove
--- @param delay boolean? Whethere or not to delay notifying the removal (Default: true)
--- @return boolean # Whethere or not the status was removed successfully
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

--- Execute a callback for each ticking timer
--- @param callback fun(string, number) The callback to execute, given status name and remaining timer time
function Sexbound.Actor.Status:forEachTimer(callback)
    for statusName, statusTime in pairs(self._timers) do
        callback(statusName, statusTime)
    end
end

--- Function called each tick to progress timers
--- @param dt number The delta time since last tick
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

--- Returns the parent actor instance
--- @return Sexbound.Actor # The parent actor instance
function Sexbound.Actor.Status:getParent()
    return self._parent or {}
end

--- Returns a reference to this actor's status list as a table.
--- @return table<integer, string> # The list of all set statuses
function Sexbound.Actor.Status:getStatusList()
    return self._config.statusList
end

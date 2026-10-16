--- Abstract shared entity statistics manager class
--- @class Sexbound.Common.Statistics
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _config table
--- @field _eventHandlers table
--- @field _firstTimeHandlers table
Sexbound.Common.Statistics = {}
Sexbound.Common.Statistics_mt = {
    __index = Sexbound.Common.Statistics
}

--- Creates new entity statistics instance
--- @return Sexbound.Common.Statistics # The newly created entity statistics instance
function Sexbound.Common.Statistics:new()
    return setmetatable({
        _eventHandlers = {},
        _firstTimeHandlers = {}
    }, Sexbound.Common.Statistics_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Statistics:init(parent)
    self._parent = parent
    storage.sexbound.statistics = storage.sexbound.statistics or {}
    self:initMessageHandlers()
end

--- Sets up entity message handlers
function Sexbound.Common.Statistics:initMessageHandlers()
    message.setHandler("Sexbound:Statistics:Add", function(_, _, args)
        return self:handleAddStatistic(args)
    end)
end

--- Message handler for incrementing a statistics value
--- @param args table The message arguments
--- @return number # The current value of the statistic or nil on failure
function Sexbound.Common.Statistics:handleAddStatistic(args)
    return self:addStatistic(args.name, args.amount)
end

--- Increments a statisitcs value
--- @param name string The statistic's name
--- @param amount number The value to add to statistic
--- @return number # The new value of the statistic or nil on failure
function Sexbound.Common.Statistics:addStatistic(name, amount)
    if not name then return 0 end
    local statistics = copy(storage.sexbound.statistics)
    statistics[name] = (statistics[name] or 0)
    if statistics[name] == 0 and amount > 0 then self:triggerFirstTime(name) end
    statistics[name] = statistics[name] + amount
    storage.sexbound.statistics = statistics
    self:triggerEvent(name)
    return storage.sexbound.statistics[name] or 0
end

--- Gets the current value of a given statistic
--- @param name string The name of the statistic
--- @return number # The current value of the statistic
function Sexbound.Common.Statistics:getStatistic(name)
    return storage.sexbound.statistics[name] or 0
end

--- Returns the list of all known statistics
--- @return number[] # The list of all statistics
function Sexbound.Common.Statistics:getStatistics()
    return storage.sexbound.statistics
end

--- Function to add an event handler for statistic increment
--- @param statName string The name of the statistic incrementing
--- @param handler function The event handler callback
--- @param first boolean Whethere or not to trigger only when the statistic is incremented for the first time
function Sexbound.Common.Statistics:addEventHandler(statName, handler, first)
    local pool = self._eventHandlers
    if first then pool = self._firstTimeHandlers end
    pool[statName] = pool[statName] or {}
    table.insert(pool[statName], handler)
end

--- Function to trigger reactions when a stat is raised
--- @param s string The statistic's name
function Sexbound.Common.Statistics:triggerEvent(s)
    if not self._eventHandlers[s] then return end
    for _,c in ipairs(self._eventHandlers[s]) do
        r,e = pcall(c)
        if not r then sb.logError("Error in statistic event handler: "..tostring(e)) end
    end
end

--- Function to trigger reactions when a stat is raised for the first time
--- @param s string The statistic's name
function Sexbound.Common.Statistics:triggerFirstTime(s)
    if not self._firstTimeHandlers[s] then return end
    for _,c in ipairs(self._firstTimeHandlers[s]) do
        r,e = pcall(c)
        if not r then sb.logError("Error in statistic event handler: "..tostring(e)) end
    end
end

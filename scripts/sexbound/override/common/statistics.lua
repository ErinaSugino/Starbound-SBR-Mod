Sexbound.Common.Statistics = {}
Sexbound.Common.Statistics_mt = {
    __index = Sexbound.Common.Statistics
}

function Sexbound.Common.Statistics:new()
    return setmetatable({
        _eventHandlers = {},
        _firstTimeHandlers = {}
    }, Sexbound.Common.Statistics_mt)
end

function Sexbound.Common.Statistics:init(parent)
    self._parent = parent
    storage.sexbound.statistics = storage.sexbound.statistics or {}
    self:initMessageHandlers()
end

function Sexbound.Common.Statistics:initMessageHandlers()
    message.setHandler("Sexbound:Statistics:Add", function(_, _, args)
        return self:handleAddStatistic(args)
    end)
end

function Sexbound.Common.Statistics:handleAddStatistic(args)
    return self:addStatistic(args.name, args.amount)
end

function Sexbound.Common.Statistics:addStatistic(name, amount)
    if not name then return end
    local statistics = copy(storage.sexbound.statistics)
    statistics[name] = (statistics[name] or 0)
    if statistics[name] == 0 and amount > 0 then self:triggerFirstTime(name) end
    statistics[name] = statistics[name] + amount
    storage.sexbound.statistics = statistics
    self:triggerEvent(name)
    return storage.sexbound.statistics[name]
end

function Sexbound.Common.Statistics:getStatistic(name)
    return storage.sexbound.statistics[name]
end

function Sexbound.Common.Statistics:getStatistics()
    return storage.sexbound.statistics
end

--- Function to add an event handler
function Sexbound.Common.Statistics:addEventHandler(statName, handler, first)
    local pool = self._eventHandlers
    if first then pool = self._firstTimeHandlers end
    pool[statName] = pool[statName] or {}
    table.insert(pool[statName], handler)
end

--- Function to trigger reactions when a stat is raised
function Sexbound.Common.Statistics:triggerEvent(s)
    if not self._eventHandlers[s] then return end
    for _,c in ipairs(self._eventHandlers[s]) do
        r,e = pcall(c)
        if not r then sb.logError("Error in statistic event handler: "..tostring(e)) end
    end
end

--- Function to trigger reactions when a stat is raised for the first time
function Sexbound.Common.Statistics:triggerFirstTime(s)
    if not self._firstTimeHandlers[s] then return end
    for _,c in ipairs(self._firstTimeHandlers[s]) do
        r,e = pcall(c)
        if not r then sb.logError("Error in statistic event handler: "..tostring(e)) end
    end
end

--- Sexbound.Log Class Module.
--- @class Sexbound.Log
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _config table
--- @field _logPrefix string
Sexbound.Log = {}
Sexbound.Log_mt = {
    __index = Sexbound.Log
}

--- Returns a reference to a new instance of this class.
--- @param logPrefix string A four letters prefix code
--- @param sexboundConfig table Global logging configuration
--- @return Sexbound.Log
function Sexbound.Log:new(logPrefix, sexboundConfig)
    return setmetatable({
        _config = sexboundConfig.log or {},
        _logPrefix = logPrefix or "???"
    }, Sexbound.Log_mt)
end

--- Logs specified data as an debug message.
--- @param data string|table A string or table to log
function Sexbound.Log:debug(data)
    if self._config.showDebug ~= true then
        return
    end
    sb.logInfo(self:_prepare(data))
end

--- Logs specified data as an error.
--- @param data string|table A string or table to log
function Sexbound.Log:error(data)
    if self._config.showError ~= true and self._config.showDebug ~= true then
        return
    end
    sb.logError(self:_prepare(data))
end

--- Logs specified data as an informational message.
--- @param data string|table A string or table to log
function Sexbound.Log:info(data)
    if self._config.showInfo ~= true and self._config.showDebug ~= true then
        return
    end
    sb.logInfo(self:_prepare(data))
end

--- Logs specified data as a warning.
--- @param data string|table A string or table to log
function Sexbound.Log:warn(data)
    if self._config.showWarn ~= true and self._config.showDebug ~= true then
        return
    end
    sb.logWarn(self:_prepare(data))
end

--- Prepares specified data to be logged.
--- @private
--- @param data string|table A string or table to log
--- @return string # The prepared logging content
function Sexbound.Log:_prepare(data)
    local pretext = "[SxB | " .. self:getLogPrefix() .. "] : "
    if type(data) == "string" then
        return pretext .. data
    end
    if type(data) == "table" then
        return pretext .. sb.printJson(data)
    end
    return pretext .. "Unable to display log data."
end

--- Returns a reference to this instance's config.
--- @return table # The logging config
function Sexbound.Log:getConfig()
    return self._config
end

--- Returns a reference to this instance's log prefix.
--- @return string # This logger's prefix
function Sexbound.Log:getLogPrefix()
    return self._logPrefix
end

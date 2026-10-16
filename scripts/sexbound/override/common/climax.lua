--- Abstract shared entity climax manager class
--- @class Sexbound.Common.Climax
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _config table
--- @field _regenRate number
Sexbound.Common.Climax = {}
Sexbound.Common.Climax_mt = {
    __index = Sexbound.Common.Climax
}

--- Creates a new entity climax manager instance
--- @return Sexbound.Common.Climax # The newly created entity climax manager instance
function Sexbound.Common.Climax:new()
    return setmetatable({}, Sexbound.Common.Climax_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Climax:init(parent)
    self._parent = parent

    self._config = config.getParameter("climaxConfig", {
        regenRates = {
            default = {-0.5, -2.0},
            havingSex = {0.0, 0.0}
        }
    })

    self._regenRate = self._config.regenRates.default
end

--- Function called each tick to update timers
--- @param dt number The delta time since last tick
function Sexbound.Common.Climax:update(dt)
    if status.isResource("climax") then
        status.modifyResource("climax", util.randomInRange(self._regenRate) * dt)
    end
end

--- Returns the current climax delta rate
--- @return number # The current climax delta rate
function Sexbound.Common.Climax:regenRate()
    return self._regenRate
end

--- Returns the current climax value
--- @return number # The current climax value
function Sexbound.Common.Climax:getCurrentValue()
    if status.isResource("climax") then
        return status.resource("climax")
    end

    return 0
end

--- Sets the current climax value
--- @param newValue number The new climax value
function Sexbound.Common.Climax:setCurrentValue(newValue)
    if type(newValue) ~= "number" then
        return
    end

    if status.isResource("climax") then
        status.setResource("climax", newValue)
    end
end

--- Sets the climax delta rate based on pre-defined mode
--- @param keyValue string The pre-defined climax rate mode ("default" or "havingSex")
function Sexbound.Common.Climax:setRegenRate(keyValue)
    if keyValue ~= nil then
        self._regenRate = self._config.regenRates[keyValue]
    end
end

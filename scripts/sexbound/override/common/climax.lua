Sexbound.Common.Climax = {}
Sexbound.Common.Climax_mt = {
    __index = Sexbound.Common.Climax
}

function Sexbound.Common.Climax:new()
    return setmetatable({}, Sexbound.Common.Climax_mt)
end

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

function Sexbound.Common.Climax:update(dt)
    if status.isResource("climax") then
        status.modifyResource("climax", util.randomInRange(self._regenRate) * dt)
    end
end

function Sexbound.Common.Climax:regenRate()
    return self._regenRate
end

function Sexbound.Common.Climax:getCurrentValue()
    if status.isResource("climax") then
        return status.resource("climax")
    end
end

function Sexbound.Common.Climax:setCurrentValue(newValue)
    if type(newValue) ~= "number" then
        return
    end

    if status.isResource("climax") then
        status.setResource("climax", newValue)
    end
end

function Sexbound.Common.Climax:setRegenRate(keyValue)
    if keyValue ~= nil then
        self._regenRate = self._config.regenRates[keyValue]
    end
end

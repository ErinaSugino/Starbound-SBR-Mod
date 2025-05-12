Sexbound.Common.Arousal = {}
Sexbound.Common.Arousal_mt = { __index = Sexbound.Common.Arousal }

--- Instantiates this class
function Sexbound.Common.Arousal:new()
    return setmetatable({
        _resourceName = "arousal",
        _multiplierName = "arousalMult"
    }, Sexbound.Common.Arousal_mt)
end

--- Initializes this instance
-- @param parent
function Sexbound.Common.Arousal:init(parent, seed)
    self._parent = parent
    self._usesHeat = parent._usesHeat or false
    seed = seed or os.time()
    arousalRate = parent:getConfig().sex.naturalHorninessRate
    if type(arousalRate) == "table" then
        local rng = sb.makeRandomSource(seed)
        local roll = rng:randf()
        arousalRate = arousalRate[1] + (arousalRate[2]-arousalRate[1]) * roll
    end
    self._defaultConfig = {regenRates = {default = arousalRate, havingSex = 0.0}}
    self._config = config.getParameter("arousalConfig", self._defaultConfig)
    if not self._config.regenRates then self._config.regenRates = self._defaultConfig.regenRates end
    if not self._config.regenRates.default then self._config.regenRates.default = self._defaultConfig.regenRates.default end
    if not self._config.regenRates.havingSex then self._config.regenRates.havingSex = self._defaultConfig.regenRates.havingSex end
    self._maxAmount = status.stat("maxArousal") or 100
    self._regenRate = self._config.regenRates.default
    if self._parent:canLog("debug") then sb.logInfo("Entity #"..entity.id().."'s current arousal gain is "..tostring(self._regenRate)) end
    
    local parentConfig = self._parent._config or {}
    local sexConfig = parentConfig.sex or {}
    self._config.playerArousalEffects = sexConfig.playerArousalEffects or false
    self._config.heatCycleLength = sexConfig.heatCycleLength or {10,30}
    
    self:initMessageHandlers()
end

--- Updates this instance
-- @param dt
function Sexbound.Common.Arousal:update(dt)
    self:try(function()
        if not self._parent._isKid then self:addAmount(self._regenRate * dt) end
    end)
end

--- Sets value of Arousal resource to 0
-- @return a boolean value
function Sexbound.Common.Arousal:instaMin()
    local result = false
    self:try(function()
        self:setAmount(0)
        result = true
    end)
    return result
end

--- Sets value of Arousal resource to entity's defined maxArousal stat
-- @return a boolean value
function Sexbound.Common.Arousal:instaMax()
    if self._parent._isKid then return false end
    
    local result = false
    self:try(function()
        self:setAmount(self._maxAmount)
        result = true
    end)
    return result
end

--- Reduces the value of this entity's arousal resource by specified percentage
-- @param percentage a decimal number. e.g. 0.1
-- @return a decimal number
function Sexbound.Common.Arousal:reduce(percentage)
    self:try(function()
        local maximumAmount = self:getMaxAmount()
        local currentAmount = self:getAmount() - (maximumAmount * percentage)
        self:setAmount(math.max(currentAmount, 0))
        return self:getAmount()
    end)
end

--- Returns boolean value to signify whether or not the arousal resource exists
-- @return a boolean value
function Sexbound.Common.Arousal:isResourceDefined()
    return status.isResource(self._resourceName)
end

--- Adds an amount to this entity's arousal resource
-- @param amount a decimal number
function Sexbound.Common.Arousal:addAmount(amount)
    if self._parent._isKid then return end
    
    -- Account for environmental multiplier
    local mult = status.stat(self._multiplierName)
    if mult > 0 then amount = amount * mult end
    status.modifyResource(self._resourceName, amount)
end

--- Returns the value of this entity's arousal resource
-- @return a decimal number
function Sexbound.Common.Arousal:getAmount()
    if self._parent._isKid then return 0
    else return status.resource(self._resourceName) end
end

--- Sets an amount to this entity's arousal resource
-- @param amount a decimal number
function Sexbound.Common.Arousal:setAmount(amount)
    if self._parent._isKid then return end
    
    status.setResource(self._resourceName, amount)
end

--- Returns the value of this entity's maximum arousal resource stat
-- @return a decimal number
function Sexbound.Common.Arousal:getMaxAmount()
    return self._maxAmount
end

--- Returns a reference to the configuration of this class instance
-- @return a table
function Sexbound.Common.Arousal:getConfig()
    return self._config
end

--- Returns a reference to the parent of this class instance
-- @return a table
function Sexbound.Common.Arousal:getParent()
    return self._parent
end

--- Returns the value of this entity's regen rate for the arousal resource
-- @return a decimal number
function Sexbound.Common.Arousal:getRegenRate()
    return self._regenRate
end

--- Sets the value of this entity's regen rate as specified name key
-- @param name e.g. default, havingSex
function Sexbound.Common.Arousal:setRegenRate(name)
    self._regenRate = self._config.regenRates[name]
    if self._parent:canLog("debug") then sb.logInfo("Entity #"..entity.id().."'s current arousal regen is "..tostring(self._regenRate)) end
end

-- [Helper] Initializes message handlers
function Sexbound.Common.Arousal:initMessageHandlers()
    -- Legacy message handler: sexbound-max-arousal
    message.setHandler("sexbound-max-arousal", function(_, _, args)
        return self:instaMax()
    end)
    message.setHandler("Sexbound:Arousal:Max", function(_, _, args)
        return self:instaMax()
    end)
    message.setHandler("Sexbound:Arousal:Min", function(_, _, args)
        return self:instaMin()
    end)
    message.setHandler("Sexbound:Arousal:Reduce", function(_, _, args)
        return self:reduce(args.amount)
    end)
end

-- [Helper] Convience function to check existence of arousal resource before callback
-- @param callback
-- @return a boolean value
function Sexbound.Common.Arousal:try(callback)
    if not self:isResourceDefined() then return false end
    return callback()
end

-- [Deprecated] Returns a reference to the configuration of this class instance
-- @return a table
function Sexbound.Common.Arousal:config()
    return self:getConfig()
end

-- [Deprecated] Returns the value of this entity's regen rate for the arousal resource
-- @return a decimal number
function Sexbound.Common.Arousal:regenRate()
    return self:getRegenRate()
end

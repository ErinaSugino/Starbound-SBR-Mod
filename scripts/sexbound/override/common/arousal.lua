--- Abstract shared entity arousal manager class
--- @class Sexbound.Common.Arousal
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _defaultConfig table
--- @field _config table
--- @field _usesHeat boolean
--- @field _maxAmount number
--- @field _regenRate number
--- @field _resourceName string
--- @field _multiplierName string
Sexbound.Common.Arousal = {}
Sexbound.Common.Arousal_mt = { __index = Sexbound.Common.Arousal }

--- Creates new entity arousal manager instance
--- @return Sexbound.Common.Arousal # The newly created entity arousal manager instance
function Sexbound.Common.Arousal:new()
    return setmetatable({
        _resourceName = "arousal",
        _multiplierName = "arousalMult"
    }, Sexbound.Common.Arousal_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
--- @param seed string|integer|nil The RNG seed for this entity
function Sexbound.Common.Arousal:init(parent, seed)
    self._parent = parent
    self._usesHeat = parent._usesHeat or false
    seed = seed or os.time()
    arousalRate = parent:getConfig().sex.naturalHorninessRate
    if type(arousalRate) == "table" then
        local rng = sb.makeRandomSource(tonumber(seed) or 1234)
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

--- Function called each tick to update timers
--- @param dt number The delta time since last tick
function Sexbound.Common.Arousal:update(dt)
    self:try(function()
        if not (self._parent --[[@as Sexbound.NPC]])._isKid then self:addAmount(self._regenRate * dt) end
    end)
end

--- Sets value of Arousal resource to 0
--- @return boolean # Whethere or not this was successful
function Sexbound.Common.Arousal:instaMin()
    local result = false
    self:try(function()
        self:setAmount(0)
        result = true
    end)
    return result
end

--- Sets value of Arousal resource to entity's defined maxArousal stat
--- @return boolean # Whethere or not this was successful
function Sexbound.Common.Arousal:instaMax()
    if (self._parent --[[@as Sexbound.NPC]])._isKid then return false end

    local result = false
    self:try(function()
        self:setAmount(self._maxAmount)
        result = true
    end)
    return result
end

--- Reduces the value of this entity's arousal resource by specified percentage
--- @param percentage number The percentage 0..1
--- @return number # The new current value for verification purposes
function Sexbound.Common.Arousal:reduce(percentage)
    self:try(function()
        local maximumAmount = self:getMaxAmount()
        local currentAmount = self:getAmount() - (maximumAmount * percentage)
        self:setAmount(math.max(currentAmount, 0))
    end)
    return self:getAmount()
end

--- Returns whether or not the arousal resource exists
--- @return boolean # Whethere or not the resource is defined
function Sexbound.Common.Arousal:isResourceDefined()
    return status.isResource(self._resourceName)
end

--- Adds an amount to this entity's arousal resource
--- @param amount number The amount to add
function Sexbound.Common.Arousal:addAmount(amount)
    if (self._parent --[[@as Sexbound.NPC]])._isKid then return end

    -- Account for environmental multiplier
    local mult = status.stat(self._multiplierName)
    if mult > 0 then amount = amount * mult end
    status.modifyResource(self._resourceName, amount)
end

--- Returns the value of this entity's arousal resource
--- @return number # The current amount
function Sexbound.Common.Arousal:getAmount()
    if (self._parent --[[@as Sexbound.NPC]])._isKid then return 0
    else return status.resource(self._resourceName) end
end

--- Sets an amount to this entity's arousal resource
--- @param amount number The new amount
function Sexbound.Common.Arousal:setAmount(amount)
    if (self._parent._isKid --[[@as Sexbound.NPC]]) then return end

    status.setResource(self._resourceName, amount)
end

--- Returns the value of this entity's maximum arousal resource stat
--- @return number # The maximum arousal value
function Sexbound.Common.Arousal:getMaxAmount()
    return self._maxAmount
end

--- Returns a reference to the configuration of this class instance
--- @return table # The arousal plugin config
function Sexbound.Common.Arousal:getConfig()
    return self._config
end

--- Returns a reference to the parent of this class instance
--- @return Sexbound.Common # The parent entity manager instance
function Sexbound.Common.Arousal:getParent()
    return self._parent
end

--- Returns the value of this entity's regen rate for the arousal resource
--- @return number # The currently set delta rate
function Sexbound.Common.Arousal:getRegenRate()
    return self._regenRate
end

--- Sets the value of this entity's regen rate as specified name key
--- @param name string The category name ("default", "havingSex")
function Sexbound.Common.Arousal:setRegenRate(name)
    self._regenRate = self._config.regenRates[name] or 0
    if self._parent:canLog("debug") then sb.logInfo("Entity #"..entity.id().."'s current arousal regen is "..tostring(self._regenRate)) end
end

--- [Helper] Initializes message handlers
--- @protected
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

--- [Helper] Convience function to check existence of arousal resource before callback
--- @param callback function The function to safely execute
--- @return any # False if resource is not defined, whatever the callback returns otherwise
function Sexbound.Common.Arousal:try(callback)
    if not self:isResourceDefined() then return false end
    return callback()
end

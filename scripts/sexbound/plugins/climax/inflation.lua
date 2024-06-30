Inflation = {}
Inflation_mt = {
    __index = Inflation
}

function Inflation:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "INFL",
        _parent = parent,
        _config = config,
        _actor = {},
        _log = {},
        _defaultLiquidId = config.projectileLiquid["default"]["male"] or "semen",
        _loads = {},
        _loadCount = 0,
        _totalInflation = 0
    }, Inflation_mt)

    _self._log = Sexbound.Log:new(_self._logPrefix, _self._parent:getRoot():getConfig())
    _self._actor = _self._parent._parent
    _self:getLog():info("Inited Inflation Tracker for ".._self:getActorLogPrefix())

    return _self
end

function Inflation:addLoad(inflationLoad)
    inflationLoad = {
        liquid = inflationLoad.liquid or self._defaultLiquidId,
        quantity = inflationLoad.quantity or 0
    }
    if inflationLoad.quantity <= 0 then return end

    self:getLog():debug(self:getActorLogPrefix().." received inflation load. "..
                        "Liquid: ["..inflationLoad.liquid.."] "..
                        "Quantity: ["..inflationLoad.quantity.."]")

    -- Add to the last load if it has the same liquid id
    if self._loadCount > 0 and self._loads[self._loadCount].liquid == inflationLoad.liquid then
        local currentQuantity = self._loads[self._loadCount].quantity
        local mergedQuantity = currentQuantity + inflationLoad.quantity
        self._loads[self._loadCount].quantity = mergedQuantity

        self:getLog():debug(self:getActorLogPrefix().." same liquid as previous; merging loads. "..
                            "Previous load quantity: ["..currentQuantity.."] "..
                            "Merged quantity: ["..mergedQuantity.."]")

    else
        self:getLog():debug(self:getActorLogPrefix().." liquid is different from previous load; adding new load.")

        self._loadCount = self._loadCount + 1
        self._loads[self._loadCount] = inflationLoad
    end

    self._totalInflation = self._totalInflation + inflationLoad.quantity

    self:getLog():debug(self:getActorLogPrefix().." has ["..self:getloadCount().."] inflation loads. "..
                        "Total inflation: [".. self:getTotalInflation().."]")
end

function Inflation:removeQuantity(quantity)
    if self._totalInflation <= 0 or self._loadCount <= 0 then return end

    local toRemove = quantity or 0
    local removedLiquids = {}
    while toRemove > 0 and self._loadCount > 0 do
        local lastLoadQuantity = self._loads[self._loadCount].quantity
        self:getLog():debug(self:getActorLogPrefix().." removing ["..toRemove.."] to total inflation.")
        self:getLog():debug(self:getActorLogPrefix().." load #"..self._loadCount.." contributes ["..lastLoadQuantity.."] to total inflation.")
        
        if toRemove < lastLoadQuantity then
            self:getLog():debug(self:getActorLogPrefix().." removing ["..toRemove.."] from load #"..self._loadCount)
            
            -- Add to removed liquid quantity
            local currentlyRemoved = removedLiquids[self._loads[self._loadCount].liquid] or 0
            removedLiquids[self._loads[self._loadCount].liquid] = currentlyRemoved + toRemove

            -- Remove entire quantity from previous load
            self._loads[self._loadCount].quantity = lastLoadQuantity - toRemove
            self._totalInflation = self._totalInflation - toRemove
            toRemove = 0
            
            self:getLog():debug(self:getActorLogPrefix().." load #"..self._loadCount.." contributes ["..self._loads[self._loadCount].quantity.."] to total inflation.")
        else
            self:getLog():debug(self:getActorLogPrefix().." removing load #"..self._loadCount)

            -- Add to removed liquid quantity
            local currentlyRemoved = removedLiquids[self._loads[self._loadCount].liquid] or 0
            removedLiquids[self._loads[self._loadCount].liquid] = currentlyRemoved + self._loads[self._loadCount].quantity

            -- Remove previous load
            self._loads[self._loadCount] = nil
            self._loadCount = math.max(0, self._loadCount - 1)
            self._totalInflation = math.max(0, self._totalInflation - lastLoadQuantity)

            -- Update quantity to remove
            toRemove = toRemove - lastLoadQuantity
        end
    end

    self:getLog():debug(self:getActorLogPrefix().." has ["..self:getloadCount().."] inflation loads. "..
                        "Total inflation: [".. self:getTotalInflation().."]")
                        
    return removedLiquids
end

function Inflation:clear()
    for i=0, self._loadCount do self._loads[i] = nil end
    self._loadCount = 0
    self._totalInflation = 0 
end

function Inflation:getTotalInflation()
   return self._totalInflation
end

function Inflation:getloadCount()
    return self._loadCount
end

function Inflation:generateLoad(liquid, quantity)
    return {
        liquid = liquid or self._defaultLiquidId,
        quantity = quantity or 0.1
    }
end

function Inflation:getLog()
    return self._log
end

function Inflation:getActor()
    return self._actor
end

function Inflation:getActorLogPrefix()
    return "Actor "..self:getActor():getActorNumber().." ("..self:getActor():getName()..")"
end
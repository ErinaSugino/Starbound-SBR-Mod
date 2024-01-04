if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/arousal.lua"
end

Sexbound.Player.Arousal = Sexbound.Common.Arousal:new()
Sexbound.Player.Arousal_mt = { __index = Sexbound.Player.Arousal }

--- Instantiates this class which extends Common Arousal
-- @param parent
function Sexbound.Player.Arousal:new(parent)
    local _self = setmetatable({
        _parent = parent,
        _arousalState = -1
    }, Sexbound.Player.Arousal_mt)

    _self:init(parent, nil)
    _self:loadMoanConfig()
    _self:updateArousalStatus()
    _self:initPlayerMessageHandlers()

    return _self
end

--- Updates this instance
-- @param dt
function Sexbound.Player.Arousal:update(dt)
    -- super update
    Sexbound.Common.Arousal.update(self, dt)
    
    if not self._config.playerArousalEffects then return end
    
    if self._usesHeat then
        local heatTimer = storage.sexbound.heatCycle or 0
        if heatTimer <= 0 then
            -- No heat cycle - generate new cycle
            local cycleLength = self._config.heatCycleLength or {10,30}
            local newCycle = 840 * util.randomIntInRange(cycleLength)
            storage.sexbound.heatCycle = newCycle
        else
            -- Active cycle - progress and handle trigger if needed
            heatTimer = heatTimer - dt
            storage.sexbound.heatCycle = heatTimer
            if heatTimer <= 0 then
                -- Trigger heat
                status.addEphemeralEffect("sexbound_arousal_heat")
            end
        end
    else
        local max = self._maxAmount
        local cur = self:getAmount()
        local percent = cur / max
        
        local targetArousalState = -1
        if percent < 0.5 then
            targetArousalState = 0
        elseif percent < 0.9 then
            targetArousalState = 1
        else
            targetArousalState = 2
        end
        
        if self._arousalState ~= targetArousalState then self:updateArousalStatus() end
    end
end

function Sexbound.Player.Arousal:loadMoanConfig()
    local plugins = self:getParent():getConfig().sex.actor.plugins or {}
    local plugin = plugins["moan"] or {}
    
    local loadedConfig = {}
    
    for _, _config in pairs(plugin.config) do
        xpcall(function()
            loadedConfig = util.mergeTable(loadedConfig, root.assetJson(_config))
        end, function(errorMessage)
            sb.logError("[SxB | ENT] Fetching Moan config for arousal handler failed: "..errorMessage)
        end)
    end
    
    self._moanConfig = loadedConfig[player.species()] or loadedConfig["default"] or {}
end

function Sexbound.Player.Arousal:updateArousalStatus()
    local removeList = {}
    local addList = {}
    
    if not self._config.playerArousalEffects then
        removeList = {"sexbound_arousal_heat", "sexbound_arousal_debuff1","sexbound_arousal_debuff2"}
        self._arousalState = -1
    else
        if self._usesHeat then
            removeList = {"sexbound_arousal_debuff1", "sexbound_arousal_debuff2"}
            self._arousalState = -1
        else
            local max = self._maxAmount
            local cur = self:getAmount()
            local percent = cur / max
            
            if percent < 0.5 then
                removeList = {"sexbound_arousal_heat", "sexbound_arousal_debuff1","sexbound_arousal_debuff2"}
                self._arousalState = 0
            elseif percent < 0.9 then
                removeList = {"sexbound_arousal_heat", "sexbound_arousal_debuff2"}
                addList = {"sexbound_arousal_debuff1"}
                self._arousalState = 1
            else
                removeList = {"sexbound_arousal_heat", "sexbound_arousal_debuff1"}
                addList = {"sexbound_arousal_debuff2"}
                self._arousalState = 2
            end
        end
    end
    
    for _,s in ipairs(removeList) do
        status.removeEphemeralEffect(s)
    end
    for _,s in ipairs(addList) do
        status.addEphemeralEffect(s, math.huge)
    end
end

function Sexbound.Common.Arousal:initPlayerMessageHandlers()
    message.setHandler("Sexbound:Pregnant:Pregnancy", function(_, _, args)
        status.removeEphemeralEffect("sexbound_arousal_heat")
    end)
    message.setHandler("Sexbound:Arousal:GetMoans", function(_, _, args)
        return self._moanConfig
    end)
end

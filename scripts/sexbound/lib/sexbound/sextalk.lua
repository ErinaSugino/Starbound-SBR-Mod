--- Sexbound.Sextalk Class Module.
-- @classmod Sexbound.Sextalk
-- @author Erina Sugino
-- @license GNU General Public License v3.0
Sexbound.Sextalk = {}
Sexbound.Sextalk_mt = {
    __index = Sexbound.Sextalk
}

require("/scripts/util.lua")

function Sexbound.Sextalk.new(parent)
    local self = setmetatable({
        _logPrefix = "SXTG",
        _parent = parent,
        _actors = {},
        _lastActor = 0,
        _talkTimer = 0,
        _active = false
    }, Sexbound.Sextalk_mt)

    Sexbound.Messenger.get("main"):addBroadcastRecipient(self)
    
    self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
    
    self._isEnabled, self._config = self.loadSextalkConfig()
    
    return self
end

function Sexbound.Sextalk:update(dt)
    if not self._isEnabled then return end
    if self._active then
        self._talkTimer = self._talkTimer - dt
        if self._talkTimer <= 0 then
            self:triggerTalk()
            local newTimer = self._config.cooldown or {10,20}
            if type(newTimer) == "table" then self._talkTimer = util.randomIntInRange(newTimer) else self._talkTimer = newTimer end
        end
    end
end

--- Handles interally received message.
-- @param message A Message
function Sexbound.Sextalk:onMessage(message)
    
end

--- Handlers for state changes
function Sexbound.Sextalk:onEnterNullState()
    self._active = false -- Null state is setup state - no talking
    self._talkTimer = 0 -- Immediately talk on next active tick
end

function Sexbound.Sextalk:onEnterIdleState()
    self._active = false -- Idle state has no talking
    self._talkTimer = 0 -- Immediately talk on next active tick
end

function Sexbound.Sextalk:onEnterSexState()
    self._active = true -- Sex state has talking
    self._talkTimer = 0 -- Immediately talk on next active tick
end

function Sexbound.Sextalk:onEnterClimaxState()
    self._active = true -- Climax state has talking
    self._talkTimer = 0 -- Immediately talk on next active tick
end

function Sexbound.Sextalk:onEnterPostClimaxState()
    self._active = true -- Post Climax state can have talking
end

function Sexbound.Sextalk:onEnterExitState()
    self._active = false -- Exit state has no talking - Don't even know what this is for
    self._talkTimer = 0 -- Immediately talk on next active tick
end

function Sexbound.Sextalk:loadSextalkConfig()
    local pluginConfig = self:getParent():getConfig().plugins.sextalk or {}
    local isEnabled = not not pluginConfig.enabled
    local toLoad = pluginConfig.config or {}
    local loadedConfig = {}

    for _, _config in pairs(toLoad) do
        xpcall(function()
            loadedConfig = util.mergeTable(loadedConfig, root.assetJson(_config))
        end, function(errorMessage)
            self._log:error(errorMessage)
        end)
    end

    return isEnabled, loadedConfig
end

--- Function to choose a random available 
function Sexbound.Sextalk:triggerTalk()
    local viableActors = {}
    for _,a in ipairs() do
        local sxt = a:getPlugins("sextalk")
        if sxt then
            if sxt._active then table.insert(viableActors, a) end
        end
    end
    
    local l = #sxt
    if l <= 0 then self._lastActor = 0 return end
    if l == 1 then self._lastActor = 0 sxt[1]:getPlugins("sextalk"):sayRandom()
    else
        local i, j = self._lastActor, 0
        while i == self._lastActor and j < 10 do
            i = math.random(l)
        end
        self._lastActor = i
        sxt[i]:getPlugins("sextalk"):sayRandom()
    end
end
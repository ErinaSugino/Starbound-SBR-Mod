--- Sexbound.Positions Class Module.
-- @classmod Sexbound.Positions
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Positions = {}
Sexbound.Positions_mt = {
    __index = Sexbound.Positions
}

if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/position.lua")
end

---Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Positions:new(parent)
    local _self = setmetatable({
        _index = -1,
        _lastPositionName = "idle",
        _logPrefix = "POSI",
        _parent = parent,
        _positionCount = 0,
        _positions = {},
        _availablePositions = {},
        _idlePosition = nil
    }, Sexbound.Positions_mt)

    Sexbound.Messenger.get("main"):addBroadcastRecipient(_self)

    _self._log = Sexbound.Log:new(_self._logPrefix, _self._parent:getConfig())
    _self:loadConfig(_self._parent:getConfig())
    _self:loadIdle(_self._parent:getConfig())
    _self:loadPositions(_self._parent:getConfig())
    _self:initMessageHandler()

    return _self
end

function Sexbound.Positions:initMessageHandler()
    message.setHandler("Sexbound:Actor:SwitchPosition", function(_, _, args)
        local stateMachine = self:getParent():getStateMachine()

        if not stateMachine:isClimaxing() and not stateMachine:isReseting() then
            self:switchPosition(args.positionId)
            return true
        end

        return false
    end)
    message.setHandler("Sexbound:Actor:Idle", function(_, _, args)
        local stateMachine = self:getParent():getStateMachine()

        if not stateMachine:isClimaxing() and not stateMachine:isReseting() then
            self:toggleIdle()
            return true
        end

        return false
    end)
end

--- Loads and returns positions config.
function Sexbound.Positions:loadConfig(sexboundConfig)
    local _, _config = xpcall(function()
        return root.assetJson(sexboundConfig.position.configFile or "/positions/positions.config")
    end, function(error)
        self:getLog():error("Unable to load positions config file!")
    end)

    self._config = _config or {}
end

--- Loads the idle setup
function Sexbound.Positions:loadIdle(sexboundConfig)
    sexboundConfig = sexboundConfig or {}
    local _, _config = nil, nil
    local targetIdle = sexboundConfig.idlePosition or "idle"

    _, _config = xpcall(function()
        return root.assetJson("/positions/idle/"..targetIdle..".config")
    end, function(error)
        self:getLog():error("Unable to load idle config file")
    end)
    
    _, _config = xpcall(function()
            if _config and _config.base and self._config[_config.base] then
                _config = util.mergeTable(root.assetJson(self._config[_config.base].configFile), _config)
            end

            return _config
        end, function(error)
            self:getLog():error("Unable to merge with base idle position config file: " ..
                                    self._config[_config.base].configFile)
        end)

    if type(_config) == "table" then
        self._idlePosition = Sexbound.Position:new(self, _config)
    end
end

--- Returns loaded Sex Positions as a table.
function Sexbound.Positions:loadPositions(sexboundConfig)
    local positionList = sexboundConfig.position.sex or {}
    
    for _, v in ipairs(positionList) do
        local _, _config = nil, nil

        _, _config = xpcall(function()
            return root.assetJson(self._config[v].configFile or "/positions/twoactors/standing/standing.config")
        end, function(error)
            self:getLog():error("Unable to load position config file: " .. self._config[v].configFile)
        end)

        _, _config = xpcall(function()
            if _config and _config.base and self._config[_config.base] then
                _config = util.mergeTable(root.assetJson(self._config[_config.base].configFile), _config)
            end

            return _config
        end, function(error)
            self:getLog():error("Unable to merge with base position config file: " ..
                                    self._config[_config.base].configFile)
        end)

        if type(_config) == "table" then
            local newPosition = Sexbound.Position:new(self, _config)
            table.insert(self._positions, newPosition)

            self._positionCount = self._positionCount + 1
        end
    end
    
    self._availablePositions = self._positions
end

--- Generates table of all valid actor composition permutations for all available positions
function Sexbound.Positions:updateActorRoles(actorList, actorCount)
    local allIndices, allPerms = self:util_generatePermutation(actorCount or 3)
    local doFilter = not self:getParent():getConfig().sex.forceAllPositions and not self:getParent():getConfig().sex.forcePositions and not self:getParent():getConfig().position.force
    
    self:getLog():debug("Updating position permutations for "..actorCount.." actors")
    
    local allPositionsToCheck = {self._idlePosition}
    for i,p in ipairs(self._availablePositions) do allPositionsToCheck[i+1] = p end
    
    for _,pos in ipairs(allPositionsToCheck) do
        local posIndices = {}
        local posPerms = {}
        local posTraits = pos:getConfig().requireTraits or {}
        local allActorsFulfilCriteria = true
        for _,index in ipairs(allIndices) do
            self:getLog():debug("Checking position composition "..index)
            allActorsFulfilCriteria = true
            local curPerm = allPerms[index]
            for i=1,actorCount do
                local curAct = curPerm[i]
                self:getLog():debug("Checking actor traits for actor "..curAct..": "..actorList[curAct]:getName())
                if actorList[curAct]:getForceRole() > 0 then
                    -- Forced role ignores trait checks
                    self:getLog():debug("Actor "..i.." has a forced role")
                    if actorList[curAct]:getForceRole() ~= i then allActorsFulfilCriteria = false break end
                elseif doFilter and not actorList[curAct]:hasTraits(posTraits[i]) then allActorsFulfilCriteria = false break end
            end
            if allActorsFulfilCriteria then table.insert(posIndices, index) posPerms[index] = allPerms[index] end
        end
        pos:setAvailableRoles(posIndices, posPerms)
    end
    
    --self._idlePosition:setAvailableRoles(allIndices, allPerms)
end

--- Filters all registered positions by their actorCount and actorTrait requirements - if not disabled
function Sexbound.Positions:filterPositions(actorList)
    actorList = actorList or {}
    local actorCount = 0
    for i,a in ipairs(actorList) do actorCount = actorCount + 1 end
    
    self:getLog():debug("Re-evaluating positions. Total available: "..#self._positions.." - actor count: "..actorCount)
    
    local forceTarget = self:getParent():getConfig().position.force
    if self:getParent():getConfig().sex.forceAllPositions or forceTarget then
        self:updateActorRoles(actorList, actorCount)
        if forceTarget and forceTarget ~= self._index then self:switchPosition(forceTarget) end
        return
    end -- filtering disabled - all positions available on load
    
    local availablePositions = {}
    local positionCount = 0
    
    for _,p in ipairs(self._positions) do
        local posConf = p:getConfig() or {}
        local posMin = posConf.minRequiredActors or 0
        local posMax = posConf.maxAllowedActors or 3
        
        if actorCount >= posMin and actorCount <= posMax then table.insert(availablePositions, p) positionCount = positionCount + 1 end
    end
    
    self:getLog():debug("Remaining positions after count check: "..positionCount)
    
    self._availablePositions = availablePositions -- first filter by count to reduce load of role composition checks
    self._positionCount = positionCount
    if self._positionCount > 0 then
        -- Only continue if there are any positions left to check
        self:updateActorRoles(actorList, actorCount)
        
        positionCount = 0
        availablePositions = {}
        local next = next
        for _,p in ipairs(self._availablePositions) do
            local i,r = p:getAvailableRoles()
            if next(i) ~= nil then table.insert(availablePositions, p) positionCount = positionCount + 1 end
            -- If available roles are not empty (has "next" value) it means there is at least one available actor composition - position valid, add to available list
        end
        
        self._availablePositions = availablePositions
        self._positionCount = positionCount
    end
    
    if self._index ~= -1 and not self:isAvailable(self._lastPositionName) then self:switchPosition(-1) end
    
    self:getParent():tickToken("positions")
    
    self:getLog():debug("New available positions: "..self._positionCount)
end

function Sexbound.Positions:nextPosition()
    if self._positionCount == 0 then return end
    local maxIndex = #self._availablePositions
    self._index = self._index + 1
    if self._index > maxIndex then self._index = 1 end

    self:switchPosition(self._index)
end

function Sexbound.Positions:previousPosition()
    if self._positionCount == 0 then return end
    local maxIndex = #self._availablePositions
    self._index = self._index - 1
    if self._index <= 0 then self._index = maxIndex end

    self:switchPosition(self._index)
end

function Sexbound.Positions:resetIndex()
    self._index = -1
    
    self:switchPosition(self._index)
end

--- Switches to the specified position.
-- @param index
function Sexbound.Positions:switchPosition(index)
    if index == -1 or self._positionCount == 0 then self._index = -1
    else self._index = util.wrap(index, 1, self._positionCount) end

    local actors = {}
    for _, actor in ipairs(self._parent._actors) do
        table.insert(actors, {
            name = actor:getName(),
            uniqueId = actor:getUniqueId()
        })
    end

    Sexbound.Messenger.get("main"):broadcast(self, "Sexbound:Event:Create", {
        eventName = "POSITION_SWITCHED",
        eventArgs = {
            actors = actors,
            position_name = self:getCurrentPosition():getConfig().name
        }
    })

    local stateMachine = self:getParent():getStateMachine()
    local stateName = stateMachine:stateDesc()

    if not stateName or stateName == "nullState" then
        return
    end

    local animationState = self:getCurrentPosition():getAnimationState(stateName)

    stateName = animationState:getStateName()

    -- Set new animation state to match the position.
    animator.setAnimationState("props", stateName, true)
    animator.setAnimationState("actors", stateName, true)

    self:getParent():helper_reassignAllRoles()
    self:getParent():resetAllActors()

    -- Send undelayed broadcast
    Sexbound.Messenger.get("main"):broadcast(
        self,
        "Sexbound:Positions:SwitchPosition",
        self:getCurrentPosition(),
        false
    )
    
    local isSex = self._index ~= -1
    stateMachine:setStatus("havingSex", isSex)
    self._lastPositionName = self:getCurrentPosition():getName()
    
    self:getLog():debug("Switching positions. New position: "..self._index.." - sexState: "..tostring(isSex))
end

function Sexbound.Positions:toggleIdle()
    self:switchPosition(-1)
end

function Sexbound.Positions:switchRandomSexPosition(fromIdle)
    fromIdle = fromIdle or false
    if self._positionCount < 1 then return end
    if fromIdle and self._index ~= -1 then return end
    local randomIndex = util.randomIntInRange({1, self._positionCount})

    self:switchPosition(randomIndex)
end

--- Returns a reference to the Positions Configuration.
function Sexbound.Positions:getConfig()
    return self._config
end

function Sexbound.Positions:getLog()
    return self._log
end

function Sexbound.Positions:getLogPrefix()
    return self._logPrefix
end

function Sexbound.Positions:getIndex()
    return self._index
end

--- Returns a reference to the Current Position.
function Sexbound.Positions:getCurrentPosition()
    if self._index == -1 then return self._idlePosition end
    return self._availablePositions[self._index]
end

function Sexbound.Positions:getParent()
    return self._parent
end

--- Returns a reference to the Positions.
function Sexbound.Positions:getPositions()
    return self._availablePositions
end

function Sexbound.Positions:getAllPositions()
    return self._positions
end

--- Returns if a position name is available
function Sexbound.Positions:isAvailable(posName)
    for _,p in ipairs(self._availablePositions) do
        if p:getName() == posName then return true end
    end
    return false
end

--- Generate permutations of actor combinations for actorCount
function Sexbound.Positions:util_generatePermutation(actorCount)
    if actorCount <= 0 then return {} end
    local permPool = {}
    for i=1,actorCount do permPool[i] = i end
    
    local it = coroutine.wrap(function() self:util_perm(permPool, 1, actorCount) end)
    local indices = {}
    local result = {}
    for p in it do
        local index = ""
        for _,i in ipairs(p) do index = index..i end
        result[index] = copy(p)
        table.insert(indices, index)
    end
    return indices, result
end
--- Coroutine iterator for actual permutation generation
function Sexbound.Positions:util_perm(a,n,m)
    if n == m then
        coroutine.yield(a)
    else
        for i=n,m do
            -- put i-th element as the first one
            a[n], a[i] = a[i], a[n]
            -- generate all permutations of the other elements
            self:util_perm(a, n + 1, m)
            -- restore i-th element
            a[n], a[i] = a[i], a[n]

        end
    end
end

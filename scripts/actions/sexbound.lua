--- Sexbound Behavior Actions
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- Every node function (as defined in the .nodes file) can receive
--- args table - The input arguments provided, as defined in node
--- board table - The overarching behavior blackboard state table. Turly black magic and fully undocumented
--- node table - The definition of the calling node being executed
--- dt number - The delta time since last execution
--- Every node returns, unless otherwise specified
--- return boolean - True if node succesfully executed, false if it failed or nil if it is still executing
--- All nodes execute asynchronously and can yield.

--- Uses radio to broadcast a message to announce birth.
--- @param args table
--- @param board table
function announceBirth(args, board)
    local targetEntity = self.sb_npc or self.sb_monster

    if targetEntity then
        targetEntity:announceBirth()
    end

    return false
end

--- Checks if the entity is ready to give birth.
--- @param args table
--- @param board table
function checkPregnancy(args, board)
    local targetEntity = self.sb_npc or self.sb_monster
    if not targetEntity then
        return false
    end

    if (targetEntity._pregnancyDelay or 0) > 0 then
        return false
    end

    local babyIndex = targetEntity:getPregnant():findReadyBabyIndex()
    if babyIndex == nil then
        return false
    end

    return true, {
        babyIndex = babyIndex
    }
end

--- Calls the entity's failed transformation function.
--- @param args table
--- @param board table
function failedTransformation(args, board)
    local targetEntity = self.sb_npc or self.sb_monster
    if not targetEntity then
        return false
    end

    targetEntity:failedTransformation()
    return true
end

--- Returns the first known open block position within an inputted area.
--- @param args table
--- @param board table
function findNearbyOpenSpace(args, board)
    if args.rectSize == nil then
        return false
    end

    local targetEntity = self.sb_npc or self.sb_monster
    if not targetEntity then
        return false
    end

    local position = targetEntity:getTransform():findNearbyOpenSpace(args.rectSize)
    if position then
        return true, {
            position = position
        }
    else
        return false
    end
end

--- Calls the entity's function to give birth.
--- @param args table
--- @param board table
function giveBirth(args, board)
    if args.babyIndex == nil then
        return false
    end

    local targetEntity = self.sb_npc or self.sb_monster
    if not targetEntity then
        return false
    end

    local entityId = targetEntity:getPregnant():handleGiveBirth(args.babyIndex)
    if not entityId then
        return false
    end

    return true, {
        entityId = entityId
    }
end

--- Checks if an entity is fully occupied.
--- @param args table
--- @param board table
function isFullyOccupied(args, board)
    -- Not implemented yet
end

--- Returns whether or not the entity is having sex.
--- @param args table
--- @param board table
function isHavingSex(args, board)
    local targetEntity = self.sb_monster or self.sb_npc

    if not targetEntity then
        return false
    end

    return targetEntity._isHavingSex
end

--- Attempts to have entity place a sex node on the ground below its feet.
--- @param args table
--- @param board table
function placeSexNode(args, board)
    if not args.position then
        return false
    end

    local targetEntity = self.sb_npc or self.sb_monster

    if not targetEntity then
        return false
    end

    local uniqueId = targetEntity:getTransform():placeSexNode(args.position)
    if uniqueId then
        return true, {
            loungeId = uniqueId
        }
    else
        return false
    end
end

--- Checks whether or not entity is a recruitable entity with a uuid.
--- @param args table
--- @param board table
function hasOwnerUuid(args, board)
    if recruitable and recruitable.ownerUuid() then
        return true, {
            entityId = recruitable.ownerUuid()
        }
    else
        return false
    end
end

--- Checks whether or not the entity is pregnant.
--- @param args table
--- @param board table
function hasPregnancy(args, board)
    if not storage.sexbound.pregnant or isEmpty(storage.sexbound.pregnant) then
        return false
    end
    return true, {
        pregnancyList = storage.sexbound.pregnant
    }
end

--- Checks whether or not the entity will respawn upon death.
--- @param args table
--- @param board table
function hasRespawner(args, board)
    if storage.respawner then
        return true, {
            entityId = storage.respawner
        }
    else
        return false
    end
end

--- Sends entity message to prevent a respawnable entity from respawning.
--- @param args table
--- @param board table
function lockRespawner(args, board)
    if args.respawnerId == nil then
        return false
    end
    world.sendEntityMessage(args.respawnerId, "Sexbound:Transform:Object", {
        uniqueId = entity.uniqueId()
    })
    return true
end

--- Setup this entity.
--- @param args table
--- @param board table
function remoteSetup(args, board)
    if args.entity == nil then
        return false
    end

    local targetEntity = self.sb_monster or self.sb_npc

    if not targetEntity then
        return false
    end

    return targetEntity:setup(args.entity)
end

--- Returns a resource's value safely.
--- @param args table
--- @param board table
function safeGetResource(args, board)
    if not status.isResource(args.resource) then
        return false
    end
    return true, status.resource(args.resource)
end

--- Returns a resource's percent value safely.
--- @param args table
--- @param board table
function safeResourcePercentage(args, board)
    if not status.isResource(args.resource) then
        return false
    end
    return status.resourcePercentage(args.resource) > args.percentage
end

--- Untransforms this entity
--- @param args table
--- @param board table
function smashSexNode(args, board)
    local targetEntity = self.sb_monster or self.sb_npc

    if targetEntity then
        targetEntity:getTransform():smashSexNode()
        return true
    end

    return false
end

--- Unloads this entity as a sex actor.
--- @param args table
--- @param board table
function unloadSexActor(args, board)
    local targetEntity = self.sb_monster or self.sb_npc

    if targetEntity then
        targetEntity:unload()
        return true
    end

    return false
end

--- Logs debugging data
--- @param args table
--- @param board table
function debugBehaviour(args, board)
    if (self.sb_monster or self.sb_npc):canLog("behavior") then
        sb.logInfo("LOGGING OF BEHAVIOR")
        sb.logInfo(leveledDump(args, 2))
        sb.logInfo(leveledDump(board, 2))
    end
    return true
end

--- Sorts sexnodes by compatibility score
--- @param args table
--- @param board table
function sortSexnodes(args, board)
    local list = args.list or {}
    local timeout = args.timeout or 1
    local dt = 0
    local i = 1
    local seen = {}
    local controllers = {}
    local nodeToController = {}
    local fetchPromises = {}
    local fetchPromiseCount = 0
    local fetchPromiseDone = 0
    local queryPromises = {}
    local queryPromiseCount = 0
    local queryPromiseDone = 0
    local targetNode = nil

    if #list <= 0 then return false end
    if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("NODE BEHAVIOR OF ENTITY #"..entity.id()) end

    local compatibilityData = (self.sb_monster or self.sb_npc):getCompatibilityData()

    -- Setup all async calls to retrieve controllerId of seat nodes
    for _,id in ipairs(list) do
        fetchPromises[id] = world.sendEntityMessage(id, "Sexbound:Retrieve:ControllerId")
        fetchPromiseCount = fetchPromiseCount + 1
        if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("ENTITY #" .. entity.id() .. " CALLING NODE #" .. tostring(id)) end
    end

    while (queryPromiseDone < queryPromiseCount or fetchPromiseDone < fetchPromiseCount) and timeout > 0 do
        -- Main async loop
        timeout = timeout - dt

        if queryPromiseDone < queryPromiseCount then
            -- Handle pending query requests (before fetch to not instantly check new query from finished fetch)
            local remainingQueryPromises = {}
            for id,p in pairs(queryPromises) do
                if p:finished() then
                    -- New query result is in
                    queryPromiseDone = queryPromiseDone + 1
                    if p:succeeded() then
                        -- Successful request - we go compatibility metrics
                        local index = p:result() or 0
                        controllers[id] = index
                        if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("ENTITY #"..entity.id().." GOT INDEX "..tostring(index).." FOR #"..tostring(id)) end
                    else
                        -- Not successful request - something went wrong. Log and treat node as 0
                        if (self.sb_monster or self.sb_npc):canLog("behavior") then
                            sb.logError("ERROR FETCHING COMPATIBILITY ON ENTITY #"..entity.id().." FOR #"..tostring(id))
                            sb.logError(tostring(p:error()))
                        end
                        controllers[id] = 0
                    end
                else remainingQueryPromises[id] = p end
            end
            queryPromises = remainingQueryPromises
        end

        if fetchPromiseDone < fetchPromiseCount then
            -- Handle pending fetch requests
            local remainingFetchPromises = {}
            for id,p in pairs(fetchPromises) do
                if p:finished() then
                    -- New request result is in
                    fetchPromiseDone = fetchPromiseDone + 1
                    if p:succeeded() then
                        -- Successful request - we got a main controller id
                        local cid = p:result()
                        if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("ENTITY #"..entity.id().." GOT CONTROLLER #"..tostring(cid).." FROM #"..tostring(id)) end
                        if cid and not seen[cid] then
                            nodeToController[id] = cid
                            controllers[cid] = 0 -- Default to 0 incase we don't get any updated results
                            seen[cid] = true
                            queryPromises[cid] = world.sendEntityMessage(cid, "Sexbound:Retrieve:NodeCompatibility", compatibilityData)
                            queryPromiseCount = queryPromiseCount + 1
                            if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("ENTITY #"..entity.id().." GOT NEW CONTROLLER #"..tostring(cid)) end
                        end
                    else
                        -- Not successful request - something went wrong. Log and treat node as 0
                        if (self.sb_monster or self.sb_npc):canLog("behavior") then
                            sb.logError("ERROR FETCHING CONTROLLER ID ON ENTITY #"..entity.id().." FOR #"..tostring(id))
                            sb.logError(tostring(p:error()))
                        end
                        nodeToController[id] = 0
                    end
                else remainingFetchPromises[id] = p end
            end
            fetchPromises = remainingFetchPromises
        end

        -- Finally, yield until next tick
        dt = coroutine.yield(nil, {list=list,entity=targetNode,data={controllers=controllers,nodeToController=nodeToController}})
    end

    if (timeout <= 0 and self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("ASYNC TIMEOUT OF ENTITY #"..entity.id()) end

    local targetIndex = 0
    for j=1,#list do
        local curIndex = controllers[(nodeToController[list[j]] or 0)] or 0
        if curIndex > targetIndex then targetNode = list[j] targetIndex = curIndex end
    end
    if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("FINAL NODE FOR #"..entity.id()..": #"..tostring(targetNode).." with "..tostring(targetIndex)) end
    if targetNode == nil or targetIndex <= 0 then return false end

    return true, {list=list,entity=targetNode,data={controllers=controllers,nodeToController=nodeToController}}
end

--- Function to count down a given time and FAIL upon completion.
-- Starbound spaghetti 101: Behaviour loop abortions.
-- There is an issue with the pathfinding that makes NPCs go stuck forever when their arousal told them to go to a node they can't reach, unless that node get's occupied by someone else or destroyed.
-- Solution: Timeout which fails the current execution loop so the whole node finding process starts over (if applicable)
-- Problem: Starbound. For a parallel execution node to fail, the specified number of nodes (parameter "fail") needs to return 'false' as first value. In this case any 1 node needs to fail for everything to abort.
-- However, the timer returns 'true' upon completion and 'nil' while still ticking, like any yielding multi-tick node.
--- @param args table
--- @param board table
--- @param dt number The delta time since last tick
function reverseTimer(args, board, _, dt)
  local timer = timeRange(args.time)
  local max = timer

  while timer > 0 do
    timer = timer - dt
    dt = coroutine.yield(nil, {ratio = (max - timer) / max})
  end

  self._nodeTimeout = true

  return false, {ratio = 1.0}
end

-- param position
-- param run
-- param runSpeed
-- param groundPosition
-- param minGround
-- param maxGround
-- param avoidLiquid
-- output direction
-- output pathfinding

--- Version of moveToPosition pathfinding function that aborts itself if a stuck condition is detected
--- @param args table
--- @param board table
--- @param node table
--- @param dt number The delta time since last tick
function abortingMoveToPosition(args, board, node, dt)
  self._nodeTimeout = false

  if args.position == nil then return false end

  if entity.entityType() == "npc" then npc.resetLounging() end
  local pathOptions = applyDefaults(args.pathOptions or {}, {
    returnBest = false,
    mustEndOnGround = mcontroller.baseParameters().gravityEnabled,
    maxDistance = 200,
    swimCost = 5,
    dropCost = 5,
    boundBox = mcontroller.boundBox(),
    droppingBoundBox = rect.pad(mcontroller.boundBox(), {0.2, 0}), --Wider bound box for dropping
    standingBoundBox = rect.pad(mcontroller.boundBox(), {-0.7, 0}), --Thinner bound box for standing and landing
    smallJumpMultiplier = 1 / math.sqrt(2), -- 0.5 multiplier to jump height
    jumpDropXMultiplier = 1,
    enableWalkSpeedJumps = true,
    enableVerticalJumpAirControl = false,
    maxFScore = 400,
    maxNodesToSearch = 70000,
    maxLandingVelocity = -10.0,
    liquidJumpCost = 15
  })

  local timeout = args.timeout
  local timeoutMax = timeout

  local lastPosition = {0,0}
  local targetPosition = {args.position[1], args.position[2]}

  local updateTarget = function()
    lastPosition = {args.position[1], args.position[2]}
    if args.groundPosition then
      targetPosition = findGroundPosition(lastPosition, args.minGround, args.maxGround, args.avoidLiquid)
    else
      targetPosition = lastPosition
    end
  end

  updateTarget()
  if not targetPosition then
    self._nodeTimeout = true
    return false
  end

  local ourLastPos = entity.position()
  local stuckFrames = 0
  local closestDistance = math.huge

  local result = mcontroller.controlPathMove(targetPosition, args.run, pathOptions)
  while true do
    if not lastPosition or world.magnitude(args.position, lastPosition) > 2 then
      updateTarget()
      if not targetPosition then
        self._nodeTimeout = true
        return false
      end
    end

    if result == false or result == true then
      self._nodeTimeout = result
      return result
    end
    result = mcontroller.controlPathMove(targetPosition, args.run)
    if not self.setFacingDirection then 
      if not mcontroller.groundMovement() then
        controlFace(mcontroller.velocity()[1])
      elseif mcontroller.running() or mcontroller.walking() then
        controlFace(mcontroller.movingDirection())
      end
    end

    if entity.entityType() == "npc" then
      if args.closeDoors then
        closeDoorsBehind()
      end
    end

    local ourCurPos = entity.position()
    if ourCurPos[1] == ourLastPos[1] and ourCurPos[2] == ourLastPos[2] then
      stuckFrames = stuckFrames + 1
    else
      stuckFrames = 0
      ourLastPos = ourCurPos
    end

    if stuckFrames >= 10 then self._nodeTimeout = true return false end -- Abort if no actual movement for 10 steps (1 second-ish - nodes seem to not run every tick, which makes sense)

    if timeout ~= -1 then -- Timeout of -1 means infinite
      local curDistance = world.magnitude(ourCurPos, targetPosition)
      -- If we work with a timeout, reset it when we actually got closer to our target
      if curDistance < closestDistance then
        closestDistance = curDistance
        timeout = timeoutMax
      end

      timeout = timeout - dt
      if timeout <= 0 then self._nodeTimeout = true return false end -- Abort if no new progress for the duration of the defined timeout
    end

    coroutine.yield(nil, {pathfinding = mcontroller.pathfinding(), direction = mcontroller.facingDirection()})
  end

  return true
end

--- Fetches list of restricted sexnodes from entity storage
--- @param args table
--- @param board table
--- @return boolean finished Whethere this node executed fully and successfully
--- @return table restrictions The loaded list of restrictions
function getNodeRestrictions(args, board)
    local restrictions = {}
    local sxb = (self.sb_npc or self.sb_monster)
    if not sxb then
        return true, restrictions
    end
    local storedRestrictions = (sxb._behaviorData or {}).excludedNodes
    if storedRestrictions then
        for c,d in pairs(storedRestrictions) do
            if d.count >= 1 then
                for _,n in ipairs((d.nodes or {})) do
                    table.insert(restrictions, n)
                end
            end
        end
    end

    if sxb:canLog("behavior") then sb.logInfo("BEHAVIOR: Loaded restrictions: "..dump(restrictions)) end

    return true, restrictions
end

--- Sets restricted sexnodes to persistent entity storage
--- @param args table
--- @param board table
function setNodeRestrictions(args, board)
    if not self._nodeTimeout then return false end

    local target = args.entity
    if not target then return false end

    local data = args.data
    if not data then return false end

    local sxb = (self.sb_npc or self.sb_monster)
    if not sxb then return false end
    sxb._behaviorData = sxb._behaviorData or {}
    local storedRestrictions = ((self.sb_npc or self.sb_monster)._behaviorData or {}).excludedNodes or {}

    local cid = data.nodeToController[target] or 0
    if storedRestrictions[cid] then
        storedRestrictions[cid].count = storedRestrictions[cid].count + 1
        storedRestrictions[cid].time = 60
        local isIn = false
        for _,n in ipairs(storedRestrictions[cid].nodes) do
            if n == target then isIn = true break end
        end
        if not isIn then table.insert(storedRestrictions[cid].nodes, target) end
    else
        storedRestrictions[cid] = {count=1,time=60,nodes={target}}
    end
    sxb._behaviorData.excludedNodes = storedRestrictions
    self._nodeTimeout = false

    if sxb:canLog("behavior") then sb.logInfo("BEHAVIOR: Node #"..target.." couldn't be reached. Excluding #"..cid.." (times: "..storedRestrictions[cid].count..")") end

    return false
end

function findSexnodes(args, board)
  if args.position == nil then return false end

  local queryArgs = {
    order = args.orderBy,
    withoutEntityId = args.withoutEntity,
    callScript = "isFullyOccupied",
    callScriptReturn = false
  }
  local loungables = world.loungeableQuery(args.position, args.range, { orientation = args.orientation, queryArgs })

  local bannedList = args.exclude or {}
  local bannedIndex = {}
    for _, id in ipairs(bannedList) do
        bannedIndex[id] = true
  end
  local filteredLoungables = {}
    for _, lid in ipairs(loungables) do
        if not (bannedIndex[lid] or false) then table.insert(filteredLoungables, lid) end
  end

  if #filteredLoungables > 0 then
        return true, { entity = filteredLoungables[1], list = filteredLoungables }
  else
    return false
  end
end

--- Fetches the occupation state of a target sexnode asynchronously
--- @param args table
--- @param board table
function asyncIsNotFull(args, board)
    local target = args.entity
    local promise = world.sendEntityMessage(target, "Sexbound:Retrieve:IsFull")
    while true do
        if promise:finished() then
            if promise:succeeded() then
                local full = not not promise:result()
                if full then return false end
            else return false end
            promise = world.sendEntityMessage(target, "Sexbound:Retrieve:IsFull")
        end

        coroutine.yield(nil)
    end
    return false
end

--- Attempts to lounge this NPC in a sexnode with multiple possible seat anchors
--- @param args table
--- @param board table
function loungeMultiSeat(args, board)
    local target = args.entity
    local success = false
    if target == nil then return false end
    if not npc.isLounging() or npc.loungingIn() ~= target then
        local seatCount = getObjectSeatCount(target)
        for i=1,seatCount do
            success = npc.setLounging(target, (-1+i))
            if success then break end
        end
    end
    self.lounge = success
    return success
end

--- [Helper] Attempt to retrieve the amount of defined seat anchors from an object's config
--- @param entityId EntityId The object entity's ID
--- @return integer # The count of seat anchors
function getObjectSeatCount(entityId)
    if not entityId or not world.entityExists(entityId) then return 1 end
    local config = world.getObjectParameter(entityId, "orientations", {})
    if not config or not config[1] then return 1 end
    local orientation = config[1]
    if not orientation.sitPositions then return 1 end
    return #orientation.sitPositions
end

--- [Helper] Dumps a table as log-able string
--- @param o any Any object
--- @return string # The assembled string dump
function dump(o)
    if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--- [Helper] Dumps a table as log-able string, only traversing one layer
--- @param o any Any object
--- @return string # The assembled string dump
function shallowDump(o)
    if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. tostring(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--- [Helper] Dumps a table as log-able string up to a defined maximum depth
--- @param o any Any object
--- @param n integer? The maximum depth (Default: 1)
--- @param i integer? The starting depth (Default: 0)
--- @return string # The assembled string dump
function leveledDump(o,n,i)
    i=i or 0
    n=n or 1
    if type(o) == 'table' and i < n then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. leveledDump(v,n,i+1) .. ','
      end
      return s .. '} '
    else
      return tostring(o)
    end
end

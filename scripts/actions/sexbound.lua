-- Sexbound Behavior Actions
-- @author Locuturus
-- @license GNU General Public License v3.0
--- Uses radio to broadcast a message to announce birth.
-- @param args
-- @param board
function announceBirth(args, board)
    local targetEntity = self.sb_npc or self.sb_monster

    if targetEntity then
        targetEntity:announceBirth()
    end

    return false
end

--- Checks if the entity is ready to give birth.
-- @params args
-- @params board
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
-- @params args
-- @params board
function failedTransformation(args, board)
    local targetEntity = self.sb_npc or self.sb_monster
    if not targetEntity then
        return false
    end

    targetEntity:failedTransformation()
    return true
end

--- Returns the first known open block position within an inputted area.
-- @params args
-- @params board
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
-- @params args
-- @params board
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
-- @params args
-- @params board
function isFullyOccupied(args, board)
    -- Not implemented yet
end

--- Returns whether or not the entity is having sex.
-- @params args
-- @params board
function isHavingSex(args, board)
    local targetEntity = self.sb_monster or self.sb_npc

    if not targetEntity then
        return false
    end

    return targetEntity._isHavingSex
end

--- Attempts to have entity place a sex node on the ground below its feet.
-- @params args
-- @params board
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
-- @params args
-- @params board
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
-- @params args
-- @params board
function hasPregnancy(args, board)
    if not storage.sexbound.pregnant or isEmpty(storage.sexbound.pregnant) then
        return false
    end
    return true, {
        pregnancyList = storage.sexbound.pregnant
    }
end

--- Checks whether or not the entity will respawn upon death.
-- @params args
-- @params board
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
-- @params args
-- @params board
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
-- @params args
-- @params board
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
-- @params args
-- @params board
function safeGetResource(args, board)
    if not status.isResource(args.resource) then
        return false
    end
    return true, status.resource(args.resource)
end

--- Returns a resource's percent value safely.
-- @params args
-- @params board
function safeResourcePercentage(args, board)
    if not status.isResource(args.resource) then
        return false
    end
    return status.resourcePercentage(args.resource) > args.percentage
end

--- Untransforms this entity
-- @params args
-- @params board
function smashSexNode(args, board)
    local targetEntity = self.sb_monster or self.sb_npc

    if targetEntity then
        targetEntity:getTransform():smashSexNode()
        return true
    end

    return false
end

--- Unloads this entity as a sex actor.
-- @params args
-- @params board
function unloadSexActor(args, board)
    local targetEntity = self.sb_monster or self.sb_npc

    if targetEntity then
        targetEntity:unload()
        return true
    end

    return false
end

function debugBehaviour(args, board)
    if (self.sb_monster or self.sb_npc):canLog("behavior") then
        sb.logInfo("LOGGING OF BEHAVIOR")
        sb.logInfo(leveledDump(args, 2))
        sb.logInfo(leveledDump(board, 2))
    end
    return true
end

function sortSexnodes(args, board)
    local list = args.list or {}
    local i = 1
    local res = nil
    local seen = {}
    local controllers = {}
    local nodeToController = {}
    if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("NODE BEHAVIOUR OF ENTITY #"..entity.id()) end
    while i <= #list do
        -- For each node queries, fetch the controller that it belongs to
        local id = list[i] or 0
        res = world.callScriptedEntity(id, "returnControllerId");
        i = i + 1
        if (self.sb_monster or self.sb_npc):canLog("behavior") then
            sb.logInfo("CALLING NODE #"..id)
            sb.logInfo("GOT ID #"..tostring(res))
        end
        if res and not seen[res] then
            controllers[res] = false
            seen[res] = true
        end
        if res then nodeToController[id] = res end
    end
    if not next(controllers) then return false end
    res = nil
    for id,_ in pairs(controllers) do
        -- For each unique controller, fetch the compatibility index
        local r,e = pcall(function() res = world.callScriptedEntity(id, "checkNodeCompatibility", (self.sb_monster or self.sb_npc):getCompatibilityData()) end)
        if not r then sb.logError(e) res = -1 end
        if (self.sb_monster or self.sb_npc):canLog("behavior") then
            sb.logInfo("CALLING CONTROLLER #"..id)
            sb.logInfo("GOT INDEX "..tostring(res))
        end
        controllers[id] = res
    end
    local targetNode = nil
    local targetIndex = 0
    for j=1,#list do
        local curIndex = controllers[nodeToController[list[j]]] or 0
        if curIndex > targetIndex then targetNode = list[j] targetIndex = curIndex end
    end
    if (self.sb_monster or self.sb_npc):canLog("behavior") then sb.logInfo("FINAL NODE: #"..tostring(targetNode).." with "..tostring(targetIndex)) end
    if targetNode == nil then return false end
    return true, {list=list,entity=targetNode,data={controllers=controllers,nodeToController=nodeToController}}
end

--- Function to count down a given time and FAIL upon completion.
-- Starbound spaghetti 101: Behaviour loop abortions.
-- There is an issue with the pathfinding that makes NPCs go stuck forever when their arousal told them to go to a node they can't reach, unless that node get's occupied by someone else or destroyed.
-- Solution: Timeout which fails the current execution loop so the whole node finding process starts over (if applicable)
-- Problem: Starbound. For a parallel execution node to fail, the specified number of nodes (parameter "fail") needs to return 'false' as first value. In this case any 1 node needs to fail for everything to abort.
-- However, the timer returns 'true' upon completion and 'nil' while still ticking, like any yielding multi-tick node.
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

  local lastPosition = false
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

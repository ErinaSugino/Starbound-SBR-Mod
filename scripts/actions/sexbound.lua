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
    if (self.sb_monster or self.sb_npc):canLog("behaviour") then
        sb.logInfo("LOGGING OF BEHAVIOUR")
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
    while i <= #list do
        -- For each node queries, fetch the controller that it belongs to
        local id = list[i] or 0
        res = world.callScriptedEntity(id, "returnControllerId");
        i = i + 1
        if (self.sb_monster or self.sb_npc):canLog("behaviour") then
            sb.logInfo("CALLING NODE#"..id)
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
        res = world.callScriptedEntity(id, "checkNodeCompatibility", (self.sb_monster or self.sb_npc):getCompatibilityData());
        if (self.sb_monster or self.sb_npc):canLog("behaviour") then
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
    if (self.sb_monster or self.sb_npc):canLog("behaviour") then sb.logInfo("FINAL NODE: #"..tostring(targetNode).." with "..tostring(targetIndex)) end
    if targetNode == nil then return false end
    return true, {list=list,entity=targetNode}
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

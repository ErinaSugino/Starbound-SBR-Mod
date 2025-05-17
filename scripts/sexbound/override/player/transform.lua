require "/scripts/sexbound/override/common/transform.lua"

Sexbound.Player.Transform = Sexbound.Common.Transform:new()
Sexbound.Player.Transform_mt = {
    __index = Sexbound.Player.Transform
}

function Sexbound.Player.Transform:new(parent)
    local _self = setmetatable({
        _canTransform = true,
        _mindControl = {},
        _nodeName = "sexbound_main_node",
        _parent = parent
    }, Sexbound.Player.Transform_mt)

    _self:init(parent)

    status.setStatusProperty("sexbound_mind_control", false)

    message.setHandler("Sexbound:Transform", function(_, _, args)
        return _self:handleTransform(args)
    end)

    return _self
end

function Sexbound.Player.Transform:handleTransform(args)
    if self:getCanTransform() then
        -- Override sexbound config that is supplied to the spawned sexnode
        self:setSexboundConfig(args.sexboundConfig)
        
        self:setTimeout(args.timeout)
        
        local targetEntity = args.targetEntity or player.id()
        local result = self:tryCreateNode(targetEntity, args.spawnOptions or {}, args.position or nil)

        if result ~= nil and args.applyStatusEffects ~= nil and targetEntity ~= player.id() then
            for _, statusName in ipairs(args.applyStatusEffects) do
                status.addEphemeralEffect(statusName, args.timeout)
            end
        end

        return result
    end

    return false
end

function Sexbound.Player.Transform:tryCreateNode(targetEntity, spawnOptions, position)
    -- Place Sexnode and store Unique ID
    local uniqueId = self:placeSexNode({
        targetEntity = targetEntity,
        randomStartPosition = true,
        noEffect = spawnOptions.noEffect or false
    }, position or nil)
    if self._parent:canLog("debug") then sb.logInfo("Placed node with UUID "..tostring(uniqueId)) end
    if uniqueId ~= nil then
        world.sendEntityMessage(targetEntity, "Sexbound:Transform:Success", {
            uniqueId = uniqueId
        })
        if targetEntity ~= player.id() then self._controllerId = uniqueId end -- Handle remote transformation
        return {
            uniqueId = uniqueId
        }
    else
        world.sendEntityMessage(targetEntity, "Sexbound:Transform:Failure")
        return nil
    end
end

function Sexbound.Player.Transform:dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. self:dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

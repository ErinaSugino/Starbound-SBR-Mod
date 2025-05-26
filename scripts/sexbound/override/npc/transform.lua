require "/scripts/sexbound/override/common/transform.lua"

Sexbound.NPC.Transform = Sexbound.Common.Transform:new()
Sexbound.NPC.Transform_mt = {
    __index = Sexbound.NPC.Transform
}

function Sexbound.NPC.Transform:new(parent)
    local _self = setmetatable({
        _nodeName = "sexbound_main_node_centered",
        _parent = parent
    }, Sexbound.NPC.Transform_mt)

    _self:init(parent)

    _self:setCanTransform(true);

    message.setHandler("Sexbound:Transform", function(_, _, args)
        return _self:handleTransform(args)
    end)

    return _self
end

function Sexbound.NPC.Transform:handleTransform(args)
    if self._parent._isKid then return false end

    if self:getCanTransform() or actorData ~= nil then
        -- Override sexbound config that is supplied to the spawned sexnode
        self:setSexboundConfig(args.sexboundConfig)

        self:setTimeout(args.timeout)

        if not args.responseRequired then
            self:notifyTransform()
        else
            local targetEntity = args.targetEntity or entity.id()
            local result = self:tryCreateNode(targetEntity, args.spawnOptions or {}, args.position or nil, args.node or nil)

            if result ~= nil and targetEntity == entity.id() then
                -- Only apply things for this entity if not remote transformation
                if args.applyStatusEffects ~= nil then
                    for _, statusName in ipairs(args.applyStatusEffects) do
                        status.addEphemeralEffect(statusName, args.timeout)
                    end
                end
                
                -- Make sure this transformed NPCs arousal is reduced to zero so it doesn't try to use itself
                self:getParent():getArousal():instaMin()
                
                storage.previousDamageTeam = storage.previousDamageTeam or world.entityDamageTeam(entity.id())
                
                npc.setDamageTeam({
                    type = "ghostly"
                })

                npc.setInteractive(false)
            end

            return result
        end

        return true
    end

    return false
end

function Sexbound.NPC.Transform:notifyTransform()
    if notify and not self:getParent():getIsHavingSex() then
        notify({
            type = "sexbound.transform",
            sourceId = entity.id()
        })
    end
end

function Sexbound.NPC.Transform:tryCreateNode(targetEntity, spawnOptions, position, nodeOverride)
    if self._parent._isKid then return nil end
    
    local uniqueId = self:placeSexNode({
        targetEntity = targetEntity,
        randomStartPosition = true,
        noEffect = spawnOptions.noEffect or false,
        node = nodeOverride
    }, position or nil)

    if uniqueId ~= nil then
        world.sendEntityMessage(targetEntity, "Sexbound:Transform:Success", {
            uniqueId = uniqueId
        })
        if targetEntity == entity.id() then self._controllerId = uniqueId end -- Handle remote transformation
        return {
            uniqueId = uniqueId
        }
    else
        world.sendEntityMessage(targetEntity, "Sexbound:Transform:Failure")
        return nil
    end
end

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
    if self:getCanTransform() then
        -- Override sexbound config that is supplied to the spawned sexnode
        self:setSexboundConfig(args.sexboundConfig)

        self:setTimeout(args.timeout)

        if not args.responseRequired then
            self:notifyTransform()
        else
            local result = self:tryCreateNode()

            if result ~= nil and args.applyStatusEffects ~= nil then
                for _, statusName in ipairs(args.applyStatusEffects) do
                    status.addEphemeralEffect(statusName, args.timeout)
                end
            end

            if result ~= nil then
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

function Sexbound.NPC.Transform:tryCreateNode()
    local position = self:findNearbyOpenSpace()

    if position == false then
        return nil
    end

    -- Place Sexnode and store Unique ID
    local uniqueId = self:placeSexNode(position, {
        randomStartPosition = true
    })

    if uniqueId ~= nil then
        world.sendEntityMessage(entity.id(), "Sexbound:Transform:Success", {
            uniqueId = uniqueId
        })
        self._controllerId = uniqueId
        return {
            uniqueId = uniqueId
        }
    else
        world.sendEntityMessage(entity.id(), "Sexbound:Transform:Failure")
        return nil
    end
end

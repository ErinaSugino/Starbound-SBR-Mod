require "/scripts/sexbound/override/common/transform.lua"

Sexbound.Monster.Transform = Sexbound.Common.Transform:new()
Sexbound.Monster.Transform_mt = {
    __index = Sexbound.Monster.Transform
}

function Sexbound.Monster.Transform:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Transform_mt)

    _self:init(parent)

    _self:setCanTransform(true);

    message.setHandler("Sexbound:Transform", function(_, _, args, actorData)
        return _self:handleTransform(args, actorData)
    end)

    return _self
end

function Sexbound.Monster.Transform:handleTransform(args, actorData)
    if self:getCanTransform() or actorData ~= nil then
        self:setSexboundConfig(args.sexboundConfig)

        self:setTimeout(args.timeout)

        if not args.responseRequired then
            self:notifyTransform()
        else
            local result = self:tryCreateNode(args.spawnOptions or {}, args.position or nil, actorData or nil)

            if result ~= nil and args.applyStatusEffects ~= nil then
                for _, statusName in ipairs(args.applyStatusEffects) do
                    status.addEphemeralEffect(statusName, args.timeout)
                end
            end

            if result ~= nil then
                -- Make sure this transformed NPCs arousal is reduced to zero so it doesn't try to use itself
                self:getParent():getArousal():instaMin()

                storage.previousDamageTeam = storage.previousDamageTeam or world.entityDamageTeam(entity.id())

                monster.setDamageTeam({
                    type = "ghostly"
                })

                monster.setInteractive(false)
            end

            return result
        end

        return true
    end

    return false
end

function Sexbound.Monster.Transform:tryCreateNode(spawnOptions, position, actorData)
    local uniqueId = self:placeSexNode({
        randomStartPosition = true,
        noEffect = spawnOptions.noEffect or false
    }, position or nil, actorData or nil)

    if uniqueId ~= nil then
        world.sendEntityMessage(entity.id(), "Sexbound:Transform:Success", {
            uniqueId = uniqueId
        })
        return {
            uniqueId = uniqueId
        }
    else
        world.sendEntityMessage(entity.id(), "Sexbound:Transform:Failure")
        return nil
    end
end

function Sexbound.Monster.Transform:notifyTransform()
    if notify and not self._parent:getIsHavingSex() then
        notify({
            type = "sexbound.transform",
            sourceId = entity.id()
        })
    end
end

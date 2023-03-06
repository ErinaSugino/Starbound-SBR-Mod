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

    message.setHandler("Sexbound:Transform", function(_, _, args)
        return _self:handleTransform(args)
    end)

    return _self
end

function Sexbound.Monster.Transform:handleTransform(args)
    if self:getCanTransform() then
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

function Sexbound.Monster.Transform:tryCreateNode()
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

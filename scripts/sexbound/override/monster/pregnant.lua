require "/scripts/sexbound/override/common/pregnant.lua"

Sexbound.Monster.Pregnant = Sexbound.Common.Pregnant:new()
Sexbound.Monster.Pregnant_mt = {
    __index = Sexbound.Monster.Pregnant
}

function Sexbound.Monster.Pregnant:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Pregnant_mt)

    _self:init(parent)

    return _self
end

function Sexbound.Monster.Pregnant:update(dt)
    if self._isGivingBirth then
        return
    end

    if self:findReadyBabyIndex() then
        self._isGivingBirth = true

        self:handleGiveBirth(self:findReadyBabyIndex())

        return
    end
end

function Sexbound.Monster.Pregnant:handleGiveBirth(index)
    if self:isGivingBirth() then return end

    self:setIsGivingBirth(true)
    self:dataFilter()

    local pregnancies = {}
    local birthResult = nil

    for i, v in ipairs(storage.sexbound.pregnant) do
        if index == i then
            local giveBirthTo = config.getParameter('sexboundConfig', {}).giveBirthTo
            if giveBirthTo then
                giveBirthTo.pregnancyType = giveBirthTo.pregnancyType or "baby"
                birthResult = self:giveBirthTo(giveBirthTo)
            else
                birthResult = {}
                for _,b in pairs(v.babies) do
                    b.pregnancyType = v.pregnancyType --Propagate pregnancy type for giveBirth()
                    table.insert(birthResult, self:giveBirth(b, nil, v.incestLevel))
                end
                if #birthResult < 1 then birthResult = nil end
            end
        else
            table.insert(pregnancies, v)
        end
    end

    storage.sexbound.pregnant = pregnancies
    self:setIsGivingBirth(false)
    self:refreshStatusEffects()
    return birthResult
end

function Sexbound.Monster.Pregnant:giveBirthTo(babyConfig)
    for _, _item in ipairs(babyConfig) do
        if _item.type == "item" or _item.type == "object" then
            return world.spawnItem(_item.name, entity.position(), _item.count or 1, _item.params)
        end
    end
end

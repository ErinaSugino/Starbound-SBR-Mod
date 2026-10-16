require "/scripts/sexbound/override/common/pregnant.lua"

--- Monster pregnancy manager class
--- @class Sexbound.Monster.Pregnant: Sexbound.Common.Pregnant
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Monster
Sexbound.Monster.Pregnant = Sexbound.Common.Pregnant:new()
Sexbound.Monster.Pregnant_mt = {
    __index = Sexbound.Monster.Pregnant
}

--- Creates a new monster pregnancy manager instance
--- @param parent Sexbound.Monster The calling parent monster manager instance
--- @return Sexbound.Monster.Pregnant # The newly created monster pregnancy manager instance
function Sexbound.Monster.Pregnant:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Monster.Pregnant_mt)

    _self:init(parent)

    return _self
end

--- Function called each tick to progress timers
--- @param dt number The delta time since last tick
function Sexbound.Monster.Pregnant:update(dt)
    if self._isGivingBirth then
        return
    end

    local readyIndex = self:findReadyBabyIndex()
    if readyIndex then
        self._isGivingBirth = true

        self:handleGiveBirth(readyIndex)

        return
    end
end

--- Message handler for request to give birth
--- @param index integer The index of the pregnancy to give birth to
--- @return EntityId[]? # The list of successfully spawned entity ids, if any
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

--- Function to give birth to a baby in item form
--- @param babyConfig table Babdy config
--- @return EntityId? # The spawned item's entity id, if successful
function Sexbound.Monster.Pregnant:giveBirthTo(babyConfig)
    for _, _item in ipairs(babyConfig) do
        if _item.type == "item" or _item.type == "object" then
            return world.spawnItem(_item.name, entity.position(), _item.count or 1, _item.params)
        end
    end
end

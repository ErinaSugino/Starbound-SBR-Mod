require "/scripts/sexbound/override/common/pregnant.lua"

--- NPC pregnancy manager class
--- @class Sexbound.NPC.Pregnant: Sexbound.Common.Pregnant
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.NPC
Sexbound.NPC.Pregnant = Sexbound.Common.Pregnant:new()
Sexbound.NPC.Pregnant_mt = {
    __index = Sexbound.NPC.Pregnant
}

--- Creates a new npc pregnancy manager instance
--- @param parent Sexbound.NPC The calling parent npc manager instance
--- @return Sexbound.NPC.Pregnant # The newly created npc pregnancy manager instance
function Sexbound.NPC.Pregnant:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Pregnant_mt)

    _self:init(parent)
    _self:initMessageHandlers()
    _self:refreshStatusText()
    return _self
end

--- Initialize additional message handlers
function Sexbound.NPC.Pregnant:initMessageHandlers()
    message.setHandler("Sexbound:Pregnant:RefreshStatusText", function(_, _, args)
        return self:handleRefreshStatusText()
    end)
    message.setHandler("Sexbound:Pregnant:Abort", function(_, _, args)
        return self:abortPregnancy()
    end)
end

--- Message handler for request to give birth
--- @param index number The index of the pregnancy to birth in the list
--- @return EntityId[]? # The list of entity ids of successfully birthed entities, if any
function Sexbound.NPC.Pregnant:handleGiveBirth(index)
    if self:isGivingBirth() then return end

    self:setIsGivingBirth(true)
    self:dataFilter()

    local pregnancies = {}
    local birthResult = nil

    for i, v in ipairs(storage.sexbound.pregnant) do
        if index == i then
            birthResult = {}
            for _,b in pairs(v.babies) do
                b.pregnancyType = v.pregnancyType --Propagate pregnancy type for giveBirth()
                table.insert(birthResult, self:giveBirth(b, nil, v.incestLevel))
            end
            if #birthResult < 1 then birthResult = nil end
        else
            table.insert(pregnancies, v)
        end
    end

    storage.sexbound.pregnant = pregnancies
    self:setIsGivingBirth(false)
    self:refreshStatusText()
    self:refreshStatusEffects()

    return birthResult
end

--- Aborts all pregnancies
function Sexbound.NPC.Pregnant:abortPregnancy()
    self:abortPregnancy()
    self:refreshStatusText()
    self:refreshStatusEffects()
end

--- Message handler for request to refresh status text
--- @return nil
function Sexbound.NPC.Pregnant:handleRefreshStatusText()
    return self:refreshStatusText()
end

--- Refreshes the status text of the NPC
function Sexbound.NPC.Pregnant:refreshStatusText()
    if not isEmpty(storage.sexbound.pregnant or {}) then
        self._parent:showName()
        storage.statusText = "Pregnant"
    else
        self._parent:hideName()
        storage.statusText = nil
    end

    npc.setStatusText(storage.statusText)
end

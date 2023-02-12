require "/scripts/sexbound/override/common/pregnant.lua"

Sexbound.NPC.Pregnant = Sexbound.Common.Pregnant:new()
Sexbound.NPC.Pregnant_mt = {
    __index = Sexbound.NPC.Pregnant
}

function Sexbound.NPC.Pregnant:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Pregnant_mt)

    _self:init(parent)
    _self:initMessageHandlers()
    _self:refreshStatusText()
    return _self
end

function Sexbound.NPC.Pregnant:initMessageHandlers()
    message.setHandler("Sexbound:Pregnant:RefreshStatusText", function(_, _, args)
        return self:handleRefreshStatusText()
    end)
    message.setHandler("Sexbound:Pregnant:Abort", function(_, _, args)
        return self:abortPregnancy()
    end)
end

function Sexbound.NPC.Pregnant:handleGiveBirth(index)
    if self:isGivingBirth() then return end

    self:setIsGivingBirth(true)
    self:dataFilter()

    local pregnancies = {}
    local birthResult = nil

    for k, v in pairs(storage.sexbound.pregnant) do
        if index == k then
            birthResult = self:giveBirth(v)
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

function Sexbound.NPC.Pregnant:abortPregnancy()
    Sexbound.Common.Pregnant.abortPregnancy(self)

    self:refreshStatusText()
    self:refreshStatusEffects()
end

function Sexbound.NPC.Pregnant:handleRefreshStatusText()
    return self:refreshStatusText()
end

function Sexbound.NPC.Pregnant:refreshStatusText()
    if not isEmpty(storage.sexbound.pregnant or {}) then
        self:getParent():showName()
        storage.statusText = "Pregnant"
    else
        self:getParent():hideName()
        storage.statusText = nil
    end

    npc.setStatusText(storage.statusText)
end

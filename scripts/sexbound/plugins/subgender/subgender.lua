--- Sexbound.Actor.Subgender Class Module.
-- @classmod Sexbound.Actor.Subgender
-- @author Erina Sugino
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

Sexbound.Actor.Subgender = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Subgender_mt = {
    __index = Sexbound.Actor.Subgender
}

--- Instantiates a new instance of Subgender.
-- @param parent
-- @param config
function Sexbound.Actor.Subgender:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "SUBG",
        _config = config,
        _previousSxbGender = nil,
        _genderOrder = {}
    }, Sexbound.Actor.Subgender_mt)

    _self:init(parent, _self._logPrefix)

    _self:verifyBaseGender()

    _self:initialCheck()
    _self._previousSxbGender = parent:getIdentity().sxbSubGender

    local defaultStatuses = {equipped_futamode="futanari"}

    _self._config.statuseffects = _self._config.statuseffects or defaultStatuses

    return _self
end

--- Handles message events.
-- @param message
function Sexbound.Actor.Subgender:onMessage(message)
    if message:getType() == "Sexbound:Status:AddStatus" then
        self:handleAddStatus(message)
    end

    if message:getType() == "Sexbound:Status:RemoveStatus" then
        self:handleRemoveStatus(message)
    end
end

--- Handles 'AddStatus' message event
-- @params message
function Sexbound.Actor.Subgender:handleAddStatus(message)
    local statusName = message:getData()
    local gender = self:getParent():getGender()
    local subgenders = self:getDefinedGender(statusName)
    if not subgenders then return end
    self:getLog():debug("Actor "..self:getParent():getName().." got subgender relevant status effect "..tostring(statusName))
    if type(subgenders) ~= "table" then subgenders = {subgenders} end
    local changes = 0
    for _,subgender in ipairs(subgenders) do
        if subgender and self:passesGenderRestriction(subgender, gender) then
            self:getLog():debug("Adding subgender by status: "..tostring(subgender))
            self:replaceSxbSubGender(subgender)
            changes = changes + 1
        else
            self:getLog():warn("Trying to add sub-gender "..tostring(subgender).." to actor "..self:getParent():getName()..", but they do not fulfill gender requirements!")
        end
    end
    if changes > 0 then self:getParent():getParent():resetAllActors() end
end

--- Handles 'RemoveStatus' message event
-- @params message
function Sexbound.Actor.Subgender:handleRemoveStatus(message)
    local statusName = message:getData()
    local gender = self:getParent():getGender()
    local subgenders = self:getDefinedGender(statusName)
    if not subgenders then return end
    self:getLog():debug("Actor "..self:getParent():getName().." lost subgender relevant status effect "..tostring(statusName))
    if type(subgenders) ~= "table" then subgenders = {subgenders} end
    local changes = 0
    for _,subgender in ipairs(subgenders) do
        if subgender and self:passesGenderRestriction(subgender, gender) then
            self:getLog():debug("Removing subgender by status: "..tostring(subgender))
            self:removeSxbSubGender(subgender)
            changes = changes + 1
        else
            self:getLog():warn("Trying to remove sub-gender "..tostring(subgender).." from actor "..self:getParent():getName()..", but they do not fulfill gender requirements!")
        end
    end
    if changes > 0 then self:getParent():getParent():resetAllActors() end
end

--- Overrides the sxbSubGender identity of this actor to be a given subgender
function Sexbound.Actor.Subgender:replaceSxbSubGender(subgender)
    local identity = self:getParent():getIdentity()
    identity.sxbSubGender = subgender
    self:getLog():info("Actor "..self:getParent():getName().." is changing subgender to "..tostring(subgender))
    -- Remove old if set before
    for i,s in ipairs(self._genderOrder) do
        if s == subgender then table.remove(self._genderOrder, i) end
        break
    end
    -- Reapply at end of list (newest)
    table.insert(self._genderOrder, subgender)
    self:getParent():buildBodyTraits() -- trigger rebuild of actor body traits
end

--- Restores the sxbSubGender identity of this actor to be the previous value
function Sexbound.Actor.Subgender:removeSxbSubGender(subgender)
    local identity = self:getParent():getIdentity()
    local nextGender = nil
    -- Efficient remove all x & keep last entry loop
    local j,n = 1,#self._genderOrder
    for i=1,n do
        local s = self._genderOrder[i]
        if s == subgender then self._genderOrder[i] = nil
        else
            if i ~= j then self._genderOrder[j] = self._genderOrder[i] end
            j = j + 1
            nextGender = s
        end
    end
    identity.sxbSubGender = nextGender or self._previousSxbGender
    self:getLog():info("Actor "..self:getParent():getName().." lost subgender to "..tostring(subgender)..", next gender: "..tostring(identity.sxbSubGender))
    self:getParent():buildBodyTraits() -- trigger rebuild of actor body traits
end

--- Returns the subgender set for a status effect name - or nil if non set
function Sexbound.Actor.Subgender:getDefinedGender(statusName)
    return self:getConfig().statuseffects[statusName]
end

--- Returns if the given gender is the required gender for a given subgender
function Sexbound.Actor.Subgender:passesGenderRestriction(subgender, gender)
    if subgender == nil then return true end
    local targetGender = self:getConfig().genderLimitations[subgender]
    if targetGender == nil then return true end
    return gender == targetGender
end

--- Verifies if the default sub-gender of the actor complies to main gender restrictions
function Sexbound.Actor.Subgender:verifyBaseGender()
    local subgender = self:getParent():getSubGender()
    local gender = self:getParent():getGender()
    
    if not self:passesGenderRestriction(subgender, gender) then
        self:getParent():getIdentity().sxbSubGender = nil
        self:getLog():warn(self:getParent():getName().."'s base sub-gender "..tostring(subgender).." doesn't meet gender requirements, discarding!")
    end
end

--- Checks if there is currently a status set that defines a subgender
function Sexbound.Actor.Subgender:initialCheck()
    local statusList = self:getParent():getStatus():getStatusList() -- list of all statuses, ordered by time adding order with recurring overrides
    local gender = self:getParent():getGender()
    for _,s in ipairs(statusList) do
        local subgenders = self:getDefinedGender(s)
        if subgenders then
            sb.logInfo("Got initial status with subgender: "..tostring(s))
            if type(subgenders) ~= "table" then subgenders = {subgenders} end
            for _,subgender in ipairs(subgenders) do
                if self:passesGenderRestriction(subgender, gender) then self:replaceSxbSubGender(subgender)
                else self:getLog():warn(self:getParent():getName().."'s initially defined status for sub-gender "..tostring(subgender).." doesn't meet gender requirements, ignoring!") end
            end
        end
    end
    
    self:getParent():getParent():resetAllActors()
end

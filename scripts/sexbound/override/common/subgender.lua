--- Abstract shared entity sub-gender manager class
--- @class Sexbound.Common.SubGender
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _config table
--- @field _genderOrder string[]
--- @field _previousSxbGender string?
Sexbound.Common.SubGender = {}
Sexbound.Common.SubGender_mt = {
    __index = Sexbound.Common.SubGender
}

--- Creates new entity sub-gender manager instance
--- @return Sexbound.Common.SubGender # The newly created entity sub-gender manager instance
function Sexbound.Common.SubGender:new()
    local _self = setmetatable({}, Sexbound.Common.SubGender_mt)

    if type(storage.sexbound.identity) ~= "table" then
        storage.sexbound.identity = {}
    end

    if _self:getSxbSubGender() == nil then
        _self:trySettingSubGenderFromStatusProperty()
    end

    _self._genderOrder = {}
    _self._previousSxbGender = storage.sexbound.identity.sxbSubGender

    return _self
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager class
function Sexbound.Common.SubGender:init(parent)
    self._parent = parent

    self:loadPluginConfig()
    self:initMessageHandlers()


    local gender = self:getParent():getGender()
    self._currentGender = self._previousSxbGender or gender
    if not self:passesGenderRestriction(self._currentGender, gender) then
        if self._parent:canLog("warn") then sb.logWarn("Entity #"..entity.id().."'s base sub-gender "..tostring(self._currentGender).." doesn't meet gender requirements, discarding!") end
        self._currentGender, self._previousSxbGender = gender, nil
        self:getParent():buildBodyTraits(self._currentGender)
    end

    if self._parent:canLog("debug") then sb.logInfo("Current gender for #"..entity.id().." is "..tostring(self._currentGender)) end
end

--- Uninitalizes this plugin
function Sexbound.Common.SubGender:uninit() end

--- Loads the sub-gender plugin config file
function Sexbound.Common.SubGender:loadPluginConfig()
    local configs = self:getParent():getConfig() or {}
    configs = configs.actor or {}
    configs = configs.plugins or {}
    configs = configs.subgender or {}
    configs = configs.config or {}

    if "table" ~= type(configs) then
        configs = {configs}
    end

    local loadedConfig = {}

    for _, _config in pairs(configs) do
        xpcall(function()
            loadedConfig = util.mergeTable(loadedConfig, root.assetJson(_config))
        end, function(errorMessage)
            sb.logError(errorMessage)
        end)
    end

    self._config = loadedConfig
end

--- Tries to set the sub-gender from an existing status property on the entity
function Sexbound.Common.SubGender:trySettingSubGenderFromStatusProperty()
    if status.statusProperty("sxbSubGender") ~= "default" then
        storage.sexbound.identity.sxbSubGender = status.statusProperty("sxbSubGender")
    end
end

--- Initializes entity message handlers
function Sexbound.Common.SubGender:initMessageHandlers()
    message.setHandler("Sexbound:SubGender:Change", function(_, _, args)
        return self:handleSxbSubGenderChange(args)
    end)
end

--- Message handler for sub-gender change
--- @param args string The name of the new sub-gender
--- @return string? # The currently set sub-gender for success verification
function Sexbound.Common.SubGender:handleSxbSubGenderChange(args)
    local sxbSubGenderName = args
    if self:passesGenderRestriction(sxbSubGenderName, self:getParent():getGender()) then self:setSxbSubGender(sxbSubGenderName)
    elseif self._parent:canLog("warn") then sb.logWarn("Entity #"..entity.id().."'s request to persistently change sub-gender to "..tostring(sxbSubGenderName).." doesn't fulfill gender requirement, ignoring!") end
    return self:getSxbSubGender()
end

--- Returns the currently set persistent sub-gender
--- @return string? # Currently set persistent sub-gender
function Sexbound.Common.SubGender:getSxbSubGender()
    return storage.sexbound.identity.sxbSubGender
end

--- Returns the current gender of this entity
--- @return string # Current gender of this entity
function Sexbound.Common.SubGender:getCurrentGender()
    return self._currentGender
end

--- Sets a new persistent sub-gender
--- @param sxbSubGenderName string? The new sub-gender
function Sexbound.Common.SubGender:setSxbSubGender(sxbSubGenderName)
    self:updateSxbSubGenderMultiplier(sxbSubGenderName)

    storage.sexbound.identity.sxbSubGender = sxbSubGenderName
    status.statusProperty("sxbSubGender", sxbSubGenderName)

    if #self._genderOrder < 1 then self._currentGender = sxbSubGenderName self:getParent():buildBodyTraits(sxbSubGenderName) end
    self._previousSxbGender = sxbSubGenderName
    if self._parent:canLog("debug") then sb.logInfo("Persistently changed entity sub-gender of #"..entity.id().." to "..tostring(sxbSubGenderName)) end
end

--- Updates some weird ancient value that tracks how often the same sub-gender was applied in succession
--- @param sxbSubGenderName string? The sub-gender name
function Sexbound.Common.SubGender:updateSxbSubGenderMultiplier(sxbSubGenderName)
    local multipler = storage.sexbound.identity.sxbSubGenderMultiplier or 1

    if sxbSubGenderName == self:getSxbSubGender() then
        multipler = multipler + 1
    else
        multipler = 1
    end

    storage.sexbound.identity.sxbSubGenderMultiplier = multipler
end

--- Message handler for adding statuses
--- @param statusName string The name of the applied status
function Sexbound.Common.SubGender:handleAddStatus(statusName)
    local gender = self:getParent():getGender()
    local subgenders = self:getDefinedGender(statusName)
    if type(subgenders) ~= "table" then subgenders = {subgenders} end
    for _,subgender in ipairs(subgenders) do
        if subgender and self:passesGenderRestriction(subgender, gender) then
            self:replaceSxbSubGender(subgender)
        elseif self._parent:canLog("warn") then sb.logWarn("Entity #"..entity.id().."'s sub-gender didn't change to "..tostring(subgender).." by status due to gender requirements!") end
    end
end

--- Message handler for removing statuses
--- @param statusName string The name of the removed status
function Sexbound.Common.SubGender:handleRemoveStatus(statusName)
    local gender = self:getParent():getGender()
    local subgenders = self:getDefinedGender(statusName)
    for _,subgender in ipairs(subgenders or {}) do
        if subgender and self:passesGenderRestriction(subgender, gender) then
            self:removeSxbSubGender(subgender)
        elseif self._parent:canLog("warn") then sb.logWarn("Entity #"..entity.id().."'s sub-gender didn't attempt to revoke "..tostring(statusName).." by status due to gender requirements!") end
    end
end

--- Overrides the sxbSubGender identity of this actor to be a given subgender
--- @param subgender string? The name of the new sub-gender
function Sexbound.Common.SubGender:replaceSxbSubGender(subgender)
    local identity = storage.sexbound.identity or {}
    self._currentGender = subgender
    -- Remove old if set before
    for i,s in ipairs(self._genderOrder) do
        if s == subgender then table.remove(self._genderOrder, i) end
        break
    end
    -- Reapply at end of list (newest)
    table.insert(self._genderOrder, subgender)
    self:getParent():buildBodyTraits(self._currentGender) -- trigger rebuild of entity body traits
end

--- Restores the sxbSubGender identity of this actor to be the previous value
--- @param subgender string? The name of the sub-gender
function Sexbound.Common.SubGender:removeSxbSubGender(subgender)
    local identity = storage.sexbound.identity or {}
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
    self._currentGender = nextGender or self._previousSxbGender or self:getParent():getGender()
    self:getParent():buildBodyTraits(self._currentGender) -- trigger rebuild of entity body traits
end

--- Returns a random sub-gender for the entity's main gender
--- @return string? # The chosen sub-gender
function Sexbound.Common.SubGender:createRandomSubGender()
    local possibleSubGenders = {}
    local count = 0
    for _,g in ipairs(self:getAllSubGenders()) do
        if g.available then table.insert(possibleSubGenders, g.name) count = count + 1 end
    end

    if count <= 0 then return nil end
    if count == 1 then return possibleSubGenders[1] end
    return util.randomChoice(possibleSubGenders)
end

--- Returns the subgender set for a status effect name - or nil if non set
--- @param statusName string The name of the status
--- @return string[]? # All defined sub-gender associated with the given status name, if any
function Sexbound.Common.SubGender:getDefinedGender(statusName)
    return self._config.statuseffects[statusName]
end

--- Returns if the given gender is the required gender for a given subgender
--- @param subgender string The name of the sub-gender to check
--- @param gender string The name of the main gender to check against
--- @return boolean # Whethere or not the main gender allows the given sub-gender
function Sexbound.Common.SubGender:passesGenderRestriction(subgender, gender)
    if subgender == nil then return true end
    local targetGender = self._config.genderLimitations[subgender]
    if targetGender == nil then return true end
    return gender == targetGender
end

--- Restores the original sub-gender, removing all temporary sub-genders
function Sexbound.Common.SubGender:restoreOriginalSubgender()
    storage.sexbound.identity.sxbSubGender = self._previousSxbGender
    status.statusProperty("sxbSubGender", self._previousSxbGender)
end

--- Returns the parent entity manager instance
--- @return Sexbound.Common # The parent entity manager instance
function Sexbound.Common.SubGender:getParent()
    return self._parent
end

--- Returns the sub-gender plugin config
--- @return table # The sub-gender plugin config
function Sexbound.Common.SubGender:getConfig()
    return self._config
end

--- Method for the customizer UI to fetch available sub-genders you can switch to.
--- @return {name: string, available: boolean}[] # The list of all sub-genders and whethere or not this entity can have it
function Sexbound.Common.SubGender:getAllSubGenders()
    local allSubGenders = self:getParent():getConfig().allGenders or {}
    local allSubGenderIndices = self:getParent():getConfig().allGenderIndices or {}
    local gender = self:getParent():getGender()
    local result = {}
    for _,i in ipairs(allSubGenderIndices) do
        if i ~= "male" and i ~= "female" then table.insert(result, {name=i,available=self:passesGenderRestriction(i,gender)}) end
    end
    return result
end

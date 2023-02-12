Sexbound.Common.SubGender = {}
Sexbound.Common.SubGender_mt = {
    __index = Sexbound.Common.SubGender
}

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

function Sexbound.Common.SubGender:init()
    self:loadPluginConfig()
    self:initMessageHandlers()
    
    
    local gender = self:getParent():getGender()
    self._currentGender = self._previousSxbGender or gender
    if not self:passesGenderRestriction(self._currentGender, gender) then
        sb.logWarn("Entity #"..entity.id().."'s base sub-gender "..tostring(self._currentGender).." doesn't meet gender requirements, discarding!")
        self._currentGender, self._previousSxbGender = gender, nil
        self:getParent():buildBodyTraits(self._currentGender)
    end
    
    sb.logInfo("Current gender for #"..entity.id().." is "..tostring(self._currentGender))
end

function Sexbound.Common.SubGender:uninit()
    --sb.logInfo("Uniniting subgender system for "..entity.id())
    
    --self:restoreOriginalSubgender()
end

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
            self._log:error(errorMessage)
        end)
    end

    self._config = loadedConfig
end

function Sexbound.Common.SubGender:trySettingSubGenderFromStatusProperty()
    if status.statusProperty("sxbSubGender") ~= "default" then
        storage.sexbound.identity.sxbSubGender = status.statusProperty("sxbSubGender")
    end
end

function Sexbound.Common.SubGender:initMessageHandlers()
    message.setHandler("Sexbound:SubGender:Change", function(_, _, args)
        return self:handleSxbSubGenderChange(args)
    end)
end

function Sexbound.Common.SubGender:handleSxbSubGenderChange(args)
    local sxbSubGenderName = args
    if self:passesGenderRestriction(sxbSubGenderName, self:getParent():getGender()) then self:setSxbSubGender(sxbSubGenderName)
    else sb.logWarn("Entity #"..entity.id().."'s request to persistently change sub-gender to "..tostring(sxbSubGenderName).." doesn't fulfill gender requirement, ignoring!") end
    return self:getSxbSubGender()
end

function Sexbound.Common.SubGender:getSxbSubGender()
    return storage.sexbound.identity.sxbSubGender
end

function Sexbound.Common.SubGender:getCurrentGender()
    return self._currentGender
end

function Sexbound.Common.SubGender:setSxbSubGender(sxbSubGenderName)
    self:updateSxbSubGenderMultiplier(sxbSubGenderName)

    storage.sexbound.identity.sxbSubGender = sxbSubGenderName
    status.statusProperty("sxbSubGender", sxbSubGenderName)
    
    if #self._genderOrder < 1 then self:getParent():buildBodyTraits(sxbSubGenderName) end
    self._previousSxbGender = sxbSubGenderName
    sb.logInfo("Persistently changed entity sub-gender of #"..entity.id().." to "..tostring(sxbSubGenderName))
end

function Sexbound.Common.SubGender:updateSxbSubGenderMultiplier(sxbSubGenderName)
    local multipler = storage.sexbound.identity.sxbSubGenderMultiplier or 1

    if sxbSubGenderName == self:getSxbSubGender() then
        multipler = multipler + 1
    else
        multipler = 1
    end

    storage.sexbound.identity.sxbSubGenderMultiplier = multipler
end

--- Handles 'AddStatus' message event
-- @params statusName
function Sexbound.Common.SubGender:handleAddStatus(statusName)
    local gender = self:getParent():getGender()
    local subgenders = self:getDefinedGender(statusName)
    if type(subgenders) ~= "table" then subgenders = {subgenders} end
    for _,subgender in ipairs(subgenders) do
        if subgender and self:passesGenderRestriction(subgender, gender) then
            self:replaceSxbSubGender(subgender)
        else
            sb.logWarn("Entity #"..entity.id().."'s sub-gender didn't change to "..tostring(statusName).." by status due to gender requirements!")
        end
    end
end

--- Handles 'RemoveStatus' message event
-- @params statusName
function Sexbound.Common.SubGender:handleRemoveStatus(statusName)
    local gender = self:getParent():getGender()
    local subgenders = self:getDefinedGender(statusName)
    for _,subgender in ipairs(subgenders) do
        if subgender and self:passesGenderRestriction(subgender, gender) then
            self:removeSxbSubGender(subgender)
        else
            sb.logWarn("Entity #"..entity.id().."'s sub-gender didn't attempt to revoke "..tostring(statusName).." by status due to gender requirements!")
        end
    end
end

--- Overrides the sxbSubGender identity of this actor to be a given subgender
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

--- Returns the subgender set for a status effect name - or nil if non set
function Sexbound.Common.SubGender:getDefinedGender(statusName)
    return self._config.statuseffects[statusName]
end

--- Returns if the given gender is the required gender for a given subgender
function Sexbound.Common.SubGender:passesGenderRestriction(subgender, gender)
    if subgender == nil then return true end
    local targetGender = self._config.genderLimitations[subgender]
    if targetGender == nil then return true end
    return gender == targetGender
end

function Sexbound.Common.SubGender:restoreOriginalSubgender()
    storage.sexbound.identity.sxbSubGender = self._previousSxbGender
    status.statusProperty("sxbSubGender", self._previousSxbGender)
end

function Sexbound.Common.SubGender:getParent()
    return self._parent
end

function Sexbound.Common.SubGender:getConfig()
    return self._config
end

--- Method for the customizer UI to fetch available sub-genders you can switch to.
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

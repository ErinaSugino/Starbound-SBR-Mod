--- Sexbound.Actor.Futanari Class Module.
-- @classmod Sexbound.Actor.Futanari
-- @author Locuturus
-- @license GNU General Public License v3.0

if not SXB_RUN_TESTS then
	require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
end

Sexbound.Actor.Futanari = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Futanari_mt = { __index = Sexbound.Actor.Futanari }

--- Instantiates a new instance of Futanari.
-- @param parent
-- @param config
function Sexbound.Actor.Futanari:new(parent, config)
  local self = setmetatable({
    _logPrefix = "FUTA",
    _config    = config
  }, Sexbound.Actor.Futanari_mt)
  
  self:init(parent, self._logPrefix)

  self:tryReplacingSxbSubGenderWithFutanari()

  local defaultAppliesToStatuses = { "equipped_futamode" }

  self:getConfig().appliesToStatuses = self:getConfig().appliesToStatuses or defaultAppliesToStatuses

  return self
end

--- Handles message events.
-- @param message
function Sexbound.Actor.Futanari:onMessage(message)
  if message:getType() == "Sexbound:Status:AddStatus" then
    self:handleAddStatus(message)
  end

  if message:getType() == "Sexbound:Status:RemoveStatus" then
    self:handleRemoveStatus(message)
  end
end

--- Handles 'AddStatus' message event
-- @params message
function Sexbound.Actor.Futanari:handleAddStatus(message)
  local statusName = message:getData()
  if not self:statusNameMatchesRequiredStatusName(statusName) then return end
  self:replaceSxbSubGender()
end

--- Handles 'RemoveStatus' message event
-- @params message
function Sexbound.Actor.Futanari:handleRemoveStatus(message)
  local statusName = message:getData()
  if not self:statusNameMatchesRequiredStatusName(statusName) then return end
  self:restoreSxbSubGender()
end

--- Overrides the sxbSubGender identity of this actor to be 'futanari' or 'cuntboy'
function Sexbound.Actor.Futanari:replaceSxbSubGender()
  local identity = self:getParent():getIdentity()
  self._previousSxbGender = identity.sxbSubGender
  if (self:getParent():getGender() == "female") then identity.sxbSubGender = "futanari" else identity.sxbSubGender = "cuntboy" end
  self:getParent():getParent():resetAllActors()
end

--- Restores the sxbSubGender identity of this actor to be the previous value
function Sexbound.Actor.Futanari:restoreSxbSubGender()
  local identity = self:getParent():getIdentity()
  identity.sxbSubGender = self._previousSxbGender
  self:tryReplacingSxbSubGenderWithFutanari()
  self:getParent():getParent():resetAllActors()
end

--- Checks whether or not the supplied status name matches the required status name
function Sexbound.Actor.Futanari:statusNameMatchesRequiredStatusName(statusName)
  for _,requireStatusName in ipairs(self:getConfig().appliesToStatuses or {}) do
    if statusName == requireStatusName then return true end
  end

  return false
end

--- Checks whether or not this actor has an applicable entity id
function Sexbound.Actor.Futanari:thisActorHasApplicableEntityId()
  for _,entityId in ipairs(self:getConfig().appliesToEntityIds or {}) do
    if self:getParent():getEntityId() == entityId then return true end
  end

  return false
end

--- Checks whether or not this actor has an applicable gender
function Sexbound.Actor.Futanari:thisActorHasApplicableGender()
  for _,genderName in ipairs(self:getConfig().appliesToGenders or {}) do
    if self:getParent():getSubGender() == genderName then return true end
    if self:getParent():getGender()    == genderName then return true end
  end

  return false
end

--- Checks whether or not this actor has an applicable name
function Sexbound.Actor.Futanari:thisActorHasApplicableName()
  for _,name in ipairs(self:getConfig().appliesToNames or {}) do
    if self:getParent():getName() == name then return true end
  end

  return false
end

--- Checks whether or not this actor has an applicable NPC Type
function Sexbound.Actor.Futanari:thisActorHasApplicableNPCType()
  for _,type in ipairs(self:getConfig().appliesToNPCTypes or {}) do
    if self:getParent():getType() == type then return true end
  end

  return false
end

--- Checks whether or not this actor has an applicable species
function Sexbound.Actor.Futanari:thisActorHasApplicableSpecies()
  for _,speciesName in ipairs(self:getConfig().appliesToSpecies or {}) do
    if self:getParent():getSpecies() == speciesName then return true end
  end

  return false
end

--- Checks whether or not this actor has an applicable status
function Sexbound.Actor.Futanari:thisActorHasApplicableStatus()
  return self:getParent():getStatus():hasOneOf(self:getConfig().appliesToStatuses)
end

--- Checks whether or not this actor has an applicable unique id
function Sexbound.Actor.Futanari:thisActorHasApplicableUniqueId()
  for _,uniqueId in ipairs(self:getConfig().appliesToUniqueIds or {}) do
    if self:getParent():getUniqueId() == uniqueId then return true end
  end

  return false
end

--- Checks whether or not this actor has the gender as female
function Sexbound.Actor.Futanari:onlyFemaleActorsCanBeFutanari()
  return self:getConfig().onlyFemaleActorsCanBeFutanari
end

function Sexbound.Actor.Futanari:thisActorHasGenderAsFemale()
  return self:getParent():getGender() == "female"
end

--- Checks whether or not this actor is excluded by entity Id
function Sexbound.Actor.Futanari:thisActorHasExcludedEntityId()
  for _,entityId in ipairs(self:getConfig().excludedEntityIds or {}) do
    if self:getParent():getEntityId() == entityId then return true end
  end

  return false
end

--- Checks whether or not this actor is excluded by gender
function Sexbound.Actor.Futanari:thisActorHasExcludedGender()
  for _,gender in ipairs(self:getConfig().excludedGenders or {}) do
    if self:getParent():getSubGender() == gender then return true end
    if self:getParent():getGender()    == gender then return true end
  end

  return false
end

--- Checks whether or not this actor is excluded by name
function Sexbound.Actor.Futanari:thisActorHasExcludedName()
  for _,name in ipairs(self:getConfig().excludedNames or {}) do
    if self:getParent():getName() == name then return true end
  end

  return false
end

--- Checks whether or not this actor is excluded by NPC Type
function Sexbound.Actor.Futanari:thisActorHasExcludedNPCType()
  for _,type in ipairs(self:getConfig().excludeNPCTypes or {}) do
    if self:getParent():getType() == type then return true end
  end

  return false
end

--- Checks whether or not this actor is excluded by species
function Sexbound.Actor.Futanari:thisActorHasExcludedSpecies()
  for _,species in ipairs(self:getConfig().excludedSpecies or {}) do
    if self:getParent():getSpecies() == species then return true end
  end

  return false
end

--- Checks whether or not this actor has a status name which excludes it
function Sexbound.Actor.Futanari:thisActorHasExcludedStatus()
  return self:getParent():getStatus():hasOneOf(self:getConfig().excludedStatuses or {})
end

--- Checks whether or not this actor is excluded by unique id
function Sexbound.Actor.Futanari:thisActorHasExcludedUniqueId()
  for _,uniqueId in ipairs(self:getConfig().excludedUniqueIds or {}) do
    if self:getParent():getUniqueId() == uniqueId then return true end
  end
  
  return false
end

--- Tries to replaces the sxbSubGender identity of this actor
function Sexbound.Actor.Futanari:tryReplacingSxbSubGenderWithFutanari()
  if self:onlyFemaleActorsCanBeFutanari() and 
     not self:thisActorHasGenderAsFemale() then return end

  if self:thisActorHasExcludedEntityId() or
     self:thisActorHasExcludedName()     or
     self:thisActorHasExcludedUniqueId() or
     self:thisActorHasExcludedGender()   or
     self:thisActorHasExcludedNPCType()  or
     self:thisActorHasExcludedSpecies()  or
     self:thisActorHasExcludedStatus() then return end

  if not self:thisActorHasApplicableEntityId() and
     not self:thisActorHasApplicableUniqueId() and
     not self:thisActorHasApplicableGender()   and
     not self:thisActorHasApplicableName()     and
     not self:thisActorHasApplicableNPCType()  and
     not self:thisActorHasApplicableSpecies()  and
     not self:thisActorHasApplicableStatus() then return end

  self:replaceSxbSubGender()
end
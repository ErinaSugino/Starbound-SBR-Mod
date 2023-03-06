--- Sexbound.Actor.Storage Class Module.
-- @classmod Sexbound.Actor.Storage
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor.Storage = {}
Sexbound.Actor.Storage_mt = {
    __index = Sexbound.Actor.Storage
}

function Sexbound.Actor.Storage:new(parent)
    return setmetatable({
        _parent = parent
    }, Sexbound.Actor.Storage_mt)
end

function Sexbound.Actor.Storage:sync(callback)
    local entityId = self:getParent():getEntityId()

    -- Check every sync because the entity could dissappear from the world
    if not world.entityExists(entityId) then return end

    local promises = self:getParent():getParent():getPromises()
    promises:add(self:_retrieveStorageFromEntityById(entityId), function(storageData)
        storageData = self:fixPregnancyData(storageData)
        sb.logInfo("actor syncing storage - before: "..self:dump(storageData.sexbound.pregnant or {}))
        if type(callback) == "function" then
            self:setData(callback(storageData) or storageData)
        else
            self:setData(storageData)
        end
        sb.logInfo("actor syncing storage - after: "..self:dump(self:getData().sexbound.pregnant or {}))
        self:_sendStorageToEntityById(entityId)
    end)
end

function Sexbound.Actor.Storage:_sendStorageToEntityById(entityId)
    sb.logInfo("Actor sending new sync data: "..self:dump(self:getData().sexbound.pregnant or {}))
    return world.sendEntityMessage(entityId, "Sexbound:Storage:Sync", self:getData())
end

function Sexbound.Actor.Storage:_retrieveStorageFromEntityById(entityId)
    return world.sendEntityMessage(entityId, "Sexbound:Storage:Retrieve")
end

--- Returns the actor's storage data or a specified parameter in the actor's storage.
-- @param name string
function Sexbound.Actor.Storage:getData(name)
    local storage = self:getParent():getConfig().storage or {}
    if name then return storage[name] end
    return storage
end

--- Sets the stored storage configuration to the specified table.
-- @param newData table
function Sexbound.Actor.Storage:setData(newData)
    self:getParent():getConfig().storage = newData
end

--- Tries to enforce a safe "number index only" state on pregnancy data
-- @param data table
function Sexbound.Actor.Storage:fixPregnancyData(data)
    if not data then return data end
    if type(data.sexbound.pregnant) ~= "table" then data.sexbound.pregnant = {} end
    if isEmpty(data.sexbound.pregnant) then return data end

    local filteredData = {}
    local count = 0
    for k, v in pairs(data.sexbound.pregnant) do
        count = count + 1
        table.insert(filteredData, count, v)
    end

    data.sexbound.pregnant = filteredData
    return data
end

-- Returns a reference to the parent Actor instance.
function Sexbound.Actor.Storage:getParent()
    return self._parent
end

function Sexbound.Actor.Storage:dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. self:dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

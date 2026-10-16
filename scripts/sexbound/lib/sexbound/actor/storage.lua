--- Sexbound.Actor.Storage Class Module.
--- @class Sexbound.Actor.Storage
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
Sexbound.Actor.Storage = {}
Sexbound.Actor.Storage_mt = {
    __index = Sexbound.Actor.Storage
}

--- Creates new storage manager instance
--- @param parent Sexbound.Actor The calling parent actor instance
--- @return Sexbound.Actor.Storage # The newly created storage manager instance
function Sexbound.Actor.Storage:new(parent)
    return setmetatable({
        _parent = parent
    }, Sexbound.Actor.Storage_mt)
end

--- Synchronize actor storage to entity
--- @param callback? fun(table): table The callback to handle the prepared storage data, returning the varified storage synced
function Sexbound.Actor.Storage:sync(callback)
    if self._parent._parent._config.position.noSync then return end

    local entityId = self:getParent():getEntityId()

    -- Check every sync because the entity could dissappear from the world
    if not world.entityExists(entityId) then return end

    local promises = self:getParent():getParent():getPromises()
    promises:add(self:_retrieveStorageFromEntityById(entityId), function(storageData)
        storageData = self:fixPregnancyData(storageData)
        if type(callback) == "function" then
            self:setData(callback(storageData) or storageData)
        else
            self:setData(storageData)
        end
        self:_sendStorageToEntityById(entityId)
    end)
end

--- [Helper] Send storage data to the entity via given id
--- @private
--- @param entityId EntityId The target entity ID
--- @return RpcPromise<table>? # The Starbound async entity message promise of the sent message or nil if sending unsuccessful
function Sexbound.Actor.Storage:_sendStorageToEntityById(entityId)
    if self._parent._parent._config.position.noSync then return end

    return world.sendEntityMessage(entityId, "Sexbound:Storage:Sync", self:getData())
end

--- [Helper] Retrieves storage data from entity via given id
--- @param entityId EntityId The target entity ID
--- @return RpcPromise<table> # The Starbound async entity message promise of the send message
function Sexbound.Actor.Storage:_retrieveStorageFromEntityById(entityId)
    return world.sendEntityMessage(entityId, "Sexbound:Storage:Retrieve")
end

--- Returns the actor's storage data or a specified parameter in the actor's storage.
--- @param name string? The name of the storage property to fetch
--- @return any # The content of the storage property requested or the entire storage if none requested
function Sexbound.Actor.Storage:getData(name)
    local storage = self:getParent():getConfig().storage or {}
    if name then return storage[name] end
    return storage
end

--- Sets the stored storage configuration to the specified table.
--- @param newData table The new storage data
function Sexbound.Actor.Storage:setData(newData)
    self:getParent():getConfig().storage = newData
end

--- Tries to enforce a safe "number index only" state on pregnancy data
--- @param data table The pregnancy data to fix
--- @return table # The fixed pregnancy data
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

--- Returns a reference to the parent Actor instance.
--- @return Sexbound.Actor # The parent actor instance
function Sexbound.Actor.Storage:getParent()
    return self._parent
end

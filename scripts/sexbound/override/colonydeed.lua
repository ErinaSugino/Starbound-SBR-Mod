require "/scripts/util.lua"

--- Return whether or not the tenant is turned into an object.
-- @param tenant
local function isTransformedIntoObject(tenant)
    return tenant.transformIntoObject or false
end

--- Inserts inputted entity Id into sexboundEntities storage table
local function handleRespawnerSync(_, _, args)
    table.insert(storage.sexboundEntities, args.entityId)

    return storage.sexboundEntities
end

--- Adds object transformation status of NPC with specified uniqueId
local function handleTransformIntoObject(_, _, args)
    if storage and storage.occupier then
        for _, _tenant in ipairs(storage.occupier.tenants) do
            if _tenant.uniqueId == args.uniqueId then
                _tenant.remoteEntityId = args.entityId
                _tenant.transformIntoObject = true
            end
        end
    end

    return true
end

--- Removes object transformation status of NPC with specified uniqueId
local function handleTransformIntoNPC(_, _, args)
    if storage and storage.occupier then
        for _, _tenant in ipairs(storage.occupier.tenants) do
            if _tenant.uniqueId == args.uniqueId then
                _tenant.transformIntoObject = false
            end
        end
    end

    return true
end

-- Override the init function. First defined by 'colonydeed.lua'
local Sexbound_ColonyDeed_Init = init
function init()
    -- Call the previous init function.
    Sexbound_ColonyDeed_Init()

    -- Init. sexbound specific storage
    storage.sexboundEntities = storage.sexbound or {}

    -- Untransform all tenants in the ColonyDeed storage
    if storage.occupier and storage.occupier.tenants then
        for _, _tenant in ipairs(storage.occupier.tenants) do
            _tenant.transformIntoObject = false
        end
    end

    -- Init. new message handlers
    message.setHandler("Sexbound:Respawner:Sync", handleRespawnerSync)
    message.setHandler("Sexbound:Transform:Object", handleTransformIntoObject)
    message.setHandler("Sexbound:Transform:NPC", handleTransformIntoNPC)

    -- Legacy message handlers. Do not remove.
    message.setHandler("transform-into-object", handleTransformIntoObject)
    message.setHandler("transform-into-npc", handleTransformIntoNPC)
end

-- Override the anyTenantsDead function. First defined by 'colonydeed.lua'
local Sexbound_ColonyDeed_anyTenantsDead = anyTenantsDead
function anyTenantsDead()
    for _, tenant in ipairs(storage.occupier.tenants) do
        if not isTransformedIntoObject(tenant) then
            return Sexbound_ColonyDeed_anyTenantsDead()
        end
    end

    return false
end

-- Override the callTenantsHome function. First defined by 'colonydeed.lua'
local Sexbound_ColonyDeed_callTenantsHome = callTenantsHome
function callTenantsHome(reason)
    -- Smash Sexbound nodes to release NPCs
    if not isEmpty(storage.sexboundEntities) then
        util.each(storage.sexboundEntities, function(_, entityId)
            if world.entityExists(entityId) then
                world.callScriptedEntity(entityId, "smash")
            end
        end)

        storage.sexboundEntities = {}
    end

    -- Remove arousal from all occupying tenants
    for _, _tenant in ipairs(storage.occupier.tenants) do
        if _tenant.uniqueId then
            world.sendEntityMessage(_tenant.uniqueId, "Sexbound:Arousal:Reduce", {
                amount = 1.0
            })
        end
    end

    -- Always call this function at the end
    Sexbound_ColonyDeed_callTenantsHome(reason)
end

--- Override the respawnTenants function. First defined by 'colonydeed.lua'
local Sexbound_ColonyDeed_respawnTenants = respawnTenants
function respawnTenants()
    if not storage.occupier then
        return
    end

    local _tenants = {
        normal = {},
        object = {}
    }

    for _, _tenant in ipairs(storage.occupier.tenants) do
        if isTransformedIntoObject(_tenant) then
            table.insert(_tenants.object, _tenant)
        end

        if not isTransformedIntoObject(_tenant) then
            table.insert(_tenants.normal, _tenant)
        end
    end

    storage.occupier.tenants = _tenants.normal

    Sexbound_ColonyDeed_respawnTenants()

    -- Merge tenants transformed back into the tenants list only after running the original respawnTenants function
    storage.occupier.tenants = util.mergeTable(storage.occupier.tenants, _tenants.object)
end

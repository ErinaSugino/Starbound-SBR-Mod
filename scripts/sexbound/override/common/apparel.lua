--- Abstract shared entity apparel manager class
--- @class Sexbound.Common.Apparel
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Common
--- @field _config table
Sexbound.Common.Apparel = {}
Sexbound.Common.Apparel_mt = { __index = Sexbound.Common.Apparel }

--- Creates new entity apparel manager instance
--- @return Sexbound.Common.Apparel # The newly created entity apparel manager instance
function Sexbound.Common.Apparel:new()
    return setmetatable({
        _config = config.getParameter("apparelConfig", {})
    }, Sexbound.Common.Apparel_mt)
end

--- Late init binding
--- @param parent Sexbound.Common The calling parent entity manager instance
function Sexbound.Common.Apparel:init(parent)
    self._parent = parent
    local nippleswearConfig  = self._config.nippleswear or {}
    local groinwearConfig    = self._config.groinwear   or {}
    storage.sexbound.apparel = storage.sexbound.apparel or {}
    storage.sexbound.apparel.nipple1 = storage.sexbound.apparel.nipple1 or
    nippleswearConfig[1] or {}
    storage.sexbound.apparel.nipple2 = storage.sexbound.apparel.nipple2 or
    nippleswearConfig[2] or {}
    storage.sexbound.apparel.groin1 = storage.sexbound.apparel.groin1 or
    groinwearConfig[1] or {}
    self:initMessageHandlers()

    self:update(nil, self:getParent():getGender()) -- initial verification
end

--- Sets up eneity message handlers
function Sexbound.Common.Apparel:initMessageHandlers()
    message.setHandler("Sexbound:Apparel:AttachToGroin1", function(_, _, args)
        return self:handleAttachToGroin1(args)
    end)

    message.setHandler("Sexbound:Apparel:AttachToNipple1", function(_, _, args)
        return self:handleAttachToNipple1(args)
    end)

    message.setHandler("Sexbound:Apparel:AttachToNipple2", function(_, _, args)
        return self:handleAttachToNipple2(args)
    end)

    message.setHandler("Sexbound:Apparel:AttachToNipples", function(_, _, args)
        return self:handleAttachToNipples(args)
    end)

    message.setHandler("Sexbound:Apparel:ResetGroin", function(_, _, args)
        return self:handleResetGroin(args)
    end)

    message.setHandler("Sexbound:Apparel:ResetNipples", function(_, _, args)
        return self:handleResetNipples(args)
    end)
end

--- Message handler for applying a groin apparel item
--- @param params table? The apparel data
function Sexbound.Common.Apparel:handleAttachToGroin1(params)
    storage.sexbound.apparel.groin1 = params or {}
    storage.sexbound.apparel.groin1.shouldUpdate = true
end

--- Message handler for applying a nipple apparel item to the first nipple
--- @param params table? The apparel data
function Sexbound.Common.Apparel:handleAttachToNipple1(params)
    storage.sexbound.apparel.nipple1 = params or {}
    storage.sexbound.apparel.nipple1.shouldUpdate = true
end

--- Message handler for applying a nipple apparel item to the second nipple
--- @param params table? The apparel data
function Sexbound.Common.Apparel:handleAttachToNipple2(params)
    storage.sexbound.apparel.nipple2 = params or {}
    storage.sexbound.apparel.nipple2.shouldUpdate = true
end

--- Message handler for applying a nipple apparel item to the nipples
--- @param params {[1]: table?, [2]: table?} The apparel data
function Sexbound.Common.Apparel:handleAttachToNipples(params)
    storage.sexbound.apparel.nipple1 = params[1] or {}
    storage.sexbound.apparel.nipple1.shouldUpdate = true
    storage.sexbound.apparel.nipple2 = params[2] or {}
    storage.sexbound.apparel.nipple2.shouldUpdate = true
end

--- Message handler for resetting the groin
--- @param params any Message data
function Sexbound.Common.Apparel:handleResetGroin(params)
    storage.sexbound.apparel.groin1 = {}
    storage.sexbound.apparel.groin1.shouldUpdate = true
end

--- Message handler for resetting the nipples
--- @param params any Message data
function Sexbound.Common.Apparel:handleResetNipples(params)
    storage.sexbound.apparel.nipple1 = {}
    storage.sexbound.apparel.nipple2 = {}
    storage.sexbound.apparel.nipple1.shouldUpdate = true
    storage.sexbound.apparel.nipple2.shouldUpdate = true
end

--- Updates all apparel items
--- @param controllerId EntityId? The sexnode controller id to notify, if lounging
--- @param gender string The entity's gender
function Sexbound.Common.Apparel:update(controllerId, gender)
    self:updateBackwear(controllerId, gender)
    self:updateNippleswear(controllerId, gender)
    self:updateChestwear(controllerId, gender)
    self:updateGroinwear(controllerId, gender)
    self:updateHeadwear(controllerId, gender)
    self:updateLegswear(controllerId, gender)
end

--- Returns the item, if any equipped, in a given slot
--- @param entityType string The entity type of the entity
--- @param slotNames string[] The names of the apparel slots
--- @return ItemDescriptor? # The apparel item data, if any equipped
function Sexbound.Common.Apparel:findItemInSlot(entityType, slotNames)
    if entityType == "player" then
        return self:findItemForPlayer(slotNames)
    end

    if entityType == "npc" then
        return self:findItemForNPC(slotNames)
    end
end

--- Returns the item, if any equipped, in a given slot for a player entity
--- @param slotNames string[] The names of the apparel slots
--- @return ItemDescriptor? # The apparel item data, if any equipped
function Sexbound.Common.Apparel:findItemForPlayer(slotNames)
    for _, slotName in ipairs(slotNames) do
        if player.equippedItem(slotName) ~= nil then
            return player.equippedItem(slotName)
        end
    end
    return nil
end

--- Returns the item, if any equipped, in a given slot for an npc entity
--- @param slotNames string[] The names of the apparel slots
--- @return ItemDescriptor? # The apparel item data, if any equipped
function Sexbound.Common.Apparel:findItemForNPC(slotNames)
    for _, slotName in ipairs(slotNames) do
        if npc.getItemSlot(slotName) ~= nil then
            return npc.getItemSlot(slotName)
        end
    end
    return nil
end

--- Returns the relevant data from an item's config for the backwear slot
--- @param gender string "male" or "female" vanilla gender of the entity
--- @return table? # The relevant data from the item config, if any equipped
function Sexbound.Common.Apparel:prepareBackwear(gender)
    self._back = self:findItemInSlot(entity.entityType(), {"backCosmetic", "back"})

    return self:extractOtherItemConfig(self._back, gender)
end

--- Returns the relevant data from an item's config for the chestwear slot
--- @param gender string "male" or "female" vanilla gender of the entity
--- @return table? # The relevant data from the item config, if any equipped
function Sexbound.Common.Apparel:prepareChestwear(gender)
    self._chest = self:findItemInSlot(entity.entityType(), {"chestCosmetic", "chest"})

    return self:extractOtherItemConfig(self._chest, gender)
end

--- Returns the relevant data from an item's config for the headwear slot
--- @param gender string "male" or "female" vanilla gender of the entity
--- @return table? # The relevant data from the item config, if any equipped
function Sexbound.Common.Apparel:prepareHeadwear(gender)
    self._head = self:findItemInSlot(entity.entityType(), {"headCosmetic", "head"})

    return self:extractHeadItemConfig(self._head, gender)
end

--- Returns the relevant data from an item's config for the legswear slot
--- @param gender string "male" or "female" vanilla gender of the entity
--- @return table? # The relevant data from the item config, if any equipped
function Sexbound.Common.Apparel:prepareLegswear(gender)
    self._legs = self:findItemInSlot(entity.entityType(), {"legsCosmetic", "legs"})

    return self:extractOtherItemConfig(self._legs, gender)
end

--- Returns the relevant data from an item's config for the groinwear slot
--- @param gender string "male" or "female" vanilla gender of the entity
--- @return table # The relevant data from the item config, if any equipped
function Sexbound.Common.Apparel:prepareGroinwear(gender)
    local _config = {[1] = {}}
    local groin1ItemName = storage.sexbound.apparel.groin1.item_name

    if groin1ItemName ~= nil then
        xpcall(function()
            _config[1] = root.assetJson("/items/armors/sexbound/groin/" .. groin1ItemName .. ".groin")
            _config[1] = _config[1].sexboundConfig
        end, sb.logError)
        -- If failure to load config then clear groin1 in storage
        if isEmpty(_config[1]) then storage.sexbound.apparel.groin1 = {} end
    end

    return _config
end

--- Returns the relevant data from an item's config for the nippleswear slot
--- @param gender string "male" or "female" vanilla gender of the entity
--- @return table # The relevant data from the item config, if any equipped
function Sexbound.Common.Apparel:prepareNippleswear(gender)
    local _config = {[1] = {}, [2] = {}}
    local nipple1ItemName = storage.sexbound.apparel.nipple1.item_name
    local nipple2ItemName = storage.sexbound.apparel.nipple2.item_name

    if nipple1ItemName ~= nil then
        xpcall(function()
            _config[1] = root.assetJson("/items/armors/sexbound/nipples/" .. nipple1ItemName .. ".nipples")
            _config[1] = _config[1].sexboundConfig
        end, sb.logError)
        -- If failure to load config then clear nipple1 in storage
        if isEmpty(_config[1]) then storage.sexbound.apparel.nipple1 = {} end
    end

    if nipple2ItemName ~= nil then
        xpcall(function()
            _config[2] = root.assetJson("/items/armors/sexbound/nipples/" .. nipple2ItemName .. ".nipples")
            _config[2] = _config[2].sexboundConfig
        end, sb.logError)
        -- If failure to load config then clear nipple2 in storage
        if isEmpty(_config[2]) then storage.sexbound.apparel.nipple2 = {} end
    end

    return _config
end

--- Updates the backwear apparel if it changed
--- @param controllerId EntityId? Sexnode controller id to notify if lounging
--- @param gender string Entity vanilla gender
function Sexbound.Common.Apparel:updateBackwear(controllerId, gender)
    if not root.itemDescriptorsMatch(self._back, self:findItemInSlot(
        entity.entityType(), {"backCosmetic", "back"}
    ) or {name = ""}) then
        local sxbConfig = self:prepareBackwear(gender) or {}
        local statuses = sxbConfig.addStatus or {}
        local oldStatuses = self._backStatuses or {}
        self:getParent():updateSubgenderStatus(oldStatuses, statuses)
        self._backStatuses = statuses
        if controllerId then
            world.sendEntityMessage(controllerId, "Sexbound:Backwear:Change", {
                entityId = entity.id(),
                backwear = sxbConfig
            })
        end
    end
end

--- Updates the chestwear apparel if it changed
--- @param controllerId EntityId? Sexnode controller id to notify if lounging
--- @param gender string Entity vanilla gender
function Sexbound.Common.Apparel:updateChestwear(controllerId, gender)
    if not root.itemDescriptorsMatch(self._chest, self:findItemInSlot(
        entity.entityType(), {"chestCosmetic", "chest"}
    ) or {name = ""}) then
        local sxbConfig = self:prepareChestwear(gender) or {}
        local statuses = sxbConfig.addStatus or {}
        local oldStatuses = self._chestStatuses or {}
        self:getParent():updateSubgenderStatus(oldStatuses, statuses)
        self._chestStatuses = statuses
        if controllerId then
            world.sendEntityMessage(controllerId, "Sexbound:Chestwear:Change", {
                entityId = entity.id(),
                chestwear = sxbConfig
            })
        end
    end
end

--- Updates the groinwear apparel if it changed
--- @param controllerId EntityId? Sexnode controller id to notify if lounging
--- @param gender string Entity vanilla gender
function Sexbound.Common.Apparel:updateGroinwear(controllerId, gender)
    if not controllerId then return end

    if
    storage.sexbound.apparel.groin1.shouldUpdate ~= true then return end
    storage.sexbound.apparel.groin1.shouldUpdate = false

    world.sendEntityMessage(controllerId, "Sexbound:Groinwear:Change", {
        entityId = entity.id(),
        groinwear = self:prepareGroinwear(gender)
    })
end

--- Updates the nippleswear apparel if it changed
--- @param controllerId EntityId? Sexnode controller id to notify if lounging
--- @param gender string Entity vanilla gender
function Sexbound.Common.Apparel:updateNippleswear(controllerId, gender)
    if not controllerId then return end

    if
    storage.sexbound.apparel.nipple1.shouldUpdate ~= true and
    storage.sexbound.apparel.nipple2.shouldUpdate ~= true then return end
    storage.sexbound.apparel.nipple1.shouldUpdate = false
    storage.sexbound.apparel.nipple2.shouldUpdate = false

    world.sendEntityMessage(controllerId, "Sexbound:Nippleswear:Change", {
        entityId = entity.id(),
        nippleswear = self:prepareNippleswear(gender)
    })
end

--- Updates the headwear apparel if it changed
--- @param controllerId EntityId? Sexnode controller id to notify if lounging
--- @param gender string Entity vanilla gender
function Sexbound.Common.Apparel:updateHeadwear(controllerId, gender)
    if not root.itemDescriptorsMatch(self._head, self:findItemInSlot(
        entity.entityType(), {"headCosmetic", "head"}
    ) or {name = ""}) then
        local sxbConfig = self:prepareHeadwear(gender) or {}
        local statuses = sxbConfig.addStatus or {}
        local oldStatuses = self._headStatuses or {}
        self:getParent():updateSubgenderStatus(oldStatuses, statuses)
        self._headStatuses = statuses
        if controllerId then
            world.sendEntityMessage(controllerId, "Sexbound:Headwear:Change", {
                entityId = entity.id(),
                headwear = sxbConfig
            })
        end
    end
end

--- Updates the legswear apparel if it changed
--- @param controllerId EntityId? Sexnode controller id to notify if lounging
--- @param gender string Entity vanilla gender
function Sexbound.Common.Apparel:updateLegswear(controllerId, gender)
    if not root.itemDescriptorsMatch(self._legs, self:findItemInSlot(
        entity.entityType(), {"legsCosmetic", "legs"}
    ) or {name = ""}) then
        local sxbConfig = self:prepareLegswear(gender) or {}
        local statuses = sxbConfig.addStatus or {}
        local oldStatuses = self._legsStatuses or {}
        self:getParent():updateSubgenderStatus(oldStatuses, statuses)
        self._legsStatuses = statuses
        if controllerId then
            world.sendEntityMessage(controllerId, "Sexbound:Legswear:Change", {
                entityId = entity.id(),
                legswear = sxbConfig
            })
        end
    end
end

--- Extracts relevant config data from a headwear item
--- @param itemDesc ItemDescriptor|string?
--- @param gender string Vanilla gender of the entity
--- @return table?
function Sexbound.Common.Apparel:extractHeadItemConfig(itemDesc, gender)
    if not itemDesc then
        return
    end

    local itemConfig = root.itemConfig(itemDesc)

    local sexboundConfig = itemConfig.config.sexboundConfig or {}

    local colors = self:getColorsByIndex(itemConfig.config.colorOptions, itemConfig.parameters.colorIndex or 0)
    local directives = itemConfig.parameters.directives

    local image = itemConfig.config[gender .. "Frames"]
    local mask = itemConfig.config.mask
    if string.find(mask, "/") then
		mask = mask
	elseif mask then
        mask = itemConfig.directory .. mask
    end
    if string.find(image, "/")then
		image = image
	elseif image then
        image = itemConfig.directory .. image
    end

    return util.mergeTable({
        colors = colors,
        directives = directives,
        image = image,
        mask = mask
    }, sexboundConfig)
end

--- Extracts relevant config data from a non-headwear item
--- @param itemDesc ItemDescriptor|string
--- @param gender string Vanilla gender of the entity
--- @return table?
function Sexbound.Common.Apparel:extractOtherItemConfig(itemDesc, gender)
    if not itemDesc then
        return
    end

    local itemConfig = root.itemConfig(itemDesc)

    local sexboundConfig = itemConfig.config.sexboundConfig

    if sexboundConfig and type(sexboundConfig) == "table" then
        sexboundConfig.colors = self:getColorsByIndex(itemConfig.config.colorOptions,
                                    itemConfig.parameters.colorIndex or 0)
        sexboundConfig.directives = itemConfig.parameters.directives

        return sexboundConfig
    end
end

--- Returns colors from a color pool by list index
--- @param colorOptions table The color pool
--- @param colorIndex integer The index
--- @return table? # The color palette if it exists
function Sexbound.Common.Apparel:getColorsByIndex(colorOptions, colorIndex)
    if (colorOptions ~= nil and colorIndex ~= nil) then
        return colorOptions[colorIndex + 1]
    end
end

--- Returns the parent entity manager instance
--- @return Sexbound.Common # The parent entity manager instance
function Sexbound.Common.Apparel:getParent()
    return self._parent
end

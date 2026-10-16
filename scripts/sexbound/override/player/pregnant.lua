if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/pregnant.lua"
end

--- Player pregnancy manager class
--- @class Sexbound.Player.Pregnant: Sexbound.Common.Pregnant
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Player
Sexbound.Player.Pregnant = Sexbound.Common.Pregnant:new()
Sexbound.Player.Pregnant_mt = {
    __index = Sexbound.Player.Pregnant
}

--- Creates new player pregnancy manager instance
--- @param parent Sexbound.Player The calling parent player manager instance
--- @return Sexbound.Player.Pregnant # The newly created player pregnancy manager instance
function Sexbound.Player.Pregnant:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Pregnant_mt)

    _self:init(parent)

    _self:addPlayerMessageHandlers()

    return _self
end

--- Function called each tick to progress timers
--- @param dt number The delta time since last tick
function Sexbound.Player.Pregnant:update(dt)
    self:progressBabyState(dt)
    self:updatePeriodCycle(dt)

    if self._isGivingBirth == true then
        return
    end

    local babyReadyIndex = self:findReadyBabyIndex()

    if babyReadyIndex == nil then
        return
    end

    self:handleGiveBirth(babyReadyIndex)
end

--- Adds additional message handlers
function Sexbound.Player.Pregnant:addPlayerMessageHandlers()
    message.setHandler("Sexbound:Pregnant:BirthNamed", function(_, _, args)
        local pIndex, bIndex, name = args.pIndex, args.bIndex, args.name
        return self:doBirthingLoop(pIndex, bIndex, name)
    end)

    message.setHandler("Sexbound:Pregnant:DebugNamedBirth", function(_, _, args)
        return self:openBabyNamingWindow(args.pregnancy, args.baby)
    end)

    message.setHandler("Sexbound:Pregnant:BirthingPill", function(_, _, args)
        return self:speedupBirth()
    end)
end

--- Function to progress pregnancy delay and progress based on script delta time
--- @param dt number The delta time since last tick
function Sexbound.Player.Pregnant:progressBabyState(dt)
    if isEmpty(storage.sexbound.pregnant) then return end
    if not self:canOvulate() then return end

    for i,b in pairs(storage.sexbound.pregnant) do
        local delay = b.delay or 0
        if delay > 0 then
            b.delay = b.delay - dt
            if b.delay <= 0 then self:triggerActualPregnancy(b) end
        elseif b.birthWorldTime > 0 then
            local halfPreg = (b.fullBirthWorldTime / 2)
            local wasOverHalf = b.birthWorldTime <= halfPreg
            b.birthWorldTime = b.birthWorldTime - dt
            if not wasOverHalf and b.birthWorldTime <= halfPreg then self:refreshStatusEffects() end
        end
    end
end

--- Function to - if enabled - progress the periodic ovulation cycle
--- @param dt number The delta time since last tick
function Sexbound.Player.Pregnant:updatePeriodCycle(dt)
    local config = self:getConfig()
    local enabled = config.enablePeriodCycle or false
    -- Feature disabled - ignore
    if not enabled then return end

    -- Player cannot ovulate in the first place - ignore
    if not self:canOvulate() or self._parent._isSterilized or self._parent._isInfertile then return end

    local ovulating = status.statusProperty("sexbound_custom_ovulating", false)
    -- Currently active ovulation effect - ignore
    if ovulating then return end

    local ovulationTimer = storage.sexbound.ovulationCycle or 0
    if ovulationTimer <= 0 then
        -- No ovulation timer, yet not active effect - generate new cycle
        local cycleLength = config.periodCycleLength or {3,5}
        local newCycle = 840 * util.randomIntInRange(cycleLength)
        storage.sexbound.ovulationCycle = newCycle
    else
        -- Active cycle - progress and handle trigger if needed
        ovulationTimer = ovulationTimer - dt
        storage.sexbound.ovulationCycle = ovulationTimer
        if ovulationTimer <= 0 then
            -- Trigger ovulation
            status.addEphemeralEffect("sexbound_custom_ovulating")
        end
    end
end

--- Speeds up birth progression of the most progressed pregnancy
function Sexbound.Player.Pregnant:speedupBirth()
    local babyIndex = nil
    local birthTime = math.huge

    for i,p in ipairs(storage.sexbound.pregnant) do
        if (p.delay or 0) <= 0 then
            if p.birthWorldTime < birthTime then
                babyIndex = i
                birthTime = p.birthWorldTime
            end
        end
    end

    if babyIndex == nil then return nil end
    return self:handleGiveBirth(babyIndex)
end

--- Returns whethere or not this player can ovulate
--- @return boolean # Whethere or not this player can ovulate
function Sexbound.Player.Pregnant:canOvulate()
    if self:getConfig().enableFreeForAll == true then
        return true
    end
    if storage.sexbound.identity.sxbCanOvulate == true then
        return true
    end

    if self:getParent()._bodyTraits.canOvulate or false then return true end

	if status.statusProperty("sexbound_override_can_ovulate", false) then return true end

    return false
end

--- Aborts all pregnancies
function Sexbound.Player.Pregnant:abortPregnancy()
    self:abortPregnancy()
    self:notifyPlayerAboutAbortionViaRadioMessage()
end

--- [DEBUG] Triggers the actual pregnancy flow
--- @param pregnancy table The mock pregnancy
function Sexbound.Player.Pregnant:triggerActualPregnancy(pregnancy)
    local config = self:getConfig()
    local dayCount = pregnancy.dayCount
    local baby = pregnancy.babies[1]
    local dialog = self:loadNotificationDialog()
    local daystring = "day"
    if dayCount > 1 then daystring = "days" end
    local message = ""

    local immersionLevel = config.immersionLevel or 1
    dialog = dialog.pregnancy or {}
    dialog = dialog[immersionLevel + 1] or {}
    --- Tries to send radio message to this actor
    if immersionLevel < 2 then
        if baby.fatherSpecies == "sexbound_tentacleplant_v2" then message = message .. (dialog.tentaclePregnant or "")
        else message = message .. (dialog.pregnant or "") end

        message = util.replaceTag(message, "name", "^green;" .. baby.fatherName .. "^reset;")
        message = util.replaceTag(message, "daycount", "^red;" .. pregnancy.dayCount .. "^reset;")
        message = util.replaceTag(message, "daystring", daystring)

        if message ~= "" then
            world.sendEntityMessage(player.id(), "queueRadioMessage", {
                messageId = "Pregnant:Success",
                unique = false,
                text = message
            })
        end
    end

    message = ""
    --- Tries to send radio message to the other actor
    if immersionLevel < 2 and baby.fatherType == "player" then
        message = message .. (dialog.remotePregnant or "")

        message = util.replaceTag(message, "name", "^green;" .. world.entityName(player.id()) .. "^reset;")
        message = util.replaceTag(message, "daycount", "^red;" .. pregnancy.dayCount .. "^reset;")
        message = util.replaceTag(message, "daystring", daystring)

        if message ~= "" then
            world.sendEntityMessage(baby.fatherId, "queueRadioMessage", {
                messageId = "Pregnant:Success",
                unique = false,
                text = message
            })
        end
    end

    --- Trigger stat-up for this entity
    world.sendEntityMessage(player.id(), "Sexbound:Statistics:Add", {
        name = "pregnancyCount",
        amount = 1
    })
end

--- Loads notification config for abortion messages
--- @return string # The abortion notification message
function Sexbound.Player.Pregnant:fetchAbortionNotificationMessage()
    local notification = self:loadNotificationDialog() or {}
    notification = notification.birth or {}

    return notification.abortion or ""
end

--- Sends radio notification to player regarding abortion
function Sexbound.Player.Pregnant:notifyPlayerAboutAbortionViaRadioMessage()
    local message = self:fetchAbortionNotificationMessage()

    world.sendEntityMessage(entity.id(), "queueRadioMessage", {
        messageId = "sexbound_abortion",
        unique = false,
        text = message
    })
end

--- Loads the script pane config for the birth confirmation dialog
--- @return table # The confirmation UI's JSON config
function Sexbound.Player.Pregnant:loadGiveBirthConfirmationConfig()
    if self._giveBirthConfirmationConfig then
        return self._giveBirthConfirmationConfig
    end
    self._giveBirthConfirmationConfig = root.assetJson("/interface/sexbound/confirmation/givebirth.config")
    return self._giveBirthConfirmationConfig
end

--- Loads the script pane config for birth naming dialog
--- @return table # The naming UI's JSON config
function Sexbound.Player.Pregnant:loadNamedBirthConfig()
    --if self._namedBirthConfig then return self._namedBirthConfig end
    self._namedBirthConfig = root.assetJson("/interface/sexbound/confirmation/namedbirth.config")
    return self._namedBirthConfig
end

--- Message handler for request to give birth. Starts multi-step process
--- @param index number Index of pregnancy in list to birth
function Sexbound.Player.Pregnant:handleGiveBirth(index)
    self:dataFilter()

    if index == nil or not storage.sexbound.pregnant[index] then
        return
    end

    self._isGivingBirth = true

    promises:add(player.confirm(self:loadGiveBirthConfirmationConfig()), function(choice)
        local pregnancyConfig = storage.sexbound.pregnant[index]

        if choice then
            self:startBirthing(index)
        else
            pregnancyConfig.birthWorldTime = pregnancyConfig.birthWorldTime + 840
            pregnancyConfig.birthOSTime = os.time() + 3600
            self._isGivingBirth = false
        end
    end)
end

--- Starts the event chain of birthing by transforming the player into sexnode with birthing position
--- @param index integer Pregnancy index to birth
function Sexbound.Player.Pregnant:startBirthing(index)
    local oldCanTransform = self._parent._transform._canTransform
    self._parent._transform:setCanTransform(true)
    if (self._parent._transform --[[@as Sexbound.Player.Transform]]):handleTransform({
        responseRequired = false,
        sexboundConfig = {position = {sex = {"birthing"}, force = 1, forceJoin = 1, noSync = 1, noStats = 1, noCompatibility = 1}},
        timeout = 600,
        spawnOptions = {
            noEffect = true
        }
    }) then
        status.addEphemeralEffect("sexbound_invisible", 600)
        sb.logInfo("Player birthing transform request succeeded - controllerId = "..tostring(self._parent._transform._controllerId))
    else sb.logInfo("Player birthing transform request failed") end
    status.addEphemeralEffect("sexbound_birthing", 600)
    self._parent._transform:setCanTransform(oldCanTransform)

    local bIndex, babyConfig = next(storage.sexbound.pregnant[index].babies)
    if bIndex == nil or babyConfig == nil then
        sb.logInfo("No baby data for pregnancy. Aborting birthing, removing data.")
        self:endBirthing(index)
        return
    end
    self:openBabyNamingWindow(index, bIndex)
end

--- Loops the interaction cycle while there is more babies for the given pregnancy
--- @param index integer Pregnancy index
--- @param babyId integer Index of baby in pregnancy
--- @param name string? Chosen birth name
function Sexbound.Player.Pregnant:doBirthingLoop(index, babyId, name)
    name = name or nil
    local babyConfig = storage.sexbound.pregnant[index].babies[babyId]
    if babyConfig == nil then
        sb.logInfo("Trying to give birth to a baby whose data does not exist. Aborting, removing data.")
        self:endBirthing(index)
        return
    end

    babyConfig.pregnancyType = storage.sexbound.pregnant[index].pregnancyType
    self:giveBirth(babyConfig, name, storage.sexbound.pregnant[index].incestLevel)
    table.remove(storage.sexbound.pregnant[index].babies, babyId)
    local bIndex, bConfig = next(storage.sexbound.pregnant[index].babies)

    if bIndex == nil or bConfig == nil then
        sb.logInfo("No next baby data for pregnancy. Ending birthing, removing data.")
        self:endBirthing(index)
        return
    end

    self:openBabyNamingWindow(index, bIndex)
end

--- Ends the birthing process and frees the player
--- @param index integer? Pregnancy index
function Sexbound.Player.Pregnant:endBirthing(index)
    status.removeEphemeralEffect("sexbound_birthing")
    status.removeEphemeralEffect("sexbound_invisible")
    self._parent._transform:smashSexNode()

    if index ~= nil then table.remove(storage.sexbound.pregnant, index) end
    self:refreshStatusEffects()
    self._isGivingBirth = false
end

--- Opens the naming dialog for a baby about to be birthed
--- @param pregnancyId integer Index of pregnancy
--- @param babyId integer Index of baby in pregnancy
function Sexbound.Player.Pregnant:openBabyNamingWindow(pregnancyId, babyId)
    if pregnancyId == nil or not storage.sexbound.pregnant then return end
    local pregnancy = storage.sexbound.pregnant[pregnancyId]
    if not pregnancy or (pregnancy.delay or 0) > 0 then
        sb.logInfo("Attempting to birth invalid pregnancy - aborting.")
        self:endBirthing()
        return
    end
    local babyConfig = storage.sexbound.pregnant[pregnancyId].babies[babyId]
    if babyConfig == nil then
        sb.logInfo("Attempting to birth invalid babyData - aborting, removing data.")
        self:endBirthing(pregnancyId)
        return
    end

    -- Check if player.interact is a function because some previous version of starbound did not implement it
    if "function" ~= type(player.interact) then
        babyConfig.pregnancyType = pregnancy.pregnancyType
        self:doBirthingLoop(pregnancyId, babyId)
        return
    end

    local babyGender = babyConfig.birthGender or "male"
    local babySpecies = babyConfig.birthSpecies or "human"
    local nameGenerator = "/species/humannamegen.config:names"
    local speciesConfig, genderId

    if babyConfig.birthEntityGroup == "humanoid" then
        -- Attempt to read configuration from species config file.
        if not pcall(function()
            speciesConfig = root.assetJson("/species/" .. babySpecies .. ".species")
            genderId = self:getParent():getGenderId(speciesConfig, babyGender)
            nameGenerator = speciesConfig.nameGen[genderId]
        end) then
            sb.logWarn("SxB: Could not find species config file for baby: "..tostring(babySpecies))
        end
    elseif babyConfig.birthEntityGroup == "monster" then nameGenerator = "/quests/generated/petnames.config:names" end

    xpcall(function()
        local _loadedConfig = self:loadNamedBirthConfig()
        _loadedConfig.config.pregnancyId = pregnancyId
        _loadedConfig.config.babyId = babyId
        _loadedConfig.config.babyGender = babyGender
        _loadedConfig.config.babySpecies = babySpecies
        _loadedConfig.config.nameGenerator = nameGenerator
        player.interact("ScriptPane", _loadedConfig, player.id())
    end, function(err)
        sb.logError("Unable to load named birth config - using normal un-named birth.")
        sb.logError(err)
        self:doBirthingLoop(pregnancyId, babyId)
    end)
end


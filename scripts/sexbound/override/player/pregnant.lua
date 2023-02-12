if not SXB_RUN_TESTS then
    require "/scripts/sexbound/override/common/pregnant.lua"
end

Sexbound.Player.Pregnant = Sexbound.Common.Pregnant:new()
Sexbound.Player.Pregnant_mt = {
    __index = Sexbound.Player.Pregnant
}

function Sexbound.Player.Pregnant:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Pregnant_mt)

    _self:init(parent)
    
    _self:addPlayerMessageHandlers()

    return _self
end

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

function Sexbound.Player.Pregnant:addPlayerMessageHandlers()
    message.setHandler("Sexbound:Pregnant:BirthNamed", function(_, _, args)
        return self:giveBirthNamed(args)
    end)
    
    message.setHandler("Sexbound:Pregnant:DebugNamedBirth", function(_, _, args)
        return self:openBabyNamingWindow(args)
    end)
end

--- Function to progress pregnancy delay and progress based on script delta time
-- @param number deltaTime
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
-- @param number deltaTime
function Sexbound.Player.Pregnant:updatePeriodCycle(dt)
    local config = self:getConfig()
    local enabled = config.enablePeriodCycle or false
    -- Feature disabled - ignore
    if not enabled then return end
    
    -- Player cannot ovulate in the first place - ignore
    if not self:canOvulate() or self:getParent()._isSterilized then return end
    
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


function Sexbound.Player.Pregnant:canOvulate()
    if self:getConfig().enableFreeForAll == true then
        return true
    end
    if storage.sexbound.identity.sxbCanOvulate == true then
        return true
    end

    if self:getParent()._bodyTraits.canOvulate or false then return true end

    return false
end

function Sexbound.Player.Pregnant:abortPregnancy()
    Sexbound.Common.Pregnant.abortPregnancy(self)

    self:notifyPlayerAboutAbortionViaRadioMessage()
end

--- Loads notifications configuration from file
function Sexbound.Player.Pregnant:loadNotificationDialog()
    local notifications = self:getParent():getNotifications() or {}
    notifications.plugins = notifications.plugins or {}
    notifications.plugins.pregnant = notifications.plugins.pregnant or {}

    return notifications.plugins.pregnant
end

function Sexbound.Player.Pregnant:triggerActualPregnancy(baby)
    local config = self:getConfig()
    local dayCount = baby.dayCount
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
        message = util.replaceTag(message, "daycount", "^red;" .. baby.dayCount .. "^reset;")
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
        message = util.replaceTag(message, "daycount", "^red;" .. baby.dayCount .. "^reset;")
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

function Sexbound.Player.Pregnant:fetchAbortionNotificationMessage()
    local notification = self:loadNotificationDialog() or {}
    notification = notification.birth or {}

    return notification.abortion or ""
end

function Sexbound.Player.Pregnant:notifyPlayerAboutAbortionViaRadioMessage()
    local message = self:fetchAbortionNotificationMessage()

    world.sendEntityMessage(entity.id(), "queueRadioMessage", {
        messageId = "sexbound_abortion",
        unique = false,
        text = message
    })
end

function Sexbound.Player.Pregnant:loadGiveBirthConfirmationConfig()
    if self._giveBirthConfirmationConfig then
        return self._giveBirthConfirmationConfig
    end
    self._giveBirthConfirmationConfig = root.assetJson("/interface/sexbound/confirmation/givebirth.config")
    return self._giveBirthConfirmationConfig
end

function Sexbound.Player.Pregnant:loadNamedBirthConfig()
    --if self._namedBirthConfig then return self._namedBirthConfig end
    self._namedBirthConfig = root.assetJson("/interface/sexbound/confirmation/namedbirth.config")
    return self._namedBirthConfig
end

function Sexbound.Player.Pregnant:handleGiveBirth(index)
    self:dataFilter()

    if index == nil or not storage.sexbound.pregnant[index] then
        return
    end

    self._isGivingBirth = true

    promises:add(player.confirm(self:loadGiveBirthConfirmationConfig()), function(choice)
        self._isGivingBirth = false

        local babyConfig = storage.sexbound.pregnant[index]

        if choice then
            --self:giveBirth(babyConfig)
            --table.remove(storage.sexbound.pregnant, index)
            --self:refreshStatusEffects()
            self:openBabyNamingWindow(index)
        end

        babyConfig.birthWorldTime = babyConfig.birthWorldTime + 840
        babyConfig.birthOSTime = os.time() + 3600
    end)
end

function Sexbound.Player.Pregnant:openBabyNamingWindow(babyId)
    if babyId == nil or not storage.sexbound.pregnant then return end
    local baby = storage.sexbound.pregnant[babyId]
    if not baby or (baby.delay or 0) > 0 then return end
    
    -- Check if player.interact is a function because some previous version of starbound did not implement it
    if "function" ~= type(player.interact) then
        self:giveBirth(baby)
        table.remove(storage.sexbound.pregnant, babyId)
        self:refreshStatusEffects()
    end
    
    local babyGender = baby.birthGender or "male"
    local babySpecies = baby.birthSpecies or "human"
    local nameGenerator = "/species/humannamegen.config"
    local speciesConfig, genderId
    
    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. babySpecies .. ".species")
        genderId = self:getParent():getGenderId(speciesConfig, babyGender)
        nameGenerator = speciesConfig.nameGen[genderId]
    end) then
        sb.logWarn("SxB: Could not find species config file for baby: "..tostring(babySpecies))
    end
    
    xpcall(function()
        local _loadedConfig = self:loadNamedBirthConfig()
        _loadedConfig.config.babyId = babyId
        _loadedConfig.config.babyGender = babyGender
        _loadedConfig.config.babySpecies = babySpecies
        _loadedConfig.config.nameGenerator = nameGenerator
        player.interact("ScriptPane", _loadedConfig, player.id())
    end, function(err)
        sb.logError("Unable to load named birth config - using normal un-named birth.")
        sb.logError(err)
        self:giveBirth(baby)
        table.remove(storage.sexbound.pregnant, babyId)
        self:refreshStatusEffects()
    end)
end

function Sexbound.Player.Pregnant:findTargetNamegenerator(speciesConfig)
    
end

function Sexbound.Player.Pregnant:giveBirthNamed(args)
    local babyId = args.id
    local babyName = args.name
    
    sb.logInfo("Attempted to give birth to "..tostring(babyId)..": "..tostring(babyName))
    self:giveBirth(storage.sexbound.pregnant[babyId])
    table.remove(storage.sexbound.pregnant, babyId)
    self:refreshStatusEffects()
end

function Sexbound.Player.Pregnant:dump(o)
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

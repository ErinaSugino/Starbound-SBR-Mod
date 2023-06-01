--- Sexbound.Actor.Pregnant Class Module.
-- @classmod Sexbound.Actor.Pregnant
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
    require("/scripts/sexbound/plugins/pregnant/baby_factory.lua")
end

Sexbound.Actor.Pregnant = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Pregnant_mt = {
    __index = Sexbound.Actor.Pregnant
}

--- Instantiates a new instance of Pregnant.
-- @param parent
-- @param config
function Sexbound.Actor.Pregnant:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "PREG",
        _config = config
    }, Sexbound.Actor.Pregnant_mt)
    
    local mainConfig = parent:getParent():getConfig() or {}
    _self:fetchRemoteConfig(mainConfig)
    _self:validateConfig()
    _self:init(parent, _self._logPrefix)
    _self:ensurePregnanciesAreStoredAsTable()
    _self:refreshStatusForThisActor()
    _self:setupMessageHandlers()

    return _self
end

--- Handles message events.
-- @param message
function Sexbound.Actor.Pregnant:onMessage(message)
    if message:getType() == "Sexbound:Pregnant:BecomePregnant" then
        self:handleBecomePregnant(message)
    end
end

--- Returns a reference to this actor's insemination decay rate.
function Sexbound.Actor.Pregnant:getInseminationDecay()
    return self._config.inseminationDecay or { 0.2, 0.3 }
end

--- Handle delta time updates
-- @param deltaTime
function Sexbound.Actor.Pregnant:onUpdateAnyState(dt)
    if self:getParent():getEntityType() == "player" then self:progressBabyState(dt) end

    if not self:isDripBlocked() then
        local fillCount = self:getCurrentAllInseminations()
        if fillCount > 0 then self:drip(dt, fillCount) end
    end
end

function Sexbound.Actor.Pregnant:drip(dt, fillCount)
    self._config.dripTimer = math.max(0, self._config.dripTimer - dt)

    if self._config.dripTimer == 0 then
        local decay = util.randomInRange(self:getInseminationDecay())
        local actor = self:getParent()
        local selfNumber = actor:getActorNumber()

        local climaxPlugin = self:getPlugin("climax")
        if climaxPlugin and climaxPlugin._config.enableClimaxParticles then
            animator.burstParticleEmitter("insemination-drip" .. selfNumber)
        end

        self._config.dripTimer = math.min(2, 1 / fillCount ^ 1.5)

        local prevBellyState = self:isBellySwollen()
        local inseminations = self._config.inseminations
        for k, v in pairs(inseminations) do
            inseminations[k] = math.max(0, v - decay * v / fillCount)
        end

        if prevBellyState ~= self:isBellySwollen() then
            actor:resetParts(actor:getAnimationState(), actor:getSpecies(), actor:getGender(),
                actor:resetDirectives(selfNumber))
        end
    end
end

function Sexbound.Actor.Pregnant:isDripBlocked()
    local impregnators = self:getParent():getImpregnatorList()
    for _, actor in ipairs(impregnators) do
        if self:otherActorHasRoleInPositionWhichCanImpregnate(actor) then
            return true
        end
    end
    return false
end

--- Function to progress pregnancy delay and progress based on script delta time
-- @param number deltaTime
function Sexbound.Actor.Pregnant:progressBabyState(dt)
    local pregnancies = self:getParent():getStorage():getData("sexbound").pregnant or {}
    if isEmpty(pregnancies) then return end
    
    for i,b in pairs(pregnancies) do
        local delay = b.delay or 0
        if delay > 0 then
            b.delay = b.delay - dt
        elseif b.birthWorldTime > 0 then
            b.birthWorldTime = b.birthWorldTime - dt
        end
    end
end

function Sexbound.Actor.Pregnant:setupMessageHandlers()
    self:getLog():debug("Setting up message handlers for "..self:getParent():getName().." in "..entity.id())
    
    message.setHandler("Sexbound:Pregnant:AddStatus", function(_, _, args)
        local compId = args.id
        local statusName = args.effect
        if compId == self:getParent():getEntityId() then
            self:getLog():debug("Adding effect "..statusName.." to "..self:getParent():getName())
            return self:getParent():getStatus():addStatus(statusName)
        end
    end)
    message.setHandler("Sexbound:Pregnant:RemoveStatus", function(_, _, args)
        local compId = args.id
        local statusName = args.effect
        if compId == self:getParent():getEntityId() then
            self:getLog():debug("Removing effect "..statusName.." from "..self:getParent():getName())
            return self:getParent():getStatus():removeStatus(statusName)
        end
    end)
end

--- Helper - Filters the pregnancies in storage and ensures it is set to a table
function Sexbound.Actor.Pregnant:ensurePregnanciesAreStoredAsTable()
    local storage = self:getParent():getStorage():getData("sexbound").pregnant

    if "table" ~= type(storage) then
        self:getParent():getStorage():getData("sexbound").pregnant = {}
    end
end

--- Handler function for 'BecomePregnant' message
-- @param message
function Sexbound.Actor.Pregnant:handleBecomePregnant(message)
    -- Climax logic doesn't trigger pregnancy request when climaxing actor cannot impregnate anyway - this check is only for relevant factors of the impregnated actor
    local otherActor = message:getData()

    self:getLog():info("Actor is trying to become pregnant: " .. self:getParent():getName())
    self:getLog():debug("Gotten pregnation request for actor ".. self:getParent():getActorNumber() .." - received parameter "..tostring(otherActor))

    local canOvulate = self:thisActorCanOvulate()
    local canPregnate = self:thisActorHasRoleInPositionWhichCanBeImpregnated()
    -- Abort checks if this actor can't get pregnant in the first place, or is not in a vaginal penetration role
    if not canOvulate or not canPregnate then return end
    
    local isProtected = self:thisActorIsUsingContraception()
    local isOvulating = self:thisActorIsOvulating()
    local ovulationCriteria = false
    if self:getConfig().enablePeriodCycle == true then ovulationCriteria = (canOvulate and isOvulating)
    else ovulationCriteria = canOvulate end
    self:getLog():debug("Ovulation check: canOvulate "..tostring(canOvulate).." - isOvulating "..tostring(isOvulating).." - final "..tostring(ovulationCriteria))
    -- Second line of defense: We can ovulate, but aren't right now. No pregnancies possible, abort.
    if not ovulationCriteria then return end
    
    local impregnators
    if otherActor then impregnators = {otherActor} else impregnators = self:getParent():getImpregnatorList() end
    local bellyFull, isClone, fuckedProtected, canImpregnate, canCum, directInsertion, compatible, curFertility
    local thisSpecies = self:getParent():getSpecies()
    local thatActor = nil

    for _, actor in ipairs(impregnators) do
        thatSpecies = actor:getSpecies()
        directInsertion = self:canImpregnate(actor)
        canImpregnate = self:otherActorHasRoleInPositionWhichCanImpregnate(actor)
        -- If the checked two actors don't even fuck directly or the penetrator isn't penetrating the vagina, no need to continue. Neither pregnancy nor hazzard can occur
        if directInsertion and canImpregnate then
            if self:getConfig().enablePregnancyHazards and self:isPregnant() and thisSpecies ~= thatSpecies then
                local chance = 0
                local chances = self:getConfig().pregnancyHazards or {["default"] = {}}
                chance = chances[thatSpecies] or chances["default"]
                chance = chance[thisSpecies] or chance["default"] or 0
                
                if chance > 0 then
                    local roll = self:generateRandomNumber() / 100
                    
                    self:getLog():debug("Pregnancy hazzard roll: "..thatSpecies.."->"..thisSpecies.." - "..roll.." <= "..chance)
                    
                    if roll <= chance then
                        self:hazardAbortion()
                        self:tryToNotifyThisActorOfHazardAbortion(actor)
                        self:tryToNotifyOtherActorOfHazardAbortion(actor)
                        -- When you were pregnant and a pregnancy hazard aborts it, you cannot get pregnant in the same turn - so abort here
                        break
                    end
                end
            end
            
            isClone = self:thisActorIsCloneOfOtherActor(actor)
            --fuckedProtected = self:otherActorIsUsingContraception(actor)
            --canCum = self:otherActorCanProduceSperm(actor)
            compatible = self:otherActorIsCompatibleSpecies(actor)
            curFertility = self:thisActorHasEnoughFertility(actor)
            bellyFull = self:thisActorIsAlreadyTooPregnant()
            
            self:getLog():debug("Pregnancy check for actor "..self:getParent():getActorNumber()..": Allow species " .. tostring(compatible) .. " - Can Impregnate " .. tostring(canImpregnate) .. " - Can be impregnated " .. tostring(canPregnate) .. " - Insertion " .. tostring(directInsertion))

            self:handleInsemination(actor)

            if not bellyFull and not isProtected and not isClone and compatible and curFertility then self:becomePregnant(actor) end
        end
    end

    -- All of these checks must pass or this actor will not become pregnant
    --if self:thisActorIsAlreadyTooPregnant() or self:thisActorIsCloneOfOtherActor() or
    --    self:thisActorIsUsingContraception() or self:otherActorIsUsingContraception() or
    --    not self:thisActorHasRoleInPositionWhichCanBeImpregnated() or not self:thisActorCanOvulate() or
    --    not self:otherActorHasRoleInPositionWhichCanImpregnate() or not self:otherActorCanProduceSperm() or
    --    not self:canImpregnate() or
    --    not self:otherActorIsCompatibleSpecies() or not self:thisActorHasEnoughFertility() then
    --    return
    --end

    -- self:becomePregnant()
end

--- Adds a new pregnancy to the in-game entity associated with this actor
function Sexbound.Actor.Pregnant:becomePregnant(daddy)
    self:getLog():info("Actor will become pregnant: " .. self:getParent():getName())

    local babyConfig = self:makeBaby(daddy)

    self:getLog():debug(babyConfig)

    self:increaseStatisticImpregnateOtherCountForOtherActor(daddy)
    if self:getParent():getEntityType() ~= "player" then
        -- Players trigger their pregnancies later so they do all this themselves
        self:increaseStatisticPregnancyCountForThisActor()
        self:tryToSendRadioMessageToThisActor(babyConfig, daddy)
        self:tryToSendRadioMessageToOtherActor(babyConfig, daddy)
        self:tryToRefreshStatusTextForThisActor(daddy)
        self:tryToApplyPregnantStatusEffectForThisActor(daddy)
    end

    self:storeBaby(babyConfig)

    self.otherActor = nil
end

--- Removes pregnancies and sends message to entity to do the same
function Sexbound.Actor.Pregnant:hazardAbortion()
    local data = self:getParent():getStorage():getData()
    data.sexbound.pregnant = {}
    
    world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Pregnant:HazardAbortion")
end

--- Generates and returns a random number between 1 & 100
function Sexbound.Actor.Pregnant:generateRandomNumber()
    return util.randomIntInRange({1, 100})
end

--- Increases the 'impregnateOtherCount' statistic of the other actor by +1
function Sexbound.Actor.Pregnant:increaseStatisticImpregnateOtherCountForOtherActor(otherActor)
    world.sendEntityMessage(otherActor:getEntityId(), "Sexbound:Statistics:Add", {
        name = "impregnateOtherCount",
        amount = 1
    })
end

--- Increases the 'pregnancyCount' statistic of the this actor by +1
function Sexbound.Actor.Pregnant:increaseStatisticPregnancyCountForThisActor()
    world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Statistics:Add", {
        name = "pregnancyCount",
        amount = 1
    })
end

--- Returns whether or not the actor is pregnant
function Sexbound.Actor.Pregnant:isPregnant()
    return self:getCurrentPregnancyCount() > 0
end

--- Returns whether or not the actor has a swollen belly
function Sexbound.Actor.Pregnant:isBellySwollen()
    return self:getCurrentAllInseminations() >= 7.5 or self:isVisiblyPregnant()
end

--- Returns whether or not the actor is visibly pregnant
function Sexbound.Actor.Pregnant:isVisiblyPregnant()
    return self:getCurrentVisiblePregnancyCount() > 0
end

--- Returns a reference to the last current pregnancy
function Sexbound.Actor.Pregnant:lastCurrentPregnancy()
    return self:getCurrentPregnancies(self:getCurrentPregnancyCount())
end

--- Loads notifications configuration from file
function Sexbound.Actor.Pregnant:loadNotificationDialog()
    local filePath = self:getConfig().notifications
    local config = root.assetJson(filePath)
    local plugins = config.plugins or {}

    return plugins.pregnant
end

--- Returns whether or not this actor has a role in a position which allows it to be impregnated
function Sexbound.Actor.Pregnant:thisActorHasRoleInPositionWhichCanBeImpregnated()
    local positionConfig = self:getParent():getPosition():getConfig()

    return positionConfig.possiblePregnancy[self:getParent():getActorNumber()] or false
end

--- Returns whether or not the other actor has a role in a position which allows it to impregnate
function Sexbound.Actor.Pregnant:otherActorHasRoleInPositionWhichCanImpregnate(otherActor)
    local positionConfig = self:getParent():getPosition():getConfig()

    return positionConfig.possibleImpregnation[otherActor:getActorNumber()] or false
end

--- Returns whether or not the other actor has a role in a position which can impregnated this actor
function Sexbound.Actor.Pregnant:canImpregnate(otherActor)
    local positionConfig = self:getParent():getPosition():getConfig()
    local thisNum = self:getParent():getActorNumber()
    local thatNum = otherActor:getActorNumber()

    self:getLog():debug("Impregnation check for " .. thatNum .. " on " .. thisNum)

    return positionConfig.actorRelation[thatNum] == thisNum or false
end

--- Returns whether or not this actor is already too pregnant
function Sexbound.Actor.Pregnant:thisActorIsAlreadyTooPregnant()
    if self:getConfig().allowMultipleImpregnations == true or self:getConfig().enableMultipleImpregnations == true then
        return false
    end

    return self:isPregnant()
end

--- Returns whether or not this actor can ovulate
function Sexbound.Actor.Pregnant:thisActorCanOvulate()
    local thisActor = self:getParent()

    if self:getConfig().enableFreeForAll == true then
        return true
    end
    if thisActor:getIdentity().sxbCanOvulate == true then
        return true
    end

    --[[local targetGender = thisActor:getSubGender() or thisActor:getGender()
    for _, gender in ipairs(self:getConfig().whichGendersCanOvulate) do
        if (gender == targetGender) then return true end
    end]]

    return thisActor:canOvulate()
end

--- Returns whether or not this actor is currently ovulating
function Sexbound.Actor.Pregnant:thisActorIsOvulating()
    if self:getParent():getEntityType() ~= "player" then return true end
    
    if self:getParent():status():hasStatus("sexbound_custom_ovulating") then return true end
    
    return false
end

--- Returns whether or not this actor is a clone of the other actor
function Sexbound.Actor.Pregnant:thisActorIsCloneOfOtherActor(otherActor)
    if self:getConfig().enableAsexualReproduction == true then
        return false
    end
    return self:getParent():getEntityId() == otherActor:getEntityId()
end

--- Returns the fertility value applicable to the current entity type
function Sexbound.Actor.Pregnant:getFertility()
    if self:getParent():getEntityType() == "player" then return self:getConfig().fertility
    else return self:getConfig().fertilityNPC end
end

--- Returns whether or not this actor has enough fertility to become pregnant
function Sexbound.Actor.Pregnant:thisActorHasEnoughFertility(otherActor)
    if self:getParent():status():hasStatus("sexbound_custom_hyper_fertility") or otherActor:status():hasStatus("sexbound_custom_hyper_fertility") then
        self:getLog():debug("Guaranteed impregnation due to hyper fertility pill effect")
        return true
    end
    local sxbFertility = self:getParent():getIdentity().sxbFertility
    local fertility = sxbFertility or self:getFertility()

    local bonusCount = self:getCurrentInseminations(otherActor)
    local bonusMax = self:getConfig().fertilityBonusMax or 0.6
    if bonusCount > 0 and fertility < bonusMax then
        local bonusMult = self:getConfig().fertilityBonusMult or 1.08

        fertility = util.clamp(fertility + (bonusMult ^ bonusCount) - 1, fertility, bonusMax)
    end

    local multiplier = self:getConfig().fertilityMult or 1.0
    if self:getParent():status():hasStatus("sexbound_custom_fertility") or otherActor:status():hasStatus("sexbound_custom_fertility") then 
        fertility = fertility * multiplier
        self:getLog():debug("Fertility chance multiplied due to fertility pill effect")
    end

    local pregnancyChance = self:generateRandomNumber() / 100;
    self:getLog():info("Pregnancy roll : " .. pregnancyChance .. " <= " .. fertility)
    return pregnancyChance <= fertility
end

--- Returns whether or not this actor is using contraception for females
function Sexbound.Actor.Pregnant:thisActorIsUsingContraception()
    return self:getParent():status():hasOneOf(self:getConfig().preventStatuses)
end

--- Returns whether or not the other actor can produce sperm
function Sexbound.Actor.Pregnant:otherActorCanProduceSperm(otherActor)
    if self:getConfig().enableFreeForAll == true or otherActor:getIdentity().sxbCanProduceSperm == true then
        return true
    end

    --[[local targetGender = otherActor:getSubGender() or otherActor:getGender()
    for _, gender in ipairs(self:getConfig().whichGendersCanProduceSperm) do
        if (gender == targetGender) then return true end
    end]]

    return otherActor:canProduceSperm()
end

--- Returns whether or not the other actor is using contraception for males
function Sexbound.Actor.Pregnant:otherActorIsUsingContraception(otherActor)
    return otherActor:status():hasOneOf(self:getConfig().preventStatuses)
end

--- Returns whether or not the other actor is a compatible species
function Sexbound.Actor.Pregnant:otherActorIsCompatibleSpecies(otherActor)
    local actor = self:getParent()
    self:getLog():debug("Species check: "..actor:getSpecies().." on "..otherActor:getSpecies())
    -- Check if conditions immediately bypass this check
    if self:getConfig().enableFreeForAll == true or self:getConfig().enableCompatibleSpeciesOnly == false or
        actor:getSpecies() == otherActor:getSpecies() then
        return true
    end
    
    -- Check if species types are compatible
    local thisSpeciesType, thatSpeciesType = actor:getIdentity("sxbSpeciesType"), otherActor:getIdentity("sxbSpeciesType")
    if thisSpeciesType == "universal" or thatSpeciesType == "universal" or (thisSpeciesType == thatSpeciesType and thisSpeciesType ~= nil) then return true end -- "nil" (aka. not set) is treated as universal incompatibility, so nil x nil == incompatible
    
    -- Alternatively check if whitelist exists for species
    local speciesList = self:getConfig().compatibleSpecies[otherActor:getSpecies()]
    if speciesList == "all" then return true end
    local ownSpecies = actor:getSpecies()
    for _, species in ipairs(speciesList or {}) do
        if ownSpecies == species then
            return true
        end
    end
    return false
end

--- Refreshes the status of this actor depending upon whether it is pregnant or not
function Sexbound.Actor.Pregnant:refreshStatusForThisActor()
    local status = self:getParent():status()
    if self:isVisiblyPregnant() then
        status:addStatus("pregnant")
    else
        status:removeStatus("pregnant")
    end
end

--- Prepares the message to send to other actor
function Sexbound.Actor.Pregnant:prepareMessageToSendToOtherActor(baby, otherActor)
    local dayCount = baby.dayCount
    local dialog = self:loadNotificationDialog() or {}
    local daystring = "day"
    if dayCount > 1 then daystring = "days" end
    local message = ""

    local immersionLevel = self._config.immersionLevel + 1
    dialog = dialog.pregnancy or {}
    dialog = dialog[immersionLevel] or {}
    message = dialog.remotePregnant or ""

    message = util.replaceTag(message, "name", "^green;" .. self:getParent():getName() .. "^reset;")
    message = util.replaceTag(message, "daycount", "^red;" .. dayCount .. "^reset;")
    message = util.replaceTag(message, "daystring", daystring)
    return message
end

--- Prepares the message to send to this actor
function Sexbound.Actor.Pregnant:prepareMessageToSendToThisActor(baby, otherActor)
    local dayCount = baby.dayCount
    local dialog = self:loadNotificationDialog() or {}
    local daystring = "day"
    if dayCount > 1 then daystring = "days" end
    local message = ""
    
    local immersionLevel = self._config.immersionLevel + 1
    dialog = dialog.pregnancy or {}
    dialog = dialog[immersionLevel] or {}
    if otherActor:getSpecies() == "sexbound_tentacleplant_v2" then message = dialog.tentaclePregnant or ""
    else message = dialog.pregnant or "" end

    message = util.replaceTag(message, "name", "^green;" .. otherActor:getName() .. "^reset;")
    message = util.replaceTag(message, "daycount", "^red;" .. dayCount .. "^reset;")
    message = util.replaceTag(message, "daystring", daystring)
    return message
end

--- Prepares the hazard abortion message to send to this actor
function Sexbound.Actor.Pregnant:prepareHazardAbortionMessageForThisActor(otherActor)
    local species = self:getParent():getSpecies()
    local dialog = self:loadNotificationDialog() or {}
    local message = ""

    local immersionLevel = self._config.immersionLevel + 1
    dialog = dialog.abortion or {}
    dialog = dialog[immersionLevel] or {}
    message = message .. (dialog[species] or dialog["default"] or "")

    return message
end

--- Prepares the hazard abortion message to send to the other actor
function Sexbound.Actor.Pregnant:prepareHazardAbortionMessageForOtherActor(otherActor)
    local species = otherActor:getSpecies()
    local dialog = self:loadNotificationDialog() or {}
    local message = ""

    local immersionLevel = self._config.immersionLevel + 1
    dialog = dialog.remoteAbortion or {}
    dialog = dialog[immersionLevel] or {}
    message = message .. (dialog[species] or dialog["default"] or "")

    return message
end

--- Tries to apply 'sexbound_pregnant' status effect for this actor
function Sexbound.Actor.Pregnant:tryToApplyPregnantStatusEffectForThisActor(otherActor)
    if self:getConfig().enableSilentImpregnations == true then
        return
    end
    world.sendEntityMessage(self:getParent():getEntityId(), "applyStatusEffect", "sexbound_pregnant", math.huge,
        otherActor:getEntityId())
end

--- Tries to refresh status text for this actor
function Sexbound.Actor.Pregnant:tryToRefreshStatusTextForThisActor(otherActor)
    if self:getConfig().enableSilentImpregnations == true or "npc" ~= self:getParent():getEntityType() then
        return
    end
    world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Pregnant:RefreshStatusText")
end

--- Tries to send radio message to this actor
function Sexbound.Actor.Pregnant:tryToSendRadioMessageToThisActor(baby, otherActor)
    local immersionLevel = self:getConfig().immersionLevel
    if immersionLevel >= 2 then return end
    if "player" ~= self:getParent():getEntityType() then
        return
    end

    local message = self:prepareMessageToSendToThisActor(baby, otherActor)

    world.sendEntityMessage(self:getParent():getEntityId(), "queueRadioMessage", {
        messageId = "Pregnant:Success",
        unique = false,
        text = message
    })

    return true
end

--- Tries to send radio message to the other actor
function Sexbound.Actor.Pregnant:tryToSendRadioMessageToOtherActor(baby, otherActor)
    local immersionLevel = self:getConfig().immersionLevel
    if immersionLevel >= 2 then return end
    if "player" ~= otherActor:getEntityType() then
        return
    end

    local message = self:prepareMessageToSendToOtherActor(baby, otherActor)

    world.sendEntityMessage(otherActor:getEntityId(), "queueRadioMessage", {
        messageId = "Pregnant:Success",
        unique = false,
        text = message
    })

    return true
end

--- Tries to send hazard abortion radio message to this actor
function Sexbound.Actor.Pregnant:tryToNotifyThisActorOfHazardAbortion(otherActor)
    local immersionLevel = self:getConfig().immersionLevel
    if immersionLevel >= 2 then return end
    if "player" ~= self:getParent():getEntityType() then
        return
    end

    local message = self:prepareHazardAbortionMessageForThisActor(otherActor)

    world.sendEntityMessage(self:getParent():getEntityId(), "queueRadioMessage", {
        messageId = "Pregnant:HazardAbortion",
        unique = false,
        text = message
    })

    return true
end

--- Tries to send hazard abortion radio message to the other actor
function Sexbound.Actor.Pregnant:tryToNotifyOtherActorOfHazardAbortion(otherActor)
    local immersionLevel = self:getConfig().immersionLevel
    if immersionLevel >= 2 then return end
    if "player" ~= otherActor:getEntityType() then
        return
    end

    local message = self:prepareHazardAbortionMessageForOtherActor(otherActor)

    world.sendEntityMessage(otherActor:getEntityId(), "queueRadioMessage", {
        messageId = "Pregnant:HazardAbortion",
        unique = false,
        text = message
    })

    return true
end

--- Makes a new baby and stores it in this actor's storage
function Sexbound.Actor.Pregnant:makeBaby(otherActor)
    local factory = BabyFactory:new(self)
    local baby = factory:make(otherActor)
    baby.birthEntityGroup, baby.birthSpecies = self:reconcileEntityGroups(otherActor)
    
    --[[local motherBodyColor, motherBodyColorAverage, motherUndyColor, motherUndyColorAverage, motherHairColor, motherHairColorAverage = self._parent:getGenes()
    local fatherBodyColor, fatherBodyColorAverage, fatherUndyColor, fatherUndyColorAverage, fatherHairColor, fatherHairColorAverage = otherActor:getGenes()
    local bodyColorPool, bodyColorPoolAverage, undyColorPool, undyColorPoolAverage, hairColorPool, hairColorPoolAverage
    if baby.birthEntityGroup ~= "humanoid" then return baby end -- no need to waste time on colors for monsters
    if baby.birthSpecies == self._parent:getSpecies() then bodyColorPool, bodyColorPoolAverage, undyColorPool, undyColorPoolAverage, hairColorPool, hairColorPoolAverage = self._parent:getGenePool() -- Baby is same species as mother - load species gene pool from cache
    elseif baby.birthSpecies == otherActor:getSpecies() then bodyColorPool, bodyColorPoolAverage, undyColorPool, undyColorPoolAverage, hairColorPool, hairColorPoolAverage = otherActor:getGenePool() -- Baby is same species as father - load species gene pool from cache
    else
        -- Baby is third species - load species file and extract color gene pool
        local speciesConfig
        
        -- Attempt to read configuration from species config file.
        if not pcall(function()
            speciesConfig = root.assetJson("/species/" .. identity.species .. ".species")
        end) then
            sb.logWarn("SxB: Could not find species config file.")
            return baby -- No species file. Abort further genetics.
        end
        
        bodyColorPool = speciesConfig.bodyColor
        bodyColorPoolAverage = {}
        undyColorPool = speciesConfig.undyColor
        undyColorPoolAverage = {}
        hairColorPool = speciesConfig.hairColor
        hairColorPoolAverage = {}
        
        -- Pre calculate color palette averages
        for i,r in ipairs(bodyColorPool) do
            if type(r) ~= "table" then break end
            local x = 0
            local avg = {0,0,0}
            local dist = 0
            -- Get average color of current checked palette from list
            for j,v in pairs(r) do
                x = x + 1
                local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
                avg[1],avg[2],avg[3] = avg[1]+r,avg[2]+g,avg[3]+b
            end
            avg[1],avg[2],avg[3] = math.floor(avg[1]/x),math.floor(avg[2]/x),math.floor(avg[3]/x)
            table.insert(bodyColorPoolAverage, avg)
        end
        for i,r in ipairs(undyColorPool) do
            if type(r) ~= "table" then break end
            local x = 0
            local avg = {0,0,0}
            local dist = 0
            -- Get average color of current checked palette from list
            for j,v in pairs(r) do
                x = x + 1
                local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
                avg[1],avg[2],avg[3] = avg[1]+r,avg[2]+g,avg[3]+b
            end
            avg[1],avg[2],avg[3] = math.floor(avg[1]/x),math.floor(avg[2]/x),math.floor(avg[3]/x)
            table.insert(undyColorPoolAverage, avg)
        end
        for i,r in ipairs(hairColorPool) do
            if type(r) ~= "table" then break end
            local x = 0
            local avg = {0,0,0}
            local dist = 0
            -- Get average color of current checked palette from list
            for j,v in pairs(r) do
                x = x + 1
                local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
                avg[1],avg[2],avg[3] = avg[1]+r,avg[2]+g,avg[3]+b
            end
            avg[1],avg[2],avg[3] = math.floor(avg[1]/x),math.floor(avg[2]/x),math.floor(avg[3]/x)
            table.insert(hairColorPoolAverage, avg)
        end
    end
    
    -- Map parent color themes to target space
    local motherBodyIndex, d11 = factory:findClosestColorAverageGene(bodyColorPoolAverage, motherBodyColorAverage)
    local fatherBodyIndex, d21 = factory:findClosestColorAverageGene(bodyColorPoolAverage, fatherBodyColorAverage)
    local motherUndyIndex, d12 = factory:findClosestColorAverageGene(undyColorPoolAverage, motherUndyColorAverage)
    local fatherUndyIndex, d22 = factory:findClosestColorAverageGene(undyColorPoolAverage, fatherUndyColorAverage)
    local motherHairIndex, d13 = factory:findClosestColorAverageGene(hairColorPoolAverage, motherHairColorAverage)
    local fatherHairIndex, d23 = factory:findClosestColorAverageGene(hairColorPoolAverage, fatherHairColorAverage)
    
    -- Generate crossed colors for baby
    math.randomseed(os.time())
    local bodyColorLambda = Sexbound.Util.normalDist()
    local undyColorLambda = Sexbound.Util.normalDist()
    local hairColorLambda = Sexbound.Util.normalDist()
    
    local babyBodyColor = nil
    if bodyColorPool[motherBodyIndex] ~= "" then
        babyBodyColor = {}
        for i,v in pairs(bodyColorPool[motherBodyIndex]) do
            babyBodyColor[i] = Sexbound.Util.rgbToHex(factory:crossfade({Sexbound.Util.hexToRgb(v)}, {Sexbound.Util.hexToRgb(bodyColorPool[fatherBodyIndex][i])}, bodyColorLambda))
        end
    end
    local babyUndyColor = nil
    if undyColorPool[motherUndyIndex] ~= "" then
        babyUndyColor = {}
        for i,v in pairs(undyColorPool[motherundyIndex]) do
            babyUndyColor[i] = Sexbound.Util.rgbToHex(factory:crossfade({Sexbound.Util.hexToRgb(v)}, {Sexbound.Util.hexToRgb(undyColorPool[fatherUndyIndex][i])}, undyColorLambda))
        end
    end
    local babyHairColor = nil
    if hairColorPool[motherHairIndex] ~= "" then
        babyHairColor = {}
        for i,v in pairs(hairColorPool[motherHairIndex]) do
            babyHairColor[i] = Sexbound.Util.rgbToHex(factory:crossfade({Sexbound.Util.hexToRgb(v)}, {Sexbound.Util.hexToRgb(hairColorPool[fatherHairIndex][i])}, hairColorLambda))
        end
    end
    
    baby.bodyColor = babyBodyColor
    baby.undyColor = babyUndyColor
    baby.hairColor = babyHairColor]]
    
    return baby
end

--- Reconciles differences between this actor and the other actor
function Sexbound.Actor.Pregnant:reconcileEntityGroups(otherActor)
    local geneticTable = self._config.geneticTable or {}
    local species = self:getParent():getSpecies()
    local otherSpecies = otherActor:getSpecies()
    if geneticTable[species] and geneticTable[species][otherSpecies] then return geneticTable[species][otherSpecies] end -- Defined cross-breed species.
    
    if self:getParent():getEntityGroup() == "humanoid" and otherActor:getEntityGroup() == "humanoid" then
        return "humanoid", self:generateBirthSpecies(otherActor)
    end

    if self:getParent():getEntityGroup() == "monsters" and otherActor:getEntityGroup() == "monsters" then
        return "monsters", self:generateBirthSpecies(otherActor)
    end

    if self:getParent():getEntityGroup() == "monsters" then
        return "monsters", species
    end

    if otherActor:getEntityGroup() == "monsters" then
        return "monsters", otherSpecies
    end

    return self:getParent():getEntityGroup(), self:getParent():getSpecies()
end

-- Returns a random species name based on the species of the parents
function Sexbound.Actor.Pregnant:generateBirthSpecies(otherActor)
    local actor1Species = self:getParent():getSpecies() or "human"
    local actor2Species = otherActor:getSpecies() or actor1Species
    if actor2Species == "sexbound_tentacleplant_v2" then return actor1Species end
    return util.randomChoice({actor1Species, actor2Species})
end

--- Stores a baby inside this actor
function Sexbound.Actor.Pregnant:storeBaby(baby)
    local _storage = self:getParent():getStorage()
    local _storageData = _storage:getData()
    table.insert(_storageData.sexbound.pregnant, baby)

    self:getParent():getStorage():sync(function(storageData)
        storageData.sexbound = storageData.sexbound or {}
        storageData.sexbound.pregnant = storageData.sexbound.pregnant or {}
        table.insert(storageData.sexbound.pregnant, baby)
        return storageData
    end)
end

--- Adds "whichGendersCanOvulate" and "whichGendersCanProduceSperm" to own config from main config
function Sexbound.Actor.Pregnant:fetchRemoteConfig(mainConfig)
    if not mainConfig then return end
    
    self._config.whichGendersCanOvulate = mainConfig.sex.whichGendersCanOvulate or {"female"}
    self._config.whichGendersCanProduceSperm = mainConfig.sex.whichGendersCanProduceSperm or {"male"}
    self._config.immersionLevel = mainConfig.immersionLevel or 1
end

function Sexbound.Actor.Pregnant:handleInsemination(otherActor)
    local inseminations = self._config.inseminations
    local otherUuid = otherActor._config.uniqueId or "other"
    local count = (inseminations[otherUuid] or 0) + 1
    inseminations[otherUuid] = count

    self:getLog():info("Actor fill count " .. count)
end

function Sexbound.Actor.Pregnant:getCurrentInseminations(otherActor)
    local inseminations = self._config.inseminations
    local otherUuid = otherActor._config.uniqueId or "other"
    return inseminations[otherUuid] or 0
end

function Sexbound.Actor.Pregnant:getCurrentAllInseminations()
    local inseminations = self._config.inseminations
    local count = 0
    for k, v in pairs(inseminations) do
        count = count + v
    end
    return count
end

--- Returns a reference to this actor's current pregnancies table
-- @param index
function Sexbound.Actor.Pregnant:getCurrentPregnancies(index)
    local pregnancies = self:getParent():getStorage():getData("sexbound").pregnant
    if index then
        return pregnancies[index]
    end
    return pregnancies
end

--- Returns the count of current pregnancies for this actor
function Sexbound.Actor.Pregnant:getCurrentPregnancyCount()
    local pregnancies = self:getParent():getStorage():getData("sexbound").pregnant or {}
    local count = 0
    for k, v in pairs(pregnancies) do
        count = count + 1
    end
    return count
end

--- Returns the count of currently visible pregnancies for this actor
function Sexbound.Actor.Pregnant:getCurrentVisiblePregnancyCount()
    local pregnancies = self:getParent():getStorage():getData("sexbound").pregnant or {}
    local count = 0
    local useOSTime = self:getConfig().useOSTimeForPregnancies
    local isPlayer = self:getParent():getEntityType() == "player"
    local osTime = os.time()
    for i,b in pairs(pregnancies) do
        if useOSTime == true and (osTime - b.fullBirthOSTime) >= ((b.birthOSTime - b.fullBirthOSTime) / 2) then
            count = count + 1
        elseif useOSTime ~= true then
            -- Since players have a countdown value for the birth time and NPCs a "countup", they need different calculations to determine if half of the pregnencies time is already over
            if isPlayer and b.birthWorldTime <= (b.fullBirthWorldTime / 2) then
                count = count + 1
            elseif not isPlayer and (world.day() + world.timeOfDay() - b.fullBirthWorldTime) >= ((b.birthWorldTime - b.fullBirthWorldTime) / 2) then
                count = count + 1
            end
        end
    end
    return count
end

--- Returns a percantage of how much the most progressed pregnancy has progressed
function Sexbound.Actor.Pregnant:getPregnancyStage()
    local result = 0
    local pregnancies = self:getParent():getStorage():getData("sexbound").pregnant or {}
    local useOSTime = self:getConfig().useOSTimeForPregnancies
    local isPlayer = self:getParent():getEntityType() == "player"
    local osTime = os.time()
    for i,b in pairs(pregnancies) do
        local tempResult
        if useOSTime == true then
            tempResult = (osTime - b.fullBirthOSTime) / (b.birthOSTime - b.fullBirthOSTime) -- OS time calculation: percentage diff time since start to total timespan
        elseif isPlayer == true then
            tempResult = 1 - (b.birthWorldTime / b.fullBirthWorldTime) -- Player world time calculation: reverse percentage of countdown
        else
            tempResult = (world.day() + world.timeOfDay() - baby.fullBirthWorldTime) / (baby.birthWorldTime - baby.fullBirthWorldTime) -- Non-Player world time calculation: percentage diff time sinc start to total timespan
        end
        if tempResult > result then result = tempResult end
    end
    return result
end

--- Returns the incest degree between this and the given actor
function Sexbound.Actor.Pregnant:incestLevel(otherActor)
    local identity = self:getParent():getIdentity()
    local otherIdentity = otherActor:getIdentity()
    local uuid = self:getParent()._config.uniqueId
    local otherUuid = otherActor._config.uniqueId
    
    if (identity.motherUuid == nil and identity.fatherUuid == nil) or (otherIdentity.motherUuid and otherIdentity.fatherUuid) then return 0 end -- Orphan, can't have (known) incest
    if identity.motherUuid == otherUuid or identity.fatherUuid == otherUuid or otherIdentity.motherUuid == uuid or otherIdentity.fatherUuid == uuid then return 3 end -- Level 3 incest - sex with your parent
    local thisPair = {identity.motherUuid, identity.fatherUuid}
    local thatPair = {otherIdentity.motherUuid, otherIdentity.fatherUuid}
    local matches = 0
    for _,v1 in ipairs(thisPair) do
        for _,v2 in ipairs(thatPair) do
            if v1==v2 then matches = matches + 1 break end
        end
    end
    
    -- Number of matches between this actor's parents and given actor's parents
    -- 1 match = level 1 incest - Sex with half-sibling
    -- 2 matches = level 2 incest - Sex with full-sibling
    return matches
end

--- Returns if there is incest between this and the given actor
function Sexbound.Actor.Pregnant:isIncest(otherActor)
    return self:incestLevel(otherActor) > 0
end

--- Validates the loaded config and sets missing config options to be default values.
function Sexbound.Actor.Pregnant:validateConfig()
    self:validateDripTimer(self._config.dripTimer)
    self:validateInseminations(self._config.inseminations)
    self:validateCompatibleSpecies(self._config.compatibleSpecies)
    self:validateEnableAsexualReproduction(self._config.enableAsexualReproduction)
    self:validateEnableCompatibleSpeciesOnly(self._config.enableCompatibleSpeciesOnly)
    self:validateEnableFreeForAll(self._config.enableFreeForAll)
    self:validateEnableMultipleImpregnations(self._config.enableMultipleImpregnations)
    --self:validateEnableNotifyPlayers(self._config.enableNotifyPlayers)
    self:validateEnablePregnancyFetish(self._config.enablePregnancyFetish)
    --self:validateEnableSilentImpregnations(self._config.enableSilentImpregnations)
    self:validateFertility(self._config.fertility)
    self:validateFertilityBonusMult(self._config.fertilityBonusMult)
    self:validateFertilityBonusMax(self._config.fertilityBonusMax)
    self:validateFertilityMult(self._config.fertilityMult)
    self:validateNotifications(self._config.notifications)
    self:validatePreventStatuses(self._config.preventStatuses)
    --self:validateWhichGendersCanProduceSperm(self._config.whichGendersCanProduceSperm)
    --self:validateWhichGendersCanOvulate(self._config.whichGendersCanOvulate)
    self:validateTrimesterCount(self._config.trimesterCount)
    self:validateTrimesterLength(self._config.trimesterLength)
    self:validateUseOSTimeForPregnancies(self._config.useOSTimeForPregnancies)
end

--- Ensures dripTimer is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateDripTimer(value)
    if type(value) ~= "number" then
        self._config.dripTimer = 0
        return
    end

    self._config.dripTimer = value
end

--- Ensures inseminations is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateInseminations(value)
    if type(value) ~= "table" then
        self._config.inseminations = {}
        return
    end

    self._config.inseminations = value
end

--- Ensures compatibleSpecies is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateCompatibleSpecies(value)
    if type(value) ~= "table" then
        self._config.compatibleSpecies = {}
        return
    end

    self._config.compatibleSpecies = value
end

--- Ensures enableAsexualReproduction is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateEnableAsexualReproduction(value)
    if type(value) ~= "boolean" then
        self._config.enableAsexualReproduction = false
        return
    end

    self._config.enableAsexualReproduction = value
end

--- Ensures enableCompatibleSpeciesOnly is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateEnableCompatibleSpeciesOnly(value)
    if type(value) ~= "boolean" then
        self._config.enableCompatibleSpeciesOnly = false
        return
    end

    self._config.enableCompatibleSpeciesOnly = value
end

--- Ensures enableFreeForAll is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateEnableFreeForAll(value)
    if type(value) ~= "boolean" then
        self._config.enableFreeForAll = false
        return
    end

    self._config.enableFreeForAll = value
end

--- Ensures enableMultipleImpregnations is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateEnableMultipleImpregnations(value)
    if type(value) ~= "boolean" then
        self._config.enableMultipleImpregnations = false
        return
    end

    self._config.enableMultipleImpregnations = value
end

--- Ensures enableNotifyPlayers is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateEnableNotifyPlayers(value)
    if type(value) ~= "boolean" then
        self._config.enableNotifyPlayers = true
        return
    end
    self._config.enableNotifyPlayers = value
end

--- Ensures enablePregnancyFetish is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateEnablePregnancyFetish(value)
    if type(value) ~= "boolean" then
        self._config.enablePregnancyFetish = false
        return
    end
    self._config.enablePregnancyFetish = value
end

--- Ensures enableSilentImpregnations is set to an allowed value
function Sexbound.Actor.Pregnant:validateEnableSilentImpregnations(value)
    if type(value) ~= "boolean" then
        self._config.enableSilentImpregnations = false
        return
    end
    self._config.enableSilentImpregnations = value
end

--- Ensures fertility is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateFertility(value)
    if type(value) ~= "number" then
        self._config.fertility = 0.1
        return
    end
    self._config.fertility = util.clamp(value, 0, 1)
end

--- Ensures fertility is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateFertilityBonusMult(value)
    if type(value) ~= "number" then
        self._config.fertilityBonusMult = 1.08
        return
    end
    self._config.fertilityBonusMult = util.clamp(value, 1, 2)
end

--- Ensures fertility is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateFertilityBonusMax(value)
    if type(value) ~= "number" then
        self._config.fertilityBonusMax = 0.6
        return
    end
    self._config.fertilityBonusMax = util.clamp(value, 0, 1)
end

--- Ensures fertility is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateFertilityMult(value)
    if type(value) ~= "number" then
        self._config.fertilityMult = 2.5
        return
    end
    self._config.fertilityMult = util.clamp(value, 1, 10)
end

--- Ensures notifications is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateNotifications(value)
    if type(value) ~= "string" then
        self._config.notifications = "/dialog/sexbound/en/notifications.config"
        return
    end
    self._config.notifications = value
end

--- Ensures preventStatuses are set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validatePreventStatuses(value)
    local defaultPreventStatuses = {"birthcontrol", "equipped_nopregnant", "equipped_iud", "infertile", "sterile"}

    if type(value) ~= "table" then
        self._config.preventStatuses = defaultPreventStatuses
        return
    end

    self._config.preventStatuses = {}
    for _, v in ipairs(value) do
        if type(v) == "string" then
            table.insert(self._config.preventStatuses, v)
        end
    end
end

--- Ensures trimesterCount is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateTrimesterCount(value)
    if type(value) ~= "number" then
        self._config.trimesterCount = 3
        return
    end
    self._config.trimesterCount = util.clamp(value, 1, value)
end

--- Ensures trimesterLength is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateTrimesterLength(value)
    if type(value) == "number" then
        self._config.trimesterLength = util.clamp(value, 1, value)
        return
    end
    if type(value) == "table" then
        local lo = value[1]
        local hi = value[2]
        if type(lo) ~= "number" then
            lo = 2
        end
        if type(hi) ~= "number" then
            hi = 3
        end
        self._config.trimesterLength = {}
        self._config.trimesterLength[1] = util.clamp(lo, 1, lo)
        self._config.trimesterLength[2] = util.clamp(hi, 1, hi)
        return
    end
    self._config.trimesterLength = {}
    self._config.trimesterLength[1] = 2
    self._config.trimesterLength[2] = 3
end

--- Ensures whichGendersCanOvulate is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateWhichGendersCanOvulate(value)
    if type(value) ~= "table" then
        self._config.whichGendersCanOvulate = {"female"}
        return
    end
    self._config.whichGendersCanOvulate = {}
    for _, v in ipairs(value) do
        if type(v) == "string" then
            table.insert(self._config.whichGendersCanOvulate, v)
        end
    end
end

--- Ensures whichGendersCanProduceSperm is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateWhichGendersCanProduceSperm(value)
    if type(value) ~= "table" then
        self._config.whichGendersCanProduceSperm = {"male"}
        return
    end
    self._config.whichGendersCanProduceSperm = {}
    for _, v in ipairs(value) do
        if type(v) == "string" then
            table.insert(self._config.whichGendersCanProduceSperm, v)
        end
    end
end

--- Ensures useOSTimeForPregnancies is set to an allowed value
-- @param value
function Sexbound.Actor.Pregnant:validateUseOSTimeForPregnancies(value)
    if type(value) ~= "boolean" then
        self._config.useOSTimeForPregnancies = true
        return
    end
    self._config.useOSTimeForPregnancies = value
end

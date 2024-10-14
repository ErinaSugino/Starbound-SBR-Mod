--- Sexbound.Actor.Climax Class Module.
-- @classmod Sexbound.Actor.Climax
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
    require("/scripts/sexbound/plugins/climax/scriptedclimax/scenario1.lua")
    require("/scripts/sexbound/plugins/climax/inflation.lua")
end

Sexbound.Actor.Climax = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Climax_mt = {
    __index = Sexbound.Actor.Climax
}

--- Instantiates a new instance of Climax.
-- @param parent
-- @param config
function Sexbound.Actor.Climax:new(parent, config)
    local _self = setmetatable({
        _logPrefix = "CLIM",
        _config = config,
        _emitterNames = {},
        _scenarios = {},
        _soundEffects = {},
        _timer = {},
        _inflation = {},
        _dripTimer = 0
    }, Sexbound.Actor.Climax_mt)

    -- Init. this plugin
    _self:init(parent, _self._logPrefix)

    _self._config.currentPoints = _self._config.currentPoints or 0

    _self:resetTimer()

    _self:refreshClimaxThreshold()

    _self:refreshEmitterName()

    _self._parent._isClimaxing = false

    _self._parent._isScriptedClimaxing = false

    _self._parent._isPreClimaxing = false

    if _self._config.enableClimaxSounds then
        _self:loadSoundEffects()
    end

    if _self._config.enableInflation then
        _self._inflation = Inflation:new(_self, _self._config)
    end

    -- Load scripted climax scenarios
    table.insert(_self._scenarios, Sexbound.ScriptedClimax.Scenario1:new(_self))
    
    _self:getLog():info("Inited Climax Plugin for actor ".._self._parent:getName())

    return _self
end

--- Sends message to apply configured arousal penatly to the entity related to this actor.
function Sexbound.Actor.Climax:applyArousalPenalty()
    local amount = util.randomInRange(self:getConfig().arousalPenalty)
    local entityId = self:getParent():getEntityId()

    if entityId then
        world.sendEntityMessage(entityId, "Sexbound:Arousal:Reduce", {
            amount = amount
        })
    end
end

--- Loads sound effects into the animator's sound pool.
function Sexbound.Actor.Climax:loadSoundEffects()
    if animator and animator.hasSound("climax") then
        animator.setSoundPool("climax", self:setSoundEffects("climax", self._config.sounds))
    end
end

--- Handles message
-- @param message
function Sexbound.Actor.Climax:onMessage(message)
    if message:getType() == "Sexbound:Climax:BeginClimax" then
        if not self._parent._isClimaxing and not self:getParent()._isScriptedClimaxing then
            self:beginClimax()
        end
    end

    if message:getType() == "Sexbound:Climax:BeginScriptedClimax" then
        self:beginScriptedClimax()
    end

    -- On Message Received: SwitchPosition
    if message:isType("Sexbound:Positions:SwitchPosition") then
        self:refreshEmitterName()
    end

    -- On Message Received: SwitchRoles
    if message:isType("Sexbound:SwitchRoles") then
        self:refreshEmitterName()
    end
    
    -- On Message Received: Inflate
    if message:isType("Sexbound:Climax:Inflate") then
        self:inflate(message:getData())
    end
end

function Sexbound.Actor.Climax:loadClimaxConfig()
    local actor = self:getParent()
    local actorNumber = actor:getActorNumber()
    local gender = actor:getGenitalType()

    self._climaxConfig = actor:getPosition():getClimaxConfig(actorNumber, gender)
end

function Sexbound.Actor.Climax:onUpdateAnyState(dt)
    self._config.currentPoints = self._config.currentPoints or 0
    
    if self:canDrip() then self:inflationDrip(dt) end
end

--- Handles event: onUpdateSexState
-- @param dt delta time
function Sexbound.Actor.Climax:onUpdateSexState(dt)
    local actor = self:getParent()
    local actorNumber = actor:getActorNumber()

    if actor._isScriptedClimaxing then
        self._scriptedClimax:run(dt)
    end

    local multiplier = actor:getPosition():getAnimationState("sexState"):getClimaxMultiplier(actorNumber) or 1
    local increase = util.randomInRange(self:getDefaultIncrease()) * multiplier * dt

    self._config.currentPoints = util.clamp(self._config.currentPoints + increase, self:getMinPoints(),
                                     self:getMaxPoints())
    
    self:tryAutoClimax()
end

function Sexbound.Actor.Climax:onEnterIdleState()
    self._parent._isClimaxing = false
    self._parent._isScriptedClimaxing = false
    self._parent._isPreClimaxing = false
end

--- Handles event: onEnterClimaxState
function Sexbound.Actor.Climax:onEnterClimaxState()
    self:refreshEmitterName()
end

--- Handles event: onExitClimaxState
function Sexbound.Actor.Climax:onExitClimaxState()
    self:getParent():status():removeStatus("climaxing")
end

--- Handles event: onUpdateIdleState
-- @param dt delta time
function Sexbound.Actor.Climax:onUpdateIdleState(dt)
    local decrease = util.randomInRange(self:getDefaultDecrease()) * dt

    self._config.currentPoints = util.clamp(self._config.currentPoints - decrease, self:getMinPoints(),
                                     self:getMaxPoints())
end

--- Handles event: onUpdateClimaxState
-- @param dt delta time
function Sexbound.Actor.Climax:onUpdateClimaxState(dt)
    local actor = self:getParent()

    if actor._isScriptedClimaxing then
        self._scriptedClimax:run(dt)
    elseif actor._isClimaxing then
        self._config.currentPoints = util.clamp(self._config.currentPoints - self:getDrainMultiplier() * dt,
                                         self:getMinPoints(), self:getMaxPoints())

        self:addTimer("shoot", dt)

        if self:getTimer("shoot") >= self:getCooldown() then
            self:shoot()
        end

        if self._config.currentPoints <= 0 then
            self:applyArousalPenalty()

            actor._isClimaxing = false
        end
    end

    -- Check that no other actors are climaxing
    if not actor._isClimaxing then
        for _, _actor in pairs(self:getRoot():getActors()) do
            if actor:getActorNumber() ~= _actor:getActorNumber() and _actor._isClimaxing then
                return
            end
        end

        self:endClimax()
    end
end

--- Begins climaxing
function Sexbound.Actor.Climax:beginClimax()
    local actor = self:getParent()
    if actor._isClimaxing or actor._isScriptedClimaxing then return end

    actor._isClimaxing = true

    world.sendEntityMessage(actor:getEntityId(), "Sexbound:Statistics:Add", {
        name   = "climaxCount",
        amount = 1
    })

    self:getLog():info("Actor is beginning climax: " .. actor:getName())
    self:getLog():debug("Climax triggered, by actor "..actor:getActorNumber())

    self:setTimer("shoot", 0)

    self:refreshCooldown(true)

    actor:getStatus():addStatus("climaxing")

    self:getParent():getStateMachine():setStatus("climaxing", true)

    -- Send message to SexTalk plugin of this actor
    Sexbound.Messenger.get("main"):send(self, actor, "Sexbound:SexTalk:BeginClimax")

    if actor:getStatus():hasOneOf(self:getConfig().preventStatuses) then
        return
    end

    -- Send messages to Pregnant plugin of other actors
    local diffNum = actor:getPosition():getConfig().actorRelation[actor:getActorNumber()] or 0
    self:getLog():debug("Impregnation target is actor "..diffNum)
    local _actor = actor:getParent():getActors()[diffNum] or nil
    if _actor then Sexbound.Messenger.get("main"):send(self, _actor, "Sexbound:Pregnant:BecomePregnant", actor) end
end

function Sexbound.Actor.Climax:beginScriptedClimax()
    local actor = self:getParent()
    if self:getParent()._isClimaxing or self:getParent().isScriptedClimaxing then return end
    self:getLog():info("Beginning Scripted Climax.")

    -- Choose random scripted climax scenario
    self._scriptedClimax = util.randomChoice(self._scenarios)

    -- These properties are always set in the beginning
    self:setTimer("scriptedclimax", 0)
    self:getParent()._isScriptedClimaxing = true

    -- Max climax points for testing purposes only
    self._config.currentPoints = self:getMaxPoints()

    self:getParent()._isPreClimaxing = true
    self:getParent():getStatus():addStatus("preclimaxing")

    world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Statistics:Add", {
        name   = "climaxCount",
        amount = 1
    })

    -- Send message to SexTalk plugin of this actor
    Sexbound.Messenger.get("main"):send(self, actor, "Sexbound:SexTalk:BeginPreClimax")

    self._scriptedClimax:start()
end

function Sexbound.Actor.Climax:endScriptedClimax()
    self:getLog():info("Ending Scripted Climax.")

    self:setTimer("scriptedclimax", 0)

    self:getParent()._isScriptedClimaxing = false
    self:getParent()._isPreClimaxing = false
    self:getParent()._isClimaxing = false
    self:getParent():getStatus():removeStatus("preclimaxing")
    self:getParent():getStatus():removeStatus("climaxing")
    
    local mActor = self:getParent()
    local amount = nil
    local entityId = nil
    amount = util.randomInRange(self:getConfig().arousalPenalty)
    amount = amount * 2
    entityId = self:getParent():getEntityId()

    if entityId then
      world.sendEntityMessage(entityId, "Sexbound:Arousal:Reduce", {
        amount = amount
      })
      if not self._config.legacyCondoms then world.sendEntityMessage(entityId, "Sexbound:Climax:CondomUpdate") end
    end

    self._scriptedClimax:stop()

    self._config.currentPoints = self:getMinPoints()
end

function Sexbound.Actor.Climax:scriptedImpregnation()
    local actor = self:getParent()
    self:getLog():debug("Triggering Scripted Climax Impregnation, by actor "..actor:getActorNumber())
    
    if actor:getStatus():hasOneOf(self:getConfig().preventStatuses) then
        self:getLog():debug("Scripted Climax Impregnation check skipped for actor "..actor:getActorNumber().." due to climax preventing status")
        return
    end
    
    local impregnationTargetNumber = self:getParent():getPosition():getConfig().actorRelation[actor:getActorNumber()] or 0
    local impregnationTarget = self:getParent():getParent():getActors()[impregnationTargetNumber] or nil
    if impregnationTarget then Sexbound.Messenger.get("main"):send(self, impregnationTarget, "Sexbound:Pregnant:BecomePregnant", actor) end
end

--- Ends climaxing
function Sexbound.Actor.Climax:endClimax()
    if not self._config.legacyCondoms then world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Climax:CondomUpdate") end
    self:getParent():getStateMachine():setStatus("climaxing", false)
    self:getParent():getStateMachine():setStatus("postclimax", true)
end

--- Plays climax sound effect
function Sexbound.Actor.Climax:playSoundEffect()
    if animator and animator.hasSound("climax") then
        animator.playSound("climax")
    end
end

--- Refreshes the climax threshold for NPC entities.
function Sexbound.Actor.Climax:refreshClimaxThreshold()
    self._config.threshold = util.randomInRange({self:getThreshold(), self:getMaxPoints()})
end

---Refreshes the cooldown time for this module.
function Sexbound.Actor.Climax:refreshCooldown(first)
    if first then self._cooldown = util.randomInRange({0.1,1})
    else self._cooldown = util.randomInRange(self._config.shotCooldown) end
    return self._cooldown
end

---Refreshes the emitterName of the climax particles.
function Sexbound.Actor.Climax:refreshEmitterName()
    local actor = self:getParent()
    local position = actor:getPosition()

    if not position then
        return
    end

    local genders = actor:getGenitalTypes()
    self._emitterNames = {}
    for _,g in ipairs(genders) do
        table.insert(self._emitterNames, position:getClimaxParticleName(actor:getActorNumber(), g))
    end
end

---Refreshes the timer table for this module.
function Sexbound.Actor.Climax:resetTimer()
    self._timer = {
        scriptedclimax = 0,
        shoot = self:getCooldown()
    }
    return self._timer
end

--- Commands this actor to shoot their climax once.
function Sexbound.Actor.Climax:shoot(...)
    if self:getConfig().enableClimaxSounds then
        self:playSoundEffect()
    end

    Sexbound.Messenger.get("main"):send(self, self._parent, "Sexbound:Climax:FireShot")
    Sexbound.Messenger.get("main"):send(self, self._parent, "Sexbound:Emote:ChangeEmote", "climax")

    self:setTimer("shoot", 0)

    self:refreshCooldown()

    -- Prevent creation of particles effects
    if self:getParent():status():hasOneOf(self:getConfig().preventStatusesVisible) then
        return
    end

    -- Spawn particles via the animator when enabled
    if self._config.enableClimaxParticles then
        self:spawnParticles()
    end

    -- Spawn liquids via spawning projectiles when enabled
    if self._config.enableSpawnLiquids then
        self:spawnProjectile(...)
    end
    
    -- Spawn items when enabled
    if self._config.enableSpawnItems then
        self:spawnItem(...)
    end
    
    local actorNum = self:getParent():getActorNumber()
    local config = self:getParent():getPosition():getConfig()
    local interactionTypes = config.interactionType or {}
    local interaction = interactionTypes[actorNum]
    
    local target = config.actorRelation[actorNum]
    if target then
        local _actor = self:getParent():getParent():getActors()[target] or nil
        if interaction == "oral" then
            world.sendEntityMessage(_actor:getEntityId(), "Sexbound:Climax:Feed")
        end
        if (interaction == "direct" or interaction == "toy_dick") and self._config.enableInflation then
            local genital = self._parent:getGenitalType()
            local liquid = self._config.projectileLiquid[self._parent:getSpecies()] or self._config.projectileLiquid["default"]
            liquid = liquid[genital]
            Sexbound.Messenger.get('main'):send(self, _actor, "Sexbound:Climax:Inflate", self._inflation:generateLoad(liquid, self:getInflationRate()))

        end
    end
end

function Sexbound.Actor.Climax:spawnParticles()
    for _,e in ipairs(self._emitterNames) do
        if e then animator.burstParticleEmitter(e) end
    end
end

--- Spawns a climax projectile.
function Sexbound.Actor.Climax:spawnProjectile(...)
    self:loadClimaxConfig()
    local args = {...}
    local climaxConfig = self._climaxConfig or {}
    local projectileName = args[1] or climaxConfig.projectileName
    if not projectileName then return end
    
    local actor, facingDirection = self:getParent(), {object.direction(), 1}
    local spawnOffset = vec2.mul(climaxConfig.projectileSpawnOffset or {0, 0}, facingDirection)
    local spawnPosition = vec2.add(args[2] or actor:getClimaxSpawnPosition(), spawnOffset)
    local sourceEntityId = args[3] or actor:getEntityId()
    local spawnDirection = args[4] or
                               vec2.mul(vec2.withAngle(util.toRadians(climaxConfig.projectileStartAngle)),
                                   facingDirection)
    local trackSourceEntity = true
    local projectileLiquid = self._config.projectileLiquid[actor:getSpecies()] or
                                 self._config.projectileLiquid["default"]
    local gender = actor:getGenitalType()

    projectileLiquid = projectileLiquid[gender]

    local handler = {}
    if projectileLiquid then
        local actionOnReap = climaxConfig.projectileActionOnReap or {
            [1] = {
                action = "liquid",
                liquid = projectileLiquid,
                quantity = 0.2
            }
        }
        
        handler.actionOnReap = actionOnReap
    end

    world.spawnProjectile(projectileName, spawnPosition, sourceEntityId, spawnDirection, trackSourceEntity, handler)
end

function Sexbound.Actor.Climax:spawnItem(...)
    self:loadClimaxConfig()
    local args = {...}
    local actor = self:getParent()
    local species = actor:getSpecies()
    
    local dospawnitem = false
    for _,_actor in pairs(self:getRoot():getActors()) do
        local _species = _actor:getSpecies()
        if species ~= _actor:getSpecies() and ((_species == "sexbound_milkingmachine") or (_species == "sexbound_milkingmachine_mk2")) then
            dospawnitem = true
        end
    end
    if species ~= "sexbound_dildo_ovipositor" and not dospawnitem then return end
    
    local facingDirection = {object.direction(), 1}
    local climaxConfig   = self._climaxConfig or {}
    local spawnOffset    = vec2.mul(climaxConfig.projectileSpawnOffset or {0, 0}, facingDirection)
    local spawnPosition  = vec2.add(args[2] or actor:getClimaxSpawnPosition(), spawnOffset)
    local genitals = actor:getGenitalTypes()
    
    if dospawnitem then
        -- Milkingmachine spawn
        local config = self._config.projectileItem or {}
        config = config.default or {}
        for _,g in ipairs(genitals) do
            local item = config[g]
            if item then world.spawnItem(item, spawnPosition, 1) end
        end
    else
        world.spawnItem("sexbound_fakeeggs", spawnPosition, 1) -- Ovipositor spawn
    end
end

--- Increases level of inflation
function Sexbound.Actor.Climax:inflate(inflationLoad)
    -- Regenerate received inflation load (fills in potential invalid values)
    inflationLoad = self._inflation:generateLoad(inflationLoad.liquid, inflationLoad.quantity)
    
    -- Add new inflation load
    local oldAmount = self._inflation:getTotalInflation()
    self._inflation:addLoad(inflationLoad)
    local newAmount = self._inflation:getTotalInflation()
    
    -- Handle case where total inflation passed the treshold
    if oldAmount < self:getInflationThreshold() and newAmount >= self:getInflationThreshold() then
        local actor = self._parent
        actor:resetParts(actor:getAnimationState(), actor:getSpecies(), actor:getGender(), actor:resetDirectives(actor:getActorNumber()))
        self:getLog():debug("Actor "..actor:getActorNumber().." ("..actor:getName()..") passed inflation threshold; "..
                            "reseting actor to show inflated belly sprite.")
    end
end

--- Gradually drecreases level of inflation
function Sexbound.Actor.Climax:inflationDrip(dt)
    self._dripTimer = math.max(0, self._dripTimer - dt)

    if self._dripTimer == 0 then
        local oldAmount = self._inflation:getTotalInflation()
        if oldAmount > 0 then
            local actor = self._parent
            self:getLog():debug("Actor "..actor:getActorNumber().." ("..actor:getName()..") dripping.")

            -- Remove drip quantity from inflation
            local dripQuantity = math.min(util.randomInRange(self:getDripRate()) * dt, self._inflation:getTotalInflation())
            local removedLiquids = self._inflation:removeQuantity(dripQuantity)
            local newAmount = self._inflation:getTotalInflation()

            -- Spawn particles if enabled
            if self._config.enableClimaxParticles then
                animator.burstParticleEmitter("insemination-drip" .. actor:getActorNumber())
            end

            -- Spawn liquid projectiles if enabled
            if self._config.enableSpawnLiquids and removedLiquids then
                local projectileName = "dripping"
                local spawnPosition = actor:getClimaxSpawnPosition() or {0.0, 0.0}
                local sourceEntityId = actor:getEntityId()
                local spawnDirection = {0, -1}
                local trackSourceEntity = false
                local handler = {}

                -- Generate liquid spawn action for projectile
                local actionOnReap = {}
                local actionCount = 0
                for liquid, quantity in pairs(removedLiquids) do
                    self:getLog():debug("Actor "..actor:getActorNumber().." dripping. Spawning "..quantity.." "..liquid..".")
                    if liquid then
                        actionCount = actionCount + 1
                        actionOnReap[actionCount] = {
                            action = "liquid",
                            liquid = liquid,
                            quantity = quantity
                        }
                    end
                end
                
                -- Spawn projectile if at least one action was generated
                if actionCount > 0 then
                    self:getLog():debug("Actor "..actor:getActorNumber().." dripping. Creating projectile.")
                    handler.actionOnReap = actionOnReap
                    world.spawnProjectile(projectileName, spawnPosition, sourceEntityId, spawnDirection, trackSourceEntity, handler)
                end
            end

            -- Handle case where total inflation lowered under the treshold
            if oldAmount >= self:getInflationThreshold() and newAmount < self:getInflationThreshold() then
                actor:resetParts(actor:getAnimationState(), actor:getSpecies(), actor:getGender(), actor:resetDirectives(actor:getActorNumber()))
                self:getLog():debug("Actor "..actor:getActorNumber().." ("..actor:getName()..") passed inflation threshold; "..
                                    "reseting actor to hide inflated belly sprite.")
            end
        end
        
        self._dripTimer = math.min(2, 1 / self._inflation:getTotalInflation() ^ self:getDripSpeed())
    end
end

--- Attempts to cause this actor to begin climaxing.
function Sexbound.Actor.Climax:tryAutoClimax()
    local entityType = self:getParent():getEntityType()
    local containsPlayer = false
    local playerControl = false
    
    if entityType == "player" then
        return
    else
        for _, actor in ipairs(self:getParent():getParent():getActors()) do
            if actor:getActorNumber() ~= self:getParent():getActorNumber() then
                if actor:getEntityType() == "player" then containsPlayer = true end
                if not actor:getStatus():hasStatus("sexbound_defeated") then playerControl = true end
            end
        end
    end
    
    if self._config.prioritizePlayer and containsPlayer and playerControl then
        -- Prevent auto climax if we have a player and that player is in control (not raped as part of sexbound defeat)
        return
    end

    if self:getParent()._isScriptedClimaxing then
        return
    end

    if entityType == "npc" and not self:getConfig().enableNPCAutoClimax then
        return
    end
    if entityType == "monster" and not self:getConfig().enableMonsterAutoClimax then
        return
    end

    if self:getCurrentPoints() >= self:getThreshold() then
        self:beginClimax()
        self:refreshClimaxThreshold()

        if math.random() <= self:getClimaxChainChance() then
            self:getLog():debug("Actor " .. self:getParent():getActorNumber() .. " trying to trigger climax chain")

            for _, actor in ipairs(self:getParent():getParent():getActors()) do
                if actor:getActorNumber() ~= self:getParent():getActorNumber() and actor:getEntityType() ~= "player" then
                    local plug = actor:getPlugins("climax")
                    if plug and plug:getCurrentPoints() >= (plug:getThreshold() * 0.8) then
                        plug:beginClimax()
                        plug:refreshClimaxThreshold()
                    end
                end
            end
        end
    end
end

--- Returns the simultaneous climax chance
function Sexbound.Actor.Climax:getClimaxChainChance()
    return self._config.nonPlayerClimaxChainChance or 0.33
end

--- Returns a reference to the cooldown.
function Sexbound.Actor.Climax:getCooldown()
    return self._cooldown or self:refreshCooldown()
end

--- Returns a reference to this actor's default climax decrease.
function Sexbound.Actor.Climax:getDefaultDecrease()
    return self._config.defaultDecrease or {0.1, 0.25}
end

function Sexbound.Actor.Climax:getDrainMultiplier()
    return self._config.drainMultiplier or 10
end

--- Returns a reference to this actor's default climax increase.
function Sexbound.Actor.Climax:getDefaultIncrease()
    return self._config.defaultIncrease or 0.5
end

--- Returns the min possible climax points.
function Sexbound.Actor.Climax:getMinPoints()
    return self._config.minPoints or 0
end

function Sexbound.Actor.Climax:getCurrentPoints()
    return self._config.currentPoints
end

--- Returns the max possible climax points.
function Sexbound.Actor.Climax:getMaxPoints()
    return self._config.maxPoints or 100
end

--- Returns the belly inflation rate
function Sexbound.Actor.Climax:getInflationRate()
    return self._config.inflationRate or 0.1
end

--- Returns the belly inflation threshold
function Sexbound.Actor.Climax:getInflationThreshold()
    return self._config.inflationThreshold or 7.5
end

--- Returns the forced dripping threshold
function Sexbound.Actor.Climax:getForcedDripThreshold()
    return self._config.forcedDripThreshold or 8.5
end

---Returns the inflation drip rate
function Sexbound.Actor.Climax:getDripRate()
    return self._config.dripRate or {0.2, 0.3}
end

--- Returns the inflation drip speed modifier
function Sexbound.Actor.Climax:getDripSpeed()
    return self._config.dripSpeed or 1.5
end

--- Returns the current inflation level offsetted by pregnancy
function Sexbound.Actor.Climax:getAdjustedInflation()
    local val = self._inflation:getTotalInflation()
    if self:getParent():isVisiblyPregnant() then
        val = val + self:getInflationThreshold()
    end
    return val
end

--- Returns whether or not dripping can currently occur
function Sexbound.Actor.Climax:canDrip()
    return not self._parent:hasInteractionType("direct") or self:getAdjustedInflation() > self:getForcedDripThreshold()
end

--- Returns whether or not this actor is currently inflated
function Sexbound.Actor.Climax:isInflated()
    return self._inflation:getTotalInflation() >= self:getInflationThreshold()
end

--- Returns a sound effect by specifed name or the table of sound effects.
-- @param name
function Sexbound.Actor.Climax:getSoundEffects(name)
    if name ~= nil then
        return self._soundEffects[name]
    end
    return self._soundEffects
end

--- Sets the current sound effects to a new table of sounds.
-- @param name
-- @param newSounds a table of sound names.
function Sexbound.Actor.Climax:setSoundEffects(name, newSounds)
    self._soundEffects[name] = newSounds or {}
    return self:getSoundEffects(name)
end

---Returns a reference to the actor's climax threshold.
function Sexbound.Actor.Climax:getThreshold()
    return self._config.threshold or 50
end

--- Returns a timer by specified name of the table timers.
-- @param name
function Sexbound.Actor.Climax:getTimer(name)
    if name ~= nil then
        return self._timer[name]
    end

    return self._timer
end

--- Sets a specified value to a specified name in the timer table.
-- @param name
-- @param newValue
function Sexbound.Actor.Climax:setTimer(name, newValue)
    self._timer[name] = newValue
    return self:getTimer(name)
end

--- Adds a specifed operand amount to the specified timer name.
-- @param name
-- @param operand
function Sexbound.Actor.Climax:addTimer(name, operand)
    if self._timer[name] ~= nil then
        self._timer[name] = self._timer[name] + operand
    else
        self._timer[name] = operand
    end

    return self._timer[name]
end

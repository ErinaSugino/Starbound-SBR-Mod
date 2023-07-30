--- Sexbound.Actor.Climax Class Module.
-- @classmod Sexbound.Actor.Climax
-- @author Locuturus
-- @license GNU General Public License v3.0

if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
  require("/scripts/sexbound/plugins/climax/scriptedclimax/scenario1.lua")
end

Sexbound.Actor.Climax = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Climax_mt = { __index = Sexbound.Actor.Climax }

--- Instantiates a new instance of Climax.
-- @param parent
-- @param config
function Sexbound.Actor.Climax:new( parent, config )
  local self = setmetatable({
    _logPrefix    = "CLIM",
    _config       = config,
    _emitterName  = nil,
    _scenarios    = {},
    _soundEffects = {},
    _timer        = {}
  }, Sexbound.Actor.Climax_mt)
  
  -- Init. this plugin
  self:init( parent, self._logPrefix )

  local _storage = self._parent:getStorage():getData('sexbound').climax

  if (type(_storage) == nil) then
    self._parent:getStorage():getData('sexbound').climax = 0
  end

  -- Addition by Red3dred
  local _entityId = self:getParent():getEntityId()
  
  if _entityId ~= -99999 then 
	  self._config.currentPoints = self:getParent():getStorage():getData("sexbound").climax or self._config.currentPoints 
	else 
    self._config.currentPoints = self._config.currentPoints or 0
  end

  self:resetTimer()
  
  self:refreshClimaxThreshold()
  
  self:refreshEmitterName()
  
  self._parent._isClimaxing = false
  
  if self._config.enableClimaxSounds then
    self:loadSoundEffects()
  end

  -- Load scripted climax scenarios
  table.insert(self._scenarios, Sexbound.ScriptedClimax.Scenario1:new(self))
  
  return self
end

--- Sends message to apply configured arousal penatly to the entity related to this actor.
function Sexbound.Actor.Climax:applyArousalPenalty()
  local amount   = util.randomInRange(self:getConfig().arousalPenalty)
  local entityId = self:getParent():getEntityId()
  
  if entityId then world.sendEntityMessage(entityId, "Sexbound:Arousal:Reduce", {amount = amount}) end
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
end

function Sexbound.Actor.Climax:loadClimaxConfig()
  local actor = self:getParent()
  local actorNumber = actor:getActorNumber()
  local gender = actor:getSubGender() or actor:getGender()

  if gender == "futanari" then gender = "male" end
  if gender == "cuntboy" then gender = "female" end

  self._climaxConfig = actor:getPosition():getClimaxConfig(actorNumber, gender)
end

function Sexbound.Actor.Climax:onUpdateAnyState(dt)
  -- Addition by Red3dred
  local _entityId = self:getParent():getEntityId()
  
  if _entityId ~= -99999 then 
	  self:getParent():getStorage():getData("sexbound").climax = self._config.currentPoints 
	else 
    self._config.currentPoints = self._config.currentPoints or 0
  end
end

--- Handles event: onUpdateSexState
-- @param dt delta time
function Sexbound.Actor.Climax:onUpdateSexState(dt)
  local actor = self:getParent()
  local actorNumber, gender = actor:getActorNumber(), actor:getGender()
  
  if actor._isScriptedClimaxing then self._scriptedClimax:run(dt) end
  
  local multiplier = actor:getPosition():getAnimationState("sexState"):getClimaxMultiplier(actorNumber) or 1
  local increase   = util.randomInRange(self:getDefaultIncrease()) * multiplier * dt

  self._config.currentPoints = util.clamp(self._config.currentPoints + increase, self:getMinPoints(), self:getMaxPoints())
  
  self:tryAutoClimax()
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

  self._config.currentPoints = util.clamp(self._config.currentPoints - decrease, self:getMinPoints(), self:getMaxPoints())
end

--- Handles event: onUpdateClimaxState
-- @param dt delta time
function Sexbound.Actor.Climax:onUpdateClimaxState(dt)
  local actor = self:getParent()
  
  if actor._isClimaxing then
    self._config.currentPoints = util.clamp(self._config.currentPoints - self:getDrainMultiplier() * dt, self:getMinPoints(), self:getMaxPoints())
    
    self:addTimer("shoot", dt)
    
    if self:getTimer("shoot") >= self:getCooldown() then self:shoot() end
		
    if self._config.currentPoints <= 0 then
      -- self:applyArousalPenalty()

      actor._isClimaxing = false
    end
  end
  
  -- Check that no other actors are climaxing
  if not actor._isClimaxing then
    for _,_actor in pairs(self:getRoot():getActors()) do
      if actor:getRole() ~= _actor:getRole() and _actor._isClimaxing then
        return
      end
    end
    
    self:endClimax()
  end
end

--- Begins climaxing
function Sexbound.Actor.Climax:beginClimax()
  local actor = self:getParent()

  actor._isClimaxing = true
  
  self:getLog():info("Actor is beginning climax: " .. actor:getName())
  
  self:setTimer("shoot", 0)
  
  self:refreshCooldown()
  
  actor:getStatus():addStatus("climaxing")

  self:getParent():getStateMachine():setStatus("climaxing", true)
  
  -- Send message to SexTalk plugin or this actor
  Sexbound.Messenger.get("main"):send(self, actor, "Sexbound:SexTalk:BeginClimax")
  
	if actor:getStatus():hasOneOf(self:getConfig().preventStatuses) then return end
	
  -- Send messages to Pregant plugin of other actors
  for _,_actor in pairs(self:getRoot():getActors()) do
    if actor:getRole() ~= _actor:getRole() then
      Sexbound.Messenger.get("main"):send(self, _actor, "Sexbound:Pregnant:BecomePregnant", actor)
    end
  end
end

function Sexbound.Actor.Climax:beginScriptedClimax()
  self:getLog():info("Beginning Scripted Climax.")

  -- Choose random scripted climax scenario
  self._scriptedClimax = util.randomChoice(self._scenarios)

  -- These properties are always set in the beginning
  self:setTimer("scriptedclimax", 0)
  self:getParent()._isScriptedClimaxing = true

  -- Max climax points for testing purposes only
  self._config.currentPoints = self:getMaxPoints()
  
  self._scriptedClimax:start()
end

function Sexbound.Actor.Climax:endScriptedClimax()
  self:getLog():info("Ending Scripted Climax.")

  self:setTimer("scriptedclimax", 0)
  
  self:getParent()._isScriptedClimaxing = false
  
  self._scriptedClimax:stop()
    
  self._config.currentPoints = self:getMinPoints()
end

--- Ends climaxing
function Sexbound.Actor.Climax:endClimax()  
  self:getParent():getStateMachine():setStatus("climaxing", false)
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
function Sexbound.Actor.Climax:refreshCooldown()
  self._cooldown = util.randomInRange(self._config.shotCooldown)
  return self._cooldown
end

---Refreshes the emitterName of the climax particles.
function Sexbound.Actor.Climax:refreshEmitterName()
  local actor    = self:getParent()
  local position = actor:getPosition()
  
  if not position then return end

  local gender = actor:getSubGender() or actor:getGender()
  if gender == "futanari" then gender = "male" end
  if gender == "cuntboy" then gender = "female" end
  self._emitterName = position:getClimaxParticleName(actor:getActorNumber(), gender)
end

---Refreshes the timer table for this module.
function Sexbound.Actor.Climax:resetTimer()
  self._timer = {scriptedclimax = 0, shoot = self:getCooldown()}
  return self._timer
end

--- Commands this actor to shoot their climax once.
function Sexbound.Actor.Climax:shoot(...)
  if self:getConfig().enableClimaxSounds then self:playSoundEffect() end

  Sexbound.Messenger.get("main"):send(self, self._parent, "Sexbound:Emote:ChangeEmote", "climax")

  self:setTimer("shoot", 0)

  self:refreshCooldown()

	-- Prevent creation of particles effects
	if self:getParent():status():hasOneOf(self:getConfig().preventStatuses) then return end

	-- Spawn particles via the animator when enabled
  if self._config.enableClimaxParticles then
    self:spawnParticles()
  end
  
  -- Spawn items depending on the context
		self:spawnItem(...)
  
  -- Spawn liquids via spawning projectiles when enabled
  if self._config.enableSpawnLiquids then 
		self:spawnProjectile(...)
	end
end

function Sexbound.Actor.Climax:spawnParticles()
  if self._emitterName then animator.burstParticleEmitter(self._emitterName) end
end

--- Spawns a climax projectile.
function Sexbound.Actor.Climax:spawnProjectile(...)
  self:loadClimaxConfig()
  local args = {...}
  local actor, facingDirection = self:getParent(), {object.direction(), 1}
  local climaxConfig   = self._climaxConfig or {}
  local spawnOffset    = vec2.mul(climaxConfig.projectileSpawnOffset or {0, 0}, facingDirection)
  local projectileName = args[1] or climaxConfig.projectileName
  local spawnPosition  = vec2.add(args[2] or actor:getClimaxSpawnPosition(), spawnOffset)
  local sourceEntityId = args[3] or actor:getEntityId()
  local spawnDirection = args[4] or vec2.mul(vec2.withAngle(util.toRadians(climaxConfig.projectileStartAngle)), facingDirection)
  local trackSourceEntity = true
  local projectileLiquid = self._config.projectileLiquid[actor:getSpecies()] or self._config.projectileLiquid["default"]
  local gender = actor:getSubGender() or actor:getGender()

  if gender == "futanari" then gender = "male" end
  if gender == "cuntboy" then gender = "female" end

  projectileLiquid = projectileLiquid[gender]
  
  local actionOnReap = climaxConfig.projectileActionOnReap or {["1"] = {
    action = "liquid", 
    liquid = projectileLiquid,
    quantity = 1 
  }}
  
  world.spawnProjectile(projectileName, spawnPosition, sourceEntityId, spawnDirection, trackSourceEntity, {actionOnReap = actionOnReap})
end

--- Spawns a climax item.
function Sexbound.Actor.Climax:spawnItem(...)
  self:loadClimaxConfig()
  local args = {...}
  local actor, facingDirection = self:getParent(), {object.direction(), 1}
  local climaxConfig   = self._climaxConfig or {}
  local spawnOffset    = vec2.mul(climaxConfig.projectileSpawnOffset or {0, 0}, facingDirection)
  local projectileName = args[1] or climaxConfig.projectileName
  local spawnPosition  = vec2.add(args[2] or actor:getClimaxSpawnPosition(), spawnOffset)
  local sourceEntityId = args[3] or actor:getEntityId()
  local spawnDirection = args[4] or vec2.mul(vec2.withAngle(util.toRadians(climaxConfig.projectileStartAngle)), facingDirection)
  local trackSourceEntity = true
  local projectileLiquid = self._config.projectileLiquid[actor:getSpecies()] or self._config.projectileLiquid["default"]
  local gender =  actor:getGender()
  local subGender = actor:getSubGender()

  if subGender == "futanari" then gender = "male" end
  if subGender == "cuntboy" then gender = "female" end
  local itemName = "liquidejaculant"
  if ( gender == "male" ) then itemName = "liquidsemen" end
  if ( actor:getSpecies() == "sexbound_dildo_ovipositor" ) then itemName = "sexbound_fakeeggs" end
  
  -- local itemName
  self.statuses = "sexbound_milkmode"
  
  local dospawnitem = false
  for _,_actor in pairs(self:getRoot():getActors()) do
	if actor:getSpecies() ~= _actor:getSpecies() and ((_actor:getSpecies() == "sexbound_milkingmachine") or (_actor:getSpecies() == "sexbound_milkingmachine_mk2")) then
		dospawnitem = true
		--sb.logInfo("Milkmode Status Check Result: True")
	--else sb.logInfo("Milkmode Status Check Result: False, species was " .. _actor:getSpecies())
	end
  end

  if ((actor:getSpecies() == "sexbound_dildo_ovipositor") or dospawnitem) then world.spawnItem(itemName, spawnPosition, 1) end
end

--- Attempts to cause this actor to begin climaxing.
function Sexbound.Actor.Climax:tryAutoClimax()
  local entityType = self:getParent():getEntityType()

  if entityType == "player" then return end

  if self:getParent()._isScriptedClimaxing then return end

  if entityType == "npc"     and not self:getConfig().enableNPCAutoClimax     then return end
  if entityType == "monster" and not self:getConfig().enableMonsterAutoClimax then return end

  if self._config.currentPoints >= self:getThreshold() then
    self:beginClimax()
    
    self:refreshClimaxThreshold()
  end
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

--- Returns a sound effect by specifed name or the table of sound effects.
-- @param name
function Sexbound.Actor.Climax:getSoundEffects(name)
  if name ~= nil then return self._soundEffects[name] end
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
  if name ~= nil then return self._timer[name] end
  
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

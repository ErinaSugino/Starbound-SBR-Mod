--- SexboundDefeat Class Module.
-- @classmod SexboundDefeat
-- @author Locuturus
-- @license GNU General Public License v3.0
SexboundDefeat = {}
SexboundDefeat_mt = { __index = SexboundDefeat }

require "/scripts/util.lua"
require "/scripts/messageutil.lua"

--- Creates and returns new instance of SexboundDefeat.
-- @param entityType
-- @param species
function SexboundDefeat:new(entityType)
  local _self = setmetatable({
		_configFilePath    = "/sexbound-defeat.config",
		_uiConfigFilePath  = "/interface/sexbound/defeat.config",
		_entityId          = entity.id(),
		_entityType        = entityType,
		_hostileEntityId   = nil,
		_hostileEntityType = nil,
		_promises          = PromiseKeeper.new(),
		_timer             = 0,
		_timeout           = 60,
		_isDefeated        = false,
		_isTransformed     = false,
		_sexNodeId         = nil
  }, SexboundDefeat_mt)

	-- Load the Sexbound Defeat config settings
	_self._config = _self:loadConfig()
	_self:validateConfig(_self._config)

	-- Initialize message handlers
	_self:initMessageHandlers()

	-- Set the default timeout as configured in the settings
	_self:_initTimeout()

	return _self
end

function SexboundDefeat:initMessageHandlers()
	message.setHandler("SexboundDefeat:Breakout", function(_,_,args)
		self._timer = self._timeout
	end)
end

-- Update Loop
function SexboundDefeat:update(dt, oldUpdate)
	self._promises:update()

  if self:isTransformed() then
    self._timer = self._timer + dt
    -- Untransform the NPC when the timer runs out
    if self._timer >= self._timeout or not self:isStunned() then
      self:setIsDefeated(false)
			self:setIsTransformed(false)
			self:setTimer(0)
      self:untransform()
    end
	end

	-- Return when is defeated to prevent the default update loop from running
	if self:isDefeated() then return end

	oldUpdate(dt)
end

--- Returns back species name retrieved with the default world API.
--- MonsterType is considered as a species by Sexbound
function SexboundDefeat:findSpecies()
	if self:isMonster() then
		return world.monsterType(self._entityId)
	end
	if self:isPlayer() or self:isNPC() then
		return world.entitySpecies(self._entityId)
	end
	return "default"
end

function SexboundDefeat:handleApplyDamageRequest(originalFunction, damageRequest)
	-- Do not return damage while the entity isDefeated is true
	if self:isDefeated() then return {} end

	-- Otherwise use the original applyDamageRequest function to process the incoming damage
	local damage = originalFunction(damageRequest)

	-- When the this entity's health is greater than 0, generate damage
	if status.resource("health") > 0 then return damage end

	-- Store a reference to the hostile entity id that delivered the killing blow to this entity
	self._hostileEntityId   = damageRequest.sourceEntityId
	if self._hostileEntityId ~= nil then
		self._hostileEntityType = world.entityType(self._hostileEntityId)
	end

	-- Handle the case that the entity has given itself a killing blow
	if self:isSuicide() then
		self:tryToDie()
		return {}
	end

	-- Prevent the entity from dying by ticking its health up by a percentage point
	status.setResourcePercentage("health", 0.01)

	-- Set this entity as isDefeated
	self:setIsDefeated(true)

	-- Reset the defeat timer to 0
	self:setTimer(0)

	-- Attempt to transform this entity into a sexnode
	self:retrieveSexboundConfig(function(result)
		return self:handleRetrieveSexboundConfigSuccess(result)
	end, function()
		return self:handleRetrieveSexboundConfigFailure()
	end)

  return {}
end

function SexboundDefeat:loadConfig()
	local _,loadedConfig = xpcall(function()
		return root.assetJson(self._configFilePath)
	end, function(err)
		sb.logError("Unable to load config file for Sexbound Defeat!")
	end)
	return loadedConfig
end

function SexboundDefeat:outputDefeatedDialog()
	if self:isNPC() and not self._config.enableStartDialogForNPCs then return end
	if self:isMonster() and not self._config.enableStartDialogForMonsters then return end
	local species = self:findSpecies()
	local defeatedDialog = self._config.startDialog.defeated[species] or
	self._config.startDialog.defeated.default
	world.sendEntityMessage(
		self._entityId, "Sexbound:Actor:Say",
		{
			message = util.randomChoice(defeatedDialog)
		}
	)
end

function SexboundDefeat:outputVictoryDialog()
	if self._hostileEntityType == "npc" and not self._config.enableStartDialogForNPCs then return end
	if self._hostileEntityType == "monster" and not self._config.enableStartDialogForMonsters then return end
	local controllerSpecies = world.entitySpecies(self._hostileEntityId)
	local victoryDialog = self._config.startDialog.victory[controllerSpecies] or
	self._config.startDialog.victory.default
	world.sendEntityMessage(
		self._hostileEntityId, "Sexbound:Actor:Say",
		{
			message = util.randomChoice(victoryDialog)
		}
	)
end

function SexboundDefeat:retrieveSexboundConfig(successCallback, failureCallback)
	self._promises:add(
		world.sendEntityMessage(
			self._hostileEntityId,
			"Sexbound:Config:Retrieve"
		),
		successCallback,
		failureCallback
	)
end

function SexboundDefeat:handleRetrieveSexboundConfigSuccess(sexboundConfig)
	-- Output the victory dialog
	self:outputVictoryDialog()
	self:transform(sexboundConfig, function(result)
		result = result or {}
		if result.uniqueId == nil then
			self:setIsDefeated(false)
			self:tryToDie()
			return
		end
		return self:handleTransformSuccess(result.uniqueId)
	end, function()
		return self:handleTransformFailed()
	end)
end

function SexboundDefeat:handleRetrieveSexboundConfigFailure()
	self:setIsDefeated(true)
	self:tryToDie()
end

function SexboundDefeat:transform(sexboundConfig, successCallback, failureCallback)
	self._promises:add(
		world.sendEntityMessage(
			self._entityId,
			"Sexbound:Transform",
			{
				responseRequired = true,
				sexboundConfig = sexboundConfig,
				timeout = 500
			}
		),
		successCallback,
		failureCallback
	)
end

function SexboundDefeat:handleTransformFailed()
	self:setIsDefeated(false)
	self:setIsTransformed(false)
	self:tryToDie()
	return false
end

function SexboundDefeat:handleTransformSuccess(nodeUniqueId)
	self._sexNodeId = nodeUniqueId
	self:setIsDefeated(true)
	self:setIsTransformed(true)
	self:setTimer(0)
	self:outputDefeatedDialog()
	if self:isPlayer() then
		if self._config.defeatedPlayersCanUseSexUI then
			self._promises:add(world.sendEntityMessage(self._sexNodeId, "Sexbound:Retrieve:UIConfig"), function(config)
				world.sendEntityMessage(self._entityId, "Sexbound:UI:Show", {config = config})
			end)
		else
			world.sendEntityMessage(self._entityId, "Sexbound:UI:Show", {config = self:loadUIConfig()})
		end
		status.addEphemeralEffect("dontstarve",    self._timeout)
		status.addEphemeralEffect("regeneration4", self._timeout)
	end

	status.addEphemeralEffect("sexbound_sex",  self._timeout)
	status.addEphemeralEffect("sexbound_stun", self._timeout)

	-- Try to notify the controlling entity to mount the defeated player.
	if (self._sexNodeId and self._hostileEntityId) then
		self._promises:add(world.sendEntityMessage(self._sexNodeId, "Sexbound:Retrieve:ControllerId"), function(controllerId)
			world.sendEntityMessage(self._hostileEntityId, "notify", {type = "sexbound.setup", targetId = controllerId})
		end)
	end

	return true
end

function SexboundDefeat:loadUIConfig()
  local _,_config = xpcall(function()
    return root.assetJson(self._uiConfigFilePath)
  end, function(error)
      sb.logError("Unable to load config file for the Sexbound Defeat!")
  end)
	_config.config.nodeUniqueId = self._sexNodeId
  return _config or {}
end

function SexboundDefeat:tryToDie()
  if not self:isPlayer() and self:isPregnant() and self._config.enableImmortalPregnantNPCs then
    local species = self:findSpecies()
		local pregnantDialog = self._config.pregnantDialog[species] or self._config.pregnantDialog.default
    world.sendEntityMessage(self._entityId, "Sexbound:Actor:Say", {message = util.randomChoice(pregnantDialog)})
    status.setResourcePercentage("health", 1.0)
  else
    status.setResourcePercentage("health", 0)
  end
end

function SexboundDefeat:smashSexNode(storage)
	if not self._sexNodeId then return end
	world.sendEntityMessage(self._sexNodeId, "Sexbound:Smash", { storage = storage })
end

-- [Helper] Untransform the Entity
function SexboundDefeat:untransform()
	if not self:isPlayer() then self:tryToDie() end
	local storage = {} -- temp local storage
	if not self:isPlayer() and self:isPregnant() and self._config.convertPregnantEnemiesToFriends then
		storage = { previousDamageTeam = { type = "friendly", team = 1 } }
	end
	self:smashSexNode(storage)
	if not self._hostileEntityId then return end
	if self._hostileEntityType == "player" then return end
	world.sendEntityMessage(self._hostileEntityId, "Sexbound:Actor:Respawn")
	self._hostileEntityId = nil
	self._hostileEntityType = nil
	self._sexNodeId = nil
	status.removeEphemeralEffect("regeneration4")
end

-- Validate Configuration
function SexboundDefeat:validateConfig()
	self:_validateConvertPregnantEnemiesToFriends(self._config.convertPregnantEnemiesToFriends, false)
	self:_validateDefeatedPlayersCanUseSexUI(self._config.defeatedPlayersCanUseSexUI, false)
	self:_validateDefeatTimeoutMonster(self._config.defeatTimeoutMonster, 60)
	self:_validateDefeatTimeoutNPC(self._config.defeatTimeoutNPC, 60)
	self:_validateDefeatTimeoutPlayer(self._config.defeatTimeoutPlayer, 30)
	self:_validateEnableImmortalPregnantNPCs(self._config.enableImmortalPregnantNPCs, false)
	self:_validateEnableStartDialogForNPCs(self._config.enableStartDialogForNPCs, true)
	self:_validateEnableStartDialogForMonsters(self._config.enableStartDialogForMonsters, false)
end

-- Getters / Setters
function SexboundDefeat:getConfig()
	return self._config
end

function SexboundDefeat:getTimer()
	return self._timer
end

function SexboundDefeat:getTimeout()
	return self._timeout
end

function SexboundDefeat:isDefeated()
	return self._isDefeated
end

function SexboundDefeat:isMonster()
	return self._entityType == "monster"
end

function SexboundDefeat:isNPC()
	return self._entityType == "npc"
end

function SexboundDefeat:isPlayer()
	return self._entityType == "player"
end

function SexboundDefeat:isPregnant()
  return status.statusProperty("sexbound_pregnant")
end

function SexboundDefeat:isStunned()
  return status.statusProperty("sexbound_stun")
end

function SexboundDefeat:isSuicide()
	return self._hostileEntityId == nil or self._hostileEntityId == self._entityId
end

function SexboundDefeat:isTransformed()
	return self._isTransformed or false
end

function SexboundDefeat:setIsDefeated(isDefeated)
	self._isDefeated = isDefeated
end

function SexboundDefeat:setIsTransformed(isTransformed)
	self._isTransformed = isTransformed
end

function SexboundDefeat:setTimer(value)
	self._timer = value
end

function SexboundDefeat:setTimeout(value)
	self._timeout = value
end

-- Misc. helper functions
function SexboundDefeat:_initTimeout()
	if self:isMonster() then
		self:setTimeout(util.randomInRange(self._config.defeatTimeoutMonster))
		return
	end
	if self:isNPC() then
		self:setTimeout(util.randomInRange(self._config.defeatTimeoutNPC))
		return
	end
	if self:isPlayer() then
		self:setTimeout(util.randomInRange(self._config.defeatTimeoutPlayer))
		return
	end
end

function SexboundDefeat:_isBoolean(value)
	return type(value) == "boolean"
end

function SexboundDefeat:_isPositiveNumberOrNumberRange(value)
	if type(value) == "number" and value > 0 then return true end
	if type(value) == "table" and #value == 2 then
		if type(value[1]) ~= "number" or value[1] <= 0 then return false end
		if type(value[2]) ~= "number" or value[2] <= 0 then return false end
		return true
	end
	return false
end

function SexboundDefeat:_logWarnInvalidValueProvided(optionName, value)
	local msg = "Invalid value was set for '" .. optionName .. "' option in " .. self._configFilePath .. " - "
	msg = msg .. "Falling back to use the default value: " .. sb.printJson(value)
	sb.logWarn(msg)
end

function SexboundDefeat:_validateConvertPregnantEnemiesToFriends(value, defaultValue)
	if self:_isBoolean(value) then return end
	self:_logWarnInvalidValueProvided("convertPregnantEnemiesToFriends", defaultValue)
	self._config.convertPregnantEnemiesToFriends = defaultValue
end

function SexboundDefeat:_validateDefeatedPlayersCanUseSexUI(value, defaultValue)
	if self:_isBoolean(value) then return end
	self:_logWarnInvalidValueProvided("defeatedPlayersCanUseSexUI", defaultValue)
	self._config.defeatedPlayersCanUseSexUI = defaultValue
end

function SexboundDefeat:_validateDefeatTimeoutMonster(value, defaultValue)
	if self:_isPositiveNumberOrNumberRange(value) then return end
	self:_logWarnInvalidValueProvided("defeatTimeoutMonster", defaultValue)
	self._config.defeatTimeoutMonster = defaultValue
end

function SexboundDefeat:_validateDefeatTimeoutNPC(value, defaultValue)
	if self:_isPositiveNumberOrNumberRange(value) then return end
	self:_logWarnInvalidValueProvided("defeatTimeoutNPC", defaultValue)
	self._config.defeatTimeoutNPC = defaultValue
end

function SexboundDefeat:_validateDefeatTimeoutPlayer(value, defaultValue)
	if self:_isPositiveNumberOrNumberRange(value) then return end
	self:_logWarnInvalidValueProvided("defeatTimeoutPlayer", defaultValue)
	self._config.defeatTimeoutPlayer = defaultValue
end

function SexboundDefeat:_validateEnableImmortalPregnantNPCs(value, defaultValue)
	if self:_isBoolean(value) then return end
	self:_logWarnInvalidValueProvided("enableImmortalPregnantNPCs", defaultValue)
	self._config.enableImmortalPregnantNPCs = defaultValue
end

function SexboundDefeat:_validateEnableStartDialogForNPCs(value, defaultValue)
	if self:_isBoolean(value) then return end
	self:_logWarnInvalidValueProvided("enableStartDialogForNPCs", defaultValue)
	self._config.enableStartDialogForNPCs = defaultValue
end

function SexboundDefeat:_validateEnableStartDialogForMonsters(value, defaultValue)
	if self:_isBoolean(value) then return end
	self:_logWarnInvalidValueProvided("enableStartDialogForMonsters", defaultValue)
	self._config.enableStartDialogForMonsters = defaultValue
end
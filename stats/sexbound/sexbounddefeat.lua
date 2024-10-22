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
		_sexNodeId         = nil,
		_hostileEntities   = {},
		_actorData		   = nil,
		_sexboundConfig    = nil
  }, SexboundDefeat_mt)

  	_self:setIsDefeated(false)

	-- Load the Sexbound Defeat config settings
	_self._config = _self:loadConfig()
	_self:validateConfig(_self._config)

	-- Initialize message handlers
	_self:initMessageHandlers()

	-- Set the default timeout as configured in the settings
	_self:_initTimeout()

	-- Set "Can use sexbound UI while defeated." state as a status for use with other scripts
	status.setStatusProperty("can_use_sex_ui_defeated", _self._config.defeatedPlayersCanUseSexUI)

	-- Enable canBeDefeated and canDefeatOthers on non-players. Additional conditions could be added.
	if _self.entityType ~= "player" then
		status.setStatusProperty("canBeDefeated", true)
		status.setStatusProperty("canDefeatOthers", true)
	end
	return _self
end

function SexboundDefeat:initMessageHandlers()
	message.setHandler("SexboundDefeat:Breakout", function(_,_,args)
		self._timer = self._timeout
	end)
	message.setHandler("SexboundDefeat:TargetedBy", function(_,_,entityId)
		-- Send hostile entity a message to add self to their hostile entity table
		if status.statusProperty("canDefeatOthers") then
			world.sendEntityMessage(entityId, "SexboundDefeat:InCombatWith", self._entityId)
		end
		local found = false
		for i, v in ipairs(self._hostileEntities) do
			if v[1] == entityId then found = true end
		end
		if not found then
			self:retrieveSexboundConfig(function(result)
				-- Run function that adds entity with their sexbound config into the hostile entity table
				return self:handleRetrieveSexboundConfigSuccess(result,entityId)
			end, function()
				return
			end,
			entityId)
		end
	end)
	-- Ends the hostile entity "handshake". Does same as "TargetedBy" but will not an additional message.
	message.setHandler("SexboundDefeat:InCombatWith", function(_,_,entityId)
		local found = false
		for i, v in ipairs(self._hostileEntities) do
			if v[1] == entityId then found = true end
		end
		if not found then
			self:retrieveSexboundConfig(function(result)
				return self:handleRetrieveSexboundConfigSuccess(result,entityId)
			end, function()
				return
			end,
			entityId)
		end
	end)
	-- Sets the entity's status to untransform at the earliers opportunity
	message.setHandler("SexboundDefeat:Untransform", function(_,_)
		self:setTimer(self._timeout - 3)
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
			status.removeEphemeralEffect("sexbound_defeat_stun")
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

	-- Handle the case where the entity doesn't have the status allowing being fucked after defeat.
	if not status.statusProperty("canBeDefeated") then
		self:tryToDie("entity does not have \"canBeDefeated\" status")
		return {}
	end

	-- Store a reference to the hostile entity id that delivered the killing blow to this entity
	local hostileEntityId   = damageRequest.sourceEntityId
	local hostileEntityType = nil
	if hostileEntityId ~= nil then
		hostileEntityType = world.entityType(hostileEntityId)
	end

	-- Handle the case that the entity has given itself a killing blow
	if self:isSuicide() then
		self:tryToDie("suicide")
		return {}
	end

	if self._entityId == "player" and hostileEntityType == "player" then
		world.sendEntityMessage(self._entityId, "SexboundDefeat:TargetedBy", hostileEntityId)
	end

	-- Prevent the entity from dying by ticking its health up by a percentage point
	status.setResourcePercentage("health", 0.01)

	-- Set this entity as isDefeated
	self:setIsDefeated(true)

	-- Reset the defeat timer to 0
	self:setTimer(0)

	-- Attempt to transform this entity into a sexnode
	self:retrieveActorData(hostileEntityId, hostileEntityType)

  return {}
end

function SexboundDefeat:retrieveActorData(damageSourceEntity, damageSourceEntityType)
	local entityId = self._entityId
	self._promises:add(
		world.sendEntityMessage(
			entityId,
			"Sexbound:Actor:GetActorData"
		),
		function(actorData)
			--find closest entity that's in the table
			local found = false
			local hostileEntityId = nil
			local sexboundConfig = nil
			local entities = world.entityQuery(entity.position(), 25, {includedTypes = {"monster","npc","player"}, order = "nearest"})
			for i,v in ipairs(entities) do
				for i2,v2 in ipairs(self._hostileEntities) do
					if v == v2[1] then
						found = true
						hostileEntityId = v2[1]
						sexboundConfig = v2[2]
						self._hostileEntityId = hostileEntityId
						self._hostileEntityType = world.entityType(self._hostileEntityId)
						break
					end
				end
				if found then break end
			end
			if hostileEntityId then
				--victory dialog, transform attempt
				self:outputVictoryDialog()
				self:transform(sexboundConfig,
					function(result)
						result = result or {}
						if result.uniqueId == nil then
							return self:handleTransformFailed()
						end
						return self:handleTransformSuccess(result.uniqueId)
					end, function()
						return self:handleTransformFailed()
					end,
					actorData
				)
			else
				self:tryToDie("Hostile entity not found in table")
			end
		end,
		function()
			self:tryToDie("Actor data retrieval failed")
		end)

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

function SexboundDefeat:retrieveSexboundConfig(successCallback, failureCallback, entityId)
	self._promises:add(
		world.sendEntityMessage(
			entityId,
			"Sexbound:Config:Retrieve"
		),
		successCallback,
		failureCallback
	)
end

function SexboundDefeat:handleRetrieveSexboundConfigSuccess(sexboundConfig, hostileEntityId)
	table.insert(self._hostileEntities, 1, {hostileEntityId, sexboundConfig})

	if #self._hostileEntities > 8 then
		table.remove(self._hostileEntities)
	end
	--[[ Output the victory dialog
	self:outputVictoryDialog()
	self:transform(sexboundConfig, function(result)
		result = result or {}
		if result.uniqueId == nil then
			return self:handleTransformFailed()
		end
		return self:handleTransformSuccess(result.uniqueId)
	end, function()
		return self:handleTransformFailed()
	end,
	self._actorData
	)
	]]
end


function SexboundDefeat:transform(sexboundConfig, successCallback, failureCallback, actorData)
	local position = nil
	local entityId = self._entityId
	if self:isPlayer() then
		position = entity.position()
		entityId = self._hostileEntityId
	end
	self._promises:add(
		world.sendEntityMessage(
			entityId,
			"Sexbound:Transform",
			{
				responseRequired = true,
				sexboundConfig = sexboundConfig,
				timeout = 500,
				position = position
			},
			actorData or nil
		),
		successCallback,
		failureCallback
	)
end

function SexboundDefeat:handleTransformFailed()
	self:tryToDie("Transform failed")
	return false
end

function SexboundDefeat:handleTransformSuccess(nodeUniqueId)
	self._sexNodeId = nodeUniqueId
	self:setIsTransformed(true)
	self:setTimer(0)
	self:outputDefeatedDialog()
	self:_initTimeout()
	if self:isPlayer() then
		-- Check config for using invisible "UI" that allows escape with ESC key
		if self._config.enableDefeatedPlayerEscape then world.sendEntityMessage(self._entityId, "Sexbound:UI:Show", {config = self:loadUIConfig()}) end
		status.addEphemeralEffect("dontstarve",    self._timeout)
		status.addEphemeralEffect("sexbound_regen4", self._timeout)
	end

	status.addEphemeralEffect("sexbound_sex",  self._timeout)
	status.addEphemeralEffect("sexbound_defeat_stun", self._timeout)

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

function SexboundDefeat:tryToDie(reason)
  --if reason then sb.logInfo("Sexbound Defeat Death: Name="..world.entityName(self._entityId).." reason: "..reason) end
  self:setIsDefeated(false)
  self:setIsTransformed(false)
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
	if not self:isPlayer() then self:tryToDie("non-player untransform") end
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
	status.removeEphemeralEffect("sexbound_regen4")
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
	self:_validateEnableDefeatedPlayerEscape(self._config.enableDefeatedPlayerEscape, false)
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
	return self._isDefeated or status.statusProperty("sexbound_defeated")
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
	return status.statusProperty("sexbound_defeat_stun")
end

function SexboundDefeat:isSuicide()
	return self._hostileEntityId == self._entityId
end

function SexboundDefeat:isTransformed()
	return self._isTransformed or false
end

function SexboundDefeat:setIsDefeated(isDefeated)
	self._isDefeated = isDefeated
	status.setStatusProperty("sexbound_defeated", isDefeated)
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

function SexboundDefeat:_validateEnableDefeatedPlayerEscape(value, defaultValue)
	if self:_isBoolean(value) then return end
	self:_logWarnInvalidValueProvided("enableDefeatedPlayerEscape", defaultValue)
	self._config.enableDefeatedPlayerEscape = defaultValue
end
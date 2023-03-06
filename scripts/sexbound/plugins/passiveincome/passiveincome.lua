--- Sexbound.Actor.PassiveIncome Class Module.
-- @classmod Sexbound.Actor.PassiveIncome
-- @author Locuturus
-- @license GNU General Public License v3.0
if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
  require("/scripts/util.lua")
end

Sexbound.Actor.PassiveIncome = Sexbound.Actor.Plugin:new()
Sexbound.Actor.PassiveIncome_mt = { __index = Sexbound.Actor.PassiveIncome }

--- Instantiates a new instance of PassiveIncome.
-- @param parent
-- @param config
function Sexbound.Actor.PassiveIncome:new(parent, config)
  local _self = setmetatable({
      _logPrefix = "PASS",
      _config    = config,
      _timers    = { default = 0  },
      _cooldowns = { default = 15 }
  }, Sexbound.Actor.PassiveIncome_mt)

  _self:init(parent, _self._logPrefix)
  _self:validateConfig()

  return _self
end

--- Handles messages sent to this instance
function Sexbound.Actor.PassiveIncome:onMessage(message)
  -- Placeholder
end

--- Updates this instance
-- @param dt
function Sexbound.Actor.PassiveIncome:onUpdateSexState(dt)
  self:addToTimer("default", dt)
  if self:getTimer("default") >= self:getCooldown("default") then
    self:rewardCurrency()
    self:resetTimer("default")
    self:resetCooldown("default")
  end
end

--- Rewards currency randomly as configured in the config file
function Sexbound.Actor.PassiveIncome:rewardCurrency()
  world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Reward:Currency", {
    currencyName = util.randomChoice(self:getRewardCurrency()),
    amount = util.randomIntInRange(self:getRewardAmount())
  })
end

--- Returns the current value of a specified cooldown
-- @param name
-- @return a number value
function Sexbound.Actor.PassiveIncome:getCooldown(name)
  name = name or "default"
  return self._cooldowns[name]
end

--- Adds a specified amount to a specified timer
-- @param name
-- @param amount
function Sexbound.Actor.PassiveIncome:addToTimer(name, amount)
  name = name or "default"
  self._timers[name] = self._timers[name] + amount
end

--- Returns the configured reward amount
-- @return a table of numbers
function Sexbound.Actor.PassiveIncome:getRewardAmount()
  return self._config.rewardAmount
end

--- Returns the configured reward cooldown
-- @return a table of numbers
function Sexbound.Actor.PassiveIncome:getRewardCooldown()
  return self._config.rewardCooldown
end

--- Returns the configured reward currency
-- @return a table of strings
function Sexbound.Actor.PassiveIncome:getRewardCurrency()
  return self._config.rewardCurrency
end

--- Returns the current value of a specified timer
-- @param name
-- @return a number value
function Sexbound.Actor.PassiveIncome:getTimer(name)
  name = name or "default"
  return self._timers[name]
end

--- Resets a specified cooldown
-- @param name
function Sexbound.Actor.PassiveIncome:resetCooldown(name)
  name = name or "default"
  self._cooldowns[name] = util.randomInRange(self:getRewardCooldown())
end

--- Resets a specified timer
-- @param name
function Sexbound.Actor.PassiveIncome:resetTimer(name)
  name = name or "default"
  self._timers[name] = 0
end

--- Validates the loaded config and sets missing config options to be default values.
function Sexbound.Actor.PassiveIncome:validateConfig()
  self:validateRewardAmount(self._config.rewardAmount,     {3,     3})
  self:validateRewardCooldown(self._config.rewardCooldown, {15,   15})
  self:validateRewardCurrency(self._config.rewardCurrency, {"sexbux"})
end

function Sexbound.Actor.PassiveIncome:validateRewardAmount(value, default)
  if type(value) == "number" then
    self._config.rewardAmount = { [1] = value, [2] = value }
    return
  end
  if type(value) ~= "table" or (type(value) == "table" and #value ~= 2) then
    self._config.rewardAmount = default
    return
  end
end

function Sexbound.Actor.PassiveIncome:validateRewardCooldown(value, default)
  if type(value) == "number" then
    self._config.rewardCooldown = { [1] = value, [2] = value }
    return
  end
  if type(value) ~= "table" or (type(value) == "table" and #value ~= 2) then
    self._config.rewardCooldown = default
    return
  end
end

function Sexbound.Actor.PassiveIncome:validateRewardCurrency(value, default)
  if type(value) == "string" then
    self._config.rewardCurrency = { [1] = value, [2] = value }
    return
  end
  if type(value) ~= "table" then
    self._config.rewardCooldown = default
    return
  end
end
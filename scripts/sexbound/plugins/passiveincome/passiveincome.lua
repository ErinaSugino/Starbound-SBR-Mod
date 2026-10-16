if not SXB_RUN_TESTS then
  require("/scripts/sexbound/lib/sexbound/actor/plugin.lua")
  require("/scripts/util.lua")
end

--- Sexbound.Actor.PassiveIncome Class Module.
--- @class Sexbound.Actor.PassiveIncome: Sexbound.Actor.Plugin
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _timers table<string, number>
--- @field _cooldowns table<string, number>
Sexbound.Actor.PassiveIncome = Sexbound.Actor.Plugin:new()
Sexbound.Actor.PassiveIncome_mt = { __index = Sexbound.Actor.PassiveIncome }

--- Instantiates a new instance of PassiveIncome.
--- @param parent Sexbound.Actor The calling parent actor instance
--- @param config table The plugin's config
--- @return Sexbound.Actor.PassiveIncome # The new passive income plugin instance
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

--- Function called each tick to progress timers
--- @param dt number The delta time since last tick
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
--- @param name string? The cooldown name
--- @return number # The reamining time on that cooldown
function Sexbound.Actor.PassiveIncome:getCooldown(name)
  name = name or "default"
  return self._cooldowns[name] or 0
end

--- Adds a specified amount to a specified timer
--- @param name string? The timer name
--- @param amount number The time to add
function Sexbound.Actor.PassiveIncome:addToTimer(name, amount)
  name = name or "default"
  self._timers[name] = (self._timers[name] or 0) + amount
end

--- Returns the configured reward amount range
--- @return table<integer, integer> # The defined reward range
function Sexbound.Actor.PassiveIncome:getRewardAmount()
  return self._config.rewardAmount
end

--- Returns the configured reward cooldown range
--- @return table<integer, integer> # The defined cooldown range
function Sexbound.Actor.PassiveIncome:getRewardCooldown()
  return self._config.rewardCooldown
end

--- Returns the configured reward currency
--- @return table<integer, string> # The list of defined reward currencies
function Sexbound.Actor.PassiveIncome:getRewardCurrency()
  return self._config.rewardCurrency
end

--- Returns the current value of a specified timer
--- @param name string? The timer name
--- @return number # The current time on the timer
function Sexbound.Actor.PassiveIncome:getTimer(name)
  name = name or "default"
  return self._timers[name] or 0
end

--- Resets a specified cooldown
--- @param name string? The cooldown name
function Sexbound.Actor.PassiveIncome:resetCooldown(name)
  name = name or "default"
  self._cooldowns[name] = util.randomInRange(self:getRewardCooldown())
end

--- Resets a specified timer
--- @param name string? The timer name
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

--- Validates the config defined reward amount range
--- @param value any The defined value
--- @param default any The default value
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

--- Validates the config set reward cooldown range
--- @param value any The defined value
--- @param default any The default value
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

--- Validates the config set list of reward currencies
--- @param value any The defined value
--- @param default any The default value
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
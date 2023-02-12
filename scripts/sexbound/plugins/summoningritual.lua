--- Sexbound.Actor.SummoningRitual Class Module.
-- @classmod Sexbound.Actor.SummoningRitual
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound/actor/plugin.lua"
require "/scripts/util.lua"

Sexbound.Actor.SummoningRitual = Sexbound.Actor.Plugin:new()
Sexbound.Actor.SummoningRitual_mt = { __index = Sexbound.Actor.SummoningRitual } 

--- Instantiates a new instance of SummoningRitual.
-- @param parent
-- @param config
function Sexbound.Actor.SummoningRitual:new( parent, config )
  local self = setmetatable({
    _logPrefix = "SUMN",
    _config = config,
    _timer = 0,
    _currentTimeline = nil,
    _isComplete = false
  }, Sexbound.Actor.SummoningRitual_mt)

  self:init(parent, self._logPrefix)
  
  self:refreshEventTimeline()
  
  return self
end

function Sexbound.Actor.SummoningRitual:refreshEventTimeline()
  self._currentTimeline = self._config.eventTimeline
  
  self._nextIndex = 1
  
  self._nextEvent = self._currentTimeline[self._nextIndex]
end

function Sexbound.Actor.SummoningRitual:onMessage(message)
  if "Sexbound:Positions:SwitchPosition" == message:getType() then self:refreshMouthPosition() end
  if "Sexbound:SwitchRoles"              == message:getType() then self:refreshMouthPosition() end
end

function Sexbound.Actor.SummoningRitual:onEnterClimaxState()
  local dialog, pregnant = self._config.dialog, self:getParent():getPlugins("pregnant")
  
  -- This guarantees that the NPC will be impregnated.
  if pregnant then pregnant._config.fertility = 1.0 end

  local otherActor  = self:getOtherActor()
  local isOtherClimaxing = otherActor:status():hasStatus("climaxing")
  local otherGender = otherActor:getGenitalType()
  
  if isOtherClimaxing then
    if otherGender == "male" and self:getPosition():getConfig().possiblePregnancy[self:getParent():getActorNumber()] then
      Sexbound.Messenger.get("main"):send(self, emote, "Sexbound:Emote:ChangeEmote", "cry")
      
      self:helper_sayDialog(dialog.otherClimaxMale, false)
      
      storage.isPregnant = true
    else
      self:helper_sayDialog(dialog.otherClimaxFemale, true)
    end
  else
    self:helper_sayDialog(dialog.climax, true)
  end
end

--- Returns reference to targeted other actor.
function Sexbound.Actor.SummoningRitual:getOtherActor()
  for _,actor in pairs(self:getParent():getParent():getActors()) do
    if actor:getRole() ~= self:getParent():getRole() then return actor end
  end
end

function Sexbound.Actor.SummoningRitual:onEnterSexState()
  local climax = self:getParent():getPlugins("climax")
  
  if climax then
    climax:getConfig().enableNPCAutoClimax = false
  end
end

function Sexbound.Actor.SummoningRitual:onUpdateSexState(dt)
  self._timer = self._timer + dt

  if self._isComplete then 
    if not self._isFinished and self._timer >= 5 then
      self._isFinished = true
    
      object.setInteractive(false)

      world.sendEntityMessage(entity.id(), "summon")
      
      world.sendEntityMessage(self:getParent():getEntityId(), "Sexbound:Arousal:Min")
    end
    
    return
  end

  if self._timer >= self._nextEvent.startTime then
    self[self._nextEvent.action](self, self._nextEvent.args)
    
    self._nextIndex = math.min(self._nextIndex + 1, #self._currentTimeline)
    
    self._nextEvent = self._currentTimeline[self._nextIndex]
  end
end

function Sexbound.Actor.SummoningRitual:checkPosition(args)
  if args[1] == self:getPosition():getName() then
    self:helper_sayDialog(args[2] or "Greattt!", true)
  else
    self:helper_sayDialog(args[3] or "Fail.", true)
    self:reset()
  end
end

function Sexbound.Actor.SummoningRitual:complete(args)
  self._isComplete = true

  storage.summoningComplete = true
  
  self._timer = 0
end

function Sexbound.Actor.SummoningRitual:sayDialog(args)
  self:helper_sayDialog(args[1], true)
end

function Sexbound.Actor.SummoningRitual:helper_sayDialog(dialog, showBlabber)
  if showBlabber then Sexbound.Messenger.get("main"):send(self, emote, "Sexbound:Emote:ChangeEmote", "blabber") end

  self:refreshMouthPosition()
  
  object.say(dialog)
end

function Sexbound.Actor.SummoningRitual:reset()
  self._timer = 0
  self._nextIndex = 1
end

-- Getters / Setters

function Sexbound.Actor.SummoningRitual:getPosition() return self:getParent():getPosition() end

function Sexbound.Actor.SummoningRitual:refreshMouthPosition()
  if self:getParent().resetMouthOffset ~= nil then
    self:setMouthPosition(self:getParent():resetMouthOffset())
  end
end

function Sexbound.Actor.SummoningRitual:setMouthPosition(position)
  self._mouthPosition = position or {0, 0}
  
  if object then object.setConfigParameter("mouthPosition", self._mouthPosition) end
end
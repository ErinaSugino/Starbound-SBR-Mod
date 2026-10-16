--- Sexbound.Actor.Head Class Module.
--- @class Sexbound.Actor.Head
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _rotation integer
--- @field _rotationLowerLimit integer
--- @field _rotationUpperLimit integer
--- @field _speedMultiplier number
--- @field _halfRotationLowerLimit number
--- @field _halfRotationUpperLimit number
--- @field _enableHeadBangingPhysics boolean
Sexbound.Actor.Head = {}
Sexbound.Actor.Head_mt = {
    __index = Sexbound.Actor.Head
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor The calling parent actor instance
--- @return Sexbound.Actor.Head # The new instance
function Sexbound.Actor.Head.new(parent)
    local self = setmetatable({
        _parent = parent,
        _rotation = 0,
        _rotationLowerLimit = -15,
        _rotationUpperLimit = 15,
        _speedMultiplier = 0
    }, Sexbound.Actor.Head_mt)
    self:resetRotationDirection()
    self._halfRotationLowerLimit = self._rotationLowerLimit / 2
    self._halfRotationUpperLimit = self._rotationUpperLimit / 2
    self._enableHeadBangingPhysics = self:getParent():getParent():getConfig().sex.enableHeadBangingPhysics
    return self
end

--- Function called every tick while in sex state
--- @param dt number The delta time since last tick
function Sexbound.Actor.Head:onUpdateSexState(dt)
  self:adjustHeadRotation(dt)
end

--- Updates the head rotation each tick
function Sexbound.Actor.Head:adjustHeadRotation(_)
  if not self._enableHeadBangingPhysics then return end
  if self._speedMultiplier == 0 then return end
  local animationRate = self:getParent():getParent():getAnimationRate()
  local angle = math.ceil(self._rotationDirection * (animationRate * self._speedMultiplier))
  angle = util.clamp(angle, self._halfRotationLowerLimit, self._halfRotationUpperLimit)
  if self._rotation + angle <= self._rotationLowerLimit then
      self._rotationDirection = 1
      return
  end
  if self._rotation + angle >= self._rotationUpperLimit then
      self._rotationDirection = -1
      return
  end
  self._rotation = self._rotation + angle
  self:getParent():rotatePart("Head", angle)
end

--- Returns the parent instance
--- @return Sexbound.Actor # The parent instance
function Sexbound.Actor.Head:getParent()
  return self._parent
end

--- Resets the head rotation
function Sexbound.Actor.Head:resetRotationDirection()
  self._rotationDirection = 1
end

--- Sets the rotation speed multiplier
--- @param speedMultiplier number The newe rotation speed multiplier
function Sexbound.Actor.Head:setSpeedMultiplier(speedMultiplier)
  self._speedMultiplier = speedMultiplier
end
--- Sexbound.Actor.Head Class Module.
-- @classmod Sexbound.Actor.Head
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor.Head = {}
Sexbound.Actor.Head_mt = {
    __index = Sexbound.Actor.Head
}

--- Returns a reference to a new instance of this class.
-- @param parent
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

--- Updates this instance
-- @param dt
function Sexbound.Actor.Head:onUpdateSexState(dt)
  self:adjustHeadRotation(dt)
end

function Sexbound.Actor.Head:adjustHeadRotation()
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

function Sexbound.Actor.Head:getParent()
  return self._parent
end

function Sexbound.Actor.Head:resetRotationDirection()
  self._rotationDirection = 1
end

function Sexbound.Actor.Head:setSpeedMultiplier(speedMultiplier)
  self._speedMultiplier = speedMultiplier
end
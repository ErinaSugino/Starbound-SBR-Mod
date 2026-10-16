--- Sexbound.Actor.Mouth Class Module.
--- @class Sexbound.Actor.Mouth
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _position table<integer, number>
Sexbound.Actor.Mouth = {}
Sexbound.Actor.Mouth_mt = {
    __index = Sexbound.Actor.Mouth
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor The calling parent actor instance
--- @return Sexbound.Actor.Mouth # The new instance
function Sexbound.Actor.Mouth:new(parent)
    return setmetatable({
        _parent = parent,
        _position = {0, 0}
    }, Sexbound.Actor.Mouth_mt)
end

--- Function called each tick to update this instance
--- @param dt number The delta time since last tick
function Sexbound.Actor.Mouth:update(dt)
    self:recalculatePosition()
end

--- Applies the intended speech bubble position to the actual object
function Sexbound.Actor.Mouth:applyPosition()
    if object == nil then
        return
    end
    object.setConfigParameter("mouthPosition", self._position)
end

--- Recalculates the intended speech bubble position
function Sexbound.Actor.Mouth:recalculatePosition()
    if self:getParent():getParent():getAnimationPartsCentered() ~= true then
        self._position = {0, 3}
        return
    end

    local offset = animator.partPoint(self:getParent():getRole() .. "-mouth", "offset")
    offset = vec2.add(offset, self:getPositionOffset())

    self._position = {0, 0}
    self._position = vec2.add(self._position, offset)
    self._position = vec2.mul(self._position, {self:getParent():getFacingDirection(), 1})
end

--- Retreive mouth offset vector as set in a position config file.
--- @return Vec2F # Mouth position offset from top left
function Sexbound.Actor.Mouth:getPositionOffset()
    local actorNumber = self:getParent():getActorNumber()
    return self._parent:getAnimationState():getMouthOffset(actorNumber)
end

--- Returns a reference to this instance's parent object
--- @return Sexbound.Actor # Parent actor instance
function Sexbound.Actor.Mouth:getParent()
    return self._parent
end

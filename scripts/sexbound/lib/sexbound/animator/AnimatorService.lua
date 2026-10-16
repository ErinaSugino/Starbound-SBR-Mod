--- Animator access wrapper class
--- @class Sexbound.AnimatorService
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _animator table
Sexbound.AnimatorService = {}
Sexbound.AnimatorService_mt = {
    __index = Sexbound.AnimatorService
}

--- Creates new wrapper instance for a given or the default animator
--- @param customAnimator ?table The animator to wrap. If none given, takes global "animator"
--- @return Sexbound.AnimatorService # The new wrapper instance
function Sexbound.AnimatorService:new(customAnimator)
    return setmetatable({
        _animator = customAnimator or animator
    }, Sexbound.AnimatorService_mt)
end

--- Sets the animation rate of the underlying animator
--- @param rate number The new rate to set
function Sexbound.AnimatorService:setAnimationRate(rate)
    self._animator.setAnimationRate(rate)
end

--- Returns the animation state running on the underlying animator
--- @param stateType string The state type group to check
function Sexbound.AnimatorService:getAnimationState(stateType)
    self._animator.animationState(stateType)
end

--- Set the animation state of the underlying animator
--- @param stateType string The name of the state type group to set it on
--- @param state string The name of the state to set on the type group
--- @param startNew boolean Whethere or not to reset the animation to frame 1 even if it's the same state as is already running
function Sexbound.AnimatorService:setAnimationState(stateType, state, startNew)
    self._animator.setAnimationState(stateType, state, startNew)
end

--- Sets the underlying animator as flipped
--- @param flipped boolean Flip?
function Sexbound.AnimatorService:setFlipped(flipped)
    self._animator.setFlipped(flipped)
end

--- Sets a global animator tag on the underlying animator
--- @param tagName string The name of the global tag
--- @param tagValue string The value to set on it
function Sexbound.AnimatorService:setGlobalTag(tagName, tagValue)
    self._animator.setGlobalTag(tagName, tagValue)
end

--- Sets a part-specific animator tag on the underlying animator
--- @param partType string The part name on which to set
--- @param tagName string The name of the tag
--- @param tagValue string The value to set
function Sexbound.AnimatorService:setPartTag(partType, tagName, tagValue)
    self._animator.setPartTag(partType, tagName, tagValue)
end

--- Returns whethere or not there is a transformation group with the requested name
--- @param transformationGroup string The name to check for
function Sexbound.AnimatorService:hasTransformationGroup(transformationGroup)
    self._animator.hasTransformationGroup(transformationGroup)
end

--- Resets the given transformation group on the underlying animator
--- @param transformationGroup string Name of the transformation group to reset
function Sexbound.AnimatorService:resetTransformationGroup(transformationGroup)
    self._animator.resetTransformationGroup(transformationGroup)
end

--- Rotates a given transformation group on the underlying animator
--- @param transformationGroup string The name of the transformation group
--- @param rotation number The target rotation (in degrees?)
--- @param rotationCenter Vec2F X and Y coordinate as to where the rotation axle is offset from top left
function Sexbound.AnimatorService:rotateTransformationGroup(transformationGroup, rotation, rotationCenter)
    self._animator.rotateTransformationGroup(transformationGroup, rotation, rotationCenter)
end

--- Scales a given transformation group on the underlying animator
--- @param transformationGroup string The name of the transformation group
--- @param scale number The scale factor. 1 is normal size
--- @param scaleCenter Vec2F X and Y coordinate as to where the scale origin is offset from top left
function Sexbound.AnimatorService:scaleTransformationGroup(transformationGroup, scale, scaleCenter)
    self._animator.scaleTransformationGroup(transformationGroup, scale, scaleCenter)
end

--- Moves a given transformation group on the underlying animator
--- @param transformationGroup string The name of the transformation group
--- @param translation Vec2F X and Y coordinate as to how to offset the group from its origin
function Sexbound.AnimatorService:translateTransformationGroup(transformationGroup, translation)
    self._animator.translateTransformationGroup(transformationGroup, translation)
end

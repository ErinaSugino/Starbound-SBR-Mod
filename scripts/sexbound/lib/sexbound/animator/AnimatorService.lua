Sexbound.AnimatorService = {}
Sexbound.AnimatorService_mt = {
    __index = Sexbound.AnimatorService
}

function Sexbound.AnimatorService:new(customAnimator)
    return setmetatable({
        _animator = customAnimator or animator
    }, Sexbound.AnimatorService_mt)
end

function Sexbound.AnimatorService:setAnimationRate(rate)
    self._animator.setAnimationRate(rate)
end

function Sexbound.AnimatorService:getAnimationState(stateType)
    self._animator.animationState(stateType)
end

function Sexbound.AnimatorService:setAnimationState(stateType, state, startNew)
    self._animator.setAnimationState(stateType, state, startNew)
end

function Sexbound.AnimatorService:setFlipped(flipped)
    self._animator.setFlipped(flipped)
end

function Sexbound.AnimatorService:setGlobalTag(tagName, tagValue)
    self._animator.setGlobalTag(tagName, tagValue)
end

function Sexbound.AnimatorService:setPartTag(partType, tagName, tagValue)
    self._animator.setPartTag(partType, tagName, tagValue)
end

function Sexbound.AnimatorService:hasTransformationGroup(transformationGroup)
    self._animator.hasTransformationGroup(transformationGroup)
end

function Sexbound.AnimatorService:resetTransformationGroup(transformationGroup)
    self._animator.resetTransformationGroup(transformationGroup)
end

function Sexbound.AnimatorService:rotateTransformationGroup(transformationGroup, rotation, rotationCenter)
    self._animator.rotateTransformationGroup(transformationGroup, rotation, rotationCenter)
end

function Sexbound.AnimatorService:scaleTransformationGroup(transformationGroup, scale, scaleCenter)
    self._animator.scaleTransformationGroup(transformationGroup, scale, scaleCenter)
end

function Sexbound.AnimatorService:translateTransformationGroup(transformationGroup, translation)
    self._animator.translateTransformationGroup(transformationGroup, translation)
end

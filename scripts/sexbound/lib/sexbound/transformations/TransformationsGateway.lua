if not SXB_RUN_TESTS then
    require("/scripts/sexbound/lib/sexbound/animator/AnimatorService.lua")
end

Sexbound.TransformationsGateway = {}
Sexbound.TransformationsGateway_mt = {
    __index = Sexbound.TransformationsGateway
}

function Sexbound.TransformationsGateway:new(animatorService)
    return setmetatable({
        _animatorService = animatorService or Sexbound.AnimatorService:new()
    }, Sexbound.TransformationsGateway_mt)
end

function Sexbound.TransformationsGateway:adjustActorsPosition(translation)
    self._animatorService:translateTransformationGroup("actors", translation)
end

function Sexbound.TransformationsGateway:adjustActorsRotation(rotation, rotationCenter)
    self._animatorService:rotateTransformationGroup("actors", rotation, rotationCenter)
end

function Sexbound.TransformationsGateway:adjustActorsScale(scale, scaleCenter)
    self._animatorService:scaleTransformationGroup("actors", scale, scaleCenter)
end

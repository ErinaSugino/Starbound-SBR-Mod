local function matchDirection()
  if mcontroller.facingDirection() ~= -1 then return end
  self.effectDirectives = self.effectDirectives .. "?flipx;"
end

function init()
  self.effectDirectives = ""
  animator.setAnimationState("changegender", "futanari")
  world.sendEntityMessage(entity.id(), "Sexbound:SubGender:Change", "futanari")
  world.sendEntityMessage(entity.id(), "Sexbound:SubGender:Change", "cuntboy")
end

function update()
  self.effectDirectives = ""
  matchDirection()
  animator.setGlobalTag("effectDirectives", self.effectDirectives)
end

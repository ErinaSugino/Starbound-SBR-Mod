function init()
  local soundEffect = effect.getParameter("soundEffects", "/sfx/sexbound/success.ogg")
  if animator.hasSound("transform") then
    animator.setSoundPool("transform", soundEffect)
    animator.playSound("transform")
  end
  animator.burstParticleEmitter("transform")
end
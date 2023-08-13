function init()

end


function uninit()
  world.sendEntityMessage(entity.id(), "Sexbound:Pregnant:GiveBirth", 1)
  effect.expire()
end
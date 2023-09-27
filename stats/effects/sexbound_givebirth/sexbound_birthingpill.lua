function init()

end


function uninit()
  world.sendEntityMessage(entity.id(), "Sexbound:Pregnant:BirthingPill", 1)
  effect.expire()
end
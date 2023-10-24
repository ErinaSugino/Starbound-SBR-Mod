require("/quests/scripts/generated/common.lua")

function onInit()
  message.setHandler("Sexbound:Quest:HaveSex", handleHaveSex)
end

function handleHaveSex(_,_,args)
  objective("have_sex"):complete()
end

function conditionsMet()
  return allObjectivesComplete()
end

function onUpdate(dt)
  
end

function questStart()
  notifyNpc("questGiver", "sexbound.transform")
end

function questComplete()

end
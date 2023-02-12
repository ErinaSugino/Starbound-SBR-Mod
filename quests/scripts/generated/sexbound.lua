require("/quests/scripts/generated/common.lua")

local function handleHaveSex(_,_,args)
  objective("have_sex"):complete()
end

function onInit()
  message.setHandler("Sexbound:Quest:HaveSex", handleHaveSex)
end

function conditionsMet()
  return allObjectivesComplete()
end

function onUpdate()

end

function questStart()
  notifyNpc("questGiver", "sexbound.transform")
end

function questComplete()

end
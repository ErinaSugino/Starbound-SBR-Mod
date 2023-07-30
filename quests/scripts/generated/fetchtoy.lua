require("/quests/scripts/generated/common.lua")

function onQuestStart()
  local giveItems = config.getParameter("giveItems")
  if giveItems then
    local items = quest.parameters()[giveItems].items
    for _,item in ipairs(items) do
      player.giveItem(item)
    end
  end
  
  bruhStorage = false
  
  -- If this is a crafting / cooking quest, give the player the necessary
  -- blueprints.
  if quest.parameters().recipes then
    for _,item in ipairs(quest.parameters().recipes.items) do
      player.giveBlueprint(item)
    end
  end

  local fetchList = config.getParameter("fetchList")
  if fetchList then
    setIndicators({fetchList})
  else
    setIndicators({})
  end
end

FetchObjective = {}
FetchObjective.__index = FetchObjective
setmetatable(FetchObjective, Objective)

function FetchObjective:init(textGenerator, item)
  Objective.init(self, textGenerator, { id = "fetch-"..item.name })
  self.item = item
  self._text = root.assetJson("/quests/quests.config:objectiveDescriptions.fetch")
end

function FetchObjective:currentCount()
  return player.hasCountOfItem(self.item.name)
end

function FetchObjective:text()
  return sb.replaceTags(self._text, {
      itemName = itemShortDescription(self.item),
      required = self.item.count,
      current = self:currentCount()
    })
end

function FetchObjective:isComplete()
  return player.hasItem(self.item)
  if ((player.hasItem(self.item)) and (bruhStorage = false)) then
	bruhStorage = true
	player.consumeItem(self.item)
  end
  return bruhStorage
end

function onInit()
  local textGenerator = currentQuestTextGenerator()
  for _,item in ipairs(fetchList()) do
    addObjective(FetchObjective:new(textGenerator, item))
  end
  addObjective(Objective:new(textGenerator, {
      id = "return",
      text = root.assetJson("/quests/quests.config:objectiveDescriptions.return")
    }))
end

function fetchList()
  local paramName = config.getParameter("fetchList")
  if not paramName then return true end
  return quest.parameters()[paramName].items or {}
end

function conditionsMet()
  return allObjectivesComplete()
end

if SXB_RUN_TESTS ~= true then
  require "/scripts/util.lua"
  require "/scripts/messageutil.lua"
  require "/scripts/sexbound/util.lua"
end

local PregnancyTest = {}
local PregnancyTest_mt = { __index = PregnancyTest }

function PregnancyTest:new()
  return setmetatable({
    entityId = activeItem.ownerEntityId(),
    animTimer = 0,
    toConsume = 0
  }, PregnancyTest_mt)
end

function PregnancyTest:update(dt)
  promises:update()
  if self.toConsume == 1 then
    self.animTimer = self.animTimer + dt
    if self.animTimer >= 1 then self.toConsume = 0 self.animTimer = 0 item.consume(1) end
  end
end

function PregnancyTest:activate(fireMode, shiftHeld)
  if self.toConsume == 1 then return false end -- If toConsume is 1, the test was used and is on "cooldown", just waiting for the animation to finish before removing item
  promises:add(
    world.sendEntityMessage(self.entityId, "Sexbound:Pregnant:GetDataAndConfig"),
    function(data)
      local pregnancies = data.pregnancies or {}
      local config = data.config or {}
      return self:handlePregnancyData(pregnancies, config)
    end
  )
end

function PregnancyTest:handlePregnancyData(pregnancies, config)
  if not self:validatePregnanciesIsTable(pregnancies)
  or not self:thisEntityHasAtLeastOnePregnancy(pregnancies)
  then self:notifyThisEntityTheyAreNotPregnant()
  else self:notifyThisEntityTheyArePregnant(pregnancies, config) end
  if not config.legacyInfinitePregnancyTest then self.toConsume = 1 end
end

function PregnancyTest:buildTimingMeridian(hour)
  if hour <= 12 then return "AM" else return "PM" end
end

function PregnancyTest:buildFormattedBirthTimeString(hour, minutes, meridian)
  --local meridian = self:buildTimingMeridian(hour)
  local time = string.format("%s:%s %s", hour, minutes, meridian)
  return "^red;" .. time .. "^reset;"
end

function PregnancyTest:buildBirthTimeBasedOnOSTime(birthOSTime)
  if birthOSTime == nil then return "" end
  local birthDateTimestamp = math.floor(birthOSTime + 0) -- convert to number
  local todayDateTimestamp = os.time()
  local diffTime = math.max(0, os.difftime(birthDateTimestamp, todayDateTimestamp))

  if (diffTime <= 86400) then
    local totalMinutes = diffTime / 60
    local hours   = math.floor(totalMinutes / 60)
    hours = "^red;" .. hours .. "^reset;"

    local minutes = math.floor(totalMinutes % 60)
    minutes = "^red;" .. minutes .. "^reset;"

    local text = config.getParameter("radioMessages.birthTodayBasedOnOSTime")
    text = util.replaceTag(text, "hours", hours)
    text = util.replaceTag(text, "minutes", minutes)
    --text = text .. " - or - "
    return text
  else
    local days = math.floor((birthDateTimestamp - todayDateTimestamp) / 86400)
    days = "^red;" .. days .. "^reset;"
    local text = config.getParameter("radioMessages.birthLaterBasedOnOSTime")
    text = util.replaceTag(text, "days", days)
    --text = text .. " - or - "
    return text
  end
end

function PregnancyTest:buildBirthTimeBasedOnWorldTime(birthTime)
  local days = math.floor(birthTime)

  birthTime = birthTime - days

  days = math.max(0, days - world.day())

  local hours = birthTime
  hours = math.floor(24 * hours)

  -- local meridian = self:buildTimingMeridian(hours)
  local minutes = math.floor(60 * (24 * birthTime - hours))
  if minutes <= 9 then minutes = minutes .. '0' end

  local appendix = 'AM'
  if hours > 12 then
    hours = hours - 12
    appendix = 'PM'
  end

  local time = self:buildFormattedBirthTimeString(hours, minutes, appendix)

  if days > 0 then
    local text = config.getParameter("radioMessages.birthLaterBasedOnWorldTime")
    days = "^red;" .. days .. "^reset;"
    text = util.replaceTag(text, "days", days)
    return text
  else
    local text = config.getParameter("radioMessages.birthTodayBasedOnWorldTime")
    text = util.replaceTag(text, "time", time)
    return text
  end
end

function PregnancyTest:buildBirthTimeBasedOnPlayerWorldTime(birthTime)
  local dayLength = world.dayLength()
  local days = math.floor(birthTime / dayLength)
  
  -- subtract full days to have remainder
  birthTime = birthTime - (days * dayLength)
  -- turn remainder into percentage 0-1
  if birthTime > 0 then birthTime = dayLength / birthTime end
  
  if days > 0 then
    local text = config.getParameter("radioMessages.birthLaterBasedOnWorldTime")
    days = "^red;" .. days .. "^reset;"
    text = util.replaceTag(text, "days", days)
    return text
  end
  
  local hours = math.floor(24 * birthTime)

  local minutes = math.floor(60 * (24 * birthTime - hours))
  if minutes <= 9 then minutes = '0' .. minutes end

  local appendix = 'AM'
  if hours > 12 then
    hours = hours - 12
    appendix = 'PM'
  end

  local time = self:buildFormattedBirthTimeString(hours, minutes, appendix)
  
  local text = config.getParameter("radioMessages.birthTodayBasedOnWorldTime")
  text = util.replaceTag(text, "time", time)
  return text
end

function PregnancyTest:buildBabyGenderText(baby)
  local text = config.getParameter("radioMessages.birthDetail") or ""
  local genderText = {male = "a boy", female = "a girl"}
  local gender = genderText[baby.birthGender] or "a surprise"
  text = util.replaceTag(text, "detail", gender)
  return text
end

function PregnancyTest:buildMultiBabyText(count)
  local text = config.getParameter("radioMessages.birthDetail") or ""
  local multiText = {[2] = "twins", [3] = "triplets"}
  local multi = multiText[count] or "a bunch"
  text = util.replaceTag(text, "detail", multi)
  return text
end

function PregnancyTest:notifyThisEntityTheyArePregnant(pregnancies, config)
  local baby = nil
  local bCount = 1
  local useOS = config.useOSTimeForPregnancies or false
  for i, b in pairs(pregnancies) do
    if useOS then
      if baby == nil or b.birthOSTime < baby.birthOSTime then
        bCount = 1
        baby = b
      elseif b.birthOSTime == baby.birthOSTime then
        bCount = bCount + 1
      end
    else
      if baby == nil or b.birthWorldTime < baby.birthWorldTime then
        bCount = 1
        baby = b
      elseif b.birthWorldTime == baby.birthWorldTime then
        bCount = bCount + 1
      end
    end
  end

  animator.setAnimationState("result", "positive", true)
  local text = "You're pregnant!\n\n"
  local progression = 0.0
  if useOS then
    text = text .. self:buildBirthTimeBasedOnOSTime(baby.birthOSTime)
    progression = (os.time() - baby.fullBirthOSTime) / (baby.birthOSTime - baby.fullBirthOSTime)
  elseif baby.motherType == "player" then
    text = text .. self:buildBirthTimeBasedOnPlayerWorldTime(baby.birthWorldTime)
    progression = 1 - (baby.birthWorldTime / baby.fullBirthWorldTime)
  else
    text = text .. self:buildBirthTimeBasedOnWorldTime(baby.birthWorldTime)
    progression = (baby.birthWorldTime - baby.fullBirthWorldTime) / ((world.day() + world.timeOfDay()) - baby.fullBirthWorldTime)
  end
  
  if progression > 0.75 then
    text = text .. "\n"
    if bCount > 1 then text = text .. self:buildMultiBabyText(bCount)
    else text = text .. self:buildBabyGenderText(baby) end
  end
  
  local symbol = "(^green;+^reset;) "
  text = symbol .. text
  self:queueRadioMessageForThisEntity("PregnancyTest", text)
end

function PregnancyTest:notifyThisEntityTheyAreNotPregnant()
  local text = config.getParameter("radioMessages.notPregnant")
  local symbol = "(^red;-^reset;) "
  text = symbol .. text
  animator.setAnimationState("result", "negative", true)
  self:queueRadioMessageForThisEntity("PregnancyTest", text)
end

function PregnancyTest:queueRadioMessageForThisEntity(messageId, text)
  local entityId = activeItem.ownerEntityId()
  local sendEntityMessageOptions = { messageId = messageId, unique = false, text = text }
  return world.sendEntityMessage(entityId, "queueRadioMessage", sendEntityMessageOptions)
end

function PregnancyTest:validatePregnanciesIsTable(pregnancies)
  sb.logInfo("Pregnancy condition - is table: "..tostring(type(pregnancies) == "table"))
  return type(pregnancies) == "table"
end

function PregnancyTest:thisEntityHasAtLeastOnePregnancy(pregnancies)
  local activePregnancies = 0
  
  for i,b in pairs(pregnancies) do
    if b.delay <= 0 then activePregnancies = activePregnancies + 1 end
  end
  
  sb.logInfo("Pregnancy condition - is pregnant: "..tostring(activePregnancies > 0))
  return activePregnancies > 0
end

-- Active Item Hooks --

function init()
  self.pregnancyTest = PregnancyTest:new()
end

function update(dt)
  self.pregnancyTest:update(dt)
end

function activate(fireMode, shiftHeld)
  self.pregnancyTest:activate(fireMode, shiftHeld)
end
-- Override to Starbound's dialog.lua function for the converse.behaviour to allow for family-specific dialogue to be used.

--- Functions to load dialogue based on family relation structure
function queryFamilyDialog(dialogKey, targetId, parentType)
  if self.dialog == nil then self.dialog = {} end
  local orgDialogSuffix = explode(".", dialogKey)
  orgDialogSuffix = orgDialogSuffix[#orgDialogSuffix] or "default"
  if self.dialog["dialog.family."..orgDialogSuffix] == nil then loadDialog("dialog.family."..orgDialogSuffix) end

  local dialog = self.dialog["dialog.family."..orgDialogSuffix]
  if dialog then
    return speciesFamilyDialog(dialog, targetId, parentType)
  end
end

function speciesFamilyDialog(dialog, targetId, parentType)
  dialog = dialog[parentType] or dialog["default"] or {}
  
  local species = context().species and context().species() or "default"
  dialog = dialog[species] or dialog.default

  local targetDialog
  if targetId then
    targetDialog = dialog[world.entitySpecies(targetId)] or dialog.default
  else
    targetDialog = dialog.default
  end

  if dialog.generic then
    targetDialog = util.mergeLists(dialog.generic, targetDialog)
  end

  return targetDialog
end

-- @OVERRIDE
-- param dialogType
-- param dialog
-- param entity
-- param tags
local org_sayToEntity = sayToEntity
function sayToEntity(args, board)
  if not self.sb_npc and not self.sb_monster then return org_sayToEntity(args, board) end
  
  local isKid = not not (self.sb_npc or self.sb_monster)._isKid
  local dialogType = isKid and "dialog.kid" or args.dialogType
  if (self.sb_npc or self.sb_monster):canLog("behavior") then sb.logInfo("BEHAVIOUR: Triggering Sexbound dialog. Type: "..tostring(dialogType)) end
  
  local dialog = nil
  local isParent, parentType = checkParent(args.entity)
  if isParent and math.random() < 0.1 then -- Add low random chance to family specific dialogue
    dialog = args.dialog and speciesFamilyDialog(args.dialog, args.entity, parentType) or queryFamilyDialog(dialogType, args.entity, parentType)
  else
    dialog = args.dialog and speciesDialog(args.dialog, args.entity) or queryDialog(dialogType, args.entity)
  end
  local dialogMode = config.getParameter("dialogMode", "static")

  if dialog == nil then
    if isKid or isParent then
      -- Fallback to original request
      dialogType = args.dialogType
      if (self.sb_npc or self.sb_monster):canLog("behavior") then sb.logInfo("Kid or family Conversation failed - no kid or family dialogue. Fallback. "..tostring(isKid).." - "..tostring(isParent)) end
      dialog = args.dialog and speciesDialog(args.dialog, args.entity) or queryDialog(dialogType, args.entity);
    end
    if dialog == nil then error(string.format("Dialog type %s not specified in %s", dialogType, entityVariant())) end
  end

  if dialogMode == "static" then
    dialog = staticRandomizeDialog(dialog)
  elseif dialogMode == "sequence" then
    dialog = sequenceDialog(dialog, dialogType)
  else
    dialog = randomizeDialog(dialog)
  end
  if dialog == nil then return false end

  local tags = sb.jsonMerge(self.dialogTags or {}, args.tags)
  tags.selfname = world.entityName(entity.id())
  tags.parentType = parentType
  if args.entity then
    tags.entityname = world.entityName(args.entity)

    local entityType = world.entityType(args.entity)
    if entityType and entityType == "npc" then
      tags.entitySpecies = world.entitySpecies(args.entity)
    end
  end

  local options = {}

  -- Only NPCs have sound support
  if entity.entityType() == "npc" then
    options.sound = randomChatSound()
  end

  context().say(dialog, tags, options)
  return true
end

--- Function to check if the target entity is the parent of the talker
-- param entityId
function checkParent(eid)
    if not eid then return false end
    
    local motherUuid = status.statusProperty("motherUuid", nil)
    local fatherUuid = status.statusProperty("fatherUuid", nil)
    if not motherUuid and not fatherUuid then return false end
    
    local targetUuid = world.entityUniqueId(eid)
    if not targetUuid then return false end
    
    if motherUuid == targetUuid then return true, "mother"
    elseif fatherUuid == targetUuid then return true, "father"
    else return false end
end

--- Function to split dialogType's into their components, PHP explode style
function explode(d,p)
   local t, ll
   t={}
   ll=0
   if(#p == 1) then
      return {p}
   end
   while true do
      l = string.find(p, d, ll, true) -- find the next d in the string
      if l ~= nil then -- if "not not" found then..
         table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
         ll = l + 1 -- save just after where we found it for searching next time.
      else
         table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
         break -- Break at end, as it should be, according to the lua manual.
      end
   end
   return t
end
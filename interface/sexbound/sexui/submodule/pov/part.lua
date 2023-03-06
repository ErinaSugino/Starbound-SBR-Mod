SexUI.POV.Part = {}
SexUI.POV.Part_mt = {
    __index = SexUI.POV.Part
}

--- Instantiates a new instance
-- @param actor an actor
-- @param part_name a string
function SexUI.POV.Part.new(actor, part_name)
  local self = setmetatable({}, SexUI.POV.Part_mt)
  self.image = self:buildImage(actor.actorSlot, part_name, actor.gender, actor.species)
  self.directives = actor.bodyDirectives or ""
  self.directives = self.directives .. (actor.hairDirectives or "")
  return self
end

--- Checks if the part's assigned image exists
function SexUI.POV.Part:checkImageExists()
  return Sexbound.Util.imageExists(self.image)
end

--- Builds an image path for this instance of part
-- @param role
-- @param part_name
-- @param gender
-- @param species
function SexUI.POV.Part:buildImage(role, part_name, gender, species)
  local filepath = "/artwork/pov/<role>/<species>/<gender>/<part_name>.png"
  filepath = util.replaceTag(filepath, "species", species)
  filepath = util.replaceTag(filepath, "gender", gender)
  filepath = util.replaceTag(filepath, "role", role)
  filepath = util.replaceTag(filepath, "part_name", part_name)
  return filepath
end

--- Draws this part's image to the specified canvas
-- @param canvas
-- @param frame
function SexUI.POV.Part:render(canvas, frame)
  canvas:drawImage(self.image .. ":" .. frame .. (self.directives or ""), {0, 0}, 1, "white", false)
end
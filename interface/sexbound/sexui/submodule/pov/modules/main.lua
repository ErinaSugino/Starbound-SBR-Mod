require "/interface/sexbound/sexui/submodule.lua"

SexUI.POV.Modules.Main = {}
SexUI.POV.Modules.Main_mt = {
    __index = SexUI.POV.Modules.Main
}

require "/interface/sexbound/sexui/submodule/pov/part.lua"

--- Instantiates a new instance
-- @param parant the parent instance
-- @param config a table of config options
function SexUI.POV.Modules.Main.new(parent, config)
    local self = setmetatable({
        _parent = parent,
        animationCycle = config.animationCycle or 1,
        animationTimer = 0,
        frameCount = config.frameCount or 5,
        frameIndex = 1,
        frameName = "",
        parts = {},
        penetrationType = 1
    }, SexUI.POV.Modules.Main_mt)
    
    self.canvas = widget.bindCanvas("pov")
    self.controls = widget.bindCanvas("povControls");
    return self
end

--- Returns if this modules has anything to render
function SexUI.POV.Modules.Main:isAvailable()
    return not isEmpty(self.parts)
end

--- Renders the animation parts managed by this instance
function SexUI.POV.Modules.Main:render(canvas)
    if isEmpty(self.parts) then
        return
    end

    local frame = self.frameName .. "." .. self.frameIndex

    canvas:drawImage(self._config.backgroundImage, {0, 0}, 1.0, "white", false)
    self.parts.actor1Body:render(canvas, frame)
    self.parts.actor1Genital:render(canvas, frame)
    self.parts.actor2Body:render(canvas, frame)
    self.parts.actor1BodyOverlay:render(canvas, frame)
    canvas:drawImage(self._config.foregroundImage, {0, 0}, 1.0, self._config.foregroundImageColor, false)
end

--- Updates this instance
-- @param dt
function SexUI.POV.Modules.Main:update(dt)
    self.animationTimer = self.animationTimer + dt

    local cycle = self.animationCycle / self:getAnimationRate()
    self.frameIndex = util.clamp(math.ceil(self.animationTimer / cycle * self.frameCount), 1, self.frameCount)

    if (self.animationTimer >= cycle) then
        self.animationTimer = 0
    end
end

function SexUI.POV.Modules.Main:triggerUpdate(actors)
    self:updateParts(actors)
end

--- Updates animation parts for each actor
-- @param a table of actors
function SexUI.POV.Modules.Main:updateParts(actors)
    self.parts = {}
    self.partDirectives = {}

    if isEmpty(actors or {}) or #actors <= 1 then
        return
    end

    self:updatePenetrationType(actors)
    self:updatePartsForActor1(actors[1])
    self:updatePartsForActor2(actors[2])

    if not self.parts.actor1Body:checkImageExists() or not self.parts.actor2Body:checkImageExists() then
        self.parts = {}
        self.partDirectives = {}
        self.frameName = ""
        return
    end

    self.frameName = actors[1].frameName
end

--- Updates animation parts for Actor1
-- @param actor an actor table
function SexUI.POV.Modules.Main:updatePartsForActor1(actor)
    actor.gender = actor.bodyType
    self.parts.actor1Body = SexUI.POV.Part.new(actor, "body")
    self.parts.actor1BodyOverlay = SexUI.POV.Part.new(actor, "body_overlay")

    actor.gender = actor.genitalType
    self.parts.actor1Genital = SexUI.POV.Part.new(actor, "genital")
end

--- Updates animation parts for Actor 2
-- @param actor an actor table
function SexUI.POV.Modules.Main:updatePartsForActor2(actor)
    actor.gender = actor.bodyType
    self.parts.actor2Body = SexUI.POV.Part.new(actor, "body_penetration" .. self.penetrationType)
end

--- Updates the penetration type according to the genital type of actor 1 and 2
-- @param actors a table of actors
function SexUI.POV.Modules.Main:updatePenetrationType(actors)
    -- genital type 0 = male; genital type 1 = female
    if actors[1].genitalType == 1 then
        self.penetrationType = 1
        return
    end
    if actors[1].genitalType == 0 and actors[2].genitalType == 1 then
        self.penetrationType = 2
        return
    end
    if actors[1].genitalType == 1 and actors[2].genitalType == 1 then
        self.penetrationType = 3
        return
    end
    self.penetrationType = 1
end

--- Sets animation rate to the specified value
-- @param animationRate a decimal number
function SexUI.POV.Modules.Main:getAnimationRate()
    return self._parent.animationRate
end

--- Returns a reference to the UI canvas
function SexUI.POV.Modules.Main:getCanvas()
    return self._parent.canvas
end

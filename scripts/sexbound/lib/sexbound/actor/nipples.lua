--- Sexbound.Actor.Nipples Class Module.
--- @class Sexbound.Actor.Nipples
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor
--- @field _config table
--- @field private _defaultImage string
Sexbound.Actor.Nipples = {}
Sexbound.Actor.Nipples_mt = {
    __index = Sexbound.Actor.Nipples
}

--- Returns a reference to a new instance of this class.
--- @param parent Sexbound.Actor The calling oparent actor instance
--- @return Sexbound.Actor.Nipples # The new instance
function Sexbound.Actor.Nipples:new(parent)
    return setmetatable({
        _defaultImage = "/artwork/defaults/default_image.png",
        _parent = parent,
        _config = parent._parent._config.actor.nipplesConfig or {}
    }, Sexbound.Actor.Nipples_mt)
end

--- Builds the image path for the nipple sprite. Currently just fixed default
--- @param entityGroup string The entity group of the actor
--- @param role string The role name of the actor
--- @param species string The species of the actor
--- @param gender string The gender of the actor
--- @return string # The file path of the nipple sprite
function Sexbound.Actor.Nipples:buildNippleImage(entityGroup, role, species, gender)
    return "/artwork/nipple.png:default"
end

--- Resets the animator parts for this actor's nipples
--- @param entityGroup string The entity group of the actor
--- @param role string The role name of the actor
--- @param species string The species of the actor
--- @param gender string The gender of the actor
function Sexbound.Actor.Nipples:resetParts(entityGroup, role, species, gender)
    if self._config.visible ~= true then return end

    if self:getParent():getIdentity().sxbShowNipples ~= true then return end

    local nipple1 = self:buildNippleImage(entityGroup, role, species, gender)
    local nipple2 = nipple1

    local bodyDirectives = self:getParent():getIdentity("bodyDirectives") or "" --[[@as string]]

    local prefix = "actor" .. self:getParent():getActorNumber()

    animator.setGlobalTag("part-" .. prefix .. "-nipple1", nipple1)
    animator.setGlobalTag(prefix .. "-nipple1", bodyDirectives)

    animator.setGlobalTag("part-" .. prefix .. "-nipple2", nipple2)
    animator.setGlobalTag(prefix .. "-nipple2", bodyDirectives)
end

--- Resets the animator directive tags of this actor's nipples
--- @param prefix string The prefix of the animator tag names
function Sexbound.Actor.Nipples:resetAnimatorDirectives(prefix)
    animator.setGlobalTag(prefix .. "-nipple1", "")
    animator.setGlobalTag(prefix .. "-nipple2", "")
end

--- Resets the animator part tags of this actor's nipples
--- @param prefix string The prefix of the animator tag names
function Sexbound.Actor.Nipples:resetAnimatorParts(prefix)
    for _, partName in
        ipairs({ "nipple1", "nipple2" }) do
        animator.setGlobalTag("part-" .. prefix .. "-" .. partName, self._defaultImage .. ":default")
    end
end

--- Returns a reference to this instance's parent object
--- @return Sexbound.Actor # The parent instance
function Sexbound.Actor.Nipples:getParent()
    return self._parent
end

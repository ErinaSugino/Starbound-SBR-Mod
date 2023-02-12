--- Sexbound.Actor.Nipples Class Module.
-- @classmod Sexbound.Actor.Nipples
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Actor.Nipples = {}
Sexbound.Actor.Nipples_mt = {
    __index = Sexbound.Actor.Nipples
}

--- Returns a reference to a new instance of this class.
-- @param parent
function Sexbound.Actor.Nipples:new(parent)
    return setmetatable({
        _defaultImage = "/artwork/defaults/default_image.png",
        _parent = parent,
        _config = parent._parent._config.actor.nipplesConfig or {}
    }, Sexbound.Actor.Nipples_mt)
end

function Sexbound.Actor.Nipples:buildNippleImage(entityGroup, role, species, gender)
    return "/artwork/nipple.png:default"
end

function Sexbound.Actor.Nipples:resetParts(entityGroup, role, species, gender)
    if self._config.visible ~= true then return end

    if self:getParent():getIdentity().sxbShowNipples ~= true then return end

    local nipple1 = self:buildNippleImage(entityGroup, role, species)
    local nipple2 = nipple1

    local bodyDirectives = self:getParent():getIdentity("bodyDirectives") or ""

    local prefix = "actor" .. self:getParent():getActorNumber()

    animator.setGlobalTag("part-" .. prefix .. "-nipple1", nipple1)
    animator.setGlobalTag(prefix .. "-nipple1", bodyDirectives)

    animator.setGlobalTag("part-" .. prefix .. "-nipple2", nipple2)
    animator.setGlobalTag(prefix .. "-nipple2", bodyDirectives)
end

function Sexbound.Actor.Nipples:resetAnimatorDirectives(prefix)
    animator.setGlobalTag(prefix .. "-nipple1", "")
    animator.setGlobalTag(prefix .. "-nipple2", "")
end

function Sexbound.Actor.Nipples:resetAnimatorParts(prefix)
    for _, partName in
        ipairs({ "nipple1", "nipple2" }) do
        animator.setGlobalTag("part-" .. prefix .. "-" .. partName, self._defaultImage .. ":default")
    end
end

--- Returns a reference to this instance's parent object
function Sexbound.Actor.Nipples:getParent()
    return self._parent
end

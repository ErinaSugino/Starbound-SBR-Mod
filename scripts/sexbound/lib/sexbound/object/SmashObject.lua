--- Wrapper for destroying a sexnode object
--- @class Sexbound.SmashObject
--- @author Locuturus
--- @license GNU General Public License v3.0
--- @field _smash function
Sexbound.SmashObject = {}
Sexbound.SmashObject_mt = {
    __index = Sexbound.SmashObject
}

--- Create new wrapper instance
--- @param smash function The target smash function (Ideally object.smash)
--- @return Sexbound.SmashObject # The new instance
function Sexbound.SmashObject:new(smash)
    return setmetatable({
        _smash = smash
    }, Sexbound.SmashObject_mt)
end

--- Execute smash function
function Sexbound.SmashObject:execute()
    if type(self._smash) ~= "function" then
        return
    end

    self._smash()
end

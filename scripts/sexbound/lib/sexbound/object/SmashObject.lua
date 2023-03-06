Sexbound.SmashObject = {}
Sexbound.SmashObject_mt = {
    __index = Sexbound.SmashObject
}

function Sexbound.SmashObject:new(smash)
    return setmetatable({
        _smash = smash
    }, Sexbound.SmashObject_mt)
end

function Sexbound.SmashObject:execute()
    if type(self._smash) ~= "function" then
        return
    end

    self._smash()
end

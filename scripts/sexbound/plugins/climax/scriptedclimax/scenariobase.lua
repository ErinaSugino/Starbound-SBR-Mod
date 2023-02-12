--- Sexbound.ScriptedClimax Class Module.
-- @classmod Sexbound.ScriptedClimax
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.ScriptedClimax = {}
Sexbound.ScriptedClimax_mt = {
    __index = Sexbound.ScriptedClimax
}

function Sexbound.ScriptedClimax:new()
    return setmetatable({
        _parent = {}
    }, Sexbound.ScriptedClimax_mt)
end

function Sexbound.ScriptedClimax:init(parent)
    self._parent = parent
end

function Sexbound.ScriptedClimax:start()

end

function Sexbound.ScriptedClimax:reset()

end

function Sexbound.ScriptedClimax:run(dt)

end

function Sexbound.ScriptedClimax:stop()

end

function Sexbound.ScriptedClimax:getParent()
    return self._parent
end

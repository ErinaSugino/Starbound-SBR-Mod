--- Sexbound.ScriptedClimax Class Module.
--- @class Sexbound.ScriptedClimax
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Actor.Climax
Sexbound.ScriptedClimax = {}
Sexbound.ScriptedClimax_mt = {
    __index = Sexbound.ScriptedClimax
}

--- Creates new scripted climax manager instance
--- @return Sexbound.ScriptedClimax # The newly created instance
function Sexbound.ScriptedClimax:new()
    return setmetatable({
        _parent = {}
    }, Sexbound.ScriptedClimax_mt)
end

--- Late init binding
--- @param parent Sexbound.Actor.Climax The calling parent climax plugin instance
function Sexbound.ScriptedClimax:init(parent)
    self._parent = parent
end

--- Placeholder start trigger
function Sexbound.ScriptedClimax:start() end

--- Placeholder reset trigger
function Sexbound.ScriptedClimax:reset() end

--- Placeholder run tick
--- @param dt number The delta time since last tick
function Sexbound.ScriptedClimax:run(dt) end

function Sexbound.ScriptedClimax:stop() end

--- Returns the parent climax plugin instance
--- @return Sexbound.Actor.Climax # The parent climax plugin instance
function Sexbound.ScriptedClimax:getParent()
    return self._parent
end

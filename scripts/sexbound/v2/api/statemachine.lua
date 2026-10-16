--- Sexbound.API.StateMachine Module.
--- @class Sexbound.API.StateMachine
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.API.StateMachine = {}

--- Returns whethere or not a given state machine status is active
--- @param name string The status name
--- @return boolean # Whethere or not that given status is active
Sexbound.API.StateMachine.getStatus = function(name)
    if not self._sexbound then
        return false
    end

    local _, result = xpcall(function()
        return self._sexbound:getStateMachine():getStatus(name)
    end, sb.logError)

    return result
end

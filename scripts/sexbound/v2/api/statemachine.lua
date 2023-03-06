--- Sexbound.API.StateMachine Module.
-- @module Sexbound.API.StateMachine
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.API.StateMachine = {}

--- Returns the status the specified State Machine state for this instance.
-- @param[opt] name A string that represents a state name.
-- @usage local isIdling = Sexbound.API.StateMachine.getStatus("idle")
-- @usage local status   = Sexbound.API.StateMachine.getStatus()
Sexbound.API.StateMachine.getStatus = function(name)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getStateMachine():getStatus(name)
    end, sb.logError)

    return result
end

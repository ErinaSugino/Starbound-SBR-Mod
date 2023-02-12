--- Sexbound.API.Positions Module.
-- @module Sexbound.API.Positions
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.API.Positions = {}

--- Returns a list of loaded positions.
Sexbound.API.Positions.getPositions = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getPositions()
    end, sb.logError)

    return result
end

--- Returns the current position.
Sexbound.API.Positions.getCurrentPosition = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getPositions():getCurrentPosition()
    end, sb.logError)

    return result
end

--- Switches actors into a random position.
Sexbound.API.Positions.switchToRandomPosition = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getPositions():switchRandomSexPosition()
    end, sb.logError)

    return result
end

--- Sexbound.API.Positions Module.
--- @class Sexbound.API.Positions
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.API.Positions = {}

--- Returns the position manager.
--- @return Sexbound.Positions? # The positions manager or nil if sexbound instance not existing
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
--- @return Sexbound.Position? # The currently active position or nil if sexbound node not existing
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
        return self._sexbound:getPositions():switchRandomSexPosition(false)
    end, sb.logError)

    return result
end

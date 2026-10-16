--- Sexbound.API.Nodes Module.
--- @class Sexbound.API.Nodes
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.API.Nodes = {}

--- Add a new node object to the current world.
--- @param tilePosition Vec2I A position to place the 8 x 8 pixel node. It is placed relative to the imagePosition of this object.
--- @param sitPosition Vec2I A position to place the character who sits in this object.
--- @param params table? A table of object params to be applied to placed object node.
Sexbound.API.Nodes.addNode = function(tilePosition, sitPosition, params)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:addNode(tilePosition, sitPosition, params)
    end, sb.logError)

    return result
end

--- Add this entity as a node.
--- @param sitPosition Vec2I A position to place the character who sits in this object.
Sexbound.API.Nodes.becomeNode = function(sitPosition)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:becomeNode(sitPosition)
    end, sb.logError)

    return result
end

--- Returns a list of all current nodes.
--- @return table<integer, Sexbound.Node>? # The list of all nodes or nil if sexbound instance not existing
Sexbound.API.Nodes.getNodes = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getNodes()
    end, sb.logError)

    return result
end

--- Replace current nodes with a list of new nodes.
--- @param newNodes table<integer, Sexbound.Node> A list of nodes.
Sexbound.API.Nodes.setNodes = function(newNodes)
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:setNodes(newNodes)
    end, sb.logError)

    return result
end

--- Returns the current node count.
--- @return integer # Number of nodes
Sexbound.API.Nodes.getNodeCount = function()
    if not self._sexbound then
        return 0
    end

    local _, result = xpcall(function()
        return self._sexbound:getNodeCount()
    end, sb.logError)

    return result
end

--- Uninitializes all nodes.
--- @return boolean # Whethere or not node uninitialization was successful
Sexbound.API.Nodes.uninitNodes = function()
    if not self._sexbound then
        return true
    end

    local _, result = xpcall(function()
        return self._sexbound:uninitNodes()
    end, sb.logError)

    return result
end

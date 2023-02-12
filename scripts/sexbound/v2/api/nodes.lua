--- Sexbound.API.Nodes Module.
-- @module Sexbound.API.Nodes
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.API.Nodes = {}

--- Add a new node object to the current world.
-- @param tilePosition A Vec2I position to place the 8 x 8 pixel node. It is placed relative to the imagePosition of this object.
-- @param sitPosition A Vec2I position to place the character who sits in this object.
-- @param params A table of object params to be applied to placed object node.
-- @usage Sexbound.API.Nodes.addNode({0, 0}, {0, 20})
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
-- @param sitPosition A Vec2I position to place the character who sits in this object.
-- @usage Sexbound.API.Nodes.addNode({0, 20})
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
-- @usage local nodes = Sexbound.API.Nodes.getNodes()
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
-- @param newNodes A list of nodes.
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
-- @usage local nodesCount = Sexbound.API.Nodes.getNodeCount()
Sexbound.API.Nodes.getNodeCount = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:getNodeCount()
    end, sb.logError)

    return result
end

--- Uninitializes all nodes.
-- @usage Sexbound.API.Nodes.uninitNodes()
Sexbound.API.Nodes.uninitNodes = function()
    if not self._sexbound then
        return
    end

    local _, result = xpcall(function()
        return self._sexbound:uninitNodes()
    end, sb.logError)

    return result
end

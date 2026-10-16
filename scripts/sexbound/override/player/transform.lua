require "/scripts/sexbound/override/common/transform.lua"

--- Player transformation manager class
--- @class Sexbound.Player.Transform: Sexbound.Common.Transform
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent Sexbound.Player
Sexbound.Player.Transform = Sexbound.Common.Transform:new()
Sexbound.Player.Transform_mt = {
    __index = Sexbound.Player.Transform
}

--- Creates new player transformation manager instance
--- @param parent Sexbound.Player The calling player manager instance
--- @return Sexbound.Player.Transform # The newly created player transformation manager instance
function Sexbound.Player.Transform:new(parent)
    local _self = setmetatable({
        _canTransform = false,
        _mindControl = {},
        _nodeName = "sexbound_main_node",
        _parent = parent
    }, Sexbound.Player.Transform_mt)

    _self:init(parent)

    status.setStatusProperty("sexbound_mind_control", false)

    message.setHandler("Sexbound:Transform", function(_, _, args)
        return _self:handleTransform(args)
    end)

    return _self
end

--- Message handler for transformation request
--- @param args table Transformation config
--- @return table|boolean|nil # The transform result or false if not possible
function Sexbound.Player.Transform:handleTransform(args)
    if self:getCanTransform() then
        -- Override sexbound config that is supplied to the spawned sexnode
        self:setSexboundConfig(args.sexboundConfig)

        self:setTimeout(args.timeout)

        local result = self:tryCreateNode(args.spawnOptions or {})

        if result ~= nil and args.applyStatusEffects ~= nil then
            for _, statusName in ipairs(args.applyStatusEffects) do
                status.addEphemeralEffect(statusName, args.timeout)
            end
        end

        return result
    end

    return false
end

--- Actually try to create the node
--- @return {uniqueId: string}? # The uuid of the created node, if successful
function Sexbound.Player.Transform:tryCreateNode(spawnOptions)
    local position = self:findNearbyOpenSpace()
    if self._parent:canLog("debug") then sb.logInfo("Looking for valid spawn position") end

    if not position then
        return nil
    end

    if self._parent:canLog("debug") then sb.logInfo("Found valid position, attempting to place actual node") end
    -- Place Sexnode and store Unique ID
    local uniqueId = self:placeSexNode(position, {
        randomStartPosition = true,
        noEffect = spawnOptions.noEffect or false
    })

    if self._parent:canLog("debug") then sb.logInfo("Placed node with UUID "..tostring(uniqueId)) end
    if uniqueId ~= nil then
        world.sendEntityMessage(entity.id(), "Sexbound:Transform:Success", {
            uniqueId = uniqueId
        })
        self._controllerId = uniqueId
        return {
            uniqueId = uniqueId
        }
    else
        world.sendEntityMessage(entity.id(), "Sexbound:Transform:Failure")
        return nil
    end
end

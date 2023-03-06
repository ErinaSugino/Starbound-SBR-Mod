--- Sexbound.Player Module.
-- @module Sexbound.Player
Sexbound = Sexbound or {}
Sexbound.Player = {}
Sexbound.Player_mt = {
    __index = Sexbound.Player
}

local SexboundErrorCounter = 0

--- Hook (init)
local Sexbound_Old_Init = init
function init()
    xpcall(function()
        Sexbound_Old_Init()

        self.sb_player = Sexbound.Player:new()
    end, sb.logError)
end

--- Hook (update)
local Sexbound_Old_Update = update
function update(dt)
    xpcall(function()
        Sexbound_Old_Update(dt)
    end, sb.logError)

    if SexboundErrorCounter < 5 then
        xpcall(function()
            self.sb_player:update(dt)
        end, function(err)
            SexboundErrorCounter = SexboundErrorCounter + 1

            sb.logError(err)
        end)
    end
end

function Sexbound.Player:new()
    return setmetatable({}, Sexbound.Player_mt)
end

function Sexbound.Player:update(dt)
    -- Placeholder
end

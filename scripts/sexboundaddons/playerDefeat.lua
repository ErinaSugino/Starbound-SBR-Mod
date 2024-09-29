--[[
  This script is responsbile for enabling the Player to be transformed into a SexNode.

  By default, the player cannot be transformed.
]]--


Player_Sexbound_Defeat = {}
Player_Sexbound_Defeat_mt = { __index = Player_Sexbound_Defeat }

--- Hook (init)
local Player_Sexbound_Defeat_Init = init
function init()
  xpcall(function()
    Player_Sexbound_Defeat_Init()
    -- Change player to be able to transform into SexNode
    if self.sb_player then
      local transform = self.sb_player:getTransform() or {}
      transform:setCanTransform(true)
    end
  end, function(err)
    sb.logError(err)
  end)
end
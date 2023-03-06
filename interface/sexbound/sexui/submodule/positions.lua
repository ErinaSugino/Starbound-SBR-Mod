require "/interface/sexbound/sexui/submodule.lua"

SexUI.Positions = SexUI.Submodule.new()
SexUI.Positions_mt = { __index = SexUI.Positions }

--- Instantiantes a new instance.
-- @param config
function SexUI.Positions.new(parent, _config)
  local _self = setmetatable({
    _allPositions = _config.allPositions or {}
  }, SexUI.Positions_mt)

  _self:init(parent, _config, "positions")
  _self:refreshPositionButtons()
  _self._canvas = widget.bindCanvas("positions")
  local offset = widget.getPosition("positions")
  
  for index, button in ipairs(_self._config.buttons) do
    local buttons = _self._parent._buttons[_self._buttonPrefix] or _self._parent._buttons["main"]
    button.offset = offset
    buttons[button.key or index] = CustomButton.new(button)
  end
  return _self
end

function SexUI.Positions:render()
  self._canvas:clear()

  -- Draw the background image for 'positions'.
  self._canvas:drawImage(self._config.backgroundImage, {129,129}, 1.0, self._config.color, true)

  self:renderButtons(self._canvas)
end

function SexUI.Positions:update(dt)
  self:updateAlphaForAllImages(self:getParent()._globalAlpha)
end

function SexUI.Positions:updateAlphaForAllImages(alpha)
  self._config.color[4] = math.min(self._config.fadeInAlpha, alpha)
  self._config.colorButtons[4] = alpha
end

function SexUI.Positions:refreshPositionButtons()
  local page = self._parent._sexPositionsPage or 1
  local offset = (page - 1) * 8
  local max = #self._allPositions
  if (offset + 1) > max then
    page = 1
    offset = 0
    self._parent._sexPositionsPage = 1
  end
  
  self._parent:forEachButton(function(key, button)
    local posNum = string.sub(key, -1, -1) or 0
    posNum = tonumber(posNum)
    if posNum > 0 then posNum = posNum + offset end
    local positionData = self._allPositions[posNum] or {}
    
    if positionData.name then button.config.name = positionData.name else button.config.name = "Position "..posNum end
    --if positionData.image then button.config.image = positionData.image else button.config.image = nil end
    --if positionData.imageOffset then button.config.imageOffset = positionData.imageOffset else button.config.imageOffset = {0,0} end
    if positionData.image then button:setNewImage(positionData.image, positionData.imageOffset) else button:setNewImage(nil, nil) end
  end, "positions")
end

function SexUI.Positions:getPositionCount()
  return #self._allPositions
end

function SexUI.Positions:setPositions(newData)
    self._allPositions = newData or {}
    self:refreshPositionButtons()
end

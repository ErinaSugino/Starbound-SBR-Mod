require "/interface/sexbound/sexui/submodule.lua"

SexUI.Commands = SexUI.Submodule.new()
SexUI.Commands_mt = { __index = SexUI.Commands }

--- Instantiantes a new instance.
-- @param config
function SexUI.Commands.new(parent, _config)
  local _self = setmetatable({}, SexUI.Commands_mt)

  _self:init(parent, _config, "commands")
  _self._canvas = widget.bindCanvas("commands")
  
  local offset = widget.getPosition("commands")
  
  for index, button in ipairs(_self._config.buttons) do
    local buttons = _self._parent._buttons[_self._buttonPrefix] or _self._parent._buttons["main"]
    button.offset = offset
    buttons[button.key or index] = CustomButton.new(button)
  end
  return _self
end

function SexUI.Commands:render()
  self._canvas:clear()
  self._canvas:drawImage(self._config.backgroundImage, {129,129}, 1.0, self._config.color, true)
  self:renderButtons(self._canvas)
end

function SexUI.Commands:update(dt)
  self:updateAlphaForAllImages(self:getParent()._globalAlpha)
end

function SexUI.Commands:updateAlphaForAllImages(alpha)
  self._config.color[4] = math.min(self._config.fadeInAlpha, alpha)
  self._config.colorButtons[4] = alpha
end

require("/interface/sexbound/common/custombutton.lua")

SexUI.Submodule = {}
SexUI.Submodule_mt = {
    __index = SexUI.Submodule
}

--- Instantiantes a new instance.
-- @param config
function SexUI.Submodule.new()
    return setmetatable({}, SexUI.Submodule_mt)
end

function SexUI.Submodule:init(...)
    local args = {...}

    self._parent = args[1]

    self._config = args[2]
    
    self._buttonPrefix = args[3] or "main"
end

function SexUI.Submodule:renderButtons(canvas)
    canvas = canvas or self._canvas

    self:getParent():forEachButton(function(key, button)
        button:render(canvas, self._config.colorButtons, self:getParent()._debug)
    end, self._buttonPrefix)
end

function SexUI.Submodule:update(dt)

end

function SexUI.Submodule:render()

end

function SexUI.Submodule:updateAlphaForAllImages(alphaValue)

end

function SexUI.Submodule:getConfig()
    return self._config
end

function SexUI.Submodule:getParent()
    return self._parent
end

function SexUI.Submodule:dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. self:dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

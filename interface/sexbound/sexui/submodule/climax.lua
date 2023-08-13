require "/interface/sexbound/sexui/submodule.lua"

SexUI.Climax = SexUI.Submodule.new()
SexUI.Climax_mt = {
    __index = SexUI.Climax
}

--- Instantiantes a new instance.
-- @param config
function SexUI.Climax.new(parent, _config)
    local _self = setmetatable({}, SexUI.Climax_mt)

    _self:init(parent, _config, "climax")
    _self._progressBars = {}

    for _, progressBar in ipairs(_self._config.progressBars) do
        table.insert(_self._progressBars, progressBar)
    end

    _self._canvas = {
        climax1 = widget.bindCanvas("climax1"),
        climax2 = widget.bindCanvas("climax2"),
        climaxOverlay = widget.bindCanvas("climaxOverlay")
    }
    
    local offset = widget.getPosition("climaxOverlay")
    
    for index, button in ipairs(_self._config.buttons) do
        local buttons = _self._parent._buttons[_self._buttonPrefix] or _self._parent._buttons["main"]
        button.offset = offset
        buttons[button.key or index] = CustomButton.new(button)
    end

    return _self
end

function SexUI.Climax:forEachCanvas(callback)
    for key, value in pairs(self._canvas) do
        callback(key, value)
    end
end

function SexUI.Climax:forEachProgressBar(callback)
    for key, value in ipairs(self._progressBars) do
        callback(key, value)
    end
end

function SexUI.Climax:renderProgressBar(canvas, progressBar)
    canvas:drawImage(progressBar.backgroundImage, progressBar.imagePosition, 1.0, progressBar.color, true)

    canvas:drawImageDrawable(progressBar.image .. progressBar.imageDirectives .. "?addmask=" .. progressBar.imageMask,
        progressBar.imagePosition, 1.0, progressBar.color, progressBar.rotation)

    canvas:drawImage(progressBar.coverImage, progressBar.imagePosition, 1.0, progressBar.coverColor, true)
end

function SexUI.Climax:render()
    self:forEachCanvas(function(_, canvas)
        canvas:clear()
    end)

    self:renderProgressBar(self._canvas.climax1, self._progressBars[1])
    self:renderProgressBar(self._canvas.climax1, self._progressBars[2])
    self:renderProgressBar(self._canvas.climax2, self._progressBars[3])
    self:renderProgressBar(self._canvas.climax2, self._progressBars[4])

    self._canvas.climaxOverlay:drawImage(self._config.buttonsBackgroundImage, {129, 129}, 1.0,
        self._config.buttonsBackgroundImageColor, true)

    self:renderButtons(self._canvas.climaxOverlay)
end

function SexUI.Climax:update(dt)
    self._progressBars[1].angle = -90 * self._progressBars[1].amount
    self._progressBars[1].rotation = self._progressBars[1].angle * math.pi / 180

    self._progressBars[2].angle = 90 * self._progressBars[2].amount
    self._progressBars[2].rotation = self._progressBars[2].angle * math.pi / 180

    self._progressBars[3].angle = -90 * self._progressBars[3].amount
    self._progressBars[3].rotation = self._progressBars[3].angle * math.pi / 180

    self._progressBars[4].angle = 90 * self._progressBars[4].amount
    self._progressBars[4].rotation = self._progressBars[4].angle * math.pi / 180

    self:updateAlphaForAllImages(self:getParent()._globalAlpha)
end

function SexUI.Climax:updateAlphaForAllImages(alpha)
    self._config.color[4] = math.min(self._config.progressBarColorFadeInAlpha, alpha)
    self._config.colorButtons[4] = alpha
    self._config.buttonsBackgroundImageColor[4] = alpha

    self:forEachProgressBar(function(_, progressBar)
        progressBar.color[4] = alpha
        progressBar.coverColor[4] = alpha
    end)
end

function SexUI.Climax:updateProgressBars(actors)
    self._progressBars[1].amount = 0
    self._progressBars[2].amount = 0
    self._progressBars[3].amount = 0
    self._progressBars[4].amount = 0

    if actors == nil then
        return
    end

    for i, actor in ipairs(actors) do
        if actor and actor.climax and actor.climax.currentPoints ~= 0 then
            self._progressBars[i].amount = actor.climax.currentPoints / actor.climax.maxPoints
        end
    end
end

function SexUI.Climax:getProgressBars()
    return self._progressBars
end

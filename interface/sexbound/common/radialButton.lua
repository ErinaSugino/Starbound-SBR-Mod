require "/scripts/util.lua"
require "/scripts/vec2.lua"

--- Class representing a canvas-rendered radial menu button area
--- @class RadialButton
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _parent RadialMenu
--- @field _config table
--- @field _isEnabled boolean
--- @field _isHovered boolean
--- @field _isInArea boolean
--- @field _isDirty boolean
--- @field _lastMousePos ?Vec2I
--- @field _imagePosition Vec2I
--- @field _backgroundPosition Vec2I
RadialButton = {}
RadialButton_mt = {__index = RadialButton}

--- Creates a new RadialButton instance
--- @param parent RadialMenu The calling parent instance
--- @param buttonConfig ?table The config overrides for this button
--- @return RadialButton # The newly created instance
function RadialButton.new(parent, buttonConfig)
    local _self = setmetatable({
        _parent = parent,
        _config = {},
        _isHovered = false,
        _isInArea = false,
        _isDirty = true,
        _lastMousePos = nil,
        _imagePosition = {0,0},
        _backgroundPosition = {0,0}
    }, RadialButton_mt)

    _self._config = util.mergeTable({
            enabled = true,
            visible = true,
            failureSound = "/sfx/interface/clickon_error.ogg",
            successSound = "/sfx/interface/ship_confirm1.ogg",
            value = true,
            radius = {0,0},
            range = {0,0},
            center = {0,0},
            color = {255,255,255,222}
        }, buttonConfig)

    _self:init()
    return _self
end

--- Initialize this instance
function RadialButton:init()
    self._isEnabled = not not self._config.enabled
    
    if self._config.image then
        self._config.imageOffset = self._config.imageOffset or {0, 0}

        local midR = (self._config.range[1] + self._config.range[2]) / 2
        local minDeg, maxDeg = self._config.radius[1], self._config.radius[2]
        if maxDeg < minDeg then maxDeg = maxDeg + 360 end
        local midDeg = (minDeg + maxDeg) / 2
        local midRad = math.rad(midDeg)

        local ox = math.cos(midRad) * midR
        local oy = math.sin(midRad) * midR

        local cx = math.floor(self._config.center[1] + ox + 0.5)
        local cy = math.floor(self._config.center[2] + oy + 0.5)
        self._imagePosition = vec2.add({cx,cy}, self._config.imageOffset)
    end

    if self._config.background then
        self._config.backgroundOffset = self._config.backgroundOffset or {0,0}
        self._backgroundPosition = vec2.add(self._config.center, self._config.backgroundOffset)
    end
end

--- Function called each tick to update the state of this instance
--- @param dt number The delta time since last tick
--- @param mPos Vec2I The current mouse position
function RadialButton:update(dt, mPos)
    if self._lastMousePos == nil or mPos[1] ~= self._lastMousePos[1] or mPos[2] ~= self._lastMousePos[2] then
        self._isInArea = self:isInBounds(mPos)
        self._lastMousePos = mPos
    end
end

--- Function called to allow this button instance its render pass
--- @param canvas CanvasWidget The target canvas to draw on
function RadialButton:render(canvas)
    local color = self._config.enabled and copy(self._config.color) or {192,192,192,222}
    if self._config.visible then
        local bg = self._config.background
        if bg then
            if self._isHovered then
                canvas:drawImage(bg.."?outline=2;FFFFFFE8;00000000", self._backgroundPosition, 1, color, true)
                color[4] = 255
            end
            canvas:drawImage(bg, self._backgroundPosition, 1, color, true)
        end

        local icon = self._config.image
        if icon then
            canvas:drawImage(icon, self._imagePosition, 1, color, true)
        end
    end

    self._isDirty = false
end

--- Function to attempt triggering a click on this button
--- @param mPos Vec2F The mouse position of the click
--- @param mBut integer Mouse* enum constant of the button pressed (0 = LMB, 1 = MMB, 2 = RMB, 3 & 4 = ???)
--- @param down boolean Whethere the button was pressed (true) or released (false)
--- @return boolean # Whethere or not this button consumed this click event
function RadialButton:click(mPos, mBut, down)
    return down and mBut == 0 and self:isInBounds(mPos)
end

--- Function to trigger updating the hover state
--- @param allowed boolean Whethere or not this element is allowed to be hovered (i.e. not yet consumed by higher element)
--- @return boolean # Whethere or not this element consumed the hover focus
function RadialButton:updateHover(allowed)
    local shouldHover = allowed and self._config.enabled and self._isInArea
    if shouldHover ~= self._isHovered then
        self._isHovered = shouldHover
        self._isDirty = true
    end
    return self._isHovered
end

--- [Helper] Check if a point is within the bounds of this instance
--- @private
--- @param pos Vec2I The position to check
--- @return boolean # Whethere or not the position is within the bounds
function RadialButton:isInBounds(pos)
    local dx = pos[1] - self._config.center[1]
    local dy = pos[2] - self._config.center[2]

    local dist = dx * dx + dy * dy
    local minR = self._config.range[1] * self._config.range[1]
    local maxR = self._config.range[2] * self._config.range[2]
    if dist < minR or dist > maxR then return false end

    --- @diagnostic disable-next-line: redundant-parameter
    local rad = math.atan(dx, dy)
    local deg = math.deg(rad)
    if deg < 0 then deg = deg + 360 end

    local startDeg = self._config.radius[1] % 360
    local endDeg = self._config.radius[2] % 360

    if startDeg <= endDeg then
        return deg >= startDeg and deg <= endDeg
    else
        return deg >= startDeg or deg <= endDeg
    end
end

--- Getter for the hover state of this button's hover state
--- @return boolean # The current hover state
function RadialButton:isHovered()
    return self._isHovered
end

--- Getter for the dirty state of this button
--- @return boolean # Whethere or not this button needs to re-render
function RadialButton:isDirty()
    return self._isDirty
end

--- Setter to change the enabled state of this button
--- @param enabled boolean Whethere or not it should be enabled now or not
function RadialButton:enable(enabled)
    if enabled ~= self._isEnabled then
        self._isEnabled = enabled
        self._isDirty = true
    end
end
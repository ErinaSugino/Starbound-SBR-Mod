require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"

--- Class representing a radial selector menu
--- @class RadialMenu
--- @author Erina Sugino
--- @license GNU General Public License v3.0
--- @field _config table
--- @field private _canvas CanvasWidget
--- @field private _promises PromiseKeeper
--- @field _center Vec2I
--- @field _size Vec2I
--- @field _range Vec2F
--- @field private _buttons RadialButton[]
RadialMenu = {}
RadialMenu_mt = {__index = RadialMenu}

require "/interface/sexbound/common/radialButton.lua"

--- Creates a new RadialMenu instance
--- @return RadialMenu # The newly created instance
function RadialMenu.new()
    local _self = setmetatable({
        _config = config.getParameter("config", {}),
        _promises = PromiseKeeper.new(),
        _canvas = widget.bindCanvas("canvas"),
        _center = {0,0},
        _range = {0,0},
        _size = {0,0},
        _buttons = {}
    }, RadialMenu_mt)

    _self:init()

    return _self
end

--- Initialize this instance
function RadialMenu:init()
    self._center = self._config.center or {0,0}
    self._size = self._config.size or {0,0}
    self._range = self._config.range or {0,0}

    local butCount = #(self._config.options or {})
    if butCount < 2 then butCount = 2 end
    if butCount > 8 then butCount = 8 end

    local steps = 360 / butCount
    for i=1,butCount do
        local minR, maxR = steps*(i-1), steps*i
        local butConf = {
            center = self._center,
            range = self._range,
            radius = {minR, maxR},
            background = "/interface/sexbound/selector/radial.png:"..butCount.."."..i
        }
        table.insert(self._buttons, RadialButton.new(self, butConf))
    end
end

--- Function called each update tick to update this menu
--- @param dt number The delta time since last tick
function RadialMenu:update(dt)
    local mPos, consumed, isDirty = self._canvas:mousePosition(), false, false

    self._promises:update(dt)

    local butCount = #self._buttons
    for i=butCount,1,-1 do
        self._buttons[i]:update(dt, mPos)
        consumed = self._buttons[i]:updateHover(not consumed)
        isDirty = isDirty or self._buttons[i]:isDirty()
    end

    if isDirty then
        self._canvas:clear()
        for i=1,butCount do
            self._buttons[i]:render(self._canvas)
        end
    end
end

--- Event handler for mouse click events on the canvas
--- @param mPos Vec2F The mouse position of where the click occured
--- @param mBut integer Mouse* enum constant of the button pressed (0 = LMB, 1 = MMB, 2 = RMB, 3 & 4 = ???)
--- @param down boolean Whethere the button was pressed (true) or released (false)
function RadialMenu:onClick(mPos, mBut, down)
    for i=#self._buttons,1,-1 do
        local res = self._buttons[i]:click(mPos, mBut, down)
        if res then
            local action = self._config.options[i]
            if action == nil then break end

            local isAsync = self:sendInteraction(action, self._config.request)
            if isAsync then self:enableAll(false) end
            break
        end
    end
end

--- [Helper] Function to toggle enabled state of all buttons
--- @private
--- @param enabled boolean Whethere or not all buttons should be enabled
function RadialMenu:enableAll(enabled)
    for i=1,#self._buttons do
        self._buttons[i]:enable(enabled)
    end
end

--- Function to send a remote interaction request based on a given action configuration
--- @private
--- @param action table The action configuration
--- @return boolean # Whethere or not the action needs to wait asynchronously
function RadialMenu:sendInteraction(action, request)
    local target, seats = action.entityId, action.seats
    if target == nil then return false end
    if seats == nil then seats = 0 end

    local curPos, targetPos = world.entityPosition(request.sourceId), world.entityPosition(action.entityId)
    if curPos == nil or targetPos == nil then return false end

    local newDiff = {math.abs(curPos[1] - targetPos[1]), math.abs(curPos[2] - targetPos[2])}
    if newDiff[1] > 10 or newDiff[2] > 10 then return false end

    request.source = newDiff
    self._promises:add(world.sendEntityMessage(target, "Sexbound:Addon:Interact", request), function(res)
        local ret = self:handleInteractionResult(res, seats)
        if ret then pane.dismiss() else self:enableAll(true) end
    end, function(err)
        self:enableAll(true)
    end)

    return true
end

--- Function to handle the async response from a remote interaction request
--- @private
--- @param action string|[string, EntityId?, any]? The InteractAction data from onInteraction
--- @param seats integer The number of seats for faked "first free" lounge requests
--- @return boolean # Whethere or not the interaction was executed successfully
function RadialMenu:handleInteractionResult(action, seats)
    if action == nil then return true end

    local actionName, entityId, actionData = action[1], action[2], action[3]
    if entityId == nil then return false end

    if actionName == "SitDown" and actionData == -1 then
        for i=0,seats-1 do
            if player.lounge(entityId, i) then return true end
        end
        return false
    end

    player.interact(actionName, actionData, entityId)
    return true
end

-- [[ Global handlers ]]

local menu

--- Script Pane initialization callback
function init()
    menu = RadialMenu.new()
end

--- Function called each update tick (defined in pane config)
--- @param dt number The delta time since last tick
function update(dt)
    if menu then menu:update(dt) end
end

--- Canvas widget click event handler
--- @param mPos Vec2F Canvas coordinate where the click event occured
--- @param mBut string Mouse* name of the button affected
--- @param down boolean Whethere the button was pressed (down = true) or released (down = false)
function onClick(mPos, mBut, down)
    if menu then menu:onClick(mPos, mBut, down) end
end
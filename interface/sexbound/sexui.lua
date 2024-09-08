require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/messageutil.lua"

require "/scripts/sexbound/util.lua"

SexUI = {}
SexUI_mt = {
    __index = SexUI
}

require "/interface/sexbound/sexui/submodule/climax.lua"
require "/interface/sexbound/sexui/submodule/commands.lua"
require "/interface/sexbound/sexui/submodule/positions.lua"
require "/interface/sexbound/sexui/submodule/pov.lua"

--- Instantiantes a new instance.
-- @param config
function SexUI.new()
    local _self = setmetatable({
        _buttons = {main = {}, climax = {}, commands = {}, positions = {}, pov = {}},
        _canvas = widget.bindCanvas("interface"),
        _canvasRect = {0, 0, 258, 258},
        _config = config.getParameter("config"),
        _controllerId = pane.sourceEntity(),
        _debug = config.getParameter("config.debug") or false,
        _globalAlpha = 0,
        _positionLabel = {
            startPosition = config.getParameter("gui.positionLabel.position"),
            color = config.getParameter("gui.positionLabel.color"),
            previousValue = "",
            currentValue = ""
        },
        _timers = {},
        _timeouts = {
            fadeIn = config.getParameter("config.fadeInTimeout", 0.5),
            fadeOut = config.getParameter("config.fadeOutTimeout", 0.5),
            sync = config.getParameter("config.syncTimeout", 0.1)
        },
        _sexPositionsPage = 1,
        _updateTokens = {["positions"]=0},
        _ownerId = config.getParameter("config.ownerId", -65537)
    }, SexUI_mt)

    _self:resetTimers()

    _self:initSubmodules()

    widget.focus("interface")

    return _self
end

function SexUI:initSubmodules()
    self._subModules = {}
    self._subModules["climax"] = SexUI.Climax.new(self, self._config.climax)
    self._subModules["commands"] = SexUI.Commands.new(self, self._config.commands)
    self._subModules["positions"] = SexUI.Positions.new(self, self._config.positions)
    self._subModules["pov"] = SexUI.POV.new(self, self._config.pov)
end

function SexUI:dismiss()
    promises:add(world.sendEntityMessage(player.id(), "Sexbound:UI:Dismiss"), function(result)
        if result then
            pane.dismiss()
        end
    end)
end

--- Gradually increases the globalAlpha value to the value stored in fadeInAlpha.
function SexUI:fadeIn(dt)
    self._timers.fadeOut = 0

    self._timers.fadeIn = math.min(self._timeouts.fadeIn, self._timers.fadeIn + dt)

    local ratio = self._timers.fadeIn / self._timeouts.fadeIn

    self._globalAlpha = interp.linear(ratio, self._globalAlpha, 255)
end

--- Gradually decreases the globalAlpha value to 0.
function SexUI:fadeOut(dt)
    self._timers.fadeIn = 0

    self._timers.fadeOut = math.min(self._timeouts.fadeOut, self._timers.fadeOut + dt)

    local ratio = self._timers.fadeOut / self._timeouts.fadeOut

    self._globalAlpha = interp.linear(ratio, self._globalAlpha, 0)
end

function SexUI:forEachButton(callback, category)
    category = category or "all"
    for key, value in pairs(self._buttons) do
        if category == "all" or key == category then
            for key2, value2 in pairs(value) do
                callback(key2, value2)
            end
        end
    end
end

function SexUI:forEachSubmodule(callback)
    for name,submodule in pairs(self._subModules) do
        callback(name, submodule)
    end
end

function SexUI:update(dt)
    -- Dismiss this pane when player is no longer lounging.
    if not player.isLounging() then
        self:dismiss()
    end

    promises:update()

    self._timers.sync = self._timers.sync + dt

    if self._timers.sync >= self._timeouts.sync then
        self._timers.sync = 0

        self:syncUI()
    end

    -- Store the current mouse position within the canvas.
    self._mousePosition = self._canvas:mousePosition()
    self._mousePosition[1] = self._mousePosition[1] - 1

    -- If mouse cursor is within interface then fade-in, else fade-out.
    local offset = {171,21}
    local offsetRect = {self._canvasRect[1] + offset[1], self._canvasRect[2] + offset[2], self._canvasRect[3] + offset[1], self._canvasRect[4] + offset[2]}
    if self._mousePosition and rect.contains(offsetRect, self._mousePosition) then
        self:fadeIn(dt)
    else
        self:fadeOut(dt)
    end

    self._positionLabel.color[4] = self._globalAlpha
    widget.setFontColor("positionLabel", self._positionLabel.color)

    self:forEachSubmodule(function(_, submodule)
        submodule:update(dt)
    end)

    local highest

    self:forEachButton(function(_, button)
        button:update(dt, self._mousePosition)

        if button.isHovered then
            if highest ~= nil then
                if button:priority() > highest then
                    highest = button:priority()
                end
            else
                highest = button:priority()
            end
        end
    end)

    if highest ~= nil then
        self:forEachButton(function(_, button)
            if button:priority() < highest then
                button.isHovered = false
            end
        end)
    end

    self:render()
end

function SexUI:render()
    self._canvas:clear()

    self:forEachSubmodule(function(_, submodule)
        submodule:render()
    end)
    
    if self._debug then
        -- Render x-axis/y-axis reference
        self._canvas:drawLine({0,0},{10,0},{255,0,0,255},2)
        self._canvas:drawLine({0,0},{0,10},{0,255,0,255},2)
        
        local mousePos = self._canvas:mousePosition()
        if mousePos then
            -- Render actual current cursor hitbox
            local mX, mY = mousePos[1], mousePos[2]
            self._canvas:drawRect({mX-2,mY-1,mX,mY+1},{255,0,0,255})
        end
    end
end

function SexUI:resetTimers()
    self._timers = {
        fadeIn = 0,
        fadeOut = 0,
        sync = 0
    }
end

function SexUI:syncUI()
    promises:add(world.sendEntityMessage(self._controllerId, "Sexbound:UI:Sync", {tokens = self._updateTokens}), function(result)
        if not result then
            return
        end

        self._positionLabel.currentValue = result.position.friendlyName
        self._buttons.commands["commands_switchrole_prev"].config.enabled = result.position.switchingEnabled
        self._buttons.commands["commands_switchrole_next"].config.enabled = result.position.switchingEnabled

        if self._positionLabel.currentValue ~= self._positionLabel.previousValue then
            widget.setText("positionLabel", "^shadow;" .. result.position.friendlyName)
            widget.setPosition("positionLabel", self._positionLabel.startPosition)

            self._positionLabel.color[4] = 255
            self._positionLabel.previousValue = self._positionLabel.currentValue
        end

        self._subModules.pov:triggerUpdate(result.actors)
        self._subModules.pov:setAnimationRate(result.animationRate or 1)
        self._subModules.climax:updateProgressBars(result.actors)

        for _, actor in ipairs(result.actors) do
            local enabled = true
            if actor.isPlayer then enabled = actor.entityId == self._ownerId end
            
            self._buttons.commands["commands_togglebackwear_" .. actor.actorSlot].config.value = actor.showBackwear
            self._buttons.commands["commands_togglebackwear_" .. actor.actorSlot].config.enabled = enabled
            self._buttons.commands["commands_togglechestwear_" .. actor.actorSlot].config.value = actor.showChestwear
            self._buttons.commands["commands_togglechestwear_" .. actor.actorSlot].config.enabled = enabled
            self._buttons.commands["commands_toggleheadwear_" .. actor.actorSlot].config.value = actor.showHeadwear
            self._buttons.commands["commands_toggleheadwear_" .. actor.actorSlot].config.enabled = enabled
            self._buttons.commands["commands_togglelegswear_" .. actor.actorSlot].config.value = actor.showLegswear
            self._buttons.commands["commands_togglelegswear_" .. actor.actorSlot].config.enabled = enabled
        end
        
        if result.positions then
            self._subModules["positions"]:setPositions(result.positions.allPositions)
        end
    end)
end

function SexUI:getControllerId()
    return self._controllerId
end

function SexUI:getSubmodules(name)
    if name then
        return self._subModules[name]
    end

    return self._subModules
end

-------------------------------

function init()
    self.sexui = SexUI.new()
end

--- Handles canvas click event.
-- @param position
-- @param button
-- @param isButtonDown
function canvasClickEvent(position, button, isButtonDown)
    self.sexui:forEachButton(function(_, button)
        if button.isHovered and isButtonDown then
            return button:callAction(function(methodName, methodArgs)
                if _ENV[methodName] then
                    _ENV[methodName](methodArgs, button)
                end
            end)
        end
    end)
end

function update(dt)
    self.sexui:update(dt)
end

--- Commands the specific actor to try to begin a normal climax.
-- @params args
function doClimax(args, button)
    if self.sexui:getSubmodules("climax"):getProgressBars()[args.actorId].amount >= 0.5 then
        promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Actor:Climax", args),
            function(result)
                if result then
                    button:playSuccessSound()
                else
                    button:playFailureSound()
                end
            end)
    else
        button:playFailureSound()
    end
end

--- Commands the player to open a specified ScriptPane.
-- @params args
function doOpenScriptPane(args, button)
    player.interact("ScriptPane", args.config)
end

--- Commands all actors to try to begin a special climax.
-- @params args
function doSpecialClimax(args, button)
    local progressBars = self.sexui:getSubmodules("climax"):getProgressBars()

    if progressBars[args.actorSlots[1]].amount >= 1 and progressBars[args.actorSlots[2]].amount >= 1 then
        promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Actor:ScriptedClimax", args),
            function(result)
                if result then
                    button:playSuccessSound()
                else
                    button:playFailureSound()
                end
            end)
    else
        button:playFailureSound()
    end
end

--- Sends a message to the main controller to "switch sex positions".
-- @params args
function doSwitchPosition(args, button)
    local modArgs = copy(args)
    modArgs.positionId = modArgs.positionId + (8 * (self.sexui._sexPositionsPage - 1))
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Actor:SwitchPosition", modArgs),
        function(result)
            if result then
                button:playSuccessSound()
            else
                button:playFailureSound()
            end
        end)
end

--- Sends a message to the main controller to "switch actor roles".
-- @params args
function doSwitchRole(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Actor:SwitchRole", args),
        function(result)
            if result then
                button:playSuccessSound()
            else
                button:playFailureSound()
            end
        end)
end

--- Sends a message to the main controller to "switch backwear on / off".
-- @params args
function doToggleBackwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Backwear:Toggle", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            button.config.value = result
        end)
end

--- Sends a message to the main controller to "switch chestwear on / off".
-- @params args
function doToggleChestwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Chestwear:Toggle", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to next backwear variant"
function doNavigateNextBackwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Backwear:NextVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to next backwear variant"
function doNavigatePrevBackwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Backwear:PrevVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message tp the main controller to "navigate to next chestwear variant"
function doNavigateNextChestwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Chestwear:NextVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to next chestwear variant"
function doNavigatePrevChestwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Chestwear:PrevVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to next headwear variant"
function doNavigateNextHeadwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Headwear:NextVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to prev headwear variant"
function doNavigatePrevHeadwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Headwear:PrevVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to next legswear variant"
function doNavigateNextLegswear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Legswear:NextVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "navigate to next legswear variant"
function doNavigatePrevLegswear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Legswear:PrevVariant", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            -- button.config.value = result
        end)
end

--- Sends a message to the main controller to "switch headwear on / off".
-- @params args
function doToggleHeadwear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Headwear:Toggle", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            button.config.value = result
        end)
end

--- Sends a message to the main controller to "switch legswear on / off".
-- @params args
function doToggleLegswear(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Legswear:Toggle", args),
        function(result)
            if result == nil then
                button:playFailureSound()
                return
            end

            button:playSuccessSound()

            button.config.value = result
        end)
end

--- Toggles new page of positions to be shown
function doPositionPage(args, button)
    local ui = self.sexui
    local val = args.val or 0
    if val == 0 then return end
    
    if val < 0 then
        if ui._sexPositionsPage == 1 then
            button:playFailureSound()
            return
        end
        
        ui._sexPositionsPage = math.max((ui._sexPositionsPage + val), 1)
        ui._subModules["positions"]:refreshPositionButtons()
        button:playSuccessSound()
    else
        local max = ui._subModules["positions"]:getPositionCount() or 0
        local newPage = ui._sexPositionsPage + val
        local newOffset = 8 * (newPage - 1)
        
        if newOffset + 1 > max then
            button:playFailureSound()
            return
        end
        
        ui._sexPositionsPage = newPage
        ui._subModules["positions"]:refreshPositionButtons()
        button:playSuccessSound()
    end
end

--- Triggers idling for the actors
function doIdle(args, button)
    promises:add(world.sendEntityMessage(self.sexui:getControllerId(), "Sexbound:Actor:Idle", args),
        function(result)
            if result then
                button:playSuccessSound()
            else
                button:playFailureSound()
            end
        end)
end

--- Toggles a POV layer
function togglePovLayer(args, button)
    local ui = self.sexui
    local layer = args.layer or 1
    local buttonName = args.buttonName or 1
    
    ui._subModules["pov"]:toggleLayer(layer, buttonName)
    
    button:playSuccessSound()
end
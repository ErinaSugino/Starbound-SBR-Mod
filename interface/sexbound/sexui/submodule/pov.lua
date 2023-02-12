require "/interface/sexbound/sexui/submodule.lua"

SexUI.POV = SexUI.Submodule.new()
SexUI.POV_mt = {
    __index = SexUI.POV
}

SexUI.POV.Modules = {}

--- Instantiates a new instance
-- @param parant the parent instance
-- @param config a table of config options
function SexUI.POV.new(parent, config)
    local self = setmetatable({
        modules = {},
        layersEnabled = {},
        layerIDs = {},
        buttonOffset = 0
    }, SexUI.POV_mt)

    self:init(parent, config, "pov")
    
    self.canvas = widget.bindCanvas("pov")
    self.controls = widget.bindCanvas("povControls");
    
    local storedSettings = self._parent._config.layersEnabled or {}
    for i,s in pairs(storedSettings) do
        self.layersEnabled[i] = not not s
    end
    
    self:loadModules(config)
    
    return self
end

---
function SexUI.POV:loadModules(config)
    for i,mod in ipairs(config.modules or {}) do
        local name = mod.class
        local filename = string.lower(name)
        local icon = mod.icon or ""
        local offset = widget.getPosition("povControls")
        res,_ = pcall(require, '/interface/sexbound/sexui/submodule/pov/modules/'..filename..'.lua')
        if res then
            if SexUI.POV.Modules[name] and SexUI.POV.Modules[name].new then
                table.insert(self.modules, SexUI.POV.Modules[name].new(self, config))
                if self.layersEnabled[filename] == nil then self.layersEnabled[filename] = true end
                table.insert(self.layerIDs, filename)
                local buttonConfig = {
                    name = "Toggle Layer "..name,
                    key = "pov_module_"..filename,
                    enabled = true,
                    image = icon,
                    directives = "",
                    imageOffset = {0, 0},
                    hoverImage = "/interface/sexbound/sexui/submodule/pov/button_hover.png",
                    clickAction = {
                        method = "togglePovLayer",
                        args = {layer = i, name = filename}
                    },
                    poly = {{4, 1+self.buttonOffset}, {8, 1+self.buttonOffset}, {11, 4+self.buttonOffset}, {11, 8+self.buttonOffset}, {8, 11+self.buttonOffset}, {4, 11+self.buttonOffset}, {1, 8+self.buttonOffset}, {1, 4+self.buttonOffset}},
                    offset = offset,
                    hoverImagePosition = {5.5,5.5+self.buttonOffset}
                }
                local buttons = self._parent._buttons["pov"] or self._parent._buttons["main"]
                buttons[buttonConfig.key] = CustomButton.new(buttonConfig)
                self.buttonOffset = self.buttonOffset + 15
                sb.logInfo("Loaded module "..name)
                local butnum = 0
                for _,b in pairs(self._parent._buttons["pov"]) do butnum = butnum + 1 end
                sb.logInfo("Buttons: "..butnum)
            end
        end
    end
end

---
function SexUI.POV:toggleLayer(layer, buttonName)
    local isEnabled = self.layersEnabled[self.layerIDs[layer]]
    self.layersEnabled[self.layerIDs[layer]] = not self.layersEnabled[self.layerIDs[layer]]
    world.sendEntityMessage(player.id(), "Sexbound:UI:SyncSettings", self.layersEnabled)
end

--- Renders the animation parts managed by this instance
function SexUI.POV:render()
    self.canvas:clear()
    self.controls:clear()
    local called = false
    
    for i,mod in ipairs(self.modules) do
        if not called then 
            stat,res = pcall(function()
                if not self.layersEnabled[self.layerIDs[i]] or not mod:isAvailable() then return false end
                mod:render(self.canvas)
                return true
            end)
        end
        
        if stat and res then called = true end -- Only render the first available module
        
        if self.layersEnabled[self.layerIDs[i]] then self.controls:drawImage("/interface/sexbound/sexui/submodule/pov/button.png", {0, (0 + 15*(i-1))}, 1.0, self._config.color, false)
        else self.controls:drawImage("/interface/sexbound/sexui/submodule/pov/button_off.png", {0, (0 + 15*(i-1))}, 1.0, {255,255,255,255}, false) end
    end
    
    self:renderButtons(self.controls)
end

--- Updates this instance
-- @param dt
function SexUI.POV:update(dt)
    for _,mod in ipairs(self.modules) do
        pcall(function() mod:update(dt) end)
    end
end

--- Sends new sync update data to modules
-- @param a table of actors
function SexUI.POV:triggerUpdate(actors)
    for _,mod in ipairs(self.modules) do
        pcall(function() mod:triggerUpdate(actors) end)
    end
end

--- Sets animation rate to the specified value
-- @param animationRate a decimal number
function SexUI.POV:setAnimationRate(animationRate)
    self.animationRate = animationRate
end

--- Returns a reference to the UI canvas
function SexUI.POV:getCanvas()
    return self.canvas
end

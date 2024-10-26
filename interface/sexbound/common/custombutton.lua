require "/scripts/util.lua"

CustomButton = {}
CustomButton.__index = CustomButton

--- Instantiantes a new instance.
-- @param config
function CustomButton.new(...)
    local self = setmetatable({
        config = {
            enabled = true,
            debug = {
                boxColor = "blue",
                boxAltColor = "red",
                defaultBoxColor = "blue",
                boxLineWidth = 2,
                polyColor = "white",
                altPolyColor = "red",
                defaultPolyColor = "white",
                polyLineWidth = 2
            },
            priority = 0,
            failureSound = "/sfx/interface/clickon_error.ogg",
            successSound = "/sfx/interface/ship_confirm1.ogg",
            value = true,
            vertCount = 0,
            offset = {0,0}
        },
        isHovered = false,
        isWithinBBox = false,
        isWithinPoly = false
    }, CustomButton)
    self:init(...)
    return self
end

--- Initializes this instance.
-- @param config A Lua table
function CustomButton:init(config)
    self.config = util.mergeTable(self.config, config)

    -- Assumes at least one pair of coordinates is given.
    self.config.xmin = self.config.poly[1][1]
    self.config.ymin = self.config.poly[1][2]
    self.config.xmax = self.config.xmin
    self.config.ymax = self.config.ymin

    -- Precisely calculate the minimum and maximum verts.
    for _, v in ipairs(self.config.poly) do
        self.config.xmin = math.min(self.config.xmin, v[1])
        self.config.xmax = math.max(self.config.xmax, v[1])
        self.config.ymin = math.min(self.config.ymin, v[2])
        self.config.ymax = math.max(self.config.ymax, v[2])

        self.config.vertCount = self.config.vertCount + 1
    end

    self.config.boundingBox = {{self.config.xmin, self.config.ymin}, {self.config.xmin, self.config.ymax},
                               {self.config.xmax, self.config.ymax}, {self.config.xmax, self.config.ymin}}

    self.config.rect = {self.config.xmin, self.config.ymin, self.config.xmax, self.config.ymax}

    if self.config.image then
        self.config.imageOffset = self.config.imageOffset or {0, 0}

        self.config.imagePosition = vec2.add(rect.center(self.config.rect), self.config.imageOffset)
    end
end

--- Returns the coordinates of the bounding box.
function CustomButton:boundingBox()
    return self.config.boundingBox
end

--- Returns whether or not this instance's bounding box contains the specified point.
-- @param point
function CustomButton:boundingBoxContains(point)
    local debug = self.config.debug

    debug.boxColor = debug.defaultBoxColor
    debug.polyColor = debug.defaultPolyColor
    
    local offsetRect = {self.config.xmin + self.config.offset[1], self.config.ymin + self.config.offset[2], self.config.xmax + self.config.offset[1], self.config.ymax + self.config.offset[2]}

    if point[1] < offsetRect[1] or point[1] > offsetRect[3] or point[2] < offsetRect[2] or point[2] > offsetRect[4] then
        self.isWithinBBox = false
        self.isWithinPoly = false
        return false
    end

    self.isWithinBBox = true
    debug.boxColor = debug.boxAltColor
    return true
end

--- Calls the instance method. Returns the method's result.
function CustomButton:callAction(callback)
    local methodName = self.config.clickAction.method
    local methodArgs = self.config.clickAction.args

    if "function" == type(callback) then
        return callback(methodName, methodArgs)
    end

    return _ENV[methodName](methodArgs)
end

--- Draws the bounding box to the specified canvas.
-- @param canvas CanvasWidget
-- @param color[opt] i.e. red, green, blue..
function CustomButton:drawBoundingBox(canvas, color)
    local debug, boundingBox, j = self.config.debug, self.config.boundingBox
    color = color or debug.boxColor

    for i, v in ipairs(boundingBox) do
        j = util.wrap(i + 1, 1, 4)

        canvas:drawLine(v, boundingBox[j], color, debug.boxLineWidth)
    end
end

--- Draws the poly to the specified canvas.
-- @param canvas
-- @param color[opt] i.e. red, green, blue..
function CustomButton:drawPoly(canvas, color)
    local debug, poly, vertCount, j = self.config.debug, self.config.poly, self.config.vertCount
    color = color or debug.polyColor

    for i, v in ipairs(poly) do
        j = util.wrap(i + 1, 1, vertCount)

        canvas:drawLine(v, poly[j], color, debug.polyLineWidth)
    end
end

function CustomButton:directives()
    return self.config.directives or ""
end

function CustomButton:altImage()
    return self.config.altImage
end

function CustomButton:disabledImage()
    return self.config.disabledImage
end

function CustomButton:enabled()
    return self.config.enabled
end

function CustomButton:hoverImage()
    return self.config.hoverImage
end

function CustomButton:hoverImagePosition()
    return self.config.hoverImagePosition
end

function CustomButton:image()
    return self.config.image
end

function CustomButton:imagePosition()
    return self.config.imagePosition
end

function CustomButton:name()
    return self.config.name
end

function CustomButton:playFailureSound()
    widget.playSound(self.config.failureSound)
end

function CustomButton:playSuccessSound()
    widget.playSound(self.config.successSound)
end

function CustomButton:poly()
    return self.config.poly
end

function CustomButton:priority()
    return self.config.priority
end

function CustomButton:polyContains(point)
    local c, poly, j = false, self.config.poly, self.config.vertCount
    local vertx1, verty1, vertx2, verty2, pointx, pointy

    self.config.debug.polyColor = self.config.debug.defaultPolyColor

    for i = 1, self.config.vertCount do
        vertx1, verty1, vertx2, verty2 = poly[i][1] + self.config.offset[1], poly[i][2] + self.config.offset[2], poly[j][1] + self.config.offset[1], poly[j][2] + self.config.offset[2]
        pointx, pointy = point[1], point[2]

        if ((verty1 >= pointy) ~= (verty2 >= pointy)) and
            (pointx <= (vertx2 - vertx1) * (pointy - verty1) / (verty2 - verty1) + vertx1) then
            c = not c
        end

        j = i
    end

    if c then
        self.config.debug.polyColor = self.config.debug.altPolyColor
    end

    self.isWithinPoly = c

    return c;
end

function CustomButton:update(dt, mousePosition)
    self.isHovered = self:boundingBoxContains(mousePosition) and self:polyContains(mousePosition)
end

function CustomButton:render(canvas, color, debug)
    color = color or {255,255,255,255}
    if self:enabled() then
        -- Draw hover image first
        if self.isHovered and self:hoverImage() then
            canvas:drawImage(self:hoverImage(), self:hoverImagePosition() or {129, 129}, 1.0, {255, 255, 255, 128}, true)
        end
        
        if self:value() and self:image() then
            canvas:drawImage(self:image() .. self:directives(), self:imagePosition(), 1.0, color, true)
        elseif self:altImage() then
            canvas:drawImage(self:altImage() .. self:directives(), self:imagePosition(), 1.0, color, true)
        end
    else
        if self:disabledImage() then
            canvas:drawImage(self:disabledImage() .. self:directives(), self:imagePosition(), 1.0, color, true)
        end
    end

    -- Draw debug lines when enabled
    if debug then
        self:drawPoly(canvas)
        self:drawBoundingBox(canvas)
    end
end

function CustomButton:value()
    return self.config.value
end

function CustomButton:setNewImage(image, imageOffset)
    self.config.image = image or nil
    if image then
        self.config.imageOffset = imageOffset or {0, 0}

        self.config.imagePosition = vec2.add(rect.center(self.config.rect), self.config.imageOffset)
    else
        self.config.image = nil
    end
end

function CustomButton:setEnabled(enabled)
    self.config.enabled = not not enabled
end
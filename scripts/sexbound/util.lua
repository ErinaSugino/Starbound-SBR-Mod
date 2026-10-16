Sexbound = Sexbound or {}
--- Sexbound.Util Module.
--- @class Sexbound.Util
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Util = {}

--- Send a Radio Message to every player in the world.
--- @param messageId string Radio message id
--- @param unique boolean Is message unique (only shown once)?
--- @param text string Message content
Sexbound.Util.broadcastRadioMessage = function(messageId, unique, text)
    for _,entityId in ipairs(world.players() or {}) do
        world.sendEntityMessage(entityId, "queueRadioMessage", {
            messageId = messageId,
            unique = unique,
            text = text
        })
    end
end

--- Returns a properly formatted replace image directive for specified table of hex color codes.
--- @param colors table<string, string> A table of hex color codes
--- @return string # The ?replace directive
Sexbound.Util.colorMapToReplaceDirective = function(colors)
    if not colors or type(colors) ~= "table" then
        return ""
    end

    local directives = {}

    for k, v in pairs(colors) do
        table.insert(directives, tostring(k) .. "=" .. tostring(v))
    end

    return "?replace;" .. table.concat(directives, ";")
end

--- Returns whethere or not an entity with a given uuid is found in the world
--- @param uniqueId string A Unique ID as a string
--- @return boolean # If the entity was found or not
Sexbound.Util.findEntityWithUid = function(uniqueId)
    if world.findUniqueEntity(uniqueId):result() then return true end -- waits for async result

    return false
end

--- Crude attempt to verify if an image exists
--- @param filename string The file's path
--- @return boolean # Whethere or not an image of dimensions other than 64x64 exists
Sexbound.Util.imageExists = function(filename)
    if type(filename) ~= "string" or string.len(filename) == 0 then
        return false
    end

    -- Assume a 64 x 64 image is a missing sprite AKA. (/assetmissing.png)
    local imageSize = root.imageSize(filename)

    -- Return the default part image when an image asset is presumed to be missing
    return (imageSize[1] ~= 64 and imageSize[2] ~= 64)
end

--- Returns a parsed version number.
--- @param version string Version code
--- @return string operator Comparison operator
--- @return integer major The major version component
--- @return integer minor The minor version component
--- @return integer patch The patch version component
--- @return boolean old Whethere or not it's an old version number (old SxB)
Sexbound.Util.parseVersion = function(version)
    version = version:gsub('[xX]', '0') -- Replace x with 0

    local isOld = false
    local r,v1,v2,v3 = string.match(version, '^([<>=]*)(%d+)%.(%d+)_(.+)$') -- With revision appendix
    if v1 == nil and v2 == nil and v3 == nil then r,v1,v2,v3 = string.match(version, '^([<>=]*)(%d+)%.(%d+)$') end -- Without revision appendix
    if v1 == nil and v2 == nil and v3 == nil then
        -- No new version number. Check for old format.
        isOld = true
        r,v1,v2,v3 = string.match(version, '^([<>=]*)(%d+)%.(%d+)%.(%d+)$')
    end
    return r,v1,v2,v3,isOld
end

--- Returns a string where all specified arguments have been joined by specified character symbol.
--- @param symbol string An ASCII character
--- @param ... string The parts to join
--- @return string # The joined string
Sexbound.Util.join = function(symbol, ...)
    return table.concat({...}, symbol or ",")
end

--- Swaps two specified elements in an array in place
--- @param array table An array table.
--- @param index1 integer|string The first index
--- @param index2 integer|string The second index
Sexbound.Util.swap = function(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

--- Returns a when result is true, otherwise returns b.
--- @param condition boolean Condition evaluating to true or false
--- @param a any Any value for true
--- @param b any Any value for false
--- @return any # A or B whethere condition is true or false
Sexbound.Util.ternary = function(condition, a, b)
    if condition then
        return a
    else
        return b
    end
end

--- Disables tile protection based on position.
--- @param position Vec2I tile position
--- @return DungeonId? # Dungeon ID that was disabled or nil on failure
Sexbound.Util.tileProtectionDisable = function(position)
    if type(world.dungeonId) ~= "function" then
        return nil
    end
    if type(world.setTileProtection) ~= "function" then
        return nil
    end

    local dungeonId, protected = world.dungeonId(position), world.isTileProtected(position)

    -- Disable tile protection
    if protected and dungeonId then
        world.setTileProtection(dungeonId, false)

        return dungeonId
    end

    return nil
end

--- Enables tile protection based on position.
--- @param dungeonId DungeonId The dungeon ID to enable
Sexbound.Util.tileProtectionEnable = function(dungeonId)
    if dungeonId ~= nil then
        world.setTileProtection(dungeonId, true)
    end
end

--- Dumps a table into a printable string for debugging purposes
--- @param o table A table to print in string form
--- @return string # The dumped content
Sexbound.Util.dump = function(o)
    if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. Sexbound.Util.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

---Dumps a table into a printable string for debugging purposes, but only one layer deep
--- @param o table A table to print in string form
--- @return string # The dumped content
Sexbound.Util.shallowDump = function(o)
    if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. tostring(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

---Returns a random number [0;1] that is the CDF value of a normal distributed value
--- @return number # 0..1 RNG value, normal distribution
Sexbound.Util.normalDist = function()
    local x = math.random()
    local mu = 0.5
    local sd = 0.1
    local acc = 0.001

    local integral = function(f,start,stop,delta,...)
        local a = 0
        for i = start, stop, delta do
            a = a + f(i, ...) * delta
        end
        return a
    end

    local dist = function(x,mu,sd)
        return (1 / (sd * math.sqrt(2 * math.pi))) * math.exp(-(((x - mu) * (x - mu)) / (2 * sd^2)))
    end

    return 0 + (x > 0 and 1 or -1) * integral(dist, 0, x, acc, mu, sd)
end

--- Returns the input list but with all keys transformed to upper case
--- @param l table<string, any> Input list
--- @return table<string, any> # Transformed key list
Sexbound.Util.listToUpper = function(l)
    local r = {}
    if type(l) == "table" then for k,v in pairs(l) do r[string.upper(k)] = v end end
    return r
end

--- Returns rgb array from hex string
--- @param hex string Hex string of length 3, 4, 6 or 8
--- @return integer r The red component 0..255
--- @return integer g The green component 0..255
--- @return integer b The blue component 0..255
Sexbound.Util.hexToRgb = function(hex)
    local l = string.len(hex)
    if l==3 or l==4 then
        local r,g,b = hex:sub(1,1),hex:sub(2,2),hex:sub(3,3)
        local rv,gv,bv = tonumber(r,16) or 0,tonumber(g,16) or 0,tonumber(b,16) or 0
        return rv*16+rv, gv*16+gv, bv*16+bv
    else
        local r1,r2,g1,g2,b1,b2 = hex:sub(1,1),hex:sub(2,2),hex:sub(3,3),hex:sub(4,4),hex:sub(5,5),hex:sub(6,6)
        return (tonumber(r1,16) or 0)*16+(tonumber(r2,16) or 0), (tonumber(g1,16) or 0)*16+(tonumber(g2,16) or 0), (tonumber(b1,16) or 0)*16+(tonumber(b2,16) or 0)
    end
end

--- Returns rgba array from hex string
--- @param hex string Hex string of length 3, 4, 6 or 8
--- @return integer r The red component 0..255
--- @return integer g The green component 0..255
--- @return integer b The blue component 0..255
--- @return integer a The alpha channel 0..255
Sexbound.Util.hexToRgba = function(hex)
    local l = string.len(hex)
    if l==3 or l==4 then
        local r,g,b,a = hex:sub(1,1),hex:sub(2,2),hex:sub(3,3),hex:sub(4,4)
        local rv,gv,bv,av = tonumber(r,16) or 0,tonumber(g,16) or 0,tonumber(b,16) or 0,255
        if av~="" then av = tonumber(a,16) or 0 end
        return rv*16+rv, gv*16+gv, bv*16+bv, av*16+av
    else
        local r1,r2,g1,g2,b1,b2,a1,a2 = hex:sub(1,1),hex:sub(2,2),hex:sub(3,3),hex:sub(4,4),hex:sub(5,5),hex:sub(6,6),hex:sub(7,7),hex:sub(8,8)
        if a1=="" then a1 = "F" end
        if a2=="" then a2 = "F" end
        return (tonumber(r1,16) or 0)*16+(tonumber(r2,16) or 0), (tonumber(g1,16) or 0)*16+(tonumber(g2,16) or 0), (tonumber(b1,16) or 0)*16+(tonumber(b2,16) or 0), (tonumber(a1,16) or 0)*16+(tonumber(a2,16) or 0)
    end
end

--- Returns hex string from rgb array
--- @param rgb table<integer, integer> The RGB value array
--- @return string hex The hex string of length 6
Sexbound.Util.rgbToHex = function(rgb)
    local r,g,b = rgb[1] or 0,rgb[2] or 0,rgb[3] or 0
    return string.format("%.2x",r)..string.format("%.2x",g)..string.format("%.2x",b)
end

--- Returns hex string from rgba array
--- @param rgba table<integer, integer> The RGBA value array
--- @return string hex The hex string of length 8
Sexbound.Util.rgbaToHex = function(rgba)
    local r,g,b,a = rgba[1] or 0,rgba[2] or 0,rgba[3] or 0,rgba[4] or 255
    return string.format("%.2x",r)..string.format("%.2x",g)..string.format("%.2x",b)..string.format("%.2x", a)
end

--- Returns hex string from rgba array with alpha channel only when not 255
--- @param rgba table<integer, integer> The RGBA value array
--- @return string hex The hex string of length 6 or 8
Sexbound.Util.rgbaToHex6 = function(rgba)
    local r,g,b,a = rgba[1] or 0,rgba[2] or 0,rgba[3] or 0,rgba[4] or 255
    local res = string.format("%.2x",r)..string.format("%.2x",g)..string.format("%.2x",b)
    if a ~= 255 then res = res..string.format("%.2x", a) end
    return res
end

--- Returns path string with dangerous // removed
--- @param s string? Input string
--- @return string? # Input string without //
Sexbound.Util.fixPath = function(s)
    if type(s) ~= "string" then return s end

    local i = 1
    while i > 0 do
        s,i = string.gsub(s,"//","/")
    end

    return s
end

--- Return hex string zerofilled to six digits
--- @param num number|string Number or string input
--- @param l integer Length to zerofill
--- @return string # Number string of at least l digits
Sexbound.Util.zerofill = function(num, l)
    if type(l) ~= "number" or l <= 0 then l = 6 end
    num = tostring(num)
    if string.len(num) < l then
        while string.len(num) < l do
            num = "0"..num
        end
    end
    return num
end

--- Returns table with all indices string encoded, so that Starbound doesn't magically change values on entity messaging
--- @param t table Input table
--- @return table # Encoded table
Sexbound.Util.messageEncode = function(t)
    if type(t) ~= "table" or not next(t) then return {} end
    
    local r = {}
    for k,v in pairs(t) do
        r[k.."X"] = v
    end
    return r
end

--- Return table with all indices decoded, ensuring Starbound didn't magically change values on entity messaging
--- @param t table Encoded input table
--- @return table # Decoded table
Sexbound.Util.messageDecode = function(t)
    if type(t) ~= "table" or not next(t) then return {} end
    
    local r = {}
    for k,v in pairs(t) do
        k = tostring(k)
        local l = string.len(k)
        if l > 1 then r[string.sub(k,1,l-1)] = v end
    end
    return r
end
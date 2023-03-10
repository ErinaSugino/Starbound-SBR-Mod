--- Sexbound.Util Module.
-- @module Sexbound.Util
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound = Sexbound or {}
Sexbound.Util = {}

--- Send a Radio Message to every player in the world.
-- @param messageId
-- @param unique
-- @param text
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
-- @param colors A table of hex color codes
-- @usage Sexbound.Util.colorMapToReplaceDirective({["ff0000"] = "0000ff", ["00ff00"] = "ff0000", ["0000ff"] = "00ff00"})
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

--- Returns an entity's world position when it is found with the specified unique ID. Otherwise, false is returned.
-- @param uniqueId A Unique ID as a string
-- @usage local position = Sexbound.Util.findEntityWithUid("sexbound")
Sexbound.Util.findEntityWithUid = function(uniqueId)
    if world.findUniqueEntity(uniqueId):result() then return true end -- waits for async result

    return false
end

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
-- @param version
-- @usage Sexbound.Util.parseVersion(">=5.0.0")
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
-- @param symbol An ASCII character
-- @param[opt] string1 A string
-- @param[optchain] string2 A string
-- @usage Sexbound.Util.join("-", "sex", "bound")
-- @usage Sexbound.Util.join(" ", "powering", "sex", "in", "starbound")
Sexbound.Util.join = function(symbol, ...)
    return table.concat({...}, symbol or ",")
end

--- Swaps two specified elements in an array.
-- @param array a Table.
-- @param index1
-- @param index2
Sexbound.Util.swap = function(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

---Returns a when result is true, otherwise returns b.
-- @param result Boolean value.
-- @param a Any value
-- @param b Any value
-- @usage local val = Sexbound.Util.ternary(1 < 2, "Success", "Failure")
Sexbound.Util.ternary = function(result, a, b)
    if result then
        return a
    else
        return b
    end
end

---Disables tile protection based on position.
-- @param position Table value.
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

---Enables tile protection based on position.
-- @param dungeonId Table value.
Sexbound.Util.tileProtectionEnable = function(dungeonId)
    if dungeonId ~= nil then
        world.setTileProtection(dungeonId, true)
    end
end

---Dumps a table into a printable string for debugging purposes
-- @param o Table value
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
-- @param o Table value
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
-- @return Number
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

---Returns the input list but with all keys transformed to upper case
-- @param list
-- @return listB
Sexbound.Util.listToUpper = function(l)
    local r = {}
    if type(l) == "table" then for k,v in pairs(l) do r[string.upper(k)] = v end end
    return r
end

---Returns rgb array from hex string
-- @param hexString
-- @return rgb
Sexbound.Util.hexToRgb = function(hex)
    return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
end

---Returns hex string from rgb array
-- @param rgb
-- @return hexString
Sexbound.Util.rgbToHex = function(rgb)
    local r,g,b = rgb[1],rgb[2],rgb[3]
    return string.format("%x",r*255)..string.format("%x",g*255)..string.format("%x",b*255)
end
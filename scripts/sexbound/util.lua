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
-- @param hexString(3|4|6|8)
-- @return rgb
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

---Returns rgba array from hex string
-- @param hexString(3|4|6|8)
-- @return rgba
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

---Returns hex string from rgb array
-- @param rgb
-- @return hexString(6)
Sexbound.Util.rgbToHex = function(rgb)
    local r,g,b = rgb[1] or 0,rgb[2] or 0,rgb[3] or 0
    return string.format("%.2x",r)..string.format("%.2x",g)..string.format("%.2x",b)
end

---Returns hex string from rgba array
-- @param rgba
-- @return hexString(8)
Sexbound.Util.rgbaToHex = function(rgba)
    local r,g,b,a = rgba[1] or 0,rgba[2] or 0,rgba[3] or 0,rgba[4] or 255
    return string.format("%.2x",r)..string.format("%.2x",g)..string.format("%.2x",b)..string.format("%.2x", a)
end

---Returns hex string from rgba array with alpha channel only when not 255
-- @param rgba
-- @return hexString(6|8)
Sexbound.Util.rgbaToHex6 = function(rgba)
    local r,g,b,a = rgba[1] or 0,rgba[2] or 0,rgba[3] or 0,rgba[4] or 255
    local res = string.format("%.2x",r)..string.format("%.2x",g)..string.format("%.2x",b)
    if a ~= 255 then res = res..string.format("%.2x", a) end
    return res
end
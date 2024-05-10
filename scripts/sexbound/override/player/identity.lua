require "/scripts/sexbound/override/common/identity.lua"

Sexbound.Player.Identity = Sexbound.Common.Identity:new()
Sexbound.Player.Identity_mt = {
    __index = Sexbound.Player.Identity
}

function Sexbound.Player.Identity:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.Identity_mt)

    _self:init(parent)

    return _self
end

--- Returns a table consisting of identifying information about the entity.
-- @param portraitData
function Sexbound.Player.Identity:build(target, portraitData)
    local identity = {
        gender = player.gender() or "male",
        species = player.species() or "human",
        name = world.entityName(entity.id()) or "",
        bodyDirectives = "",
        emoteDirectives = "",
        facialHairDirectives = "",
        facialHairFolder = "",
        facialHairGroup = "",
        facialHairType = "",
        facialMaskDirectives = "",
        facialMaskFolder = "",
        facialMaskGroup = "",
        facialMaskType = "",
        hairFolder = "hair",
        hairGroup = "hair",
        hairType = "1",
        hairDirectives = ""
    }
    
    local speciesConfig = {}
    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. identity.species .. ".species")
    end) then
        sb.logWarn("SxB: Could not find species config file.")
    end

    identity = self:addCustomProperties(identity, speciesConfig)

    util.each(world.entityPortrait(player.id(), "full"), function(k, v)
        -- Attempt to find facial mask
        if identity.facialMaskGroup ~= nil and identity.facialMaskGroup ~= "" and
            string.find(v.image, "/" .. identity.facialMaskGroup) ~= nil then
            identity.facialMaskFolder, identity.facialMaskType =
                string.match(v.image, '^.*/(' .. identity.facialMaskGroup .. '.*)/(.*)%.png:.-$')
            identity.facialMaskDirectives = self:filterReplace(v.image)
        end

        -- Attempt to find facial hair
        if identity.facialHairGroup ~= nil and identity.facialHairGroup ~= "" and
            string.find(v.image, "/" .. identity.facialHairGroup) ~= nil then
            identity.facialHairFolder, identity.facialHairType =
                string.match(v.image, '^.*/(' .. identity.facialHairGroup .. '.*)/(.*)%.png:.-$')
            identity.facialHairDirectives = self:filterReplace(v.image)
        end

        -- Attempt to find body identity
        if (string.find(v.image, "body.png") ~= nil) then
            identity.bodyDirectives = string.match(v.image, '%?replace.*')
        end

        -- Attempt to find emote identity
        if (string.find(v.image, "emote.png") ~= nil) then
            identity.emoteDirectives = self:filterReplace(v.image)
        end

        -- Attempt to find hair identity
        if (string.find(v.image, "/hair") ~= nil) then
            identity.hairFolder, identity.hairType = string.match(v.image, '^.*/(hair.*)/(.*)%.png:.-$')

            identity.hairDirectives = self:filterReplace(v.image)
        end
    end)
    
    local altOptionAsUndyColor = not not speciesConfig.altOptionAsUndyColor
    local headOptionAsHairColor = not not speciesConfig.headOptionAsHairColor
    
    -- Separate directives string into individual color pairs
    identity.genetics.bodyColor = {}
    identity.genetics.bodyColorAverage = {0,0,0}
    identity.genetics.undyColor = {}
    identity.genetics.undyColorAverage = {0,0,0}
    identity.genetics.hairColor = {}
    identity.genetics.hairColorAverage = {0,0,0}
    
    local res,err = pcall(function()
        local bodyColors = {}
        if string.match(identity.bodyDirectives, "^%?replace;") then
            -- Expecting normal Starbound Syntax
            for r in string.gmatch(identity.bodyDirectives, "%?replace;([^?]+);?") do table.insert(bodyColors, r) end
            local l = #bodyColors
            if l > 0 then
                -- If nothing extracted - no color can be retrieved
                for k,v in string.gmatch(bodyColors[1], "(%w+)=(%w+);?") do identity.genetics.bodyColor[string.upper(k).."X"] = v end
                -- Undy color only exists if altOptionAsUndyColor is true, and should be at the end of the body directives
                if altOptionAsUndyColor and l > 1 then for k,v in string.gmatch(bodyColors[l], "(%w+)=(%w+);?") do identity.genetics.undyColor[string.upper(k).."X"] = v end end -- If length < 2 we only have body colors
            end
        elseif string.match(identity.bodyDirectives, "^%?replace=") then
            -- Expecting old Starbound Syntax where every value has it's own replace
            local ref, ref2
            local i = 1
            -- Fetch valid reference palette
            while not ref and identity.genetics.bodyColorPool[i] do
                if identity.genetics.bodyColorPoolAverage[i][1] >= 0 then ref = Sexbound.Util.listToUpper(identity.genetics.bodyColorPool[i]) end
                i = i + 1
            end
            i = 1
            while not ref2 and identity.genetics.undyColorPool[i] do
                if identity.genetics.undyColorPoolAverage[i][1] >= 0 then ref2 = Sexbound.Util.listToUpper(identity.genetics.undyColorPool[i]) end
                i = i + 1
            end
            
            for k,v in string.gmatch(identity.bodyDirectives, "%?replace=(%w+)=(%w+);?") do
                local compare = string.upper(k)
                if ref[compare] then identity.genetics.bodyColor[compare.."X"] = v end
                if altOptionAsUndyColor and ref2[compare] then identity.genetics.undyColor[compare.."X"] = v end
            end
        end
        -- Hair colors only exist if headOptionAsHairColor is true
        if headOptionAsHairColor then
            local hairColors = {}
            if string.match(identity.hairDirectives, "^%?replace;") then
                for r in string.gmatch(identity.hairDirectives, "%?replace;([^?]+);?") do table.insert(hairColors, r) end
                local l = #hairColors
                if l > 0 then
                    -- If nothing extracted - no color can be retrieved
                    for k,v in string.gmatch(hairColors[1], "(%w+)=(%w+);?") do identity.genetics.hairColor[string.upper(k).."X"] = v end
                end
            elseif string.match(identity.hairDirectives, "^%?replace=") then
                local ref
                local i = 1
                -- Fetch valid reference palette
                while not ref and identity.genetics.hairColorPool[i] do
                    if identity.genetics.hairColorPoolAverage[i][1] >= 0 then ref = Sexbound.Util.listToUpper(identity.genetics.hairColorPool[i]) end
                    i = i + 1
                end
                
                for k,v in string.gmatch(identity.hairDirectives, "%?replace=(%w+)=(%w+);?") do
                    local compare = string.upper(k)
                    if ref[compare] then identity.genetics.hairColor[compare.."X"] = v end
                end
            end
        end
    end)
    if not res and self._parent:canLog("warn") then sb.logWarn("[SxB | GENE] - Couldn't fetch entity colors! Entity "..entity.id().." has no colors!") sb.logWarn(err) end
    
    -- Pre calculate color palette averages
    local x = 0
    for i,v in pairs(identity.genetics.bodyColor) do
        x = x + 1
        local r,g,b = Sexbound.Util.hexToRgb(v)
        identity.genetics.bodyColorAverage[1],identity.genetics.bodyColorAverage[2],identity.genetics.bodyColorAverage[3] = identity.genetics.bodyColorAverage[1]+r,identity.genetics.bodyColorAverage[2]+g,identity.genetics.bodyColorAverage[3]+b
    end
    identity.genetics.bodyColorAverage[1],identity.genetics.bodyColorAverage[2],identity.genetics.bodyColorAverage[3] = math.floor(identity.genetics.bodyColorAverage[1]/x),math.floor(identity.genetics.bodyColorAverage[2]/x),math.floor(identity.genetics.bodyColorAverage[3]/x)
    x = 0
    for i,v in pairs(identity.genetics.undyColor) do
        x = x + 1
        local r,g,b = Sexbound.Util.hexToRgb(v)
        identity.genetics.undyColorAverage[1],identity.genetics.undyColorAverage[2],identity.genetics.undyColorAverage[3] = identity.genetics.undyColorAverage[1]+r,identity.genetics.undyColorAverage[2]+g,identity.genetics.undyColorAverage[3]+b
    end
    identity.genetics.undyColorAverage[1],identity.genetics.undyColorAverage[2],identity.genetics.undyColorAverage[3] = math.floor(identity.genetics.undyColorAverage[1]/x),math.floor(identity.genetics.undyColorAverage[2]/x),math.floor(identity.genetics.undyColorAverage[3]/x)
    x = 0
    for i,v in pairs(identity.genetics.hairColor) do
        x = x + 1
        local r,g,b = Sexbound.Util.hexToRgb(v)
        identity.genetics.hairColorAverage[1],identity.genetics.hairColorAverage[2],identity.genetics.hairColorAverage[3] = identity.genetics.hairColorAverage[1]+r,identity.genetics.hairColorAverage[2]+g,identity.genetics.hairColorAverage[3]+b
    end
    identity.genetics.hairColorAverage[1],identity.genetics.hairColorAverage[2],identity.genetics.hairColorAverage[3] = math.floor(identity.genetics.hairColorAverage[1]/x),math.floor(identity.genetics.hairColorAverage[2]/x),math.floor(identity.genetics.hairColorAverage[3]/x)
    
    sb.logInfo("Entity colors:")
    sb.logInfo(sb.print(identity.genetics.bodyColor))
    sb.logInfo(sb.print(identity.genetics.undyColor))
    sb.logInfo(sb.print(identity.genetics.hairColor))

    return identity
end

require "/scripts/sexbound/override/common/identity.lua"

Sexbound.NPC.Identity = Sexbound.Common.Identity:new()
Sexbound.NPC.Identity_mt = {
    __index = Sexbound.NPC.Identity
}

function Sexbound.NPC.Identity:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.NPC.Identity_mt)

    _self:init(parent)

    return _self
end

--- Returns a table consisting of identifying information about the entity.
function Sexbound.NPC.Identity:build()
    local identity = npc.humanoidIdentity()
    
    local speciesConfig = {}
    -- Attempt to read configuration from species config file.
    if not pcall(function()
        speciesConfig = root.assetJson("/species/" .. identity.species .. ".species")
    end) then
        sb.logWarn("SxB: Could not find species config file.")
    end
 
    local identity = self:addCustomProperties(identity, speciesConfig)
    
    local altOptionAsUndyColor = not not speciesConfig.altOptionAsUndyColor
    local headOptionAsHairColor = not not speciesConfig.headOptionAsHairColor
    
    -- Separate directives string into individual color pairs
    local bodyColors = {}
    for r in string.gmatch(identity.bodyDirectives, "?replace;([^?]+);?") do table.insert(bodyColors, r) end
    local hairColors = {}
    for r in string.gmatch(identity.hairDirectives, "?replace;([^?]+);?") do table.insert(hairColors, r) end
    
    identity.genetics.bodyColor = {}
    identity.genetics.bodyColorAverage = {0,0,0}
    identity.genetics.undyColor = {}
    identity.genetics.undyColorAverage = {0,0,0}
    identity.genetics.hairColor = {}
    identity.genetics.hairColorAverage = {0,0,0}
    
    for k,v in string.gmatch(bodyColors[1], "(%w+)=(%w+);?") do identity.genetics.bodyColor[string.upper(k)] = v end
    if altOptionAsUndyColor then for k,v in string.gmatch(bodyColors[#bodyColors], "(%w+)=(%w+);?") do identity.genetics.undyColor[string.upper(k)] = v end end
    if headOptionAsHairColor then for k,v in string.gmatch(hairColors[1], "(%w+)=(%w+);?") do identity.genetics.hairColor[string.upper(k)] = v end end
    
    -- Pre calculate color palette averages
    local x = 0
    for i,v in pairs(identity.genetics.bodyColor) do
        x = x + 1
        local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
        identity.genetics.bodyColorAverage[1],identity.genetics.bodyColorAverage[2],identity.genetics.bodyColorAverage[3] = identity.genetics.bodyColorAverage[1]+r,identity.genetics.bodyColorAverage[2]+g,identity.genetics.bodyColorAverage[3]+b
    end
    identity.genetics.bodyColorAverage[1],identity.genetics.bodyColorAverage[2],identity.genetics.bodyColorAverage[3] = math.floor(identity.genetics.bodyColorAverage[1]/x),math.floor(identity.genetics.bodyColorAverage[2]/x),math.floor(identity.genetics.bodyColorAverage[3]/x)
    x = 0
    for i,v in pairs(identity.genetics.undyColor) do
        x = x + 1
        local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
        identity.genetics.undyColorAverage[1],identity.genetics.undyColorAverage[2],identity.genetics.undyColorAverage[3] = identity.genetics.undyColorAverage[1]+r,identity.genetics.undyColorAverage[2]+g,identity.genetics.undyColorAverage[3]+b
    end
    identity.genetics.undyColorAverage[1],identity.genetics.undyColorAverage[2],identity.genetics.undyColorAverage[3] = math.floor(identity.genetics.undyColorAverage[1]/x),math.floor(identity.genetics.undyColorAverage[2]/x),math.floor(identity.genetics.undyColorAverage[3]/x)
    x = 0
    for i,v in pairs(identity.genetics.hairColor) do
        x = x + 1
        local r,g,b = tonumber(v:sub(1,2), 16), tonumber(v:sub(3,4), 16), tonumber(v:sub(5,6), 16)
        identity.genetics.hairColorAverage[1],identity.genetics.hairColorAverage[2],identity.genetics.hairColorAverage[3] = identity.genetics.hairColorAverage[1]+r,identity.genetics.hairColorAverage[2]+g,identity.genetics.hairColorAverage[3]+b
    end
    identity.genetics.hairColorAverage[1],identity.genetics.hairColorAverage[2],identity.genetics.hairColorAverage[3] = math.floor(identity.genetics.hairColorAverage[1]/x),math.floor(identity.genetics.hairColorAverage[2]/x),math.floor(identity.genetics.hairColorAverage[3]/x)
    
    return identity
end

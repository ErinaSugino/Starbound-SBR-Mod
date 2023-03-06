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
    local identity = self:addCustomProperties(npc.humanoidIdentity())
    
    --[[-- Fetch current color palette "genes" of entity
    local directives = identity.bodyDirectives..identity.hairDirectives
    local presets = {Sexbound.Util.listToUpper(identity.genetics.bodyColorPool[1]), Sexbound.Util.listToUpper(identity.genetics.undyColorPool[1]), Sexbound.Util.listToUpper(identity.genetics.hairColorPool[1])}
    
    -- Separate directives string into individual color pairs
    local result, i = {}, 0
    for r in string.gmatch(directives, "?replace;([^?]+);?") do
        i = i + 1
        local res = {}
        for k,v in string.gmatch(r, "(%w+)=(%w+);?") do res[string.upper(k)] = v end
        table.insert(result, res)
        if i == 3 then break end
    end
    
    identity.genetics.bodyColor = {}
    identity.genetics.bodyColorAverage = {0,0,0}
    identity.genetics.undyColor = {}
    identity.genetics.undyColorAverage = {0,0,0}
    identity.genetics.hairColor = {}
    identity.genetics.hairColorAverage = {0,0,0}
    
    -- Match only values that exists in the species template
    for k,v in pairs(result[1]) do if presets[1][k] then identity.genetics.bodyColor[k] = v end end
    for k,v in pairs(result[2]) do if presets[2][k] then identity.genetics.undyColor[k] = v end end
    for k,v in pairs(result[3]) do if presets[3][k] then identity.genetics.hairColor[k] = v end end
    
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
    identity.genetics.hairColorAverage[1],identity.genetics.hairColorAverage[2],identity.genetics.hairColorAverage[3] = math.floor(identity.genetics.hairColorAverage[1]/x),math.floor(identity.genetics.hairColorAverage[2]/x),math.floor(identity.genetics.hairColorAverage[3]/x)]]
    
    return identity
end

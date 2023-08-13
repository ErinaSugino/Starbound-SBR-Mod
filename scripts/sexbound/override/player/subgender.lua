require "/scripts/sexbound/override/common/subgender.lua"

Sexbound.Player.SubGender = Sexbound.Common.SubGender:new()
Sexbound.Player.SubGender_mt = {
    __index = Sexbound.Player.SubGender
}

function Sexbound.Player.SubGender:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Player.SubGender_mt)
    
    _self:init()
    
    return _self
end

function Sexbound.Player.SubGender:handleSxbSubGenderChange(args)
    local sxbSubGenderName = args
    if self:passesGenderRestriction(sxbSubGenderName, self:getParent():getGender()) then self:setSxbSubGender(sxbSubGenderName) self:notifyPlayerAboutSubGenderChange(sxbSubGenderName) end
    return self:getSxbSubGender()
end

function Sexbound.Player.SubGender:notifyPlayerAboutSubGenderChange(sxbSubGenderName)
    local text = self:generateTextNotification(sxbSubGenderName)

    if text == nil then
        return
    end

    world.sendEntityMessage(player.id(), "queueRadioMessage", {
        messageId = "SubGender:Change",
        unique = false,
        text = text
    })
end

function Sexbound.Player.SubGender:generateTextNotification(sxbSubGenderName)
    local notifications = self:getParent():getNotifications() or {}
    notifications = notifications.events or {}
    notifications = notifications.genderchange or {}
    
    local text
    
    if sxbSubGenderName == nil then text = notifications[sxbSubGenderName] or notifications["none"] -- Revert to default
    else text = notifications[sxbSubGenderName] or notifications["default"] end -- Change sub-gender

    return text
end

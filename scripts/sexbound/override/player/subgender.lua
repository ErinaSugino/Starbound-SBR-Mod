require "/scripts/sexbound/override/common/subgender.lua"

--- Player sub-gender manager class
--- @class Sexbound.Player.SubGender: Sexbound.Common.SubGender
--- @author Locuturus
--- @author Erina Sugino
--- @license GNU General Public License v3.0
Sexbound.Player.SubGender = Sexbound.Common.SubGender:new()
Sexbound.Player.SubGender_mt = {
    __index = Sexbound.Player.SubGender
}

--- Creates new player sub-gender manager instance
--- @param parent Sexbound.Player The calling parent player manager instance
--- @return Sexbound.Player.SubGender # The newly created player sub-gender manager instance
function Sexbound.Player.SubGender:new(parent)
    local _self = setmetatable({}, Sexbound.Player.SubGender_mt)

    _self:init(parent)

    return _self
end

--- Message handler override for sub-gender change
--- @param args string The name of the new sub-gender
--- @return string? # The currently set sub-gender for success verification
function Sexbound.Player.SubGender:handleSxbSubGenderChange(args)
    local sxbSubGenderName = args
    if self:passesGenderRestriction(sxbSubGenderName, self:getParent():getGender()) then self:setSxbSubGender(sxbSubGenderName) self:notifyPlayerAboutSubGenderChange(sxbSubGenderName) end
    return self:getSxbSubGender()
end

--- Sends the player a radio message notifying about a sub-gender change
--- @param sxbSubGenderName string? The new sub-gender
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

--- Generates the notification text for a potential sub-gender change
--- @param sxbSubGenderName string? The name of the new sub-gender
--- @return string? # The generated notification, if any
function Sexbound.Player.SubGender:generateTextNotification(sxbSubGenderName)
    local notifications = self:getParent():getNotifications() or {}
    notifications = notifications.events or {}
    notifications = notifications.genderchange or {}

    local text

    if sxbSubGenderName == nil then text = notifications[sxbSubGenderName] or notifications["none"] -- Revert to default
    else text = notifications[sxbSubGenderName] or notifications["default"] end -- Change sub-gender

    return text
end

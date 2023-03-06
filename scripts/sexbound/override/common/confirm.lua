require "/scripts/util.lua"

Sexbound.Common.Confirm = {}
Sexbound.Common.Confirm_mt = {
    __index = Sexbound.Common.Confirm
}

function Sexbound.Common.Confirm:new(parent)
    local _self = setmetatable({
        _parent = parent
    }, Sexbound.Common.Confirm_mt)

    message.setHandler("Sexbound:UI:Confirm", function(_, _, args)
        _self:handleChoice(args)
    end)

    return _self
end

function Sexbound.Common.Confirm:build(config)
    local paneLayout = util.split(config.paneLayout, ":")
    local configFile = root.assetJson(paneLayout[1])
    local paneLayoutConfig

    if paneLayout[2] ~= nil then
        paneLayoutConfig = configFile[paneLayout[2]]
    else
        paneLayoutConfig = configFile
    end

    local newConfig = {
        gui = paneLayoutConfig,
        scripts = {"/interface/sexbound/confirmation.lua"},
        scriptDelta = 60,
        scriptWidgetCallbacks = {"cancel", "confirm"}
    }

    local windowtitle = newConfig.gui.windowtitle or {}
    windowtitle.icon.file = config.icon or windowtitle.icon.file
    windowtitle.title = config.title or windowtitle.title
    windowtitle.subtitle = config.subtitle or windowtitle.subtitle

    local message = newConfig.gui.message or {}
    message.value = config.message or message.value

    local buttonOk = newConfig.gui.ok or {}
    buttonOk.caption = config.okCaption or buttonOk.caption

    local buttonCancel = newConfig.gui.cancel or {}
    buttonCancel.caption = config.cancelCaption or buttonCancel.caption

    local portrait = newConfig.gui.portrait or {}
    portrait.file = config.portrait or portrait.file

    return newConfig
end

function Sexbound.Common.Confirm:handleChoice(args)

end

Sexbound.Player.Legal = {}
Sexbound.Player.Legal_mt = {
    __index = Sexbound.Player.Legal
}

function Sexbound.Player.Legal:new(parent)
    local _self = setmetatable({
        _parent = parent,
        _uninstallMessageTimeout = 10
    }, Sexbound.Player.Legal_mt)

    _self._requirePlayerAgeVerification = parent:getConfig().requirePlayerAgeVerification or false

    _self._timer = _self._uninstallMessageTimeout

    return _self
end

function Sexbound.Player.Legal:verify()
    if storage.sexboundConfig.isLegal == true then
        return
    end

    -- Nil out the value incase players mistakenly responded the previous time
    storage.sexboundConfig.isLegal = nil

    if not self._requirePlayerAgeVerification then
        self:passed()
        return
    end

    promises:add(player.confirm(root.assetJson("/interface/sexbound/confirmation/legal.config")), function(choice)
        storage.sexboundConfig.isLegal = choice

        if storage.sexboundConfig.isLegal then
            self:passed()
        else
            self:failed()
        end
    end)
end

function Sexbound.Player.Legal:passed()
    status.removeEphemeralEffect("sexbound_stun")
end

function Sexbound.Player.Legal:failed()
    status.addEphemeralEffect("sexbound_stun", math.huge)
end

function Sexbound.Player.Legal:radioUninstallMessage()
    world.sendEntityMessage(player.id(), "queueRadioMessage", {
        messageId = "Sexbound_Event:Underage",
        unique = false,
        text = "^red;You must close Starbound and uninstall the 'Sexbound' mod from your mods directory!"
    })
end

function Sexbound.Player.Legal:update(dt)
    if storage.sexboundConfig.isLegal == false then
        self._timer = self._timer + dt

        if self._timer >= self._uninstallMessageTimeout then
            self:radioUninstallMessage()

            self._timer = 0
        end
    end
end

function Sexbound.Player.Legal:getParent()
    return self._parent
end

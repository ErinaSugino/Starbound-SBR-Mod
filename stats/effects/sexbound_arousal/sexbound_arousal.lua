function fetchConfig()
    self._config = {}
    r,err = pcall(function()
        local config = root.assetJson("/sexbound.config")
        if config and config.arousal then config = config.arousal
        self._config = config[self._effect] or {playMoans = false, moanChance = 0.1, moanFrequency = 10, speedDebuff = 1, strengthDebuff = 1, fertilityBonus = 0}
        else sb.logError("Arousal effect could not fetch arousal config!") return end
    end)
    if not r then
        sb.logError("Arousal effect could not fetch main config!")
        return
    end
end

function fetchSpeciesConfig()
    local species = world.entitySpecies(entity.id())
    self._speciesConfig = (species and config.getParameter(species)) or config.getParameter("default", {})
end

function setupEffects()
    if (self._speciesConfig.strength or 0) ~= 0 and (self._config.strengthDebuff or 0) ~= 0 then
        effect.addStatModifierGroup({
            { stat = "powerMultiplier", effectiveMultiplier = self._speciesConfig.strength * self._config.strengthDebuff }
        })
    end
end

function setupTimers()
    self._timers = {}
    self._doSpeed = 0
    
    if (self._speciesConfig.speed or 0) ~= 0 and (self._speciesConfig.speedInterval or 0) > 0 and (self._speciesConfig.speedChance or 0) > 0 and (self._config.speedDebuff or 0) ~= 0 then
        table.insert(self._timers, {action = "speed", value = self._speciesConfig.speed * self._config.speedDebuff, chance = self._speciesConfig.speedChance, timeMax = self._speciesConfig.speedInterval, timeCur = self._speciesConfig.speedInterval})
    end
    
    if self._config.playMoans and (self._config.moanChance or 0) > 0 and (self._config.moanFrequency or 0) > 0 then
        self._fetchMoans = true
        table.insert(self._timers, {action = "moan", chance = self._config.moanChance, timeMax = self._config.moanFrequency, timeCur = self._config.moanFrequency})
    end
end

function update(dt)
    promises:update()
    
    if self._fetchMoans then
        promises:add(world.sendEntityMessage(entity.id(), "Sexbound:Arousal:GetMoans"), function(moans)
            self._moanSfx = moans or {}
            if self._moanSfx.soundEffects then animator.setSoundPool("moan", self._moanSfx.soundEffects) end
        end)
        self._fetchMoans = false
    end
    
    for _,t in ipairs(self._timers) do
        t.timeCur = t.timeCur - dt
        if t.timeCur <= 0 then
            t.timeCur = t.timeMax
            handleTimer(t)
        end
    end
    
    if self._doSpeed and self._doSpeed ~= 0 then
        mcontroller.controlModifiers({
            speedModifier = self._doSpeed
        })
    end
end

function handleTimer(timer)
    local a = timer.action
    local v = timer.value
    local c = timer.chance
    local r = math.random()
    
    if a == "speed" then
        if r <= c then self_doSpeed = v else self._doSpeed = 0 end
    elseif a == "moan" then
        if r <= c then
            local pitch = self._moanSfx.pitch or 1.0
            if type(pitch) == "table" then pitch = pitch[1] + (math.random() * (pitch[2] - pitch[1])) end
            animator.setSoundPitch("moan", pitch)
            animator.playSound("moan")
        end
    end
end
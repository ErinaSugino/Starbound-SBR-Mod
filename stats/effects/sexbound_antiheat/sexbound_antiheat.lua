function init()
  if status.uniqueStatusEffectActive("sexbound_arousal_heat") then
    local data = root.assetJson("/stats/effects/sexbound_arousal_heat/sexbound_arousal_heat.statuseffect") or {}
    local maxTime = data.defaultDuration or 1800
    local effects = status.activeUniqueStatusEffectSummary()
    local effectDuration = 1
    for _,effect in ipairs(effects) do
      if effect[1] == "sexbound_arousal_heat" then
        effectDuration = effect[2]
        break
      end
    end
    
    local remaining = math.floor(maxTime * effectDuration / 2)
    status.removeEphemeralEffect("sexbound_arousal_heat")
    status.addEphemeralEffect("sexbound_arousal_heat_weak", remaining)
  end
  effect.expire()
end
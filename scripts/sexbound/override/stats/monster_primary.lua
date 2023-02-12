local sexbound_monster_primary_init = init
function init()
    sexbound_monster_primary_init()

    message.setHandler("Sexbound:removeStatusEffect", function(_, _, effectName)
        status.removeEphemeralEffect(effectName)
    end)
end

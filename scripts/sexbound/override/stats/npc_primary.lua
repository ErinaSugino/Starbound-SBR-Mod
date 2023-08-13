local sexbound_NPC_Primary_init = init
function init()
    sexbound_NPC_Primary_init()

    message.setHandler("Sexbound:removeStatusEffect", function(_, _, effectName)
        status.removeEphemeralEffect(effectName)
    end)
end

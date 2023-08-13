GenerateActor = {}

function GenerateActor.makeRandomHuman()
    local actor = GenerateActor.buildGenericHumanoid()
    self.speciesConfig = root.assetJson("/species/human.species")
    actor.identity = {
        species = "human"
    }
    actor.identity = GenerateActor.generateHumanoidIdentityForSexbound(actor.identity)
    return actor
end

function GenerateActor.buildGenericHumanoid()
    return {
        entityId = -99999,
        entityType = "npc"
    }
end

function GenerateActor.generateHumanoidIdentityForSexbound(identity)
    identity = GenerateActor.applyRandomGender(identity)
    identity = GenerateActor.applyRandomName(identity)
    identity = GenerateActor.applyRandomFacialHair(identity)
    identity = GenerateActor.applyRandomFacialMask(identity)
    identity = GenerateActor.applyRandomHair(identity)
    identity = GenerateActor.applyRandomBodyAndEmoteDirectives(identity)
    return identity
end

function GenerateActor.applyRandomName(identity)
    identity.name = GenerateActor.generateRandomName(identity)
    return identity
end

function GenerateActor.applyRandomBodyAndEmoteDirectives(identity)
    identity.bodyDirectives = GenerateActor.generateRandomBodyAndEmoteDirectives()
    identity.emoteDirectives = identity.bodyDirectives
    return identity
end

function GenerateActor.applyRandomGender(identity)
    identity.gender = util.randomChoice({"male", "female"})
    return identity
end

function GenerateActor.applyRandomFacialHair(identity)
    identity.facialHairDirectives = ""
    identity.facialHairFolder = ""
    identity.facialHairGroup = ""
    identity.facialHairType = ""
    return identity
end

function GenerateActor.applyRandomFacialMask(identity)
    identity.facialMaskDirectives = ""
    identity.facialMaskFolder = ""
    identity.facialMaskGroup = ""
    identity.facialMaskType = ""
    return identity
end

function GenerateActor.applyRandomHair(identity)
    local identityConfig = GenerateActor.retrieveSpeciesIdentityConfigByGender(identity)
    local hairList = identityConfig.hair
    identity.hairDirectives = GenerateActor.generateRandomHairDirectives()
    identity.hairType = util.randomChoice(hairList)
    identity.hairFolder = "hair"
    identity.hairGroup = "hair"
    return identity
end

function GenerateActor.generateRandomBodyAndEmoteDirectives()
    local bodyColorsList = GenerateActor.retrieveSpeciesBodyColors()
    bodyColorsList = util.randomChoice(bodyColorsList)
    return Sexbound.Util.colorMapToReplaceDirective(bodyColorsList)
end

function GenerateActor.generateRandomHairDirectives()
    local hairColorsList = GenerateActor.retrieveSpeciesHairColors()
    hairColorsList = util.randomChoice(hairColorsList)
    return Sexbound.Util.colorMapToReplaceDirective(hairColorsList)
end

function GenerateActor.generateRandomName(identity)
    return root.generateName(GenerateActor.retrieveSpeciesNameGenConfig(identity))
end

function GenerateActor.retrieveSpeciesNameGenConfig(identity)
    local genderIndex = 1
    if identity.gender == "female" then
        genderIndex = 2
    end
    return self.speciesConfig.nameGen[genderIndex]
end

function GenerateActor.retrieveSpeciesBodyColors()
    return self.speciesConfig.bodyColor
end

function GenerateActor.retrieveSpeciesHairColors()
    return self.speciesConfig.hairColor
end

function GenerateActor.retrieveSpeciesIdentityConfigByGender(identity)
    local genderIndex = 1
    if identity.gender == "female" then
        genderIndex = 2
    end
    return self.speciesConfig.genders[genderIndex]
end
function init()
    self.chosenName = nil
    self.nameGen = config.getParameter("config.nameGenerator", "/species/humannamegen.config")
    self.babySpecies = config.getParameter("config.babySpecies", "human")
    self.babyGender = config.getParameter("config.babyGender", "male")
    self.babyGenderText = " boy"
    self.babyId = config.getParameter("config.babyId")
    if self.babyGender == "female" then self.babyGenderText = " girl"
    elseif self.babyGender ~= "male" then self.babyGenderText = "" end
    
    buildText()
end

function update(dt)
    
end

function uninit()
    local result = {id=self.babyId,name=self.chosenName}
    world.sendEntityMessage(pane.sourceEntity(), "Sexbound:Pregnant:BirthNamed", result)
end

---
function useName()
    self.chosenName = widget.getText("nameInput")
    pane.dismiss()
end

function generateRandom()
    local newName = root.generateName(self.nameGen) or ""
    widget.setText("nameInput", newName)
end

function nameInput(elemName)
    return
end

---
function buildText()
    local text = "^shadow;You are about to give birth to a baby ^#00bfff;"..self.babySpecies.."^reset;^shadow;^orange;"..self.babyGenderText.."^reset;^shadow;!\n\nHow do you want to name it?"
    widget.setText("message", text)
end
--- Baby Class Module.
-- @classmod Baby
-- @author Locuturus
-- @license GNU General Public License v3.0
Baby = {}
Baby_mt = { __index = Baby }

function Baby:new(input)
  input = input or {}

  return setmetatable({
    birthDate      = input.birthDate      or 0,
    birthGender    = input.birthGender    or "male",
    birthSpecies   = input.birthSpecies   or "human",
    birthTime      = input.birthTime      or 0,
    birthOSTime    = input.birthOSTime    or 0,
    birthWorldTime = input.birthWorldTime or 0,
    dayCount       = input.dayCount       or 0,
    fatherName     = input.fatherName     or "",
    fatherId       = input.fatherId       or "",
    fatherUuid     = input.fatherUuid     or "",
    fatherType     = input.fatherType     or "",
    motherName     = input.motherName     or "",
    motherId       = input.motherId       or "",
    motherUuid     = input.motherUuid     or "",
    motherType     = input.motherType     or "villager"
  }, Baby_mt)
end
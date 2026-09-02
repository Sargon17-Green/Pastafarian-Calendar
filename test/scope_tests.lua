local root=arg[1] or "."
local forbidden={
  "oldRemainder","oldDayTag","oldDistance","mutateStonesWrong","legacyPrior",
  "GRIND_TABLE_WITH_SENTINEL","oldPermutationUnrank0","bowlAlias","vaultOld",
  "orderAt46Latch","oldNextBowlFixedName","biasedLegacyPick","wideDetour",
  "oldGateQuestionDay","LEGACY_YEAR_MAX","oldJumpGuess","oldStructureSauce",
  "VirtualLegacyList","legacyChooseEachDaySeparately","oldContiguousMonthDayGuess"
}
local files={root.."/src/bigint.lua",root.."/src/source_language_catalog.lua",root.."/src/monster_base.lua",root.."/src/spaghetti.lua"}
for _,path in ipairs(files) do
  local f=assert(io.open(path,"r")); local text=f:read("*a"); f:close()
  for _,token in ipairs(forbidden) do
    assert(not text:find(token,1,true),"Kòd yon patch pita parèt nan Stage 1: "..token)
  end
  assert(not text:find("normative_oracle",1,true),"Production pa dwe enpòte oracle la")
end
print("PASS limit Stage 1")

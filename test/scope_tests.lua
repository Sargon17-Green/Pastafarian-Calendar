local root=arg[1] or "."
local forbidden={
  "oldRemainder","oldDayTag","oldDistance","mutateStonesWrong","legacyPrior",
  "GRIND_TABLE_WITH_SENTINEL","oldPermutationUnrank0","bowlAlias","vaultOld",
  "orderAt46Latch","oldNextBowlFixedName","biasedLegacyPick","wideDetour",
  "oldGateQuestionDay","LEGACY_YEAR_MAX","oldJumpGuess","oldStructureSauce",
  "VirtualLegacyList","legacyChooseEachDaySeparately","oldContiguousMonthDayGuess"
}
local files={root.."/src/bigint.lua",root.."/src/source_language_catalog.lua",root.."/src/monster_base.lua"}
for _,path in ipairs(files) do
  local f=assert(io.open(path,"r")); local text=f:read("*a"); f:close()
  for _,token in ipairs(forbidden) do
    assert(not text:find(token,1,true),"Kòd yon patch pita parèt nan Stage 1: "..token)
  end
  assert(not text:find("normative_oracle",1,true),"Production pa dwe enpòte oracle la")
end
-- Modil baz Stage 1 yo rete fèmen; facade a grandi etap apre etap.
-- Tout nouvo chemen pwodiksyon yo toujou pa dwe enpòte oracle tès la.
local f=assert(io.open(root.."/src/spaghetti.lua","r"))
local facade=f:read("*a");f:close()
assert(not facade:find('require("normative_oracle")',1,true),
       "Facade pwodiksyon an pa dwe enpòte oracle")
assert(facade:find("function S.bootstrapProbe(",1,true),
       "Pwen antre Stage 1 la disparèt")
print("PASS limit Stage 1")

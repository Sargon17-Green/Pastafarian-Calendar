local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local legacy=read("src/legacy_biased_choice.lua")
local patch=read("src/short_choice_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find("return B.add(ONE,B.mod(B.sub(firstAnswer,ONE),size))",1,true))
assert(not legacy:find('require("short_choice_patch")',1,true))
assert(patch:find("local wrong,ctx=Legacy.execute(seed,step,size)",1,true))
assert(patch:find("local limit=B.mul(B.floorDiv(M,size),size)",1,true))
assert(patch:find("local reply=Legacy.answerAt(seed,step,rejected)",1,true))
assert(patch:find('manager.dispatcher:register("SHORT_CHOICE_REJECTION_PATCH"',1,true))
assert(facade:find('local ShortChoicePatch = require("short_choice_patch")',1,true))
assert(facade:find("function S.shortChoicePatchProbe(",1,true))
assert(facade:find("function S.shortChoiceCoreProbe(",1,true))
assert(facade:find("local corrected=ShortChoicePatch.execute(first,direction,optionCount)",1,true))
assert(facade:find("function S.legacyBiasedChoiceProbe(",1,true))
for _,source in ipairs({legacy,patch,facade}) do
 for _,word in ipairs({"normative_oracle","legacyChooseWide","chooseRankWidePatch",
   "postStir12","sealGatePatch","gatePatch"}) do
  assert(not source:find(word,1,true),"Stage 28+ antre twò bonè: "..word)
 end
end
print("PASS Stage 27 scope: 3 commits, legacy preserved, rejection for 1<=N<=M")

local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local t=f:read("*a");f:close();return t
end
local legacy=read("src/legacy_short_only_choice.lua")
local patch=read("src/short_choice_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find("local ok,result,child=pcall(Short.execute,initial,direction,options)",1,true))
assert(legacy:find("local isWide=B.compare(options,M)>0",1,true))
assert(legacy:find('manager.dispatcher:register("LEGACY_WIDE_SENT_TO_SHORT_PATH"',1,true))
assert(legacy:find("return nil,ctx",1,true))
assert(legacy:find("wideRankAvailable=false",1,true))
assert(patch:find("local wrong,ctx=Legacy.execute(seed,step,size)",1,true))
assert(facade:find("function S.legacyShortOnlyChoiceProbe(",1,true))
assert(facade:find("if BigInt.compare(size,BigInt.from(",1,true))
assert(facade:find("local corrected=ShortChoicePatch.execute(first,direction,optionCount)",1,true))
for _,src in ipairs({legacy,patch,facade}) do
 for _,s in ipairs({"normative_oracle","chooseRankWidePatch",
     "wideDetourPatch","postStir12","wideDigitBuilder"}) do
  assert(not src:find(s,1,true),"Stage 29+ antre twò bonè: "..s)
 end
end
print("PASS Stage 28 scope: short-only legacy routes N>M into PATCH 13 and blocks without wide fix")

local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_short_only_choice.lua")
local short=read("src/short_choice_patch.lua")
local wide=read("src/wide_choice_patch.lua")
local facade=read("src/spaghetti.lua")
assert(old:find('local ok,result,child=pcall(Short.execute,initial,direction,options)',1,true))
assert(old:find('wideRankAvailable=false',1,true))
assert(short:find('local wrong,ctx=Legacy.execute(seed,step,size)',1,true))
assert(wide:find('local missing,ctx=Old.execute(seed,step,size)',1,true))
assert(wide:find('validateLegacy(missing,ctx,seed,step,size)',1,true))
assert(wide:find('manager.dispatcher:register("WIDE_CHOICE_REJECTION_PATCH"',1,true))
assert(wide:find('local reply=Stream.answerAt(seed,step,j)',1,true))
assert(facade:find('local corrected=ShortChoicePatch.execute(first,direction,optionCount)',1,true))
assert(facade:find('local corrected=WideChoicePatch.execute(first,direction,optionCount)',1,true))
assert(facade:find('function S.legacyShortOnlyChoiceProbe(',1,true))
for _,src in ipairs({old,short,wide,facade}) do
 for _,needle in ipairs({"normative_oracle","postStir12","calendarDateOracle"}) do
  assert(not src:find(needle,1,true),"Fuit oracle/oswa Stage 30+: "..needle)
 end
end
assert(not old:find("WIDE_CHOICE_REJECTION_PATCH",1,true)
   and not short:find("WIDE_CHOICE_REJECTION_PATCH",1,true),
   "Legacy pa dwe genyen PATCH 14")
print("PASS Stage 29 scope: original Stage 28 block, Stage 27 short, separate second wide commit")

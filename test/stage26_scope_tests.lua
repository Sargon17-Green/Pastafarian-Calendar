local root=arg[1] or "."
local function read(path)
 local file=assert(io.open(root.."/"..path,"rb"))
 local content=file:read("*a");file:close();return content
end
local legacy=read("src/legacy_biased_choice.lua")
local public=read("src/spaghetti.lua")
local stage25=read("src/neighbor_patch.lua")
assert(legacy:find("function Legacy.answerAt(first,direction,k)",1,true))
assert(legacy:find("return Save.savePatch(B.add(seed,B.mulSmall(offset,step)))",1,true))
assert(legacy:find("function Legacy.oldBiasedModuloPick(first,direction,n)",1,true))
assert(legacy:find("return B.add(ONE,B.mod(B.sub(firstAnswer,ONE),size))",1,true))
assert(legacy:find('manager.dispatcher:register("LEGACY_REPLY_STREAM"',1,true))
assert(legacy:find('manager.dispatcher:register("LEGACY_BIASED_MODULO_PICK"',1,true))
assert(public:find('local LegacyBiasedChoice = require("legacy_biased_choice")',1,true))
assert(public:find("function S.answerAtSpaghetti(",1,true))
assert(public:find("function S.legacyBiasedChoiceProbe(",1,true))
assert(public:find("function S.oldBiasedModuloPickProbe(",1,true))
assert(public:find("function S.choiceSpaghetti(",1,true))
assert(not stage25:find('require("legacy_biased_choice")',1,true))
-- Tès etap 26 pa dwe entèdi kwasans facade nan PATCH 13.
for _,src in ipairs({legacy}) do
 for _,token in ipairs({"normative_oracle","chooseRankPatch",
   "rejectionSamplingPatch","legacyChooseWide","postStir12"}) do
  assert(not src:find(token,1,true),"Stage 27+ antre twò bonè: "..token)
 end
end
print("PASS Stage 26 scope: genuine SAVE stream, legacy modulo without acceptance, no Stage 27")

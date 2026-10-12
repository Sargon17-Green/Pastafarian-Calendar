local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_aliased_stir")
local Save=require("save_patch")
local oldLegacy=Legacy.execute
local oldSave=Save.savePatch
local stone={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local total=0
local function valid(a,c)
 assert(#a==6 and c.mode=="STAGE_21_PATCH_10"
    and c.commitToken==4 and c.status=="PATCH_STIR_RETURNED"
    and c.pendingSemanticState==nil and c.rollbackSnapshot==nil
    and #c.branchTrace==4 and #c.diagnostics==4)
end
for _,drop in ipairs({1,121,241,720}) do
 local guard=false
 local nested
 Legacy.execute=function(...)
   if not guard then
     guard=true
     local a,c=S.stirPatchProbe(121,5,bowls,stone)
     nested={a,c}
     guard=false
   end
   return oldLegacy(...)
 end
 local ok,a,c=pcall(S.stirPatchProbe,drop,4,bowls,stone)
 Legacy.execute=oldLegacy
 assert(ok and nested)
 valid(a,c);valid(nested[1],nested[2])
 nested[2].semanticState.correctedOrder[1]=99
 assert(c.semanticState.correctedOrder[1]~=99)
 total=total+1
end
for _,drop in ipairs({1,121,241,720}) do
 local guard=false
 local nested
 Save.savePatch=function(...)
   if not guard then
     guard=true
     local a,c=S.stirPatchProbe(241,5,bowls,stone)
     nested={a,c}
     guard=false
   end
   return oldSave(...)
 end
 local ok,a,c=pcall(S.stirPatchProbe,drop,4,bowls,stone)
 Save.savePatch=oldSave
 assert(ok and nested)
 valid(a,c);valid(nested[1],nested[2])
 nested[1][1].d[1]=12345
 nested[2].semanticState.correctedBowls[1]="FAKE"
 assert(c.semanticState.correctedBowls[1]~="FAKE")
 total=total+1
end
local first,ctx=S.stirPatchProbe(241,4,bowls,stone)
local frozen={}
for id=1,6 do frozen[id]=tostring(first[id]) end
first[1].d[1]=99
ctx.semanticState.correctedBowls[1]="FAKE"
ctx.diagnostics[4].permutation[1]=99
local again,second=S.stirPatchProbe(241,4,bowls,stone)
for id=1,6 do assert(tostring(again[id])==frozen[id]) end
assert(second.diagnostics[4].permutation[1]~=99 and second.semanticState.correctedBowls[1]~="FAKE")
assert(total==8 and Legacy.execute==oldLegacy and Save.savePatch==oldSave)
print("PASS Stage 21 reentrance: 8 nested/8 outer, ownership endepandan")

local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local old={10,20,30,40,50,60}
local stones={w=2,b=3,s=5,m=7,r=11}
local rocks={2,3,5,7,11,2}
local count,changed=0,0
for rank=1,720 do
    local corrected,ctx=S.stirPatchProbe(rank,4,old,stones)
    local order=O.bowlOrderFromDrop(B.from(rank))
    local legacy=S.legacyAliasedStirProbe(rank,4,old,stones)
    local pours={}
    for p=1,3 do
      pours[p]=O.SAVE(B.from(rank)*B.from(rank)
        +B.from(rocks[p])*B.from(old[order[p]])
        +B.from(({3,5,7})[p]*4))
    end
    assert(ctx.commitToken==4 and ctx.mode=="STAGE_21_PATCH_10"
       and ctx.phase=="PATCH_SNAPSHOT_BOWL_STIR"
       and ctx.status=="PATCH_STIR_RETURNED"
       and ctx.currentHandler=="STIR_SNAPSHOT_PATCH"
       and ctx.previousHandler=="LEGACY_ALIASED_STIR"
       and #ctx.branchTrace==4 and ctx.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
       and ctx.branchTrace[2]=="BOWL_ORDER_POUR_PATCH"
       and ctx.branchTrace[3]=="LEGACY_ALIASED_STIR"
       and ctx.branchTrace[4]=="STIR_SNAPSHOT_PATCH")
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.metrics["legacy.stir.aliasCalls"]==1
       and ctx.metrics["stir.patch.calls"]==1
       and ctx.metrics["stir.patch.legacyCallsPreserved"]==1)
    assert(#ctx.diagnostics==4 and ctx.diagnostics[3].samePhysicalWorkingTable
       and ctx.diagnostics[4].correctedDistinctTables)
    assert(ctx.semanticState.aliasSeparated and ctx.semanticState.historicalAliasingPreserved)
    local mismatches=0
    for p=1,6 do
       local id=order[p]
       local prev=order[(p+4)%6+1]
       local nxt=order[p%6+1]
       local sum=B.from(old[id])+B.from(2)*B.from(old[prev])
          +B.from(3)*B.from(old[nxt])+(p<=3 and pours[p] or B.from(0))
          +B.from(rank)+B.from(rocks[p])
       local target=O.SAVE(sum*sum+B.from(5)*B.from(old[prev])*B.from(old[nxt])+B.from(4*p))
       assert(B.compare(corrected[id],target)==0,"Lòd "..rank..", bòl "..id)
       assert(ctx.semanticState.previousBowls[id]==tostring(old[id]))
       assert(ctx.semanticState.correctedBowls[id]==tostring(target))
       assert(ctx.semanticState.historicalAliasedBowls[id]==tostring(legacy[id]))
       if B.compare(corrected[id],legacy[id])~=0 then mismatches=mismatches+1 end
    end
    assert(ctx.semanticState.changedBowlIds==mismatches)
    assert(ctx.metrics["stir.patch.changedBowlIds"][1]==mismatches)
    assert(mismatches>=1,"Alias la pa t parèt pou rank "..rank)
    count=count+1;changed=changed+mismatches
end
assert(count==720 and changed>=720)
local public=S.aliasedStirSpaghetti(241,4,old,stones)
local match=S.stirPatchProbe(241,4,old,stones)
for id=1,6 do assert(B.compare(public[id],match[id])==0) end
assert(select("#",S.aliasedStirSpaghetti(1,4,old,stones))==1)
assert(select("#",S.stirPatchProbe(1,4,old,stones))==2)
print("PASS Stage 21: 720/720 permutation, sis snapshot yo, tras 4 commits")

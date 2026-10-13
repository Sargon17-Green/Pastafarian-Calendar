local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local inputs={{M,1,5,2,1,1},{M,-1,5,2,5,2},
 {B.sub(M,1),-1,5,1,5,1},{M,1,11,6,1,1}}
for _,c in ipairs(inputs) do
 local first,step,n,legacyAnswer,wanted,reject=c[1],c[2],c[3],c[4],c[5],c[6]
 local rank,ctx=S.shortChoicePatchProbe(first,step,n)
 assert(B.compare(rank,wanted)==0
   and B.compare(ctx.legacyChoiceRank,legacyAnswer)==0
   and ctx.mode=="STAGE_27_PATCH_13"
   and ctx.phase=="PATCH_SHORT_CHOICE_ACCEPTANCE"
   and ctx.status=="PATCH_SHORT_CHOICE_COMPLETE"
   and ctx.commitToken==3 and #ctx.branchTrace==3
   and ctx.branchTrace[1]=="LEGACY_REPLY_STREAM"
   and ctx.branchTrace[2]=="LEGACY_BIASED_MODULO_PICK"
   and ctx.branchTrace[3]=="SHORT_CHOICE_REJECTION_PATCH"
   and ctx.currentHandler=="SHORT_CHOICE_REJECTION_PATCH"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(ctx.legacyChoiceSemanticState.source=="LEGACY_DIRECT_MODULO_WITHOUT_REJECTION"
   and ctx.legacyChoiceSemanticState.didApplyAcceptanceThreshold==false
   and ctx.legacyChoiceSemanticState.resultRankDecimal==tostring(legacyAnswer))
 assert(ctx.semanticState.source=="PATCH_13_ACCEPTANCE_REJECTION_SHORT"
   and ctx.semanticState.correctedRankDecimal==tostring(wanted)
   and ctx.semanticState.legacyRankDecimal==tostring(legacyAnswer)
   and ctx.semanticState.logicallyRejectedCountDecimal==tostring(reject)
   and ctx.semanticState.appliesAcceptanceThreshold==true
   and ctx.semanticState.legacyCallPreserved==true
   and ctx.semanticState.previousCommitCount==2
   and ctx.semanticState.shortPathOnly==true)
 assert(ctx.metrics["shortChoice.patch.calls"]==1
   and ctx.metrics["shortChoice.patch.accepted"]==1
   and ctx.metrics["legacy.biasedModulo.calls"]==1)
 assert(#ctx.diagnostics==3
   and ctx.diagnostics[2].code=="DISCOVERY_13_SKIPS_ACCEPTANCE_LIMIT"
   and ctx.diagnostics[3].code=="PATCH_13_ACCEPTANCE_THRESHOLD_AND_REJECTION")
 local public=S.choiceSpaghetti(first,step,n)
 local legacy=S.legacyBiasedChoiceProbe(first,step,n)
 assert(B.compare(public,wanted)==0 and B.compare(legacy,legacyAnswer)==0)
end
local same,ctx=S.shortChoicePatchProbe(1,-1,1)
assert(B.compare(same,1)==0
   and ctx.semanticState.logicallyRejectedCountDecimal=="0")
ctx.legacyChoiceSemanticState.resultRankDecimal="CORRUPT"
assert(ctx.semanticState.legacyRankDecimal~="CORRUPT")
print("PASS Stage 27 PATCH 13: four historical failures corrected, 3 commits, clean ownership")

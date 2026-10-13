local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local cases={
 {B.add(M,1),B.from(1),1},
 {B.add(M,1),B.from(M),-1},
 {B.mul(M,M),B.from(3),1},
 {B.add(B.mul(M,M),1),B.from(M),1},
 {B.pow(M,3),B.from(1),-1},
 {B.add(B.pow(M,3),1),B.from(M),1},
 {B.add(B.pow(M,4),1),B.from(1),1},
 {B.add(B.pow(M,5),1),B.from(1),1},
 {B.add(B.pow(M,2),B.from(2)),B.from(2),1},
 {B.add(B.pow(M,3),B.from(2)),B.from(1),1},
}
for _,case in ipairs(cases) do
 local n,first,step=case[1],case[2],case[3]
 local before,legacy=S.legacyShortOnlyChoiceProbe(first,step,n)
 assert(before==nil and legacy.status=="LEGACY_WIDE_CHOICE_BLOCKED"
        and legacy.commitToken==1)
 local rank,ctx=S.wideChoicePatchProbe(first,step,n)
 local expected=O.chooseRankWide({first=first,directionStep=step},n)
 assert(B.compare(rank,expected)==0)
 assert(B.compare(S.choiceSpaghetti(first,step,n),expected)==0)
 assert(ctx.mode=="STAGE_29_PATCH_14" and ctx.phase=="PATCH_WIDE_CHOICE_DETOUR"
    and ctx.status=="PATCH_WIDE_CHOICE_COMPLETE" and ctx.commitToken==2
    and ctx.branchTrace[1]=="LEGACY_WIDE_SENT_TO_SHORT_PATH"
    and ctx.branchTrace[2]=="WIDE_CHOICE_REJECTION_PATCH"
    and ctx.currentHandler=="WIDE_CHOICE_REJECTION_PATCH"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 local old=ctx.legacyWideSemanticState
 local s=ctx.semanticState
 assert(old.source=="LEGACY_SHORT_ASSUMPTION_REJECTS_N_GREATER_THAN_M"
    and old.wideRankAvailable==false and old.optionCountDecimal==tostring(n))
 assert(s.source=="PATCH_14_BASE_M_WIDE_CHOICE"
    and s.wideRankAvailable and s.legacyBlockPreserved
    and s.previousCommitCount==1 and s.correctedRankDecimal==tostring(expected)
    and s.optionCountDecimal==tostring(n)
    and s.digitCount==#s.digitRepliesDecimal
    and B.compare(s.answerSpaceDecimal,n)>=0)
 local rebuild,weight=B.from(1),B.from(1)
 for _,answer in ipairs(s.digitRepliesDecimal) do
  rebuild=B.add(rebuild,B.mul(B.sub(answer,1),weight))
  weight=B.mul(weight,M)
 end
 assert(B.compare(rebuild,s.initialWideAnswerDecimal)==0
    and B.compare(weight,s.answerSpaceDecimal)==0)
 assert(ctx.metrics["legacy.wideBlocked.calls"]==1
    and ctx.metrics["wideChoice.patch.calls"]==1
    and ctx.diagnostics[1].code=="DISCOVERY_14_WIDE_SHORT_ONLY_BLOCK"
    and ctx.diagnostics[2].code=="PATCH_14_WIDE_DETOUR_AFTER_HISTORIC_BLOCK")
 ctx.semanticState.digitRepliesDecimal[1]="TAMPERED"
 assert(ctx.legacyWideSemanticState.optionCountDecimal==tostring(n))
end
for _,n in ipairs({B.add(M,1),B.add(B.pow(M,2),1),B.add(B.pow(M,3),1)}) do
 for _,first in ipairs({1,2,3,7,17}) do
  local step=1
  local expected=O.chooseRankWide({first=B.from(first),directionStep=step},n)
  assert(B.compare(S.choiceSpaghetti(first,step,n),expected)==0)
 end
end
print("PASS Stage 29 wide: 25 independent oracle selections, legacy block and second commit")

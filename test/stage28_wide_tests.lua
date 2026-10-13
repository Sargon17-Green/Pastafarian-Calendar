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
}
local checked=0
for _,c in ipairs(cases) do
 local n,first,step=c[1],c[2],c[3]
 local wrong,ctx=S.legacyShortOnlyChoiceProbe(first,step,n)
 assert(wrong==nil and ctx.mode=="STAGE_28_DISCOVERY_14"
    and ctx.phase=="LEGACY_SHORT_ONLY_SELECTION_DISPATCH"
    and ctx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
    and ctx.commitToken==1 and #ctx.branchTrace==1
    and ctx.currentHandler=="LEGACY_WIDE_SENT_TO_SHORT_PATH"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(ctx.semanticState.source=="LEGACY_SHORT_ASSUMPTION_REJECTS_N_GREATER_THAN_M"
    and ctx.semanticState.optionCountDecimal==tostring(n)
    and ctx.semanticState.attemptedShortPatch
    and ctx.semanticState.failureIsShortSizeRestriction
    and ctx.semanticState.noWidePath
    and ctx.semanticState.wideRankAvailable==false
    and ctx.semanticState.logicallyValidRankAbsent
    and ctx.semanticState.attemptedCalls==1)
 assert(ctx.semanticState.shortError:find("PATCH 13: kantite chwa dwe 1..M",1,true))
 assert(ctx.metrics["legacy.wideBlocked.calls"]==1
    and ctx.metrics["legacy.wideBlocked.shortAttempt"]==1
    and ctx.diagnostics[1].code=="DISCOVERY_14_WIDE_SHORT_ONLY_BLOCK")
 local blockedAgain,ctxAgain=S.legacyShortOnlyChoiceProbe(first,step,n)
 assert(blockedAgain==nil and ctxAgain~=ctx
    and ctxAgain.status=="LEGACY_WIDE_CHOICE_BLOCKED")
 local expected=O.chooseRankWide({first=first,directionStep=step},n)
 assert(B.compare(expected,1)>=0 and B.compare(expected,n)<=0)
 assert(B.compare(S.answerAtSpaghetti(first,step,1),
   O.answerAt({first=first,directionStep=step},1))==0)
 checked=checked+1
end
assert(checked==7)
print("PASS Stage 28 wide witnesses: 7 valid oracle ranks blocked by legacy short dispatcher")

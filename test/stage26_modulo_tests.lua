local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local O=require("normative_oracle")
local B=require("bigint")
local S=require("spaghetti")
local M=O.M
local cases={
 {first=B.from(1),step=1,n=1},
 {first=B.from(1),step=1,n=5},
 {first=B.from(5),step=-1,n=5},
 {first=B.sub(M,2),step=1,n=5},
 {first=B.sub(M,1),step=-1,n=5},
 {first=B.from(M),step=-1,n=5},
 {first=B.from(M),step=1,n=5},
 {first=B.from(M),step=1,n=11},
 {first=B.from(M),step=-1,n=B.from(M)},
 {first=B.from("9"..string.rep("7",90)),step=1,n=97}
}
local mismatches=0
for _,c in ipairs(cases) do
 local value,ctx=S.legacyBiasedChoiceProbe(c.first,c.step,c.n)
 local expected=B.add(B.from(1),B.mod(B.sub(c.first,1),c.n))
 assert(B.compare(value,expected)==0)
 assert(ctx.mode=="STAGE_26_DISCOVERY_13"
    and ctx.phase=="LEGACY_DIRECT_MODULO_SELECTION"
    and ctx.status=="LEGACY_BIASED_PICK_COMPLETE"
    and ctx.commitToken==2 and #ctx.branchTrace==2
    and ctx.branchTrace[1]=="LEGACY_REPLY_STREAM"
    and ctx.branchTrace[2]=="LEGACY_BIASED_MODULO_PICK"
    and ctx.currentHandler=="LEGACY_BIASED_MODULO_PICK"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(ctx.semanticState.source=="LEGACY_DIRECT_MODULO_WITHOUT_REJECTION"
    and ctx.semanticState.resultRankDecimal==tostring(value)
    and ctx.semanticState.consumedAnswerCount==1
    and ctx.semanticState.ignoredFurtherAnswers
    and ctx.semanticState.didApplyAcceptanceThreshold==false
    and ctx.semanticState.legacyModuloBiasPreserved
    and ctx.semanticState.shortPathOnly)
 assert(ctx.metrics["legacy.replyStream.calls"]==1
    and ctx.metrics["legacy.biasedModulo.calls"]==1
    and #ctx.diagnostics==2
    and ctx.diagnostics[2].code=="DISCOVERY_13_SKIPS_ACCEPTANCE_LIMIT")
 local wanted=O.chooseRankShort({first=c.first,directionStep=c.step},c.n)
 if B.compare(value,wanted)~=0 then mismatches=mismatches+1 end
 local public=S.choiceSpaghetti(c.first,c.step,c.n)
 assert(B.compare(public,value)==0)
 assert(B.compare(S.oldBiasedModuloPickProbe(c.first,c.step,c.n),value)==0)
end
assert(mismatches>=4)
for _,bad in ipairs({0,"-1",B.add(M,1),false,{}}) do
 assert(not pcall(S.legacyBiasedChoiceProbe,1,1,bad))
end
print("PASS Stage 26 modulo: 10 fixture traces, "..mismatches.." genuine normative divergences")

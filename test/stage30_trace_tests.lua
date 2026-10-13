local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local cases={0,1,2,10,41,122,-1,-2,-10,-41,-122}
local negative,nonnegative=0,0
for _,step in ipairs(cases) do
 local actual,ctx=S.legacyGateQuestionProbe(step)
 local abs=B.abs(step)
 local history=B.add(F,abs)
 local wanted=B.add(F,step)
 assert(B.compare(actual,history)==0
  and B.compare(S.legacyGateQuestionProbe(step),history)==0
  and B.compare(S.oldGateQuestionDayProbe(abs),history)==0)
 assert(ctx.mode=="STAGE_30_DISCOVERY_15"
  and ctx.status=="LEGACY_GATE_QUERY_COMPLETE"
  and ctx.phase=="LEGACY_GATE_ABSOLUTE_QUERY"
  and ctx.commitToken==2 and #ctx.branchTrace==2
  and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
  and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.currentHandler=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 local st=ctx.semanticState
 assert(st.source=="LEGACY_ABSOLUTE_GATE_QUERY"
  and st.signedStepDecimal==tostring(B.from(step))
  and st.distanceMagnitudeDecimal==tostring(abs)
  and st.queriedDayDecimal==tostring(history)
  and st.foundationDayDecimal==tostring(F)
  and st.passedAbsoluteStep and st.preservedOriginalSignedInput
  and not st.didCorrectNegativeGate and st.signLostForNegative==(step<0))
 assert(ctx.metrics["legacy.gateSignedInput.calls"]==1
  and ctx.metrics["legacy.gateAbsoluteQuery.calls"]==1
  and #ctx.diagnostics==2
  and ctx.diagnostics[1].code=="DISCOVERY_15_SIGNED_GATE_REQUEST"
  and ctx.diagnostics[2].code=="DISCOVERY_15_ABSOLUTE_SIGN_LOSS")
 if step<0 then
  assert(B.compare(actual,wanted)~=0);negative=negative+1
 else
  assert(B.compare(actual,wanted)==0);nonnegative=nonnegative+1
 end
end
assert(negative==5 and nonnegative==6)
print("PASS Stage 30 traces: 11 signed cases, 5 historical negatives, two owned commits")

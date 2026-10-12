local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local O=require("normative_oracle")
local c=O.FOUNDATION_DAY
local result,report=S.visibleDropSpaghetti(c,c,1,{})
assert(result==nil and report.status=="LEGACY_VISIBLE_INCOMPLETE")
assert(report.missingGrind==11 and report.completedGrinds==10)
assert(report.visibleIndex==1 and #report.trace==11)
for g=1,10 do
 assert(report.trace[g].grind==g and report.trace[g].missing==false)
 assert(report.trace[g].status=="LEGACY_GRIND_RETURNED")
end
assert(report.trace[11].grind==11 and report.trace[11].missing==true)
assert(not pcall(S.visibleDropSpaghetti,c,c,0,{}))
assert(not pcall(S.visibleDropSpaghetti,c,c,47,{}))
assert(not pcall(S.calendarDateSpaghetti))
print("PASS chemen vizib Stage 14: 10 grind reyèl, 11yèm ranje manke")

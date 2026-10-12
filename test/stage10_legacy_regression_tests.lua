local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY

local counts=O.workCounts(F,F)
local normative=O.buildHiddenDrops(counts,O.STONES)
local production=S.legacyHiddenProbe(F,F)
local differences={}
for k=1,7 do
    assert(B.compare(production[k],normative[8-k])==0,
           "Depo a pa envèse egzakteman, oubyen kalkil gout yo pa normatif")
    if B.compare(production[k],normative[k])~=0 then differences[#differences+1]=k end
end
assert(table.concat(differences,",")=="1,2,3,5,6,7",
       "Se pa sis pozisyon envèse ki te prevwa yo")
if #differences>0 then
    error("EXPECTED_RED Stage 10 DISCOVERY 05: 6 hidden drops nan move plas: "..
          table.concat(differences,","),0)
end
print("PASS legacy Stage 10: pa gen diferans istorik")

local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local expected={
 {3,5,7,11,"w"},{5,7,11,13,"b"},{7,11,13,17,"s"},
 {11,13,17,19,"m"},{13,17,19,23,"r"},{17,19,23,29,"w"},
 {19,23,29,31,"b"},{23,29,31,37,"s"},{29,31,37,41,"m"},
 {31,37,41,43,"r"},{37,41,43,47,"w"}
}
local wrong={}
for g=1,11 do
 local row=S.grindRowSpaghetti(g)
 local e=expected[g]
 if row==nil or row.a~=e[1] or row.b~=e[2] or row.c~=e[3] or
    row.d~=e[4] or row.kind~=e[5] then
    wrong[#wrong+1]=tostring(g)
 end
end
assert(table.concat(wrong,",")=="1,2,3,4,5,6,7,8,9,10,11",
       "Sa pa egzakteman onz pwoblèm tab grind yo")
error("EXPECTED_RED Stage 14 DISCOVERY 07: 11 ranje tounaj mal endekse: " ..
      table.concat(wrong,",") .. "; denye ranje manke",0)

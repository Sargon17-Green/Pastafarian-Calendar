local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local expected={
 {3,5,7,11,"w"},{5,7,11,13,"b"},{7,11,13,17,"s"},
 {11,13,17,19,"m"},{13,17,19,23,"r"},{17,19,23,29,"w"},
 {19,23,29,31,"b"},{23,29,31,37,"s"},{29,31,37,41,"m"},
 {31,37,41,43,"r"},{37,41,43,47,"w"}
}
for g=1,11 do
 local row=S.grindRowSpaghetti(g)
 local e=expected[g]
 assert(row and row.a==e[1] and row.b==e[2] and row.c==e[3] and
     row.d==e[4] and row.kind==e[5],"Ranje grind koreksyon diferan: "..g)
end
print("PASS Stage 14: 11 ranje grind nan lòd normatif")

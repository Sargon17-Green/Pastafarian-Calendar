local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stones={w=B.from("1"..string.rep("0",83)),b=B.from("2"..string.rep("9",69)),
 s=B.from("3"..string.rep("4",65)),m=B.from("4"..string.rep("1",73)),
 r=B.from("5"..string.rep("7",60))}
local old={}
for id=1,6 do old[id]=B.from(tostring(id)..string.rep("0",84)) end
local drops={"0","1","2","719","720","721","-1","-720","-721",
 "1"..string.rep("0",200),"-"..string.rep("9",243)}
local seed=2121
for i=1,100 do
 local parts={tostring(i%9+1)}
 for j=1,85+i do
   seed=(seed*48271)%2147483647
   parts[#parts+1]=tostring(seed%10)
 end
 drops[#drops+1]=(i%4==0 and "-" or "")..table.concat(parts)
end
local rocks={stones.w,stones.b,stones.s,stones.m,stones.r,stones.w}
for _,str in ipairs(drops) do
 local drop=B.from(str)
 local result,ctx=S.stirPatchProbe(drop,46,old,stones)
 local order=O.bowlOrderFromDrop(drop)
 local pours={}
 for p=1,3 do pours[p]=O.SAVE(drop*drop+rocks[p]*old[order[p]]
             +B.from(({3,5,7})[p]*46)) end
 for p=1,6 do
   local id=order[p]
   local prev=order[(p+4)%6+1]
   local nxt=order[p%6+1]
   local v=old[id]+B.from(2)*old[prev]+B.from(3)*old[nxt]
        +(p<=3 and pours[p] or B.from(0))+drop+rocks[p]
   local expected=O.SAVE(v*v+B.from(5)*old[prev]*old[nxt]+B.from(46*p))
   assert(B.compare(result[id],expected)==0,"BigInt gout "..str..", bòl "..id)
 end
 assert(ctx.commitToken==4)
end
assert(#drops==111)
print("PASS Stage 21 BigInt: 111 gout, siy negatif, >256-bit, i=46")

local root=arg[1] or "."
package.path=root.."/src/?.lua;"..package.path
local Legacy=require("legacy_permutation")

local function key(p) return table.concat(p,",") end
local function nextLex(p)
    local i=5
    while i>=1 and p[i]>=p[i+1] do i=i-1 end
    if i==0 then return false end
    local j=6
    while p[j]<=p[i] do j=j-1 end
    p[i],p[j]=p[j],p[i]
    local left,right=i+1,6
    while left<right do
        p[left],p[right]=p[right],p[left]
        left,right=left+1,right-1
    end
    return true
end
local enumerated={1,2,3,4,5,6}
local seen={}
for rank0=0,719 do
    local direct=Legacy.oldPermutationUnrank0(rank0)
    local k=key(direct)
    assert(k==key(enumerated),"Unrank legacy pa swiv lòd leksikografik: "..rank0)
    assert(not seen[k],"Yon permutasyon repete: "..k)
    seen[k]=true
    local flags={}
    for _,id in ipairs(direct) do
        assert(type(id)=="number" and id>=1 and id<=6 and not flags[id])
        flags[id]=true
    end
    if rank0<719 then assert(nextLex(enumerated)) else assert(not nextLex(enumerated)) end
end
local count=0
for _ in pairs(seen) do count=count+1 end
assert(count==720)
assert(key(Legacy.oldPermutationUnrank0(0))=="1,2,3,4,5,6")
assert(key(Legacy.oldPermutationUnrank0(719))=="6,5,4,3,2,1")
local one=Legacy.oldPermutationUnrank0(0)
one[1]=99
assert(key(Legacy.oldPermutationUnrank0(0))=="1,2,3,4,5,6")
for _,bad in ipairs({-1,720,721,1.5,"0","719",true,{}}) do
    assert(not pcall(Legacy.oldPermutationUnrank0,bad),"Rang ilegal aksepte: "..tostring(bad))
end
print("PASS Stage 16 factoradic: 720/720 permutasyon, lòd leksikografik, kopi ak limit")

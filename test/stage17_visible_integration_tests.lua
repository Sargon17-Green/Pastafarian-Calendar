local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local cases={{F,F},{F+1,F-1},{F-5,F+9}}
local checked=0
for _,pair in ipairs(cases) do
    local store={}
    for i=1,3 do
        local drop,visibleContext=S.visibleDropSpaghetti(pair[1],pair[2],i,store)
        assert(visibleContext.status=="PATCH_VISIBLE_COMPLETE"
               and visibleContext.completedGrinds==11)
        local actual,ctx=S.permutationPatchProbe(drop)
        local expected=O.bowlOrderFromDrop(drop)
        assert(table.concat(actual,",")==table.concat(expected,","))
        assert(ctx.status=="PATCH_PERM_RETURNED" and ctx.commitToken==3)
        store[i]=B.from(drop)
        checked=checked+1
    end
end
assert(checked==9)
print("PASS Stage 17 cross-layer: 9 native visible drops -> corrected unrank")

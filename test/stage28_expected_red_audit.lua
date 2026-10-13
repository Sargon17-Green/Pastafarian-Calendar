local root=arg[1] or "."
local old=arg
for i=1,4 do
 arg={root}
 local fn=assert(loadfile(root.."/test/stage28_expected_red_"..i..".lua"))
 local ok,err=pcall(fn)
 assert(not ok and err==
    "EXPECTED_RED Stage 28 DISCOVERY 14 witness "..i..": N>M blocked by short-only legacy",
    "Stage 28 audit bad red "..i..": "..tostring(err))
end
arg=old
print("PASS Stage 28 EXPECTED_RED audit: 4 genuine wide-N failures preserved")

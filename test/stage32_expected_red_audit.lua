local root=arg[1] or "."
local previous=arg
for i=1,3 do
 arg={root}
 local fn=assert(loadfile(root.."/test/stage32_expected_red_"..i..".lua"))
 local ok,msg=pcall(fn)
 assert(not ok and msg==
  "EXPECTED_RED Stage 32 DISCOVERY 16 witness "..i..": gate gap legacy offset plus one",
  "Stage 32 red audit wrong at witness "..i..": "..tostring(msg))
end
arg=previous
print("PASS Stage 32 EXPECTED_RED audit: 3 genuine wrong-offset gate gaps")

local root=arg[1] or "."
local old=arg
for i=1,3 do
 arg={root}
 local fn=assert(loadfile(root.."/test/stage34_expected_red_"..i..".lua"))
 local ok,msg=pcall(fn)
 assert(not ok and msg==
  "EXPECTED_RED Stage 34 DISCOVERY 17 witness "..i..": positive gate forgot prior gaps",
   "Stage 34 audit: wrong witness "..i..": "..tostring(msg))
end
arg=old
print("PASS Stage 34 EXPECTED_RED audit: 3 historical cumulative chain failures")

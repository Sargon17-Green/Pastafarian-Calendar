local root=arg[1] or "."
local save=arg
for i=1,3 do
 arg={root}
 local fn=assert(loadfile(root.."/test/stage30_expected_red_"..i..".lua"))
 local ok,msg=pcall(fn)
 assert(not ok and msg==
  "EXPECTED_RED Stage 30 DISCOVERY 15 witness "..i..": negative gate sign lost",
  "Stage 30 red audit failed at "..i..": "..tostring(msg))
end
arg=save
print("PASS Stage 30 EXPECTED_RED audit: 3 genuine negative gate historical failures")

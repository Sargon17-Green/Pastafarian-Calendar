local root=arg[1] or "."
local before=arg
for i=1,4 do
 arg={root}
 local fn=assert(loadfile(root.."/test/stage26_expected_red_"..i..".lua"))
 local ok,err=pcall(fn)
 assert(not ok and err==
    "EXPECTED_RED Stage 26 DISCOVERY 13 witness "..i..": modulo san rejè",
    "Odit wouj "..i.." pa jwenn erè egzak: "..tostring(err))
end
arg=before
print("PASS Stage 26 EXPECTED_RED audit: four separate short-path modulo bias witnesses")

local root=arg[1] or "."
local tests={
  "test/bigint_tests.lua",
  "test/catalog_tests.lua",
  "test/oracle_helper_tests.lua",
  "test/production_base_tests.lua",
  "test/scope_tests.lua",
  "test/virtual_family_bruteforce_tests.lua",
  "test/human_language_shape_tests.lua",
  "test/fixture_tests.lua"
}
for _,path in ipairs(tests) do
  local chunk,err=loadfile(root.."/"..path)
  assert(chunk,err)
  local oldarg=arg
  arg={root}
  local ok,msg=pcall(chunk)
  arg=oldarg
  assert(ok,path.." echwe: "..tostring(msg))
end
print("PASS Stage 1")

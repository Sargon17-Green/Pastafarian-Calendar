local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local O = require("normative_oracle")
local B = require("bigint")

-- Verifye echèk istorik LEGACY a menm apre PATCH 01, pa yon erè o aza.
local previousArg = arg
arg = {root}
local chunk = assert(loadfile(root .. "/test/stage02_legacy_regression_tests.lua"))
local ok, message = pcall(chunk)
arg = previousArg
assert(not ok, "Ansyen chemen legacy a pa bay twa diferans istorik yo ankò")
assert(type(message) == "string", "Echèk la pa bay yon mesaj tès")
local prefix = "EXPECTED_RED Stage 2 DISCOVERY 01: 3 ka SAVE pa ekivalan: "
assert(message:sub(1, #prefix) == prefix,
       "Se pa twa diferans SAVE espere yo: " .. message)
local suffix = message:sub(#prefix + 1)
local expect = {}
for _, name in ipairs({"M", "2M", "3M"}) do
    expect[#expect + 1] = name .. ": legacy=0 normative=" .. tostring(O.M)
end
assert(suffix == table.concat(expect, "; "),
       "Lis diferans yo pa egzak oswa gen lòt echèk: " .. suffix)
assert(B.compare(O.SAVE(O.M + B.from(1)), B.from(1)) == 0)
print("PASS odit EXPECTED_RED Stage 2: egzakteman M, 2M, 3M")

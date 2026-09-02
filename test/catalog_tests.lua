local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. package.path
local C = require("source_language_catalog")
assert(C.version() == "1.0.0")
assert(C.language() == "Kreyòl ayisyen")
assert(C.cutletCount() == 17)
assert(C.monthCount() == 47)
local seen = {}
for i, e in C.iterCutlets() do
    assert(i == e.canonicalIndex)
    assert(type(e.sourceString) == "string" and #e.sourceString > 0)
    assert(not seen[e.canonicalIndex])
    seen[e.canonicalIndex] = true
end
for i = 1, 17 do assert(seen[i]) end
seen = {}
for i, e in C.iterMonths() do
    assert(i == e.canonicalIndex)
    assert(type(e.sourceString) == "string" and #e.sourceString > 0)
    assert(not seen[e.canonicalIndex])
    seen[e.canonicalIndex] = true
end
for i = 1, 47 do assert(seen[i]) end
local ok = pcall(function() C.someNewField = 1 end)
assert(not ok)
print("PASS catalog")

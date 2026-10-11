local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local S = require("spaghetti")
local M = B.from("170141183460469231731687303715884105727")

-- Yon fonksyon ki ekspoze yon rezilta pa dwe kite kontèks dyagnostik la koule.
assert(select("#", S.saveSpaghetti(M)) == 1,
       "saveSpaghetti dwe retounen yon sèl valè")
assert(select("#", S.legacySaveProbe(M)) == 2,
       "legacySaveProbe dwe retounen rezilta ak kontèks")

local earlier, earlierContext = S.legacySaveProbe(M)
local later, laterContext = S.legacySaveProbe(M + B.from(1))
assert(tostring(earlier) == "0" and tostring(later) == "1")
assert(earlierContext ~= laterContext)
assert(earlierContext.semanticState ~= laterContext.semanticState)
assert(earlierContext.metrics ~= laterContext.metrics)
assert(earlierContext.diagnostics ~= laterContext.diagnostics)
assert(earlierContext.branchTrace ~= laterContext.branchTrace)
assert(earlierContext.pendingSemanticState == nil)
assert(laterContext.pendingSemanticState == nil)

-- Referans dyagnostik ki chanje pa dwe ekri sou lòt invocation yo.
earlierContext.semanticState.resultDecimal = "999"
earlierContext.diagnostics[1].code = "CHANJE"
earlierContext.metrics["legacy.save.calls"] = 42
assert(laterContext.semanticState.resultDecimal == "1")
assert(laterContext.diagnostics[1].code == "REGULAR_MOD_INSTEAD_OF_SAVE")
assert(laterContext.metrics["legacy.save.calls"] == 1)
assert(tostring(S.saveSpaghetti(M)) == "0")

-- Erè nan valè antre pa dwe lakòz okenn retou pasyèl.
for _, bad in ipairs({"", "1.2", "pa-yon-antye", {}, true, 0.5}) do
    assert(not pcall(S.saveSpaghetti, bad), "Antre sa a ta dwe rejte")
end
print("PASS kontra API ak pwopriyetè eta Stage 2")

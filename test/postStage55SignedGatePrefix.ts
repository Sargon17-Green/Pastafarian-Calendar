import { MonsterValidationError } from "../src/monsterBase.ts";
import { createProductionSignedGatePrefix } from "../src/postStage55SignedGatePrefix.ts";
import { Patch18VerifiedGateWindowBuilder } from "../src/patch18YearWalk.ts";
import { REAL_YEAR_MAX_PATCH } from "../src/patch16YearMax.ts";
import { FOUNDATION_DAY as F, NormativeOracle } from "./normativeOracle.ts";
function ok(b: boolean, m: string): void { if (!b) throw new Error(m); }
const oracle = new NormativeOracle();
const c = oracle.gateDay(1n) + 1n;
const p = createProductionSignedGatePrefix(c, c + 1n);
ok(p.signedAnchorIndex === 1n, "real Stage16 anchor");
ok(p.positive.length > 0 && p.negative.length > 0, "signed sides");
ok(p.actualNativeCalls === p.positive.length + p.negative.length &&
  p.actualSharedWrites === BigInt(p.actualNativeCalls) * 58n, "Native accounting");
ok(Object.isFrozen(p) && Object.isFrozen(p.positive) &&
  Object.isFrozen(p.negative) && Object.isFrozen(p.positiveGateDays) &&
  Object.isFrozen(p.negativeGateDays), "immutable owned output");
let compared = 0;
for (let i = 0; i < p.positive.length; i++) {
  const n = BigInt(i + 1);
  ok(p.positive[i]!.targetDay === F + n, "positive signed question");
  ok(p.positiveGateDays[i] === oracle.gateDay(n), "positive independent gate " + n);
  compared++;
}
for (let i = 0; i < p.negative.length; i++) {
  const n = -BigInt(i + 1);
  ok(p.negative[i]!.targetDay === F + n, "negative signed question");
  ok(p.negativeGateDays[i] === oracle.gateDay(n), "negative independent gate " + n);
  compared++;
}
const actual = new Patch18VerifiedGateWindowBuilder().build(p.positive, p.negative);
ok(actual.minimumDay < c - REAL_YEAR_MAX_PATCH &&
  actual.maximumDay > c + REAL_YEAR_MAX_PATCH, "Stage37 window coverage");
ok(actual.realGapQuestions === p.actualNativeCalls &&
  actual.realPredecessorWrites === p.actualSharedWrites, "physical second execution");
// A nearby c is not after a gate; historical Stage16 may not fake its anchor.
const nonAnchor = createProductionSignedGatePrefix(c + 1n, c + 1n);
ok(nonAnchor.signedAnchorIndex === null, "no invented anchor");
let invalid = 0;
for (const [cc, tt, max] of [
  [0, 1n, 128], [0n, "x", 128], [null, 0n, 128],
  [1n, 1n, 0], [1n, 1n, 129]
] as unknown as [bigint, bigint, number][]) {
  try { createProductionSignedGatePrefix(cc, tt, max); }
  catch (e) { if (e instanceof MonsterValidationError) invalid++; }
}
ok(invalid === 5, "preflight guards");
console.log("POST_STAGE55_SIGNED_GATE_PREFIX_PASS windows=2 independentGateComparisons=" +
  compared + " realStage37Questions=" + actual.realGapQuestions +
  " constructionNativeCalls=" + p.actualNativeCalls +
  " constructionSharedWrites=" + p.actualSharedWrites +
  " nonAnchor=1 malformedRejected=" + invalid);

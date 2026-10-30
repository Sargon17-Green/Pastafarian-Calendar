// This independent witness MUST fail with exit 1; synthetic regression only.
import assert from "node:assert/strict";
const w=[1,2,1,2,1,2,1,3,2,3,3,3,3];
const month=1,day=2;
const first=w.indexOf(month),last=w.lastIndexOf(month);
const obsoleteSpanAssumption=first<=day-1 && day-1<=last;
const actualMember=w[day-1]===month;
assert.equal(obsoleteSpanAssumption,actualMember,"DISCOVERY27_SYNTHETIC_SPAN_EXPECTED_RED");

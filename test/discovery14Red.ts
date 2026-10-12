// तेरावे ऐतिहासिक defects आणि Stage27 corrected code अपरिवर्तित.
// Stage28 चा एक आवश्यक real full-route red witness: N=M+1, जुना result शून्य.
import { discoverLegacyShortOnlyWide } from "../src/index.ts";
import {
 FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,askBowl,sauce,chooseRank
} from "./normativeOracle.ts";
const count=workCounts(F,F),hidden=buildHiddenDrops(count,STONES);
const visible=buildVisibleDrops(count,STONES,hidden),start=initialBowls(count);
const original=discoverLegacyShortOnlyWide(F,F,visible,STONES,start,1,1n,M+1n);
const correct=chooseRank(askBowl(sauce(F,F),1,1n),M+1n);
const wrong=original.legacyShortOnlyRank!==correct?1:0;
const matches=1-wrong;
if(wrong===1&&matches===0&&original.blockedWideSelection&&
 original.legacyShortOnlyRank===0n&&original.correctedPredecessorRank===correct){
 throw Error("DISCOVERY_14_EXPECTED_RED mismatches=1 matches=0 N=M+1 blocked=1 old=0");
}
throw Error("DISCOVERY_14_WITNESS_DRIFT mismatches="+wrong+" matches="+matches);

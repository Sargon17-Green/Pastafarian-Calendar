import { discoverLegacyDistance, patch02DayTags } from "../src/index.ts";
import { FOUNDATION_DAY as F } from "./normativeOracle.ts";
let pairs=0;
for(let a=-7;a<=7;a++) for(let b=-7;b<=7;b++){
  const c=F+BigInt(a),t=F+BigInt(b);
  const x=discoverLegacyDistance(c,t);
  const y=discoverLegacyDistance(t,c);
  const tags=patch02DayTags(c,t);
  const diff=tags.action.correctedTag-tags.target.correctedTag;
  const expected=diff<0n?-diff:diff;
  if(x.legacyDistance!==expected || y.legacyDistance!==expected) throw Error("सममिती किंवा tag-अंतर चुकले");
  if(x.context===y.context) throw Error("संदर्भ-विलगीकरण बिघडले");
  if(x.context.metrics.get("discovery03.calls")!==1n) throw Error("मापन चुकीचे");
  pairs++;
}
console.log(`STAGE_06_DISCOVERY_03_PROPERTIES_PASS pairs=${pairs}`);

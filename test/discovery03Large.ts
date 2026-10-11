import {discoverLegacyDistance,patch01Save,patch02DayTags} from "../src/index.ts";
import {FOUNDATION_DAY as F,M,SAVE} from "./normativeOracle.ts";
const deltas=[0n,1n,2n,M,-M,1n<<4096n,-(1n<<4096n)];
for(const d of deltas){
  const a=discoverLegacyDistance(F+d,F-d);
  const tags=patch02DayTags(F+d,F-d);
  const raw=tags.action.correctedTag-tags.target.correctedTag;
  if(a.legacyDistance!==(raw<0n?-raw:raw)) throw Error("मोठी bigint गणना चुकली");
}
const a=discoverLegacyDistance(F,F),b=discoverLegacyDistance(F,F);
a.context.logs.push("स्वतंत्र");
a.context.metrics.set("personal",99n);
if(b.context.logs.length || b.context.metrics.has("personal")) throw Error("अवस्था सामायिक आहे");
if(patch01Save(F,F,M).savedValue!==SAVE(M)) throw Error("PATCH01 भंग");
console.log("STAGE_06_DISCOVERY_03_LARGE_AND_ISOLATION_PASS");

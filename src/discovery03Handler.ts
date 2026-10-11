import { bootstrapMonster } from "./monsterBase.ts";
import { oldDistance } from "./discovery03LegacyDistance.ts";

export function discoverLegacyDistance(c: bigint, t: bigint) {
  const context = bootstrapMonster(c,t);
  const legacyDistance = oldDistance(c,t);
  context.branchTrace.push("DISCOVERY_03_TAG_DISTANCE");
  context.metrics.set("discovery03.calls",1n);
  return Object.freeze({calculationDay:c,targetDay:t,legacyDistance,context});
}

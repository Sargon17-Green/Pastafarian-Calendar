import { patch02DayTags } from "./patch02DayTag.ts";

export function oldDistance(calculationDay: bigint, targetDay: bigint): bigint {
  const tags = patch02DayTags(calculationDay, targetDay);
  const difference = tags.action.correctedTag - tags.target.correctedTag;
  return difference < 0n ? -difference : difference;
}

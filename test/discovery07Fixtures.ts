// केवळ चाचण्यांसाठी; Appendix A मधील 11 ग्राइंड-ओळी स्वतंत्रपणे मांडल्या.
// हा नमुना src मधून आयात केलेला नाही आणि उत्पादन अंमलबजावणी इथे येत नाही.
import { SAVE } from "./normativeOracle.ts";

export const NORMATIVE_GRIND_ROWS = Object.freeze([
  Object.freeze([3n, 5n, 7n, 11n, 0] as const),
  Object.freeze([5n, 7n, 11n, 13n, 1] as const),
  Object.freeze([7n, 11n, 13n, 17n, 2] as const),
  Object.freeze([11n, 13n, 17n, 19n, 3] as const),
  Object.freeze([13n, 17n, 19n, 23n, 4] as const),
  Object.freeze([17n, 19n, 23n, 29n, 0] as const),
  Object.freeze([19n, 23n, 29n, 31n, 1] as const),
  Object.freeze([23n, 29n, 31n, 37n, 2] as const),
  Object.freeze([29n, 31n, 37n, 41n, 3] as const),
  Object.freeze([31n, 37n, 41n, 43n, 4] as const),
  Object.freeze([37n, 41n, 43n, 47n, 0] as const)
]);

export function normativeGrindStep(
  g:number,x:bigint,p1:bigint,p3:bigint,p7:bigint,stone:readonly bigint[]
):bigint {
  if(!Number.isInteger(g)||g<1||g>11)throw new RangeError("नियमाधारित grind 1..11");
  if(!Array.isArray(stone)||stone.length!==5 ||
     Array.from({length:5},(_,j)=>typeof stone[j]!=="bigint").some(Boolean))
    throw new RangeError("पाच bigint दगड अपेक्षित");
  const row=NORMATIVE_GRIND_ROWS[g-1]!;
  return SAVE(x*x + row[0]*x + row[1]*p1 + row[2]*p3 +
    row[3]*p7 + stone[row[4]]!);
}

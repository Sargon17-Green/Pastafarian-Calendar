# INT-02 bounded month composition ABI — candidate
Project PC-BRANCH-COBOL-SIMPLIFIED-CHINESE. Parent e79b73e307e9d5393d2977b221393ede7106913c.
CALENDAR-MONTH-COMPOSITION(op,Y,m,rank-in,vector-in,result,vector-out,status), all by reference.
C=count, R=one-based lexicographic rank, U=unrank; vectors 47 unsigned binary-short items, unused items zero; Y/m/status unsigned binary-short. Domain 252<=Y<=5778, 1<=m<=47, 4m<=Y<=123m. Distinct input/output handles; output handle empty at entry; caller frees it. Invalid domain, vector or rank: 22; overflow: 24; service errors propagated. No mutation of input. U returns no handle, C/R return no vector.
DP uses 48*5779*11 unsigned 32-bit limbs in base 10^9 = 12,205,248 bytes; 99 decimal digits cover the proved 95-digit maximum. Recurrence D[p,s]=D[p,s-1]+D[p-1,s-4]-D[p-1,s-124]. Carries and borrows normalized at each limb, final carry must be zero. At most 3,000,000 limb updates; at most 5640 candidate block lookups. Only bounded rank/count serialization; no service scratch allocations or new arena. Caller owns returned handle. The month gate is separate from wide selection and weaving.
Independent differential uses inclusion-exclusion and explicit boundary enumeration; rank inversion and invalid ranks, input immutability and live heap baseline are checked by the driver. Oracle-only is not COBOL evidence.
```sh
cobc -free -x -o int02-month-composition test/int02_month_composition_driver.cob src/calendar_month_composition.cob src/big_integer.cob
node test/int02_month_composition_diff.mjs ./int02-month-composition
```
Do not rerun the six accepted gates. Native compilation and differential remain pending until observed. No converter readiness or full INT-02 acceptance.

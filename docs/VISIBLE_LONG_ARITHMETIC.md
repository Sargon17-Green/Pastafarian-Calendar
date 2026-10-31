# ᓈᓴᐅᑏᑦ: single-digit Excel algebra (Stage 1)

**Current contract, superseding the earlier base-10000 experiment.**
Each input cell is exactly one decimal digit in 0..9. Two operand boards have 8 rows × 16 columns = 128 digits each. Their sum has 129 slots; the product has 256 slots. All arithmetic is implemented via visible Excel formulas, not opaque string or VBA big integers.

## Workbook layout

| Sheet | Role |
| --- | --- |
| `00_ᓈᓴᐅᑏᑦ` | Navigation and scope |
| `01_ᓈᓴᐅᑏᑦ` | Two blue editable 8×16 digit boards (D8:S15 and D20:S27) |
| `02_ᐃᓪᓗᒍ` | 129 addition rows: digit, carry in, raw, digit out, carry out, identity |
| `03_×` | 128×128 matrix of 16,384 elementary products, each 0..81 |
| `04_Σ` | Diagonal sums, modulo 10, carries, 256 product digits |
| `05_▦` | Colour-coded horizontal digit boards for A, B, sum and product |
| `06_∑` | Mathematical note and source documentation |
| `07_ᖃᐅᔨᓴᕐᓂᖅ` | Input, carry and result invariants |

## Formal proof of digit identity and arithmetic

Define the encoding Φ of a digit array d indexed from the units end by Φ(d)=Σ_i d_i 10^i, where every d_i∈{0,...,9}.

**Uniqueness.** If Φ(a)=Φ(b), reduction modulo 10 shows a_0=b_0. After subtraction of those equal digits and division by 10 the same reasoning proves a_1=b_1, and induction proves all remaining digits equal. Leading zeros encode the same integer.

**Addition.** Let c_0=0, t_i=a_i+b_i+c_i, r_i=t_i mod 10, c_(i+1)=⌊t_i/10⌋. The exact identity a_i+b_i+c_i=r_i+10c_(i+1), multiplied by 10^i and summed, telescopes the carries to Φ(a)+Φ(b)=Σ_i r_i 10^i+c_n10^n.

**Multiplication.** By distributivity, Φ(a)Φ(b)=Σ_k(Σ_{i+j=k}a_i b_j)10^k. The matrix on `03_×` explicitly computes each a_i b_j. `04_Σ` sums each diagonal and applies the same base-10 carry relation, establishing exact equality with Φ(product).

**Excel exactness bound.** Since each a_i b_j≤81, any diagonal has ≤128 terms, so q_k≤10,368. If incoming carry≤1,152, outgoing carry floor((10,368+1,152)/10)≤1,152, by induction from zero. Thus all intermediate totals ≤11,520<2^53, and binary64 numeric arithmetic produces exact integer outputs.

The mathematical proof is displayed in worksheet `06_∑`; its role is a visible explanatory note, not merely an implementation assertion.

## Verification and limitations

A demonstration with one 123-digit and one 119-digit value was checked **digit-by-digit**: all 256 product slots and all 129 sum slots exactly reconstruct Python independent arbitrary-precision integer results. Workbook ZIP and key formulas were inspected; a preview was rendered. Native Microsoft Excel recalculation and VBA compilation remain **NOT TESTED**. The 128-digit capacity is a bounded current build; expanding to 256 digits requires expanding the board and the product matrix, not changing the mathematics. Negative values and SAVE modulo 2^127−1 remain unimplemented. Canonical ordered F(c,t) with five date components is **NOT IMPLEMENTED**.

The older `base=10000` worksheet generation has been **replaced** by the new source in `src/VisibleArithmeticFormulas.bas`.

Inuktitut vocabulary sources: https://tiontario.ca/wp-content/uploads/2020/08/vocabulary-booklet-web-2.pdf and https://ksec.ca/wp-content/uploads/2015/10/Math-English-Inuktitut-Glossary.pdf . Remaining linguistic labels require native review; do not silently invent them.

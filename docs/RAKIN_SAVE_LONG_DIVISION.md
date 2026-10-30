# Rakin: exact Euclidean SAVE and signed subtraction (Word VBA)

**Code:** `src/RakinSaveAndSubtract.bas`; self-contained Word VBA, independent of all foreign programming-language branches. In Word desktop import the module to a trusted macro-enabled document/template, then run `RakinSignedAndSaveReport` via Alt+F8. Two unsigned decimal input strings (up to 256 digits) are used to create three colour-coded tables: signed A−B, SAVE(A), SAVE(B). Every filled table cell contains exactly **one digit**. The minus sign is displayed separately.

## Proof

For a decimal string, define Φ(d)=Σ_i d_i10^i. It is unique after leading zero removal, since equality implies equal units digits modulo ten, then induct after subtract/dividing by ten. For subtraction use `t_i=a_i−b_i−borrow_i`, `digit_i=t_i mod 10`, `borrow_(i+1)=1 iff t_i<0`, giving `t_i=digit_i−10borrow_(i+1)`. Multiplying by 10^i and summing telescopes the borrows, proving the signed difference algorithm.

Let M=2^127−1=170141183460469231731687303715884105727. For absolute decimal input digits d_1…d_n processed left-to-right, define r_0=0 and r_(k+1)=(10r_k+d_(k+1)) mod M. Inductively r_k∈[0,M−1], so t=10r+d<10M; repeated subtraction of M stops after at most nine subtractions. The result is therefore exactly the Euclidean remainder, without any fixed-precision big integer.

The canonical SAVE is `SAVE(x)=1+((x−1) mod M)`. Equivalently it is x mod M with zero residue represented by M. For negative x, first compute q=|x| mod M; the Euclidean remainder is zero if q=0, otherwise M−q. This proves the signed implementation for zero and negative inputs as well as positive inputs.

Maximum unsigned operand length: 256 ASCII decimal digits. Computation uses only small VBA Long counters, characters and strings. No floating-point storage of any large operand.

## Evidence / limitations

- Reference string recurrence tested on **512 inputs** (including ±M, 0, −1, M+1, 256-digit magnitudes, 500 random cases) against independently computed Python arbitrary-precision `1+((x−1)%M)`: all PASS.
- Eight Word VBA runtime assertions are supplied in `RakinModularSelfTest`, but **Word-native execution and compilation have not been performed**.
- The five canonical date components F(c,t), 17 cutlet and 47 month name approvals, and the remaining 55-stage gates are not complete.

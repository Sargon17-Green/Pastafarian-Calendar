# Foundation full weave root and 177-digit selection — audit witness

**Status:** independent arithmetic references reproduced; HDL source
and SHA-256 gates committed, **not yet certified by Icarus CI**.

Authoritative input: `main@56bc4173aae4975ded019ef5ab5a36249f1424df`,
sections M, N, V. The calendar target is
`P(c,t)` for `c=t=Foundation=-15055671`. The applicable year
starts at `firstDay=-15057702`. The sauce to select the *entire
woven month word* is evaluated at `(c, firstDay)`, not `(c,c)`.

## Sauce checkpoint for (Foundation, firstDay)

```text
Bowl values after 12 post-stirs:
Q1 = 104801149399974323964160455528163370769
Q2 = 78471368830660551745973228614769007971
Q3 = 120242669391032623778229844410337772153
Q4 = 68405753691768034022026521715063004414
Q5 = 69216999894300723029207159165527918879
Q6 = 102967821965301591097533657552300482421
orderAt46 = [2,5,6,4,3,1]
B = 4, z = 32; next bowl is 3
A0 = 106458209471735273212934705135928382248
D  = 158023501449213800568736474174904318352
D is even; the answer direction is -1.
```

The first-digit calculation and post-stir sauce are now also
asserted by the separate test-only SystemVerilog gate oracle.
The claim is not CI-verified for these **new** assertions yet.

## Root count independently reproduced

The ordered 45 length-vector entries total 4244 days.
The first-position transfer calculated the root woven count
with arbitrary-precision integers in two independent references:

```text
bit_length(N) = 22470
minimal BE byte length = 2809
SHA256(minimal BE N) =
925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da
```

The 22528-bit test-only root engine must write exactly 2809 bytes
to `build/foundation_weave_root.bin`. The runner checks this
hash before using the count for selection.

## Canonical wide choice with bowl 4, seal 32

With `M=2^127-1`, `k=177`, and `N` from above:

```text
S=M^177, bit_length(S)=22479
A_j = 1+((A0-1-j) mod M)  (0<=j<177; no wrap occurs)
W = 1+sum((A_j-1)*M^j)
floor(S/N) = 555
Lw=555*N
W<=Lw: true, so the original W is accepted; no rejection steps.
rank = 1+((W-1) mod N)
bit_length(rank)=22469
SHA256(minimal BE W)=
41b957eacf9a86fcdaaf83047e7f5c3a85df22adee5a0179581f5c89734d630d
SHA256(minimal BE rank)=
2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06
rank BE length=2809 bytes.
```

`tests/tb_weave_full_rank.sv` builds the exact wide answer with
177 radix-M digits; it checks `555*N<=S<556*N` and calculates
`mod N` by repeated **exact subtraction** (at most 555 times)
without invoking Icarus's defective native enormous `/`.

`scripts/verify_weave_fullroot.sh` validates the root SHA first,
then executes the rank module and validates the selected rank SHA.
Both files and execution logs are captured by isolated QA.

## Remaining acceptance work

- Actual successful Icarus run of full root and selected rank
  **on the same source SHA**, respecting memory and time budgets.
- Exact 4244-symbol lexical weave `unrank` under bounded resources.
- Independent `47P45` month-name choice through bowl 5 seal 33.
- Final canonical month index 20 and day-in-month 56, plus
  multi-vector regression for all 5 calendar output fields.
- Qualified native Kalaallisut approval for all 64 names
  (0 are approved, 8 are only provisional lexical candidates).

The root/rank hashes are **test-only witnesses**, not output
strings. This must not be merged into `main`. Stage 1 remains
open; Stage 2 must not be started.

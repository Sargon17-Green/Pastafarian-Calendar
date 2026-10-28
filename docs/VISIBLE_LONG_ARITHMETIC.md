# Visible arithmetic in Excel / ᓈᓴᐅᑏᑦ

This is an independently inspectable *worksheet formula* implementation of positive-integer addition and long multiplication, NOT yet the canonical calendar F(calculation day,target day).

## Workbook sheets and algorithm

| Prefix | Visible label | Operation |
|---|---|---|
| 08 | ᓈᓴᐅᑏᑦ | Blue editable tiles A[i], B[i] |
| 09 | ᓈᓴᐅᑏᑦ + | Rowwise addition and carry |
| 10 | ᓈᓴᐅᑏᑦ × | 64×64 multiplication matrix |
| 11 | ᓈᓴᐅᑏᑦ Σ | Anti-diagonal reduction and carry |
| 12 | ᖃᐅᔨᓴᕐᓂᖅ | Example checks, limits and status |

Use base B=10,000: one 4-digit **integer** per cell. The least significant block is at row 8 and higher powers occupy rows 9..71. Every chunk is 0..9999. This prevents the user's decimal numbers from being rounded to 15 significant digits.

Addition, rows i=0..63:
```
raw[i] = A[i] + B[i] + carry[i]
digit[i] = MOD(raw[i], 10000)
carry[i+1] = QUOTIENT(raw[i], 10000)
```

Multiplication is *written out* on sheet 10:
```
P[i,j] = A[i] * B[j]              (one visible formula cell)
diag[k] = SUM(P[i,j] : i+j=k)
raw[k]  = diag[k] + carry[k]
digit[k] = MOD(raw[k], 10000)
carry[k+1] = QUOTIENT(raw[k], 10000)
```
This is exactly the familiar paper-and-pencil algorithm. It produces up to 128 blocks = 512 digits from two 64-block (256-digit) operands.

### Proof of intermediate exactness

Each `P[i,j] ≤ 99,980,001`; each diagonal sums at most 64 such entries. With the bounded incoming carry, raw diagonal sums remain below 6.4×10^9, far below 2^53, so all numeric cell operations remain exact in Excel's binary floating-point representation. Increasing N requires revisiting this bound and workbook performance. The current demonstrator supports nonnegative integers only.

The native `.xlsx` is formula-driven and runs without enabling VBA. If formulas are damaged, an optional module can rebuild them in a saved `.xlsm` copy. The workbook and its optional macro source are distributed separately as conversation attachments; this repository file gives the same equation/coordinate contract without silently substituting another language implementation.

Demo independently checked: reconstructed every product tile and addition tile, compared with Python arbitrary-precision `int`, and passed 13 workbook fixture checks. This is **not** Excel/Office native certification.

### Language status and responsibility

The confirmed noun **ᓈᓴᐅᑏᑦ** means *Numbers*; its source is https://ilinniapaa-learning.ca/wp-content/uploads/2024/04/Inuktut-Titiqqiriniq-Resources-Checklist-English.pdf . Other operation labels are mathematical symbols or unapproved candidates, not purported native-validated translations. Stage 1 17+47 calendar names remain unfrozen, and `main` is untouched.

Canonical calendar: ordered F(c,t) with precisely five output components remains NOT IMPLEMENTED; no calendar results may be fabricated or cached by these worksheets.

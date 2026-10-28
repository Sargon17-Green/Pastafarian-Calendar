# ᓈᓴᐅᑏᑦ / exact signed subtraction in Excel

This is a Stage 1 arithmetic worksheet extension. Not a Pastafarian calendar F(c,t) converter.

## Visible sheets (v7 workbook attached to the conversation)

- `08_−`: 128 rows, digit A_i, digit B_i, A−B borrow, raw, output, next borrow, an algebraic identity check; a second B−A borrow chain; a sign gate; final |A−B| digit.
- `09_▦−`: horizontal 8×16 grid of magnitude digits, sign in a separate highlighted cell. All numeric tiles are one decimal digit 0..9.
- `10_∑−`: formal proof and four live tests. The proof is also attached as a native Excel cell note to `B7`.

For i starting at the units column, compute
```
t_i = a_i - b_i - borrow_i
r_i = MOD(t_i,10)
borrow_(i+1) = IF(t_i<0,1,0)
t_i = r_i - 10*borrow_(i+1)
```
Multiplying the final identity by 10^i and summing proves
```
A-B = SUM_i(r_i 10^i) - 10^n*borrow_n.
```
If A>=B, borrow_n=0 and the digits encode A−B. If A<B, compute B−A in a parallel exact row chain and report minus the resulting magnitude. Leading zeros are immaterial.

### Exactness bound
Each intermediate t_i is between −10 and 9, each borrow is either 0 or 1, and every modulo/carry is an integer. Excel's binary64 format therefore represents all intermediate arithmetic exactly.

### Verification
- Default 128-digit A−B was reconstructed from all digit cells and matched independent Python arbitrary-precision integers.
- Change inputs to A=0,B=3: sign −1 and magnitude 3, PASS.
- Change inputs to A=3,B=3: sign 0 and magnitude 0, PASS.
- All four dynamic workbook QA cells in `10_∑−` returned TRUE; scan found no formula errors.
- UI range `08_−!A1:O16` rendered for visual inspection.
- Native Microsoft Excel recalculation remains untested. The canonical M=2^127−1 SAVE operator is NOT implemented in Excel yet.

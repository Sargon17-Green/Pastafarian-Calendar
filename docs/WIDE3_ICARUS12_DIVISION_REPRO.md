# Icarus 12: incorrect native 384-bit unsigned quotient in wide3 testcase

## Reproduction and evidence

The test-only wide selection fixture in
`tests/tb_selection_rejection_equivalence.sv` originally evaluated
`big_space / big_n` directly as a SystemVerilog `logic signed [383:0]`
division, with positive values in range.

Icarus Verilog 12.0-2build2 from GitHub Actions run
[39772016684](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39772016684)
returned an incorrect quotient. The whole suite ended in FAILURE at
`WIDE_THREE_DIGITS_ARITHMETIC`.

Define `M=2^127-1`,
`S=M^3`, `N=M^2+1`. The **exact mathematical** long division is:

```text
S_hex = 1fffffffffffffffffffffffffffffff400000000000000000000000000000017fffffffffffffffffffffffffffffff
N_hex = 3fffffffffffffffffffffffffffffff00000000000000000000000000000002
Q_correct_hex = 7ffffffffffffffffffffffffffffffe
R_correct_hex = 3ffffffffffffffffffffffffffffffe80000000000000000000000000000003
Q_icarus12_hex = 7fffffffffffffff0000000000000003
```

The identity is easy to prove without dividing:

```text
M^3 = (M-1)(M^2+1) + (M^2-M+1)
0 <= M^2-M+1 < M^2+1
```

Thus `Q=M-1` and `R=M^2-M+1` are forced by Euclidean
division. The discrepancy is in the native division result returned
by the simulator, not in the prescribed Pastafarian algorithm.

## Independent mitigation, test-only

`tests/pcal_exact_division_pkg.sv` implements a **384-bit unsigned
binary long divider** with a 385-bit remainder register; it does not
use built-in `/` or `%` to calculate quotient and remainder.

`tests/tb_wide_division_golden.sv` checks 36 independently computed
dividend/divisor/quotient/remainder vectors, including the failing
`M^3/(M^2+1)` and full-width 384-bit cases.

`tests/tb_selection_rejection_equivalence.sv` tests the exact
quotient and remainder against the derivation above, preserving a
non-fatal diagnostic for the known incorrect simulator native value.
It NEVER uses that native value for the acceptance rule.

This mitigation does **not** validate any production big-integer
division; the independent long divider is test-only. The production
ASIC must implement exact bigint division/remainder and must be
checked separately through later architecture, RTL and formal gates.

## Validation gate

- Original Icarus native-division mismatch: **observed and recorded**.
- Updated test-only exact divider: **written, pending new CI verdict**.
- 36 generated golden vectors: **written, pending new CI verdict**.
- No Stage-1 PASS and no Stage-2 work is authorized by this document.

# Rakin: decimal digits as exact arithmetic (Word VBA)

## The command

Import `src/RakinDigitArithmetic.bas` as a Word standard VBA module into a trusted macro-enabled document or template, then run `RakinVisibleArithmetic` (Alt+F8). Input two unsigned decimal integers, each up to 256 digits. It computes **exact decimal addition and multiplication without floating-point or web dependencies**, and inserts four formatted 16-column digit tables (A, B, A+B, A×B). Each nonempty cell contains exactly one digit. It also inserts the mathematical explanation in the document.

Run `RakinArithmeticSelfTest` to exercise five built-in fixtures in Microsoft Word; **native execution has not yet been recorded**, so no PASS is claimed for this command.

The previous `InsertPastafarianDate` remains available for presenting an externally computed *five-component* canonical date. Neither command implements the actual calendar F(c,t).

## Mathematical proof

For digit sequence d in least-significant-first order with d_i ∈ {0,…,9}, define Φ(d)=Σ_i d_i10^i.

**Injective representation up to leading zeros:** Φ(a)=Φ(b) implies a_0=b_0 upon reduction modulo 10. Subtract and divide by 10; induction proves every digit the same.

**Addition:** t_i=a_i+b_i+c_i, r_i=t_i mod 10, c_(i+1)=⌊t_i/10⌋ with c_0=0. Multiplying the identity a_i+b_i+c_i=r_i+10c_(i+1) by 10^i and summing cancels all internal carries, yielding Φ(a)+Φ(b)=Φ(r)+c_n10^n.

**Multiplication:** By distributivity, Φ(a)Φ(b)=Σ_k(Σ_{i+j=k}a_ib_j)10^k. Accumulate all small products in an array of diagonal sums and normalize each by base-10 carries; the same telescoping identity proves that the digit string equals the full integer product.

**No precision loss:** With at most 256 digits per operand, an elementary product ≤81, each raw diagonal ≤256×81=20,736. Inductively an incoming carry ≤2,304 and a total before division ≤23,040. All these are well within signed VBA `Long` (2³¹−1). The code *never* casts the 256-digit number to any machine numeric type.

## Language

`rakin` is attested for counting/numbers; `trapom rakin` for addition, `yeñpramen` for multiplication in a Chilean educational dictionary. These are presentation labels only, and do not replace the missing official approval of the project's 17 cutlet + 47 month names.

Sources:
- https://bibliotecadigital.mineduc.cl/bitstream/handle/20.500.12365/17171/Diccionario_mapudungun.pdf?isAllowed=y&sequence=1
- https://mapudungun.cl/nemul/raki.html

## Engineering limits

- Input integers must be unsigned ASCII decimals, length 1..256; zero is supported.
- Output sum is at most 257 digits; product at most 512 digits; both one digit per table cell.
- Word page layout may span many pages at maximal length.
- Macro security must be managed by the user in Word; do not enable untrusted documents.
- Five normative calendar fields, SAVE, cutlet/month names and ordered day pair remain out of scope. Stage 1 stays open.

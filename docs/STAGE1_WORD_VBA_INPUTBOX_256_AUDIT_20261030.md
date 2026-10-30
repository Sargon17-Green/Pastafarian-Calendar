# Stage 1 — Word VBA InputBox 256-digit boundary audit (2026-10-30)

## Scope / authority
- Branch: `Word-VBA+Mapudungun`, **Stage 1 only**. Pre-change verified HEAD: `33b30cce44ecbfdad01a326de36eb22851b95eaa`.
- Changed **only the entry paths**, not exact arithmetic: `src/RakinSaveAndSubtract.bas` and `src/RakinDigitArithmetic.bas`.
- Historical reference tests: 512/512 Python SAVE/subtraction, prior 7 PASS / 1 SKIP independent boundary suite. **Not rerun** here.
- No imported calendar engine, no merge to `main`, no Stage 2 authorization.

## Proven defect and narrowly scoped fix
Microsoft's official VBA `InputBox` documentation says the text box accepts only 255 characters **and the returned string is truncated to 254 characters**:
https://learn.microsoft.com/en-us/office/vba/language/reference/user-interface-help/inputbox-function

Both report macros formerly collected a claimed 1..256-digit operand with one `InputBox`, then accepted any returned 1..256 ASCII decimal digits. A 255- or 256-digit input can thus be silently accepted as a shortened 254-digit number, potentially producing **arithmetically correct output for the wrong input**.

Both report macros now use a private `PromptExactUnsignedOperand` routine in their own module (no cross-module dependency). It:
1. Requires an explicit decimal digit count `1..256` (at most 3 ASCII digits).
2. Reads the first `min(n,128)` digits in a distinct `InputBox`, with exact length and ASCII digit validation.
3. For `n>128`, reads the exact remaining `n-128` digits in a second `InputBox`, and rejects a missing, canceled, shortened, or invalid chunk.
4. Returns the concatenated operand only when all checks succeed; the existing arithmetic and table renderer are unchanged.

Each digit chunk is at most 128 characters and cannot be silently cut by the 254-character VBA return limit. The length question introduces an additional explicit step, but prevents numeric data corruption. Caller-facing input is still unsigned; `RakinSaveExact` remains a signed-number API when called programmatically.

## Non-native regression evidence, performed this round
- 9 chunk reconstruction cases: lengths `1, 2, 39, 127, 128, 129, 254, 255, 256` — **9/9 PASS** in an independent JavaScript mirror of the chunking specification.
- 5 negative model checks: total length `0`, total length `257`, wrong first chunk at 256, missing final chunk at 129, wrong final chunk at 255 — **5/5 rejected** in that mirror.
- After GitHub readback, both changed modules underwent 9 static source checks each (**18/18 PASS**): one helper per module, 3-digit count gate, `1..MAX_DIGITS` gate, exact first and second lengths, ASCII validation, changed public entry calls, declared 256 digit maximum, and exact byte-for-byte equivalence to the earlier code after reversing **only** the intended UI-entry patch. The original arithmetic bodies therefore stayed intact.
- Scope: these are source-level and independent-specification checks, **not** Word compilation, native UI automation or actual VBA execution.

## Five canonical component handoff review (read-only)
`src/PastafarianWord.bas` currently prompts for exactly five **externally supplied** fields in this order:
`year`, `cutletName`, `dayInCutlet`, `monthName`, `dayInMonth`.
It checks syntactic signed decimal for year, positive decimal for both day fields, and only nonempty text for names. It does not verify provenance, the 17 cutlet / 47 month canonical indices, Unicode NFC, Mapudungun linguistic approval, or calendar range constraints. `CalculatePastafarianDateInWord` explicitly raises NOT IMPLEMENTED. None of these omissions implies the five-field canonical converter exists.

**Additional pending input-contract risk:** the five-field prompt also uses the limited VBA `InputBox`; long external values could be truncated. Do not infer a safe maximum length for year or canonical names without the normative five-field specification. The five-field macro was **not changed** in this patch; establish lossless external-value transfer and explicit field length/index rules before native approval.

## Open acceptance gate / precise NEXT
When a Word Desktop Windows machine is available:
- Import `src/RakinSaveAndSubtract.bas` and `src/RakinDigitArithmetic.bas` into trusted `.docm`; compile VBA.
- Run `RakinModularSelfTest` (8 local assertions) and `RakinArithmeticSelfTest` (5), preserve Native output, machine, time and HEAD.
- Exercise **interactive** 128, 129, 254, 255, 256-digit entry, including intentionally shortened/canceled second chunks, then check grid for `A=0,B=M`, `A=M+1,B=1`, and a 256-digit pair (one digit per filled cell; sign separate). Preserve evidence.
- If Word remains inaccessible, stay in Stage 1 and review lossless, provenance-aware five-field external tuple input **without implementing F(c,t)**. No Stage 2, no main merge.

Word Native remains **NOT RUN**; device availability check on 2026-10-30 found two remote Windows devices offline. Mapudungun labels and F(c,t) remain unapproved/unimplemented.

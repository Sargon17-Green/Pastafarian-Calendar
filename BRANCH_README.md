# Excel / Inuktitut (ᐃᓄᒃᑎᑐᑦ)

Independent Excel VBA implementation branch; based on the normative rules in the root README. **Stage 1 only**: a usable Excel input/display host, not a canonical calendar converter. The computational core F(calculationDay, targetDay) is not yet present; no output of five fields may be attributed to the engine.

## Run on Windows Excel desktop
1. Create/open a workbook, press Alt+F11, import `src/PastafarianExcel.bas` as a standard module, save as `.xlsm` (not `.xlsx`).
2. Run `InitializePastafarianSheet` using Alt+F8. It creates or formats the `Calendar` sheet without clearing existing user data.
3. Enter externally verified *exact canonical* five values into **B11:B15** as **text** (year, cutletName, dayInCutlet, monthName, dayInMonth). Do not type numeric values into General-format cells; Excel truncates long integer precision.
4. Run `RenderPastafarianDate`: the formatted five-component string appears in E5.
5. `CalculatePastafarianDate` deliberately raises a clear NOT IMPLEMENTED error: no invented answer.

The day-pair inputs in B5:B6 are reserved for a future independent exact-integer engine; the formatter never uses them. Root README remains untouched, and main is not modified. Names must be localized by meaning from the canonical rules and approved in fixed canonicalIndex order, never sorted by alphabet or Unicode. Inuktitut syllabics require Unicode-capable Office fonts and native-language QA. No translations are asserted as approved in this stage.

## Scope and correctness
- Every canonical computation requires distinct calculation and requested days and the fixed five output fields; the pair is ordered.
- Use exact signed-decimal arithmetic (not Excel floating-point) before attempting F(c,t), including M = 2^127 - 1.
- Complete all 55 governed stages and independent native comparison before declaring a converter or placing any values in canonical-output cells automatically.
- No imports from any other programming-language branch and no network backend fallbacks.
- Office-native execution and linguistic review are **NOT VERIFIED** in this commit.

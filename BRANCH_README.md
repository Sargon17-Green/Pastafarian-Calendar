# Word VBA / Mapudungun

Independent Microsoft Word macro branch; rooted in the normative Maltese README. This is **Stage 1 bootstrap**, not a date-conversion engine.

## Working Word command

On Word desktop for Windows:
1. Open a document, press **Alt+F11**, import `src/PastafarianWord.bas` as a standard VBA module.
2. Save the document as `.docm`, or save the macro in a trusted `.dotm` template.
3. Press **Alt+F8**, select `InsertPastafarianDate`, and click Run.
4. Supply exactly five **externally calculated and verified** canonical values in order: year; cutletName; dayInCutlet; monthName; dayInMonth. The macro validates decimal fields and inserts the tuple at the current cursor position.
5. `CalculatePastafarianDateInWord` intentionally reports NOT IMPLEMENTED. The macro does not compute dates.

The order-sensitive canonical `F(calculationDay, targetDay)` still requires an independently implemented exact-number engine through the governed 55 stages. No request to another branch, online service, or guessed output is allowed.

Natural-language source: **Mapudungun** (ISO 639-3: arn), language of Mapuche communities, with no single universally adopted orthographic standard. No purported local translations are included prior to qualified review. Any 17 cutlet names and 47 month names must retain fixed `canonicalIndex` from the normative reference, with Unicode NFC and native orthography QA. Technical identifiers in the prototype are not presented as translations.

## Verification state

The macro source has been committed; **native Word VBA compilation and execution have not been verified**. Stage 1 remains open. Do not merge into main or label a complete implementation yet.

Reference: https://www.cambridge.org/core/journals/journal-of-the-international-phonetic-association/article/mapudungun/344B2E4440607BD0B521E8DECF98BAFF

## New: Rakin single-digit arithmetic

The independent, **unverified-in-native-Word** `RakinVisibleArithmetic` command in `src/RakinDigitArithmetic.bas` prompts for two decimal integers (up to 256 digits each), performs exact schoolbook addition and multiplication using integer arrays, and inserts colour-coded tables with exactly **one digit per cell**. A complete algebraic proof is in `docs/RAKIN_DECIMAL_ALGEBRA.md` and the macro comments. `RakinArithmeticSelfTest` contains five fixtures that must be run inside Word before acceptance.

**No calendar date calculation is implied;** this is an exact arithmetic component only. No main branch merge is authorized.

## New Stage 1 arithmetic: signed subtraction and SAVE

The additional macro `RakinSignedAndSaveReport` in `src/RakinSaveAndSubtract.bas` accepts two unsigned decimals (1..256 digits), inserts a colour-coded signed difference and both canonical SAVE residues with one decimal digit per table cell. The sign is outside the cells. See `docs/RAKIN_SAVE_LONG_DIVISION.md` for the exact long-division proof and `RakinModularSelfTest` for eight native acceptance assertions. Word-native execution is **still pending**. This is a mathematical primitive, not F(c,t) or a final calendar implementation.

## Stage 1: exact five-field selection input (Word-native validation pending)

`InsertPastafarianDate` now rejects a 254-character InputBox return, because VBA InputBox can silently truncate longer strings. For arbitrary-length fields, import `src/PastafarianWord.bas` and use `InsertPastafarianDateFromSelection`.

Select exactly five Word paragraphs with these labels in order (example placeholder values, **not** a canonical date):

```text
year=123
cutletName=EXTERNAL_CUTLET
dayInCutlet=1
monthName=EXTERNAL_MONTH
dayInMonth=1
```

The new command preserves the selected source and inserts a separate five-field display after it. It checks field order, ASCII integer syntax and nonzero day fields, but **does not** verify source authenticity, 17/47 canonical name indices, Unicode NFC, Mapudungun linguistic review or calendar calculations. No `F(c,t)` exists. A new local VBA smoke test `PastafarianInputContractSelfTest` is written but not executed in Word. See `docs/STAGE1_WORD_FIVE_FIELD_SELECTION_CONTRACT_20261030.md` for non-native regression and acceptance steps.

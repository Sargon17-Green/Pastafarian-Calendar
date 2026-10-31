# Stage31 / Discovery16 — normative Pastafarian year-boundary probe (research only)

Branch: PowerShell+Tagalog. Direct successor of Stage31's 50 + 72 finite ordinal observations on commit dd4fc94347872f82b4a9378cab5038966a0e7b2d. Stage30 remains the last completed stage; this is **not** a Stage31 seal.

## Why this additional test is necessary
The previous 122 observations are offsets around the foundation day F=-15055671. A distance of 365/366 or 36525/36526 days is not a Pastafarian year-boundary mapping, and no Gregorian conversion was performed. The normative Pastafarian calendar has variable-length years (declared range 252..5778 days), found by gate enumeration; therefore presumed civil-year offsets cannot establish a calendar boundary.

## Inputs and independently specified boundary selection
Use the normative `Get-NormYear5000 -CalculationDay F` year record, not an arbitrary fixed-day approximation. Verify that `OpenGateDay < F <= CloseGateDay`, the normative year number equals 5000, the length is 252..5778 days, and gate-index gap >=6. For the same calculation day F, select exactly six target ordinals: OpenGateDay-1, OpenGateDay, OpenGateDay+1, CloseGateDay-1, CloseGateDay, CloseGateDay+1. For each target invoke both seal 1 and seal 2: 6 * 2 = 12 rows. The open endpoint is excluded and the close endpoint included in the normative year definition.

## Executable acceptance and independent oracle
On Windows PowerShell 5.1, call the production `Invoke-CalendarDateSpaghetti` and `Get-Discovery13AnswerStreamFromContext`. In a separate module, compute `Invoke-NormSauce` and `Get-NormAnswerStream` for each identical input, comparing First and Step exactly. Verify First in 1..M, Step in {-1,+1}, exactly 58 order-memory writes, and exactly one Patch12 call per observation. Four metadata assertions, four normative-boundary assertions, 12*6 row assertions, five aggregate assertions = **85 planned assertions**. Capture exact year open/close ordinals, 12 individual records and summary counters. Zero failed assertions required. No observed counts or actual boundary values are presumed in advance.

The year boundary is identified by the independent normative calendar, not by the production implementation or a civil/Gregorian epoch conversion. This tests behavior *at the reference year boundaries*; it does not independently prove the reference calendar or the full five-component output. Preserve the Stage26 historical expected-red. Exact SHA-pinned checkout, 20-minute job limit, retained transcript/metadata; do not duplicate past runs or claim native success until completed job logs.

## Seal gates
A completed job with 85/85 assertions and predecessor regression + verify success supports a bounded research finding, not global statistical independence/uniformity or all-calendar accuracy. Before Stage31 seal: review actual records and boundary ordinals; check stability and metadata/CI compatibility for an evidence-only seal, and ensure no claims about Gregorian mapping or distribution are made. Keep `CURRENT_STAGE=30` and `LAST_COMPLETED_STAGE=30` until those gates are reviewed. No production source, main, or protected-ref changes.

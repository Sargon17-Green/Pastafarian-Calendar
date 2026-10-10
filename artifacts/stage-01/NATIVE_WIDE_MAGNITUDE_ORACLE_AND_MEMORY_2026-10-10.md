# Stage 1 QA — beyond-128-bit Native numerical domain and g/p read provenance

The newly added Native test uses unchanged, exact-source-pinned Befunge-98
to verify 13 large-number four-field date/count inputs with boundaries
at 255, 256, 257, 512, and 1024 bits and 155-/240-digit decimal
magnitudes. The corpus includes forward/reverse adjacency, negative
and mixed-sign crossings and equal-magnitude opposite-sign cases.

Every expected seven-field answer comes from **three independently
executed Native Befunge-98 references**: one work_counts and two save
executions. The QA production is run for each input in three whitespace
layouts: normalized, leading-tab/CRLF inner separator, and mixed
tab/space/trailing whitespace. Python only constructs large integer
input tokens and compares native output; it never calculates the
calendar answer.

For each case a separate Native Program execution instruments direct
g physical return values, observed prior p write relationships,
all engine-level Space.put writes, executed k target and zero
runtime putspace usage. The Native instrumented program must
match the independent Befunge reference output and terminate.
The Python 3 auditor independently reconstructs all 13 large input
values and SHA-256 input identities and rejects ten deliberately
tampered reports.

The test is not a proof for all integers, all encoding variants, all
memory APIs, or full Stage-1 acceptance. It does not modify production
Funge source, canonical Befunge+Кыргызча, main or draft PR #17 and
does not start Stage 2. Exact-head CI required before marking PASS.


## QA budget adjustment after first measured CI failure

On the first 13-case run, the 10 cases through 155 decimal digits passed.
The first 240-digit-class case passed all three native-output oracle
parity layouts but exceeded the old 750,000-step **instrumentation**
limit. The separate wide-domain sampler now permits up to five million
actual Native instruction steps per case; this does not increase the
other Stage-1 test budgets, relax oracle/space/termination assertions,
or make the acceptance scope universal. Exact-head CI remains required.

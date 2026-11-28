# QA31CB — natural-input sweep of the three-digit final token

**Project:** \`PC-BRANCH-BEFUNGE98-KYRGYZ\`  
**Branch:** \`qa-befunge98-stage1-order-isolation-20261008\`  
**Source Git blob:** \`560d6aa5807a7f766213a33835cce85eab0fa40c\`  
**Status before execution:** \`READY\`; this is a new, non-duplicative Native experiment.

## Why this is the next step

QA31CA proved that a single explicit Native intervention changing the physical \`p\` value at \`[1500,1860]\` from 62 to 118 causes a real fetch of opcode 118 and a different route. It did **not** prove that ordinary stdin can produce that value.

QA31BP/QA31BQ established the original input-to-memory/code dependency and the fixed-route relation:

\`code_value = 56 * g([19,1696]) + 62\`.

The existing signed numeric corpus covers the final three-digit token \`000\`–\`099\`. The missing natural-input region is \`100\`–\`999\`. The owner at \`[19,1696]\` is input-tainted in the observed original cases, so testing the remaining numeric token domain is a direct, evidence-based way to close the natural-reachability gap.

## Measurable contract

- **Input:** 900 exact ASCII inputs, \`1 0 0 100\` through \`1 0 0 999\`, with no appended newline; one fresh Native program instance per input.
- **Source:** exact production blob \`560d6aa5807a7f766213a33835cce85eab0fa40c\`; no source edits.
- **Runtime:** PyFunge \`0.5-rc2\`, package SHA-256 \`e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac\`; 50,000-step cap per input.
- **Forbidden:** no stack edits, no FungeSpace edits, no IP relocation, no storage-offset intervention, no changed code bytes.
- **Primary observations:** all physical \`p\`/\`g\` operations touching \`[19,1696]\` or \`[1500,1860]\`; every instruction fetch at \`[1500,1860]\`; actual stdin/stdout; full per-case trace SHA-256; halt/step-limit/multi-IP/error status.
- **Oracle:** independent Python 3 reconstruction from full Native STEP traces, including storage offset, physical cell-before/cell-after, last writer, \`g\` value, code-cell write, and fetched opcode. Where the chain is present, test whether \`code_value == 56*g_value+62\` and whether the fetched opcode equals the last code-cell write.
- **Evidence:** 900 per-case receipts and trace SHA values; full traces are retained in the job's temporary workspace during independent audit. The artifact retains the four boundary sentinels (\`100\`, \`199\`, \`500\`, \`999\`) and every anomalous/non-HALT trace.
- **Adversarial checks:** 20 detached receipt mutations must be rejected.

## Interpretation rules

- \`g=1\`, \`p=118\`, and a physical fetch of opcode 118 on an unmodified Native run proves natural-input reachability for that exact input.
- \`g=0\`, \`p=62\`, and fetch 62 is only a finite negative result for that input.
- A route that does not reach the owner/write/fetch is classified as route divergence, not as a failed test.
- Step limits, multi-IP runs, and runtime errors are reported separately; they are never silently counted as HALT.
- Even a positive case is a finite Native result, not Stage1 acceptance. Stage1 remains open pending its complete global gates.

## Output

\`qa31cb_cases.jsonl\`, \`qa31cb_case_audit.jsonl\`, \`qa31cb_audit.json\`, \`qa31cb_hostile_results.jsonl\`, \`qa31cb_artifact_manifest.json\`, and selected full traces. The workflow uploads these as a run artifact. No merge, main update, release, or protected-branch change is authorized.

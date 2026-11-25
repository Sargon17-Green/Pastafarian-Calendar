# SM83 Stage1 Native393 — isolated integration candidate, NOT ACCEPTED
PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Parent c8fe435741875432b3f705216a294d5e160f43c5, existing runtime adapter. Push CI45551563389 completed/success 24 jobs; the adapter was not built there.

Inputs/outputs and numeric contract: see tests/sm83_stage1_answer_rank_preflight.js and docs/SM83_STAGE1_BOWL_ANSWER_NATIVE_QA.md. Isolated target only: make build/calendar_bowl_answer_rank.gb. New bench: four Foundation A0/direction vectors with independent literal ring rank/accepted A_k, 26 full-width synthetic cases using the same rank/publish path, invalid N=0/19045, invalid bowl/seal/order/residue, idle and output sentinels, owner/lease/SRAM checks. Synthetic cases preserve input A0. No prior ROM dispatcher or tests changed. RGBDS v1.0.4, ROM_HEADER, measured ROM0 free>=10, PyBoy A5/393/40 <=120000f, retain Native370..392, inspect ROM/map/sym.

Still required before Native393 acceptance: source-derived nonfoundation vectors, explicit full Q/order/ordinal immutability snapshots, standalone ring +/-1 wrap or equivalent full-width ring checks; verify actual CI results and artifacts. No Stage2/main/merge/release. A successful candidate run alone cannot close the remaining coverage gap.

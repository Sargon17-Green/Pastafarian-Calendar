# Stage12 DISCOVERY06 — observed format repair and signed/wide raw gate
PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
PARENT_SHA=cdf14add100fce2e1eff65ecb719edc191a92b44
STAGE12_CLOSURE=NOT_CLAIMED

All 12 automatic runs on parent completed; Stage01 run 46129322721 job 140930816196 passed, including two Stage12 tests and one ignored strict RED; Names Lock run 46129322646 job 140930816117 succeeded. Exact SHA seen in decoded logs. Ten failed jobs all show the same rustfmt diff at tests/stage12_discovery06_prior.rs:49 (exit 1, no evidence upload); runs/jobs: 46129322733/140930816361, 46129322716/140930816490, 46129322698/140930816211, 46129322624/140930815953, 46129322628/140930816013, 46129322680/140930816020, 46129322685/140930816180, 46129322645/140930816063, 46129322689/140930816285, 46129322621/140930815905.

Apply observed formatting repair. Add independent raw matrix: 13 exact pairs, including reversed signs and +/-2^180, 598 prefixes, 1794 dispatcher observations; expected counts 143 missing slots and 1651 controls. Synthetic prefixes include 1 and M, not normative visible-drop generation. Raw actual comes from observed enum, not expected. Independent Python arithmetic reconstructs H(k) and verifies raw inputs, prefix, index, coverage, and outcomes. Dedicated push-only workflow bounded 20 min, strict Stage12 and Stage10 exit101 and failure-specific markers; artifact includes exact SHA and exit codes. No production changes; counters remain 11/11; successor compatibility still pending. New tests and oracle not executed at commit; no Stage12 acceptance.

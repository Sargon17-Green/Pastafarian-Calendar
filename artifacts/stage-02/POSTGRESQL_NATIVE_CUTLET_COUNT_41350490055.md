# SQL+தமிழ் Stage 2 Slice 17 — PostgreSQL Native cutlet-count acceptance

Date: 2026-11-01 (UTC). Scope: Slice 17 only; not Stage 2/full-calendar acceptance.

## Locked identity and result
- Repository: Sargon17-Green/Pastafarian-Calendar
- Branch: SQL+தமிழ்
- Tested HEAD: c13209e05602b1706fd6ce97533d7b62d33e7df4
- Workflow: .github/workflows/sql-tamil-stage02-cutlet-count-native.yml
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41350490055
- Run ID: 41350490055; attempt 1; event push; completed/success; six completed/success jobs
- PostgreSQL: 17.11 (Debian 17.11-1.pgdg13+2) confirmed from archived version files.
- Independent post-run readback: branch HEAD equals tested SHA, no intervening code change before this report.

## Executed and verified gates
1. Native job 124979392367 — 20 named assertions returned true; count=20; native_20_of_20=1.
2. Production isolation job 124979392024 — four recorded checks; isolation_4_of_4=1.
3. Differential job 124979392233 (g6) — actual=6, expected=6; differential_1_of_1=1.
4. Differential job 124979392509 (g7) — actual=6, expected=6; differential_1_of_1=1.
5. Differential job 124979392326 (g17) — actual=8, expected=8; differential_1_of_1=1.
6. Differential job 124979392428 (g18) — actual=8, expected=8; differential_1_of_1=1.

Total: 28/28 assertions, six/six jobs. The four differential cases compare independently loaded normative reference and production outputs; production isolation uses no reference schema. The outcome proves these bounded fixtures, not arbitrary days or the final five-component date.

## Raw ZIP verification (original downloaded bytes, independent local SHA-256 and ZipFile.testzip)
| Artifact ID | Job | Bytes | SHA-256 | CRC |
| --- | --- | ---: | --- | --- |
| 13101699150 | Native | 943 | 17d7da527fa6cef48d60a727f376d57a80fc03b76c86528f384a1a233f9b0a65 | PASS |
| 13102365375 | isolation | 545 | c1b2dad25e58829802b6ec89ec2332678ce859bdf407195fc184c994ed08ab94 | PASS |
| 13102205767 | differential g6 | 1817 | 13cf17a56526cdc6bd9f2b4f854558b89c9aa9fcd07e278525b18ffc6fa0b402 | PASS |
| 13102485599 | differential g7 | 1817 | 8036fedf2b57407df465266416e364f00405ce3a39d2d73d76d1f51287287c4e | PASS |
| 13102021504 | differential g17 | 1822 | f21974f71c93c5fd5d6ea84745e52ff3d1b5de4f3a6b2374f09e225fb46e15b4 | PASS |
| 13101772942 | differential g18 | 1816 | 2b6c345634a5d2f306bc3cfa564fd902d1ac5eab575a5927e295e817310cc4e4 | PASS |

All six computed ZIP digests independently matched both GitHub's artifact digest and the respective upload-job log; all six archives passed CRC and opened successfully.

## Generated differential SQL integrity
The archived differential_case.sql was independently hashed, then checked against its own case_sha256.txt from that same job. All four checks passed:
- g6: 145dbbd9e5896635b26bc6543125a781538a07d937fd4b07fa7a2bf3610047ad
- g7: af7b670f64452b5677a71c15871c35115fcf59d35a50bfb09062cb6ced87be35
- g17: 8487ad0a1880143c52ceaef25391b55becde3b14ecd960409fbcb096af9afa7b
- g18: 08e6e18316ab995b5f30e7dd2e8c7bea89873842f779c2aefd102512c4dec820

## Disposition
Slice 17 **ACCEPTED** on tested SHA c13209e05602b1706fd6ce97533d7b62d33e7df4. No manual CI re-run was triggered. No main modification, merge, publishing, or claim of Stage 2 completion. NEXT: independently contract Slice 18 cutlet partition, then implement separately against same-branch normative function with its own bounded QA and native workflow.

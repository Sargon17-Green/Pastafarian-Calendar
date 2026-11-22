# Stage56 B5 — exact-SHA CI triage and isolated PHP sauce diagnostic

Date: 2026-11-22 (Asia/Jerusalem)
PROJECT_ID: PC-BRANCH-PHP-MALAY
Authorized branch: PHP+Bahasa-Melayu
Analyzed branch SHA: a6ede92f178f1d931baeaa25ece0bdeaac74c8a8
Pinned external source: Sargon17-Green/pastafari-calendar@cc2cf0b422757a5e7c33218ce30cffa8f99c6786
Calculation JDN: -13334246
Stage56: NOT ACCEPTED.

## Completed, exact-SHA evidence

GitHub Actions run 44997466409 completed/failure on the analyzed SHA: 30 jobs, 29 succeeded, sole failing job external-reference-differential (#137131495812). Its artifact #14746371794 has published SHA256 73ac01bd12f8e2d6f70e2f8975165456696db92465be7681d3f56d8a745a9bf1, matching the job upload log, size 65,518 bytes.

The independently pinned Python/Scroll/JS comparison passed 271 semantic tuples; it does not certify PHP production. B1–B4, source-bound preflight and production-slices jobs passed. PHP full-year attempts failed or timed out: year 4999 built in 489.71s (42 PHP months vs 34 expected), year 5000 in 392.78s (35 vs 45), year 5001 timed out at 900s without a completed profile. Source-free cutlet oracle passed years 4999 and 5000 only; no Stage56 acceptance.

The profile JSONL-derived comparator reported:
- 4999: PHP month-choice stream first=140960777505853032371660893283975711285, step=+1, rank=9; pinned Python first=73798764692288874135000024365109114723, step=+1, rank=1. Slowest complete stages: weaving unrank 326.74s, weaving count 105.02s, month length unrank 29.65s.
- 5000: PHP first=73681716853725033477590868786771290397, step=-1, rank=1; Python first=81778901639473882019855462426029763179, step=+1, rank=11. Slowest complete stages: weaving unrank 252.51s and count 102.65s.
- 5001: PHP first=75109720026470078295951442101647132522, step=-1, rank=2; Python first=81920530390712611044014623049095354507, step=+1, rank=1. Weaving count alone took 272.55s before timeout.

## Provenance and semantic decision

Python reference uses bowl IDs 0..5. PHP uses 1..6; the PHP month-count choice bowl ID 3 is precisely Python ID 2, so merely changing bowl numbers would be wrong. The first divergence is within an upstream source stream or its sauce, not yet localized to a specific PHP production operation. No PHP algorithm modification was justified by the existing evidence.

## New QA-only, source-free-on-PHP probe contract

Inputs: exactly the three year-start target JDNs (-13340403,-13336277,-13332033), calculation JDN -13334246, actual PHP BootstrapKernel::sauceOrder and ::askBowl at seal 30/bowl 3. No year construction, synthetic fixtures, or imported Python code in PHP.

Output: exact decimal contents of all six final PHP bowls, ordered 46th-drop permutation, response first, response step and next bowl ID. The comparison process uses the external pinned Python source at its exact clean Git HEAD and its own sauce() and response_descriptor() functions, converting only one-based PHP bowl IDs to zero-based Python indices. Oracle reports the first divergent bowl, permutation element, response or neighbor per year. Invalid source/envelope returns exit 2; mismatch returns exit 1; full agreement returns exit 0. The independent reference source is not accepted as PHP production.

Workflow order: run the inexpensive isolated comparison before three 900-second real-year profiles, and fail closed on mismatch to avoid needlessly repeating an already-proven failure. Retain stdout, stderr, distinct exit codes, JSON report, and hashes through the existing always-uploaded SHA-bound artifact. Successful probe is a local differential gate only, not full Stage56 acceptance.

New files: tests/stage56_php_sauce_probe.php, tools/stage56_compare_php_sauce.py; single QA step added to canonical-names-lock.yml. PHP syntax and Python syntax were checked locally on PHP 8.4.24 / Python 3.13.5 before GitHub write; these are static checks, NOT Native PHP8.3 evidence. New-sha automatic CI must be inspected when completed. No new stage, runtime integration, PATCH22/PATCH23 merge, main or publication.

## Links

- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997466409
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997466409/job/137131495812
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997466409/artifacts/14746371794
- https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/a6ede92f178f1d931baeaa25ece0bdeaac74c8a8

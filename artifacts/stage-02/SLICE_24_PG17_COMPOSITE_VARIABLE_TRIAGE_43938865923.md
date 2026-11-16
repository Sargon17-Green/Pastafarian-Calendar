# SQL+தமிழ் Slice24: PostgreSQL 17 composite-target triage

- Project: `PC-BRANCH-SQL-TAMIL`; branch `SQL+தமிழ்`
- Tested commit: `df114a9217e16626709d168fd2e245417a6bb2c5`
- Original automatic run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43938865923
- Inspected 2026-11-16; run contains 16/16 completed/failure jobs (8 native, 8 differential).
- All 16 original job logs match the tested HEAD, PostgreSQL 17.12, and `ERROR: "y" is not a scalar variable` with process exit 3. Native errors at generated `test.sql:61`; differential at `test.sql:27`.
- All 16 original GitHub ZIP archives downloaded. Independently computed archive SHA-256 matches GitHub artifact metadata and upload log for 16/16; ZIP CRC clean 16/16; generated test.sql hashes match embedded generated-sha256.txt 16/16. Each archive contains six source-file hashes and they agree across all 16 jobs; source files unchanged in this patch.
- The previous `142` VALUES missing-comma error is no longer observed: execution passes fixture loading and reaches generated test PL/pgSQL.

## Root cause and bounded patch

Both test templates declared `d numeric; y pastafari_sql_tamil.year_rec` and attempted `SELECT x.d,x.y INTO STRICT d,y ...`. A PL/pgSQL scalar target list cannot mix the scalar `d` with a composite `y`, so compilation fails before any assertions execute.
Change just one line in each of `sql/test/143_stage02_year_structure_native.sql` and `sql/test/144_stage02_year_structure_differential.sql` to two independent `SELECT ... INTO STRICT` statements (one scalar and one composite). The case table is temporary and unchanged during these reads. No production SQL, normative oracle, fixtures, expected outputs, or workflow changes.
- Static before-commit guard: 2/2 exact one-line replacements; 29/29 named native assertions and 9/9 differential named comparisons retained; no acceptance inferred from static verification.
- Native case assertions, independent Python actual-structure oracle, full differential and isolation remain **UNDECIDED** until a completed fresh natural push run and verification of original artifacts. No manual rerun, main merge, or publication.

## Original ZIP evidence (SHA-256)

| Lane | Case | Artifact ID | SHA-256 (metadata = upload log = downloaded ZIP) |
|---|---|---:|---|
| differential | boundary_close | 14264070079 | `4f2a82623bc530f8ca575f86eb4271b5c870fddbd4f30d02f9703ab4178adfa2` |
| differential | boundary_open | 14264010322 | `910f0ddd8aa5265d4015d3af38be68115b3ca7ba9e98f6f51890541a7a5eace4` |
| differential | next_1 | 14263355934 | `73814d144dd1f7e0e0515580a9ed72696f14cc66f2189482220305a9042d710e` |
| native | prev_2 | 14263241308 | `7879f8a932308702d8c50e6336b99179dcbc5a39e17311a9980e64f21b1daca3` |
| differential | prev_3 | 14263137947 | `242400071019aa3be9ab9e77a3f7bdd2cb992126eb0a471cfabaca2c2ae2dee6` |
| native | prev_3 | 14263052725 | `cb719590ff7f089d3def9a8a60f2b38486babcee4a21cba00f0b3cf273428b13` |
| native | next_2 | 14263022703 | `b225c942fedeb09e08cd6e9c397db0e01cc077def8c6d61372f632cff8977d28` |
| differential | next_3 | 14262823558 | `57ab37f2070dbed3f76b6af968e785d613b91429f47a35eca9a5316161105d1b` |
| native | next_1 | 14262649707 | `9dacf6a513193a22eb57bb96d9c8b5563e998de098a58f83dea54206317054c0` |
| differential | prev_2 | 14262533914 | `b20fc9774285ede9b533cfc020b668288d270929d4c406174e33dacad7159e6e` |
| native | boundary_open | 14262083083 | `54c9da18c4d13610fa066a253a3f93b64173532c8e89b2f7462b3d1c9013893c` |
| native | anchor | 14261904563 | `a774fb93be1864d303860ffa7b83ad62d10fe9fdac8ddb12daefaa4c5006d1a7` |
| native | next_3 | 14261894680 | `ad92a870725cf5f4d56ba0d3092da0970a7bfb24ebeb58aef6cf446b8fe2c185` |
| differential | next_2 | 14261889285 | `eddeb4b42b43bdcec32ba1bad5fa5694f42fe38ab4a6cc4e2be4856111acbece` |
| native | boundary_close | 14261038236 | `8da588260b1bfb940a38fde6a5aeb69bfe187ad0c645c245bc16f30bbfb2eaff` |
| differential | anchor | 14260889690 | `788a0ec26ccd14c213eb1cc0fd212334e894da1b5df65ae70f7d9320c30ae841` |

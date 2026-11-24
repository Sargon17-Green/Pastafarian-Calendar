# Issue29 v190: byte-exact corrected GMP production provenance

Scope: READ-ONLY static QA of historical versus corrected Ada. NO new original F(c,t), no Calendar_Date, no Native converter, no Soak, no merge, no Stage42, no production source changes.

Historical original source SHA a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72. Corrected Ada source SHA 1160096aa847c54cbef27c232771ce1549d7ba8f. The full normative_oracle.adb code outside its one Choose_Month_Weaving function (including its immediately preceding comment) is BYTE-FOR-BYTE IDENTICAL after removal of exactly three new GMP imports. No year/gate/Sauce/cutlet/name/output code changed INSIDE THAT FILE.

The corrected path uses exactly one source-level ordered chain: Build -> Count -> Choose_Rank -> Unrank, with Ask_Bowl(Structure_R,4,Seal_Month_Weaving). Calendar_Date calls it once. No legacy Month_Weaving.From_Choices in that production path. The old standalone month_weaving.adb is STILL PRESENT and byte-identical historically (Git blob 9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef); another entrypoint could still call it. The normal GPR includes gnatcoll_gmp.gpr.

This source-only guard pins nine Git blob refs across historical and corrected source, protects the 42 disabled legacy calendar jobs, and must reject six deliberate source mutants (unrelated prefix/suffix edits, import loss, Count replacement, return mutation and old path reintroduction). Full per-source hashes and verdict are archived.

Independent prior full-stack native proof is Actions run 45271645185 (corrected Ada matches pinned original Python in FIVE fields for exactly ONE day). This v190 audit does NOT repeat that run and does NOT authorize broader testing.

Technical debt: the GMP package code comments still label the packages QA-only although the corrected production oracle now links to them. That is misleading documentation and should be corrected under a separately reviewed production edit, not silently here.

Decision remains Issue #29 OPEN, STOP_NEW_NATIVE_SOAK_DISPATCH=true, 0/10000 accepted original years.
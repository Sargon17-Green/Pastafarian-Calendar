# 第 15 階段 Native／CI 正式驗收（2026-11-06）

專案：`PC-BRANCH-PERL-GUOYU`；工作分支：`Perl+國語`。本驗收對象僅為 Stage07 + Stage14 的正式五欄投影組合器與其獨立日展開 oracle；**不**是完整年份結構生成器、sauce、askBowl 或其餘階段的驗收。

## 精確來源與完整 CI

已在編寫前查驗分支 HEAD：`7d4151a68ce8b3ce54b51970be24e28748e8d6ec`；原始來源與驗收文件的新提交須明確區分。
canonical push CI： https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176645305 。
run_id=42176645305；attempt=1；event=push；status=completed；conclusion=success；head_branch=`Perl+國語`；head_sha=`7d4151a68ce8b3ce54b51970be24e28748e8d6ec`。
按頁查閱全部 **162 jobs**：16/16 必需 jobs completed/success，其他 146 skipped；沒有必需 job 失敗。直接讀取所有 **16 份 raw job logs**。必需 job IDs：
- verify 127756525503；perl-stage01 127756525158。
- Stage02 127756530353；Stage03 127756530314；Stage04 127756530462；Stage05 127756530440；Stage06 127756530568；Stage07 127756530579；Stage08 127756530427。
- Stage09 127756530349；Stage10 127756530298；Stage11 127756530386；Stage12 127756530260；Stage13 127756530410；Stage14 127756530487；Stage15 127756530443。

Stage01 完整 Native suite：`Files=111, Tests=195226, Result: PASS`，包含 `t/05_language_and_isolation_audit.t` 修復後的成功與 `t/60_stage15_canonical_five_field_projection.t`。
Stage15 獨立 Native job：`Files=1, Tests=14320, Result: PASS`，`STAGE15_INDEPENDENT_EXPANDED_DAYS=6993`、`STAGE15_INDEPENDENT_DAY_COMPARISONS=1585`、`STAGE15_STREAM_BOUNDARY_CONFIGURATIONS=24`、`STAGE15_INVALID_CASES=28`；測試自身明確標示 `STAGE15_FULL_GENERATOR_NOT_VERIFIED`。
CI runner：Perl `v5.40.5`；模組及測試各一個 `syntax OK`，共 2/2；`timeout 120s`；`ulimit -v 393216` KiB。此為**虛擬記憶體上限**而非 RSS 峰值測量。測試 `stderr` 0 bytes、`exit=0`。

## ZIP 位元組獨立核對

Stage15 新來源 artifact：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176645305/artifacts/13483712618
artifact ID `13483712618`；大小 48022 bytes。原始 ZIP 下載後在獨立本地環境對實際位元組計算 SHA256：
`b9c1ed675764d814c1060fe9a48e0ab2f4f4da15e37d29ae6b64da478163d4f6`
此值與 GitHub provider metadata 中 `digest` 及 Stage15 raw job 的 upload SHA256 完全相等。ZIP `testzip()` 無錯；**恰七件且沒有多餘項目**：
1. `source.txt` = `7d4151a68ce8b3ce54b51970be24e28748e8d6ec`，與 CI 與原始來源一致；
2. `perl-version.txt` = `v5.40.5`；
3. `syntax.stderr` = 生產模組和測試各一個 `syntax OK`；
4. `test.stdout` = 14320 TAP、全部四種 oracle/邊界標記、`Result: PASS`；
5. `test.stderr` = 空；
6. `test.exit` = `0`；
7. `result.txt` = `STAGE15_NATIVE_PASS=1`。

## 驗收結論與後續界限

**STAGE15 ACCEPTED；LAST_COMPLETED_STAGE=15** 對上述**精確來源 SHA**成立。上一個失敗來源 `c6cf720e250d943cc74c75e61f87098161522cd4` 的 Stage01 稽核旗標已於此來源修正，不能以舊 run 或舊 artifact 代替這次新來源驗收。驗收報告、標記更新或 Stage16 探索文件之新提交沒有自動取得本來源的 Native PASS。

尚未驗證完整年度生成器、完整範圍月份交織、sauce、askBowl 或 55 階段總驗收；無 main 變更、merge 或對外發佈。

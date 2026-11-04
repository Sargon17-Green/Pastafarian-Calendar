# 第 12 階段 Native／CI 驗收紀錄（2026-11-04）

專案 PC-BRANCH-PERL-GUOYU；工作分支 `Perl+國語`。本紀錄僅驗收串流排名與互異名稱**索引**的有限整合，不代表已完成五欄年曆或全部 55 階段。

## 同源 canonical CI 與稽核修復

驗收 source SHA：`6cc8a6f85c32663e664e644544abd2ef91ce4a94`；驗收時經 GitHub branch endpoint 核實 HEAD 完全相同。上一版 source `07ffbd87ea86e19b1fc61dd047dd5473fb1fe4b5` 的 run 41712689426 因 Stage01 一項過時稽核斷言而 12/13，**不視為驗收**。修復 blob `370264fc19ee3e43d1eb73fc03d5f8a0d5de168b` 將 GITHUB_ACTIONS_PERFORMED=YES 與既有真實接受證據一致，保留舊值 NO 的相容性；詳見 [稽核修復報告](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/6cc8a6f85c32663e664e644544abd2ef91ce4a94/docs/STAGE_12_CI_AUDIT_PATCH_2026-11-04.md)。

[canonical push run 41775860313](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41775860313)：head_branch=`Perl+國語`、head_sha 與上述來源完全相同、attempt=1、completed/success，最後更新 2026-11-04T04:58:51Z。GitHub REST jobs 兩頁（100 + 59），總計 159 jobs：**13/13 必需 job completed/success**，另 146 項 skipped，無其他失敗或取消。已逐一讀取全部 13 項必需 job 原始日誌：

| 必需 job | Job ID |
| --- | ---: |
| verify | 126395931369 |
| perl-stage01 | 126395930815 |
| stage02-weaving-native | 126395936495 |
| stage03-weaving-native | 126395936421 |
| stage04-month-occurrence-native | 126395936430 |
| stage05-cutlet-occurrence-native | 126395936434 |
| stage06-year-occurrence-native | 126395936466 |
| stage07-five-field-native | 126395936513 |
| stage08-month-length-generation-native | 126395936449 |
| stage09-cutlet-partition-native | 126395936479 |
| stage10-distinct-name-native | 126395936381 |
| stage11-stream-rank-native | 126395936623 |
| stage12-stream-distinct-name-native | 126395936440 |

主 `perl-stage01`：`Files=108, Tests=175648`、`All tests successful.`、`Result: PASS`；前述 t/05 第 7 項不再失敗。Stage12 專屬工作：`Files=1, Tests=5012`、`Result: PASS`，獨立枚舉 4730、21 families、48 boundary cases、14 invalid cases，沒有 `not ok`。其他 Stage02–11 工作均在相同來源成功，原始日誌顯示專屬 TAP PASS。

## Stage12 七件 Native 原始產物

[Artifact 13296882126](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41775860313/artifacts/13296882126)，名稱 `perl-stage12-stream-distinct-name-native`。直接下載 ZIP：15,444 bytes；獨立計算 **SHA256 `d257124d9091ab095143cc625648db26c8034d1d255db365881752e18b91f989`**，與 GitHub artifact digest 及 Stage12 上傳日誌相同。ZIP CRC 7/7 通過，恰有七個成員：

- `source.txt` = `6cc8a6f85c32663e664e644544abd2ef91ce4a94`；
- `perl-version.txt` = `v5.40.5`；
- `syntax.stderr`：生產模組、測試檔各有 `syntax OK`（2/2）；
- `test.stdout`：5012/5012 TAP、無 `not ok`，上述獨立 oracle 標記、`All tests successful.`、`Result: PASS`，以及 `STAGE12_FULL_GENERATOR_NOT_VERIFIED`；
- `test.stderr` = 0 bytes；
- `test.exit` = `0`；
- `result.txt` = `STAGE12_NATIVE_PASS=1`。

Native job 實際以 `timeout 120s` 和 `ulimit -v 393216` KiB 限制執行；5 秒為報告中的 test wallclock。該記憶體限制是 VSZ 上限，不是峰值 RSS 數據。

## 結論與後續

**STAGE12 ACCEPTED**，僅限 `StreamDistinctNameSelection::select_distinct_name_indices`：以 M=2^127-1、方向 ±1、1..47 的選取長度與目錄大小、精確 BigInt 串流選取字典序互異索引，驗證輸入、不變性與獨立 oracle。允許後續正常 commit 將 `LAST_COMPLETED_STAGE` 設為 12。新的 commit 不會自動取得 Stage13 Native PASS。真正的正規名稱文字、sauce、askBowl、完整年/月/日與五欄日期尚未通過整體驗收。

下一個有限工程階段：Stage13 以由呼叫端提供的有序名稱目錄，將 Stage12 索引安全映射為文字名稱，另有獨立 oracle 和新 source SHA 的 Native/CI 閘門。禁止 main／merge／發佈。

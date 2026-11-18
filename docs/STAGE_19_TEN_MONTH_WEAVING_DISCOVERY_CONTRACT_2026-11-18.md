# Stage19：十月份／四十日交織擴展探索契約（2026-11-18）

專案：`PC-BRANCH-PERL-GUOYU`  
分支：`Perl+國語`  
Stage18 已接受來源：`7ae6fc32ce7ce9593ad41dc5c75056fa564aa591`  
Stage18 證據提交：`7d12f88c5f976f13e2c157903fd3719fac88900f`  
Stage19 基準 HEAD：`7d12f88c5f976f13e2c157903fd3719fac88900f`  
`LAST_COMPLETED_STAGE=18`；本文件只開啟 Stage19 DISCOVERY，不代表 Stage19 實作或 Native PASS。

## 一、工程選擇與範圍

Stage16、17、18 依序驗收 7 個月／28 日、8 個月／32 日、9 個月／36 日。Stage19 選擇延續同一條明確的單步邊界成長路徑：**10 個月／總計最多 40 日**。此選擇是從已接受階段推導，不引入另一個無關功能。

本階段只擴展 `Pastafari::Monster::WeavingPrimitive` 的既有 API：

- `count_weavings(profile)`
- `rank_weaving(profile, word)`
- `unrank_weaving(profile, rank)`

保留 1-based 字典序、`Math::BigInt` 精確計數、ARRAYref 輸出、輸入與輸出可變性隔離，以及首次／末次出現順序規則。有效 profile 為 1..10 個月、每月正整數日數、總和 1..40。Stage18 的所有有效 1..9 月／1..36 日輸入必須保持結果與排序不變。

明確拒絕 11 個月、41 日、零／負／非整數／非法型別、非法排名與非法序列。此階段不擴展 `MonthOccurrence`、完整年曆產生器或其他獨立模組；特別是 `t/49_stage04_month_occurrence.t` 的 36 日限制屬另一模組契約，不應為了本階段而修改。

## 二、已完成的有界資源預檢

從 Stage18 已接受的 module blob `7402605a542ddad2da9eb8d29ccbf6e7b4c32723` 重建本地來源；還原 9／36 邊界後，`git hash-object` 精確吻合該 blob。未提交的臨時候選 blob 為 `f2fed952d134a3b59f9a9a8b61edcc311267c16d`，只把月份上限 9 改為 10、總日數上限 36 改為 40。候選語法檢查通過。環境為 Linux x86_64、Perl `v5.40.1`；各次量測採 120 秒 timeout 與 393216-KiB virtual-memory limit。

| Profile | Count | 檢查 | Wall time | VmHWM |
|---|---:|---|---:|---:|
| `[2 x 10]` | 16,796 | Catalan10 全部 16,796 個獨立 Dyck words；production rank/unrank 16,796/16,796 | 62.015 s | 未記錄 |
| `[3 x 10]` | 3,515,569,641,156 | 首／中／末 BigInt rank-unrank roundtrip | 1.521 s | 13,548 KiB |
| `[4 x 10]` | 4,971,032,496,120,057,390,920 | 首／中／末 BigInt rank-unrank roundtrip | 75.985 s | 101,372 KiB |
| `[31,1 x 9]` | 1 | 首／中／末 roundtrip | 0.007 s | 10,920 KiB |
| `[40]` | 1 | 首／中／末 roundtrip | 0.006 s | 10,880 KiB |

對 `[2 x 10]`，閉式獨立 oracle 為：

`Catalan(10) = 20! / (10! 11!) = 16796`.

獨立 Dyck 產生器建立完整 16,796 個詞，依字典序排序；production count 與閉式相同，所有 16,796 個位置的 unrank 與獨立詞序一致，且 16,796 個 rank roundtrip 均一致。此測試耗時 62.015 秒、exit 0、stderr 空白。此處是獨立 oracle 驗證。

`[3 x 10]` 與 `[4 x 10]` 的 count 數字是預檢所得 production 結果，不是獨立計數 oracle；對這兩種大型 profile，預檢只證明 count 可計算及首／中／末 roundtrip 一致。不得把 roundtrip 稱為獨立 oracle。

上述結果證明 10／40 候選在所測 profiles 下具備可行性，但**不是**已提交 production code 的 Native CI 證據，也不是 Stage19 接受。

## 三、實作與回歸要求

1. 從 Stage18 已接受來源出發，只修改 `WeavingPrimitive.pm` 的上限檢查與對應註解；不得重寫演算法或變更 API。
2. 新增 `t/64_stage19_weaving_ten_months.t`：
   - 以完整多重集合排列後再檢查首／末出現次序，建立至少 4 個小型十月份獨立 oracle profiles。
   - 以獨立 Dyck-path 雙射建立 Catalan(10) 全部 16,796 個詞，逐一比對 count、字典序 unrank 與 rank roundtrip。
   - 覆蓋 11 月、41 日及非法 profile／rank／word；保留 BigInt 與輸入不可變性檢查。
3. 新增 `t/65_stage19_weaving_ten_months_large_profiles.t`：
   - 至少覆蓋 `[3 x 10]`、`[4 x 10]`、`[31,1 x 9]`、`[40]`。
   - 對大型 profile 核對 BigInt 首／中／末 rank-unrank、輸出長度、profile 與 rank 不變性。
   - 清楚標示大型 profile 的 roundtrip 一致性不是獨立 count oracle。
4. 只修正因 10／40 邊界放寬而不再非法的既有負向 fixtures；不得改動無關案例：
   - `t/47_stage02_weaving_primitive.t`：37 日改為 41 日；10 個單日月份改為 11 個。
   - `t/48_stage03_weaving_extended.t`：37 日改為 41 日；10 個月份改為 11 個；`[18,19]`（37 日）改為 `[20,21]`（41 日）。
   - `t/61_stage16_weaving_seven_months.t`：10 個月份改為 11 個；37 日案例改為 41 日案例，包括 `[31,1 x 6]` 與其排列案例。
   - `t/62_stage17_weaving_eight_months.t`、`t/63_stage18_weaving_nine_months.t`：10 個月份改為 11 個；37 日案例改為 41 日案例，包括 `[29,1 x 8]` 及 `[1 x 8,29]`。
   - 不修改 `t/49_stage04_month_occurrence.t`：它驗證不同的 `MonthOccurrence` 契約，並非本階段的 WeavingPrimitive 邊界。
5. 不得刪除或放寬 Stage18 的正向、排序、BigInt、獨立 oracle、不可變性或錯誤輸入測試。

## 四、Native CI 與接受門檻

- 在 `canonical-names-lock.yml` 新增同分支專屬 `stage19-weaving-ten-months-native` job；既有 19 個必需 jobs 保持不變，新的 canonical push 應有 **20/20 required jobs completed/success**。
- 使用 Perl >= 5.40；production module 與兩個新 test files 必須 3/3 syntax OK。
- 分別以 `timeout 120s`、`ulimit -v 393216`、`ulimit -c 0` 執行 t/64 與 t/65；整個 job timeout 5 分鐘。兩個 prove 結果均須 PASS，stderr 空白、exit 0，並核對明確 TAP totals 與所有 Stage19 markers。
- Stage01 全套必須完成，包含上述歷史測試檔；不得只以 Stage19 專用測試取代回歸套件。
- 專用 job 上傳七檔證據：`source.txt`、`perl-version.txt`、`syntax.stderr`、`test.stdout`、`test.stderr`、`test.exit`、`result.txt`。
- 只有 exact source SHA 的 canonical push run 20/20 required success、所有 20 個 raw logs inspected、Stage01 PASS、t/64 與 t/65 PASS，且 artifact upload/provider/local SHA-256 相同、CRC 7/7、source exact、Perl version、syntax、stderr、exit 與 result marker 全部一致時，才可將 `LAST_COMPLETED_STAGE` 推進至 19。
- queued/in_progress 不是 PASS 也不是 blocker；不得重複 dispatch。不得 merge 到 main、發布或對外發佈。

## 五、明確排除

完整年曆產生器（252..5778 日）仍未驗證。Stage19 只涵蓋 10 個月／40 日的 WeavingPrimitive；不得將本階段的成功擴大宣稱為全年支援。

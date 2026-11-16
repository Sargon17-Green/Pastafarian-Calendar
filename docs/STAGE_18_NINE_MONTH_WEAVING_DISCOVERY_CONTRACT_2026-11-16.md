# Stage18：九月份／三十六日交織上限探索契約（2026-11-16）
專案：`PC-BRANCH-PERL-GUOYU`；分支：`Perl+國語`。

## 前提與工程選擇
Stage17 驗收來源為 `457eb0a8c444c5d3416c79e03273d3144dcc3dec`；canonical run 43939070420 18/18 必需 completed/success、全部 job raw logs、Stage01 199251 tests、Stage17 專用 2972 tests、七檔 artifact SHA256/CRC/source 均已核對；參見 `docs/STAGE_17_NATIVE_CI_ACCEPTANCE_2026-11-16.md`。選擇從 **8 月／32 日** 擴至 **9 月／36 日** 的單一、漸進式、具資源上限 scope；這是 **Stage18 DISCOVERY**，不是 production implementation 或 Native PASS。

## API 與不變條件
保留 `Pastafari::Monster::WeavingPrimitive` 中 `count_weavings(profile)`、`rank_weaving(profile, word)`、`unrank_weaving(profile, rank)`；月份標籤依首次及末次出現 1..m 上升；1-based 字典序；count/rank 精確使用 `Math::BigInt`，unrank 輸出 ARRAYref；不得修改輸入物件／共享可變輸出。
期望有效邊界：1..9 個月、日數總和 1..36，各月正整數日數。舊 1..8 月、1..32 日的所有有效結果、排序、類型保持不變。**10 月、37 日、零／負／非整數／非法型別／非法 rank、非法 word** 必須明確拒絕；只更新因範圍放寬而不再非法的舊 negative fixture，先確認，再精準改至 10 月／37 日。

## 最先執行的精確 source 預檢（實作前）
從已驗收的 Stage17 source 和相同 `WeavingPrimitive.pm` 出發；使用 Perl >= 5.40、同一 checkout、`timeout 120s`、`ulimit -v 393216` KiB，分別試 `[(2)x9]`、`[(3)x9]`、`[(4)x9]` 的 count/首中末 rank/unrank。此處超出現行界限，**不得把 expected rejection 當成效能結果**：先以獨立有界參考模型估算成本，或完成最小局部邊界改動後立即測量；記錄來源 SHA、環境、wall time、RSS（如可測）、exit/stderr、正確性。任一 >120s 或超內存，需有原始可重現證據，再選擇狀態壓縮或縮小合理範圍；不得報假 PASS。
有界 oracle：`[(2)x9]` 須以獨立 Dyck-path/Catalan 雙射得到 `Catalan(9)=binom(18,9)/10=4862`，不能從 production DP 取 expected。對 `[(3)x9]`／`[(4)x9]`，先取獨立 count 或清楚標示僅為 production roundtrip 一致性測試，不可將同一算法當獨立 oracle。大型測試不能窮舉整個指數狀態空間。

## 預定 Stage18 實作與 native 門檻（探索通過後）
- 用獨立多重集合排列＋合法性過濾建立小型 exhaustive fixtures，逐項比對 count/rank/unrank/字典排序，不調用生產 DP 生成 expected；以獨立括號/Dyck 字串驗證 `[(2)x9]` 全部 4862 lexicographic positions。
- 大型九月／36 日 profiles 及變動月份向量：核對 BigInt 首位、中位、末位、雙向 roundtrip、不可變性、錯誤輸入；清楚區分獨立 oracle 比對與一致性檢查。
- 預定新增 `t/63_stage18_weaving_nine_months.t`（不得複製其他分支實作），修訂本分支 `t/47`、`t/48`、`t/49`、`t/61`、`t/62` 中確已過期的負例，現有正例仍 PASS；新增專屬 Stage18 job 和七檔 source/version/syntax/stdout/stderr/exit/result ZIP。
- 所有測試固定上限 120s/393216KiB；新專用 TAP 必須含 oracle 及邊界數量標記、2/2 syntax OK、exit0、stderr0，並有具體的測試總數；同一 source SHA 的 canonical workflow 須 19/19 required completed/success，直接閱讀全 19 raw logs、Stage01 全套、受影響歷史測試；新 7-file artifact 須 SHA256 provider/upload/local 一致、CRC 7/7、source/version/marker 全部一致，才能接受 `LAST_COMPLETED_STAGE=18`。
- 若 CI queued/in_progress，記 run ID/SHA 並做獨立工作，不重複 dispatch、不判 PASS。禁止 main、merge、對外發布。全年產生器仍未驗證。

**本提交只確認 Stage17 Native 與開啟 Stage18 可執行的 DISCOVERY 規格；Stage18 實作、CI 與完整年曆皆未獲接受。**

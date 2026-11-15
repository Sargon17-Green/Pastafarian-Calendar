# Stage17：八月份／三十二日交織上限擴展探索契約（2026-11-15）
專案：`PC-BRANCH-PERL-GUOYU`；分支：`Perl+國語`。Stage16 已以 source `303bc820e2c9250ff21ea0f9bedf7f8ce2119695`、run 42390320913、17/17 必需 jobs 和 SHA/CRC/source 比對的七件 native ZIP 接受。本文件開啟**Stage17 DISCOVERY**；不是 Stage17 原生 PASS，也不是 252..5778 日全年生成器。

## 選擇及範圍
目前 `Pastafari::Monster::WeavingPrimitive::_counts` 的界線是最多 7 月且總日數 28。延續 Stage16 漸進式、可測量的有界擴展，而不一次跳至多千日；下一個唯一 scope 為 **1..8 個月、總日數 1..32**。保留既有 `count_weavings(profile)`、`rank_weaving(profile,word)`、`unrank_weaving(profile,rank)` 和傳回型別 `Math::BigInt` / ARRAYref，以及 label 首次/末次出現按 1..m 遞增、1-based 字典序排名的相同語義。舊 1..7 月/28 日所有有效輸入的 rank、輸出不變；非法 9 月、33 日、非法長度／型別／rank／word 必須拒絕。嚴禁引入其他分支算法或 `t/lib` 到生產碼，不可修改輸入或共享可變參照。

## 預檢／資源門檻
先以**完全相同來源版本**與 Perl >= 5.40 對 [2×8]、[3×8]、[4×8] 做 profile count 與 rank/unrank 初步資源門檻：每個 timeout 120s、`ulimit -v 393216` KiB，stderr 空，exit0，數值正確。2026-11-15 的獨立、手寫模擬 DP（**不是**目前 GitHub 生產模組的 Native 證據）測得：[2×8] 45 memo states / 10240 KiB RSS / 0.08s；[3×8] 1013 / 10752 KiB / 0.08s；[4×8] 14757 / 19584 KiB / 0.78s，皆在本地 25s / 393216KiB 限額內；這僅支持可行性，不作為實作 PASS。若真正原始碼超限，須記錄可重現現象，採同一來源的狀態壓縮、合理剪枝或改用更小可測範圍，不能假造通過。

## 獨立 oracle 與測試
新增 `t/62_stage17_weaving_eight_months.t`：小 profile 透過**完整多重集合排列後再篩選**的獨立枚舉 oracle，對 `[(1)x8]`、`[2,(1)x7]` 等可窮舉輸入，逐項驗證 count / rank / unrank / 字典排序；不得調用 production DP 產生 expected。對 `[(2)x8]` 使用獨立括號／Dyck-path bijection 推出 `Catalan(8)=C(16,8)/9=1430`，加 1430 個排名往返與首末排序證明；不可將 production count 當成 Catalan oracle。對 `[(4)x8]` 32 日及其他混合 8 月 profiles，驗證 1、中位、末位的 Math::BigInt 精確往返、完整長度、不可變性、無輸出共享狀態；大型 profiles 的 roundtrip 是**一致性檢查**，不可冒稱獨立 oracle 的逐項比較。針對既有 `t/47`、`t/48`、`t/49`、`t/61` 中因擴展而成為合法的舊 negative fixtures，僅在確認後改為 9 月／33 日等仍非法配置；原有正例和 oracle 證據不變。新測試包含非法 rank 0、負值、NaN、超出總數、錯序／數量／型別、不可變性。

## 程式及 CI 可驗收交付
僅修改相同工作分支的 bounded production `WeavingPrimitive.pm`、必要的舊測試負例與新 oracle TAP，並為 canonical workflow 增加**專用 Stage17 Native job**，保留七件 evidence：source, Perl version, syntax, stdout, stderr, exit, result。Stage17 job 必須檢查 2/2 syntax OK、正確測試計數及獨立 oracle/1430 Catalan/32 日標記、stderr 空、exit0、120s/393216KiB 上限。完整 canonical push CI 須在**同一新 source SHA** 上達成 **18/18 required completed/success**，直接讀取全部 18 raw logs，Stage01 full TAP 及受影響歷史測試仍 PASS，下載新的七件 ZIP 對照 provider/upload/local SHA256、CRC 7/7、source.txt=CI source SHA，然後才可將 LAST_COMPLETED_STAGE 改成 17。不得將 queued/in_progress 當成 PASS 或阻塞；無 main/merge/發佈。

**本次只有獨立 Stage16 驗收與 Stage17 DISCOVERY 契約；Stage17 production、test、CI 未部署，full-year 尚未驗證。**

# 第 16 階段：七月份／二十八日交織上限擴展探索契約（2026-11-06）

專案：`PC-BRANCH-PERL-GUOYU`；分支 `Perl+國語`。Stage15 已在來源 `7d4151a68ce8b3ce54b51970be24e28748e8d6ec`、run 42176645305、16/16 必需 jobs、14320 Stage15 TAP 及七件 ZIP SHA/CRC 的證據下驗收。本文件只開啟 **Stage16 DISCOVERY**；並非 Stage16 實作或 Native PASS。

## 現有缺口與設計選擇

`Pastafari::Monster::WeavingPrimitive` 目前在 `_counts` 中明確限制最多 6 個月、總計 24 日。Stage08 可生成 3..47 個月、252..5778 日、每月 4..123 日的長度族；Stage15 接收外部已物化的 `monthWeaving`，而不產生它。故直接聲稱完整年度生成器可用是錯誤。為避免一次性從 24 日跳到 5778 日造成無界狀態空間，本次選擇**獨立且可量測的漸進擴展**：只將原生交織排名原語的上限擴至 **7 個月／28 日**，保留所有既有輸出排序與拒絕規則，後續年度全範圍仍未驗證。

## API、輸入、輸出與驗證契約

保留既有 `Pastafari::Monster::WeavingPrimitive` 公開函式：`count_weavings(profile)`、`rank_weaving(profile,word)`、`unrank_weaving(profile,rank)`；回傳型別維持 `Math::BigInt` 或整數標籤的 ARRAYref。新合法上限為月數 1..7、合計 1..28 日，其餘正整數規則與「月份 1..m 首次出現依序、末次出現依序」條件完全不變。不能改變既有任意合法輸入的字典序排名；1-based rank，`1 <= rank <= count`，不可修改輸入、`Math::BigInt` 或輸出共享參照。不合法月數、天數、profile、完整序列、重複/缺少標籤、順序或 rank 都必須拒絕，且不產生部分成功輸出。不得在生產模組引入 `t/lib` 或其他分支實作。

先驗算舊 DP 的記憶化狀態複雜度，以七個月和 28 日作固定工作上限；若 120 秒／393216KiB 虛擬位址空間不可完成，記錄**實際可重現**資源失敗後改選合理的狀態壓縮/剪枝技術，不得虛構測試通過。新 production 算法和 oracle 仍需彼此獨立。

## 獨立 oracle 與測試資料

新增 `t/61_stage16_weaving_seven_months.t`。小型 profile 的 oracle 以直接枚舉所有不同多重集合排列，再**完成後才篩選**首末出現順序，計算精確字典序 rank/unrank；不呼叫 production DP 作 expected，禁止複製其他分支 fixture。必查舊 profile 與 Stage02/03 的保留語義；新增 `[2,2,2,2,2,2,2]` 的 Catalan(7)=429 作**獨立閉式計數**，並測試 429 個排名往返；新增 `[4,4,4,4,4,4,4]` 28 日的 rank=1、(N+1) div 2、N 大整數精確往返及輸出 28 日；混合 7 月且 28 日以內的多個合法 profile，交織順序及邊界；非法 8 個月、29 日、0、負值、非整數與超範圍 rank 等拒絕。不可預填未知 `N` 的數值或 TAP 計數。

## Native／CI 驗收門檻

Perl >=5.40、模組與新測試 syntax 2/2、獨立 TAP 全部 PASS、stderr 空、exit0，`timeout 120s`／`ulimit -v 393216` KiB；新專用 Stage16 CI job，保留七件 ZIP（source/version/syntax/stdout/stderr/exit/result）。如 canonical jobs 全部保持啟用，新增 Stage16 後須 **17/17 必需 jobs** 在相同 source SHA 上 completed/success；逐份審核 17 份 raw logs，下載新七件 ZIP、比較 provider/upload/local SHA256、CRC 及 `source.txt`。僅全部符合後才可將 `LAST_COMPLETED_STAGE=16`。不得把本 Stage16 局部 28 日擴展當作 252..5778 日全年度交織或完整產生器驗收。

**目前：Stage16 DISCOVERY CONTRACT ONLY；零 Stage16 production/test/CI 實作，沒有 Stage16 PASS。** 無 main、merge 或發佈。

# 第 3 階段：交織排名原語有界擴充契約（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。此階段依使用者 2026-10-30 明確決定，**先擴大交織原語**，尚不接入日曆的五個日期分量。第 2 階段驗收文檔：`docs/STAGE_02_NATIVE_CI_ACCEPTANCE_2026-10-30.md`；其時原始 HEAD 為 `fb72d2b830f075433e1b1ab578755ba5784a4827`，`LAST_COMPLETED_STAGE=2`。

## 輸入與輸出（可量測）

維持 `lib/Pastafari/Monster/WeavingPrimitive.pm` 原有三個匯出 API：
- `count_weavings($profile) -> Math::BigInt`；
- `rank_weaving($profile,$word) -> Math::BigInt`（一基）；
- `unrank_weaving($profile,$rank) -> ArrayRef[Int]`。

月份標籤是規範索引 `1..m`，不依中文譯名排序。每個月索引必須出現對應的正整數次數，月份首次出現與末次出現均嚴格依索引遞增；合法完整序列以數值索引字典序排名。**新的能力上限為 `1 <= m <= 6`，各月份長度為無前導零的正十進位整數，`sum(profile) <= 24`。** 既有 Stage2 合法輸入的計數、排名、反排名與錯誤語義不得退化；先前「五個月／十三天必拒絕」的測試需更換為本階段超界設定。負數、零、非整數、超出範圍的 rank、無效標籤、錯誤長度、首末次順序違反，均須拒絕，且不得修改輸入或 `Math::BigInt` 實例。輸出不得與內部可變記憶共享。

## 演算法與獨立 oracle

保留 Stage2 的精確 `Math::BigInt` 局部記憶化動態規劃，以剩餘長度向量及已首見／已末見前沿為狀態，無浮點數、無偷載 `t/lib`。本階段只擴充驗證後的安全界限；不可複製其他語言的生產演算法、不可改寫日期入口、不暗示全年性能。

獨立差分由 `t/48_stage03_weaving_extended.t` 的**多重集合全部排列**產生，不使用生產 DP 的下一步合法性剪枝；在完整排列結束後另行判斷首見與末見順序，再比較總數、全體有效排名及反排名。其窮舉集合刻意限於可在資源界內完成的長度小於或等於 10 之設定。對六個各長度二的月份，採用獨立的 Catalan 閉式 `C_6=132` 作計數錨點，再檢查每個排名雙向往返；這是代數對照，不是第二次窮舉。六個各長度四的月份以及 24 日單月份僅驗證邊界和 first/middle/last rank 的雙向一致性，**不宣稱對全部大規模字串做過獨立窮舉**。

## Native／CI 驗收

- 同一個 Stage3 來源 SHA 下，GitHub Actions `stage03-perl-weaving-extended.yml`：Perl 5.40、UTF-8、語法、至少 100 條 TAP 斷言、全部成功、stderr 空、退出碼零；該 job 以 `timeout 120s` 和 `ulimit -v 393216`（384 MiB **虛擬位址空間**，不是實測 RSS）限制。
- 同 SHA：`t/47_stage02_weaving_primitive.t` 回歸通過；完整 `perl-stage01` 及 `verify` 通過，必要時讀取相應 job 日誌；不重跑已通過的舊 SHA。
- 保存 `source.txt`、`perl-version.txt`、`test.stdout`、`test.stderr`、`test.exit`、`result.txt` 的 artifact，記錄 run ID、SHA、TAP 數、stderr、限制和結論。原始 artifact 如可能再獨立核對雜湊。
- `CURRENT_STAGE=3` 而 `LAST_COMPLETED_STAGE=2`，直至所有以上證據完成；queued/in_progress 不是 PASS 也不是阻塞。
- 禁止 merge/main、跨實作差分代替獨立 oracle、未測先行 PASS。下一步在 CI completed 後依日誌修正或登記精確驗收。

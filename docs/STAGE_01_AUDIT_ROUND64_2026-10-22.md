# 第 64 輪：提前末次序閉式 1..8 完整小型四月份狀態窮舉

日期：2026-10-22（以色列時間）。只在 `Perl+國語` Stage 1。
不得修改 main、正式曆法、Stage 2、其它語言或 HANDOFF。

## 已實證的第 63 輪

HEAD `1b8744b013529e80d961c7f3998b75089ddfc7b8`。
原生 GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39773597999
verify、普通 Perl 83 檔／88980 斷言、opt-in 小空間
全部 SUCCESS。R63 共 2401 個月長 1..7 的四月向量、
429779 個合法可達狀態，其中 96040 個是前三月已開、
第四月未開的可達狀態；正向獨立合法後繼遞迴、
歷史 DFS、受控 FIFO 與 CLOCK 逐狀態一致。
R63 受控工作耗時 42.871 秒、VmHWM 110136 KiB。

## 本輪新增的覆蓋範圍

不改寫 R63 原始工具與歷史 Native 證據。
新增 `tools/profile_r64_exhaustive_early_last.pl`，
將四個月份長度的全笛卡兒積由 1..7 擴至
1..8，總共 **4096** 個四月份向量。

另一個簡短、獨立合法後繼狀態枚舉計算已得到：
- **1194240** 個全部合法可達狀態；
- **244224** 個前三月已開、第四月未開的合法可達狀態；
- [8,8,8,8] 完整合法詞數恰為 **216355766851224**。

工具本身再次從零依獨立的合法「首次依次、末次依次」
規則計算所有向量、所有可達前綴與每一狀態的完工數。
在每個提前末次序狀態，各自要求歷史未啟用閉式 DFS、
opt-in FIFO 與 opt-in CLOCK 精確 BigInt 都等於
獨立純後繼遞迴整數。另核對全部可達狀態皆由
參考遞迴遍歷、重入和修改 BigInt 回傳不汙染快取。

最大向量 32 日，特別核對上述最長對稱完工數；
純參考整數不得達到有號 int64 可能溢位的界線。
仍然保留 FIFO、CLOCK 每個 **16** 個 BigInt
記憶結果的硬限制。

只新增 `[weaving-fourmonth-r64-exhaustive]` 原生 opt-in
工作，單子程序最多 185 秒／393216 KiB RSS，
GitHub 五分鐘、外層 260 秒不放寬。
新增 `t/83_r64_early_last_exhaustive_ci_contract.t`，
校驗全部四重 1..8、三個精確總量數字、最長對稱
向量參考詞數、數學模型獨立性與每個資源限制。

只有新 opt-in、普通 Perl 全量、verify 全部 Native PASS
才可以結束第 64 輪；任何 FAIL、BLOCKED、取消應保留
原始證據，不能只因 R63 PASS 而聲稱已完成。

此處依然僅為 Stage 1 私有 QA 四月份小空間閉式測試，
不代表 45 個月／4244 日完整年度的字典序驗證，
也不是跨語言 Soak，Stage 2 仍未獲授權。

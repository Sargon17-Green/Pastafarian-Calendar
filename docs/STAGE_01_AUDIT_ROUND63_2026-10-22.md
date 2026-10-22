# 第 63 輪：提前末次序閉式的 1..7 全部小型四月份狀態窮舉

日期：2026-10-22（以色列時間）；Perl+國語 Stage 1，
不可更動 main、Stage 2、生產日曆或 HANDOFF。

R62 已 Native 完整 PASS：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39763152182
HEAD d73882ef2cbdd565d0c75fc796ce903cd3a7a03c；
普通 Perl 82 檔、88961 個斷言 PASS，
625 組四月向量，9375 個「前三月已開」狀態與
35625 個整體合法狀態的直接字序列舉皆 PASS。

新增獨立工具 tools/profile_r63_exhaustive_early_last.pl，
保留原 R62 來源和歷史 CI 不變。每月長由 1..5 擴大到
**1..7**，四個月的笛卡兒積為 **2401** 組。
用另一個純合法下一月份遞迴獨立遍歷：
- 所有可達狀態：**429779**；
- 第四月尚未開而前三月已開的狀態：**96040**；
- 純參考記憶式計數涵蓋的合法狀態必須等於 429779。

對每一個前三月已開的可達狀態，把獨立純遞迴所得
合法完整後繼詞的精確整數和以下三種原始實際引擎核對：
不啟用閉式的 DFS、啟用提前末次序閉式的 FIFO、
啟用提前末次序閉式的 CLOCK。
每個向量亦檢查原始完整總數、快取回傳 BigInt 可變
所有權、重入、CLOCK second chance 和 FIFO 淘汰。
即時快取 BigInt 項上限仍為 **16**，不得提升。
最大 28 日的參考詞數小於 4^28，可精確容納有號 int64。

新 opt-in [weaving-fourmonth-r63-exhaustive]，
一個原生 GitHub CI 工作，185 秒、RSS 393216 KiB、
外部 260 秒和工作最高五分鐘均與原先相同。
新增 t/82_r63_early_last_exhaustive_ci_contract.t
核對域的完整性、模型獨立性、精確狀態數與 CI 守衛。

必須原生額外工作、全部 Perl 回歸與 verify 全部成功
才可標記 R63 完成。仍然只驗證小型四月份 QA 閉式，
不是完整 45 月／4244 日全球 BigInt 字序證明或跨語言 soak。

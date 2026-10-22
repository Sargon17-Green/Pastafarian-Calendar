# 第 62 輪：四月份提前末次序閉式的全部 1..5 小空間窮舉

日期：2026-10-22（以色列時間）。僅 Perl+國語 Stage 1，
不更改 main、正式曆法、Stage 2、任何 HANDOFF 或其他語言。

## 原生基線與歷史錯誤

R61 最終修復 HEAD ed5e1b638544ffda823fb8437c435f2f8b81681a
原生 GitHub Actions：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39733238028

verify、普通 Perl 全套以及 R61 名次 08、09 兩份獨立
312 日 SHA-512 BigInt 字典序工作全部 Native SUCCESS。
原生第一版 R61 的 t/79 測試覆蓋門檻錯誤、原 R60
08/09 TIME_LIMIT BLOCKED 均繼續保留，不准改寫為 PASS。

R61 對七個小型四月份向量的 74 個「前三月已開、
第四月尚未首次出現」狀態，把可選組合閉式
與舊 DFS、直接合法字序逐項比對，結果 PASS。

## R62 獨立窮舉加深

在全新的工具 tools/profile_r62_exhaustive_early_last.pl，
對所有四月份月長從 1..5 的完整笛卡兒積執行：
5^4 = **625** 組向量，全部恰好 **9375** 個不同
「前三月已開、第四月尚未開」可達狀態。

每組自行從剩餘日數、已首次開月數、按順序已關月數
逐步窮舉**所有合法下一月份**。另一個局部閉包式
記憶遞迴用精確原生 64 位整數保存純列舉答案
（最長只有 20 日，計數小於 64 位整數界限）；
它不呼叫被測提前末次序閉式、原 Oracle 或位置多項式。

對每個可達狀態，分別比較：
- 未開新閉式的原始記憶式 DFS；
- 明確 opt-in 提前末次序閉式 + FIFO，快取上限 16；
- 明確 opt-in 提前末次序閉式 + CLOCK，快取上限 16；
三者全都須等於獨立合法字序遞迴的精確數值，
不能只核對整個向量的總數。重入及修改可變 BigInt
答案後再查也不能污染快取。

每份小向量的前沿狀態全部遍歷，前提、月份首次／末次
合法性與關月次序不偷用被測多項式引擎。
R62 原生 opt-in：
[weaving-fourmonth-r62-exhaustive]；
一個完全受控工作，185 秒、393216 KiB RSS、
GitHub job 五分鐘，內部短快取 16 個 BigInt 結果。
任一非法、漏驗、結果不等、時限／記憶超限均不可 PASS。
新增 t/81_r62_early_last_exhaustive_ci_contract.t
檢查測試域、独立遞迴、9375 個狀態、唯一 job
及原始硬資源上限，屬一般 Perl 快速回歸。

只有新增原生工作、全套 Perl、verify 都 SUCCESS
才可標記 R62 完成。即使完成，也只更強地驗證
四月份小空間的私有 QA 閉式，不是完整 45 月／4244 日
全球 BigInt 排名或跨語言 soak。

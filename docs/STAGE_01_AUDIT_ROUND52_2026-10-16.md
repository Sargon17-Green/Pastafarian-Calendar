# 第 52 輪：236 日真實四月份的完整 236 次 BigInt 字序獨立對照

日期：2026-10-16；僅 Perl+國語 Stage 1，嚴禁變更
main、正式算法、Stage 2 或 HANDOFF 包。

## 動機

Round 46–51 已用各自有界的獨立正向合法狀態前沿
和精確 BigInt 分割逐個核對中間名次的前六天
[1,2,1,2,3,1]，歷史 Round47 的 TIME_LIMIT BLOCKED
已由分片工作替代，且原生紀錄未遭刪除。

此前 Round31 的記憶式私有前綴 Oracle
\`Pastafari::WeavingMemoOracle\` 曾在 322 日真實四月
以單一共享 memo、完全不用排名器 DP 的方式，
對中間一基 BigInt 排名的**全部 322 日**
進行合法候選精確分割，186325 個私有狀態、約 202 MiB
之內完成。它和每個前綴另開完整正向前沿不同，
有可能高效核對同一個 236 日窗口的全部日位。

## 本輪更嚴格驗證

既有 \`tools/profile_canonical_memo_multi_ranks.pl\`
原生工具僅支援 zero-based offset 38、39、40。
只新增受控 offset 37，明確比對同一權威年份 SHA-256
選出的月份為 **[83,88,40,25]**、合計 **236 日**。
舊窗口、14 名次選項、計數核心均維持原樣。

新增獨立 opt-in
\`[weaving-window37-full-middle]\` GitHub 工作，
執行 \`--window-offset 37 --case-filter middle\`：

1. 以独立記憶式剩餘月長、opened/closed 狀態及末次
   出現的組合閉式，計算精確的全局 BigInt 數，
   並對照常駐位置多項式總數；
2. 索引式 \`unrankWeavingPolynomial\` 產生 236 日中間詞，
   並以索引式正向排名完全還原同一個 BigInt；
3. 對每一天 \`1..236\`，獨立 Oracle 獲得目前母前綴
   全部完工數，再逐一求所有合法下一月份 BigInt，
   斷言完整候選精確和等於母前綴；
4. 完全不讀取排名器的選擇快取，獨立按局部一基 BigInt
   減去較小候選得到當天應選月份，和索引反排名的
   第 1..236 個字元逐一比對；
5. 所有月份長度歸零，局部一基名次等於 1，
   可變 BigInt 原始輸入未被污染。

沿用 185 秒、393216 KiB RSS、外層 260 秒、
索引單檔 16 MiB；未滿足所有 236 日則不能 PASS，
超時必須 BLOCKED。新增一般回歸
\`t/69_quad_whole_middle_memo_ci_contract.t\`
檢查真實向量 236 日、每天候選和與字元核對、
唯一 opt-in 與安全上限。

只有受控原生工作、全套 Perl 和 verify 都 PASS
才標記本輪完成。若成功，這是該四月窗口中間排名
**整個 236 日**獨立核對，比第 51 輪逐日分片更強。
但它依然不是全年度 45 個月/4244 日的全域
BigInt 字序比對，也不是其它語言實作 soak。

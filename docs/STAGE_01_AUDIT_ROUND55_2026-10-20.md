# 第 55 輪 Stage 1 稽核：236 日全部十二個 SHA-512 BigInt 名次

日期：2026-10-20；僅 Perl+國語 Stage 1。此為**稽核輪次 55**，
不是 DISCOVERY/PATCH 開發階段 55，沒有 Stage2 授權；
不改 main、規範曆法或 HANDOFF。

第 54 輪 Native CI：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39410645316
verify、一般 72 個 Perl 測試檔／88542 斷言、十四個固定
一基 BigInt 排名分兩批全長 236 天的獨立候選計數核對
全部成功（14×236 = 3304 次逐日決策）。

固定前 4 個月 [83,88,40,25] 的完整合法字序數 N
有 125 位十進數字。舊的 14 個固定候選著重首尾、
十／四分位與中位；還需取得大範圍中的非邊界候選。
本輪以不依賴後綴多項式的確定性 SHA-512 種子
PASTAFARIAN-5000-FOURMONTH-37-R55:{0..11} 產生
512 位十六進位值，精確 BigInt 對 N 取模再加 1，
將最終排名置於 1..N。嚴格檢查 12 名次均不同，
否則 FAIL，不能默默減少樣本數。
前六個名次為 hash-a，後六個為 hash-b，
兩份受控獨立 opt-in CI 工作啟動。

對每個名次，每一天：
1. 由既有完全獨立的剩餘月長／已開已關狀態
   Pastafari::WeavingMemoOracle 精確計數父前綴；
2. 窮舉所有合法下一月份並算出各 BigInt 完工數，
   候選總和必須恰為母前綴；
3. 用局部一基 BigInt 扣去較小候選，
   得出的字元須和磁碟索引 unrank 全長結果相等；
4. 236 日耗盡全部真實月份，最後局部排名為 1，
   正向 rank 還原、原始 BigInt 不被污染。

共 12×236 = 2832 次進一步的全長合法分支檢驗。
保留 FIFO 常駐 200000 筆 BigInt 快取項硬上限，
單次 185 秒、393216 KiB RSS，索引單檔 16 MiB、
GitHub job 5 分鐘。新增 t/72_quad_hash_ranks_ci_contract.t
以外部 SHA-512 固定摘要片段核對種子、總排名生成式、
防重、兩個六樣本工作與全部資源限制。
僅提交標記 [weaving-window37-hash12] 觸發。

只在兩工作、完整 Perl 和 verify 均 Native SUCCESS 時
關閉本輪。這仍是 236 日四月份局部樣本，
不是全 45 月 4244 日全球 BigInt 次序或跨實作 soak。

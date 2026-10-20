# 第 56 輪 Stage 1 稽核：230、240 日真實四月份之 24 個 SHA-512 BigInt 完整排名

日期：2026-10-20，僅 Perl+國語 Stage 1。本文件「輪次 56」
不是 55 階段程序的 Stage 56，沒有 Stage 2 授權。
不改 main、正式算法或 HANDOFF。

第 55 輪原生 CI
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39411801966
SUCCESS：73 Perl 檔、88564 斷言，固定 offset 37 窗口
[83,88,40,25] 236 日的 12 個由 SHA-512 派生 125 位
BigInt 名次均各自依獨立記憶式前綴 Oracle 完整逐日
驗證，兩個原生 opt-in 工作皆 PASS。
原有 14 個重要名次亦在第 54 輪完全成功，
故該窗口累計 26×236=6136 次獨立逐日選擇。

本輪擴及其它**真實年份**零起始四月窗口：
- 38: [88,40,25,77] = 230 日；
- 39: [40,25,77,98] = 240 日。
保留固定 Year 5000 45 月、4244 日 SHA 指紋與所有
原本名次樣本、FIFO 僅 37 窗啟用的嚴格界線。
每窗口使用另外固定的 ASCII 種子
PASTAFARIAN-5000-FOURMONTH-<offset>-R56:<index>
對 index 0..11 逐個計算整個 SHA-512 512 位精確 BigInt，
模該窗口全部合法詞數 N 加一得到一基合法排名；
重複排名必須 FAIL，絕不可默默省略。

新增各窗口 a（前六）與 b（後六）兩個 opt-in 工作：
[weaving-fourmonth-hash24]。
合計 2 窗×12 排名×每窗 230 或 240 天
= 12×230+12×240=5640 次獨立下一月份決策。
每一天記憶式 Oracle 對合法子分支精確 BigInt 計數，
子分支總和等於父前綴；獨立排序扣除數值與
unrankWeavingPolynomial 每個字元完全一致，
且 rank 完整雙向還原、月份日數全耗盡、局部排名為 1。

每工作最多 185 秒、393216 KiB RSS，外層 260 秒，
索引文件單檔 16 MiB、GitHub job 5 分鐘；
任何一次超額皆 BLOCKED 並標示未完成。
新增 t/73_quad_hash_multiwindow_ci_contract.t：
驗證兩組 12 個位置的已知 SHA-512 摘要片段、
嚴格 offset 域分離與四工作全覆蓋，
不影響第 55 輪歷史已通過的 seed 字串。

僅 verify、全部 Perl、四個原生工作皆 SUCCESS
才算本輪完成。此仍為四月份局部窗口，絕非完整
45 月份 4244 日全局 BigInt 排名或跨實作 soak。

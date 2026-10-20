# 第 57 輪 Stage 1 稽核：真實 322 日四月份之 12 個 SHA-512 BigInt 完整排名

日期：2026-10-20（以色列時間）。只修改 Perl+國語 的 Stage 1
原生測試工具、驗證 CI 及文件，不改 main、正式曆法算法、
Stage 2 或任何 HANDOFF。

已確認的前置 Native 證據：
- 第 54 輪 236 日的 14 個精確排序位置、每位 236 日全長獨立驗證，
  https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39410645316
- 第 55 輪同一 236 日的 12 個 SHA-512 名次，完整兩份 opt-in
  Native PASS，73 Perl 檔、88564 斷言 PASS，
  https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39411801966
- 第 56 輪另外兩個真實窗口 38：[88,40,25,77]／230 日，
  39：[40,25,77,98]／240 日，各自 12 個 SHA-512 完整
  BigInt 字序 Native PASS；四工作皆 PASS、74 Perl 檔、
  88596 斷言 PASS。來源：
  https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39412867075

本輪擴展至固定 Year5000 零起始窗口 40：原始月份
[25,77,98,122]，共 **322 日**。該窗口與 37..39
同源自 SHA-256 固定的 45 個月、4244 日權威快照。
保持舊有 322 日重要排名驗證及 37、38、39 三個窗口
所有選項與 SHA 種子不變。

新增只接受 hash40-a、hash40-b 的具名 CLI 路徑。
使用 SHA-512 固定域分離種子
PASTAFARIAN-5000-FOURMONTH-40-R57:{0..11}，
逐一將 512 位精確 BigInt 除以本窗口所有完工詞
BigInt 總數 N 取餘，再加一得到一基字序排名。
若任一重複或越界必須 FAIL。
每個 opt-in 工作檢查完整六個排名 × 322 日，
全部候選下一月份精確合法完工數之和、獨立一基局部
排名、與磁碟索引反排名逐日逐字一致；
正向排名必須還原、全部原始月份長度用盡、
最後局部名次恰為 1。

兩份 opt-in 工作由 [weaving-fourmonth40-hash12] 觸發，
共 12×322=3864 次完整逐日 BigInt 分支選擇。
每個子進程 185 秒、RSS 393216 KiB，外層
260 秒、索引單檔 16 MiB，Oracle 預設嚴格
200000 項快取狀態 hard-fail（第 40 窗未啟用 FIFO）；
任何 BLOCKED 或 FAIL 不得冒充 PASS。
新增 t/74_quad_322_sha_ranks_ci_contract.t
以固定獨立 SHA-512 摘要片段、具名路徑、保留
全部舊選項、獨立排序和式、唯一 CI job 與所有硬預算
防止靜默遺漏。

關閉第 57 輪條件：verify、普通 Perl 全量測試、
兩個真實 322 日 Native opt-in 工作全部 SUCCESS。
此為 Stage 1 的第 57 輪獨立稽核，不是 Stage 57；
不聲稱完整 45 月／4244 日全局字序或跨語言 soak。

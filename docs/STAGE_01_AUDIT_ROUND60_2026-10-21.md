# 第 60 輪 Stage 1：312 日 R59 三個超時排名的有界 clock 快取修復

日期：2026-10-21。只修改 Perl+國語 的 Stage 1 QA/CI；
不改 main、規範曆法算法、Stage2 或 HANDOFF。

第 59 輪 Native CI：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39610214165
已有 21/24 個獨立 312/319 日 SHA-512 完整字序 PASS，
但窗口 36 的 hash36-08、hash36-09、hash36-10
各在 185 秒被 TIME_LIMIT BLOCKED（不是算術矛盾）。
所有 BLOCKED 歷史必須保留，不得將 R59 誤記為全 PASS。

R60 不提高 185 秒、RSS 393216 KiB、200000 個同時
BigInt 狀態或外層 260 秒的原定界線。
在完全不更動獨立後綴遞迴或 BigInt 精確算法前提下，
僅為三個已確認的超時排名，顯式啟用
cache_policy=>'clock' 的 second-chance 淘汰：
快取命中狀態附加引用標記，滿額時依 FIFO 次序逐個
檢查；近期有命中的狀態給一次第二機會，
未命中的狀態才逐出並在需要時重新計算。
同時儲存狀態永遠不得超過 200000。
預設、此前 R53–R59 全部窗口和 FIFO 原生歷史行為不變。

新增 t/77_bounded_memo_clock.t 小空間交叉比對
FIFO、clock 和獨立位置多項式的精確 BigInt，
以限額四個狀態主動觸發逐出和 second-chance，
並檢查禁止超限及未知政策。
新增 t/78_r60_clock_ci_contract.t 驗證三個
指定名次唯一性、原有資源上限、其他排名仍沿用
原政策。

三個 Native opt-in 工作由
[weaving-fourmonth-r60-clock] 觸發，
各自必須精確查驗 hash36-08／09／10 的
312 日所有合法下一前綴及 BigInt 母區段，
與索引反排名逐字相等、最後局部名次為 1，
並可正向還原原排名。其餘 21 個在原生 R59 已 PASS
的排名保留其各別 SHA 及日序證據。
只有三份 R60、全量 Perl、verify 全部 PASS 並
配合前 21 份 R59 Native PASS，才可稱全部
24 個 R58 名次完成獨立驗證。
不宣稱 Stage2、45 月 4244 日全局名次或跨實作 Soak。

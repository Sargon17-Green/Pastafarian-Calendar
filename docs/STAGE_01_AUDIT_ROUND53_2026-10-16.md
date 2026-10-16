# 第 53 輪：不放寬記憶上限的私有 BigInt Oracle FIFO 淘汰修復

日期：2026-10-16，限定 Perl+國語 Stage 1，不改 main、
正式曆法算法、Stage 2 或 HANDOFF。

第 52 輪真實 Year 5000 四月窗口 [83,88,40,25]
中位 BigInt 236 日完整記憶式獨立字序核對工作：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38918732706
原生結果為 FAIL：開始約 13 秒時
「獨立驗證狀態快取超過 200000 項」。
原始 200000 項內存硬界線確實阻止該 Oracle
驗證此窗口；沒有 BigInt 字序或數學差異的證據。
原歷史 FAIL 必須保留；第 52 輪不得被稱為 PASS。

此輪改進**測試專用** t/lib/Pastafari/WeavingMemoOracle.pm
的可選快取政策，數學遞推及原生歷史選項不變。
預設仍是嚴格 200000 項 hard-fail。
只有明確指定 bounded_cache=>1 時：
任何時刻仍最多 200000 個快取 BigInt 結果，
超出上限就以 FIFO 刪除一個**已計算的**私有狀態，
需要時重新計算；並追蹤被逐出的數量。
所有月份、字序有效性及 BigInt ownership 不變。
不提升任何記憶上限或執行時間。

只有 window-offset 37 的完整中位實驗顯式使用
{bounded_cache=>1,cache_limit=>200000}，
offset38..40 仍是原本完全相同的嚴格上限。
新增 t/70_bounded_memo_fifo.t，在 3 組小空間內
把硬上限刻意設為 4，獨立比對總數、前綴計數、
重入和所有權，且拒絕超界／未啟動選項。
本輪 commit 再觸發同一個
[weaving-window37-full-middle] 原生 GitHub CI 工作，
務必確認該 job 全部 236 日逐字比對、verify 和
一般 Perl 全套全部 PASS；若仍 BLOCKED/FAIL，
分析重算成本與深度後再設計，不得宣稱完成。

第 47 輪 TIME_LIMIT BLOCKED 和第 52 輪
CACHE_LIMIT FAIL 都屬於歷史真實記錄，不可刪改。


## 第 52 輪全套 Perl 尾端取消

第 52 輪 `perl-stage01` 原生日誌顯示全部 70 檔、88,465 斷言、`Result: PASS`，但耗時 593 秒；隨後 GitHub 的 10 分鐘 job 上限在清理過程標記該工作 `cancelled`。因此 **整個 CI 仍非 PASS**。第 53 輪只把一般 `perl-stage01` 的外層 GitHub job 上限由 10 改為 12 分鐘，給原生全套與清理時間留餘裕；**各個單獨計算的 185 秒、393216 KiB RSS、外層 260 秒並未加大**。

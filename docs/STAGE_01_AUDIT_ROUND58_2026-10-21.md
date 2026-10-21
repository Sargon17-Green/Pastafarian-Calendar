# 第 58 輪 Stage 1 稽核：較早月份 319 日與 312 日的 SHA-512 BigInt 全長排序

日期：2026-10-21（以色列時間）。只修改 Perl+國語 的 Stage 1
QA／CI／文件；不修改 main、正式曆法、Stage 2 或 HANDOFF。

第 57 輪修復 HEAD edb3255857b00fb307fe858452b429d4078803e1
於 GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39497020492
完整 Native SUCCESS（verify、Perl 全套與窗口 40 兩份 SHA-512
六排名精確全長字序）；初版 R57 的 t/73 文本契約
FAIL 在此新 HEAD 已修復，歷史失敗不可改寫。

從同一套 SHA-256 固定的 Year 5000 45 月、4244 日
月份向量，選兩個之前尚未實施全長 SHA-512 名次
獨立比對的較早四月窗口：
- zero-based 34: [81,54,101,83]，319 日；
- zero-based 36: [101,83,88,40]，312 日。

固定 R58 域分離種子
PASTAFARIAN-5000-FOURMONTH-<offset>-R58:<index>
（offset 僅 34 或 36；index=0..11）。
以完整 512-bit SHA-512 BigInt 對窗口全部合法
字序完工數 N 求餘，加 1 取得一基合法排名。
拒絕無效排名或十二個名次碰撞，不作靜默去重。
前六名與後六名分別在 opt-in 的 a/b 原生工作中執行：
[weaving-fourmonth-r58-hash24]，共四份工作、
12×319+12×312 = **7572 次**逐日 BigInt 字序分支核查。

每一天對所有合法下一月份，與索引式排名器
互相隔離的 Pastafari::WeavingMemoOracle
獨立算出所有完工數，候選精確和須等於父前綴；
由一基 BigInt 當前名次依字序扣除較小候選，
得到的月份標籤須與完整磁碟索引式反排名一致，
且正向 BigInt rank 完全還原、全部天數耗盡、
最後局部排名為 1、BigInt input 未污染。

這兩個較大窗口明確選用既有 private bounded_cache
FIFO 200000 同時結果硬上限，與第 37 窗規則相同；
38–40 舊窗口仍保留原有嚴格 hard-fail 設置。
每個原生子程序維持 185 秒、RSS 393216 KiB、
外層 260 秒，索引單檔 16 MiB，
Github job 整體 5 分鐘。超額是 BLOCKED，
數值不一致是 FAIL。

新增 t/75_quad_hash_earlywindows_ci_contract.t，對兩個
原生月份窗口、八個 SHA-512 已知摘要、
四份 job 的唯一性、資源上限、種子域分離、
獨立合法前綴候選和／逐字比較作直接回歸。
保留舊 R55–R57 的所有固定 SHA 與 opt-in 介面。

只有四份原生工作、verify 和全套 Perl
全部 SUCCESS 才能宣稱 R58 已完成。
本輪仍屬 Stage 1 局部四月樣本；不是完整 45 月、
4244 日全域 BigInt 排名，也不是跨實作 Soak。

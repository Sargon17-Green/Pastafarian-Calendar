# 第 59 輪 Stage 1：四月窗口 319／312 日各十二個精確 SHA-512 名次獨立分片

日期：2026-10-21（以色列時間）；僅 Perl+國語 Stage 1。
不可修改 main、正式曆法算法、Stage 2 或 HANDOFF。

第 58 輪四個六排名原生工作
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39607641880
均因 185 秒 TIME_LIMIT 而 BLOCKED，並非算術差異；
其 PASS 前綴次數不能冒稱六排名全部完成。
完整原始 CI 和 BLOCKED 日誌須保留。

為避免放寬時間、RAM 或 BigInt 記憶上限，本輪以兩個
GitHub Actions 固定 strategy.matrix 工作對零起始窗口 34
[81,54,101,83]（319 日）與 36 [101,83,88,40]（312 日）
各生成 12 個單排名原生子工作。matrix index 固定 00..11，
fail-fast:false，總共 24 個互補 job，無遺漏／重複。

每個子工作仍從完整 Year5000 SHA-256 權威月份
以及同一 R58 ASCII SHA-512 seed
PASTAFARIAN-5000-FOURMONTH-<offset>-R58:<index>
得出所有 12 個完整 512-bit BigInt 排名，確認互不碰撞；
但只對選中的一個 BigInt 排名執行 312/319 天
所有合法下一標籤的獨立完整計數／父前綴 BigInt
和式／字典序選擇／索引式反排名逐字比對、正向還原、
月份日數歸零和原始 BigInt 不污染。

每個工作硬上限仍 185 秒、RSS 393216 KiB、
BigInt FIFO 同時最多 200000 狀態、
私有索引單檔最多 16 MiB、GitHub job 最多五分鐘。
若任何排名 FAIL、BLOCKED 或取消，整個 R59 仍未完成。
所有 24 工作加普通 Perl 回歸和 verify 必須
於同一 HEAD Native SUCCESS。
新增 t/76_quad_hash_shard_ci_coverage.t 防止原始月份、
SHA seed、24 matrix 名次和硬限制靜默變更。

這仍只是 Stage 1 的 2 個局部四月份排名樣本，
並非全年度 45 月、4244 日全球 BigInt 字序，
也不是跨語言 soak。Stage 2 未獲授權。

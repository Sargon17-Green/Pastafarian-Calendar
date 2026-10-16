# 第 54 輪：四個真實月份 236 日的全部十四種 BigInt 字典序驗證

日期：2026-10-16。僅 Perl+國語 Stage 1；不得變更 main、
正式曆法、Stage 2 或 HANDOFF。

在第 53 輪的私有 FIFO BigInt Oracle 中，保持 200000 個同時
快取狀態的硬上限，允許安全淘汰既有結果並重新計數。
該輪獨立原生工作 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38920442890
已在 [83,88,40,25] 236 日窗口對一基中間 BigInt 名次完成
236/236 天逐字核對；每一天全部合法下一標籤的
獨立完工詞和等於父前綴，索引反排名相符，
200000 個常駐 BigInt 快取項、88965 次 FIFO 淘汰、
563850 次命中、耗時 48.768 秒、VmHWM 216688 KiB。
第 53 輪一般 Perl 回歸是否最終全 PASS 需另行確認；
歷史第 52 輪 CACHE_LIMIT FAIL 不可覆寫。

本輪把已通過的同一原生獨立測試由「單一中位名次」
擴充為全部十四個固定精確 BigInt 字典序重要排名：

first, second, third, fourth, p10, p25, pre_middle,
middle, p75, p90, near_last3, near_last2, near_last1, last。

兩個獨立 GitHub Actions opt-in 工作只在
[weaving-window37-all14] 提交標記時執行：
first-half 固定前七、last-half 固定後七，互補不重複。
每組七個 BigInt 排名，全長 236 天，總共
14×236 = 3304 次獨立前綴 BigInt 選擇，
每個選擇需枚舉所有當日合法後繼的獨立完工數，
和父前綴一致，再和索引反排名字元逐位對照。

每個工作維持單子程序 185 秒、393216 KiB RSS，
GitHub 5 分鐘、單檔索引 16 MiB、
FIFO 同時 BigInt 狀態最多 200000。資源不足時
必須 BLOCKED，數學差異時必須 FAIL；
不可把 7/14 部分成功記作全部通過。
新增 t/71_quad_fourteen_ranks_ci_coverage.t
核對兩組互補、唯一性、原生 hard limit 和前綴和式。

兩組完整原生工作、verify、一般 Perl CI 全部 PASS 才能
標記此輪完成。這是零起始 37..40 四個局部月份
236 日字序的 14 個指定排名，不是全年度
45 個月份/4244 日的 BigInt 順序，也不等同跨語言 soak。

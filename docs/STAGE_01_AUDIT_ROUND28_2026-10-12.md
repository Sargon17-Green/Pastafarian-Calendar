# 第 28 輪：真實四月份 240 日十四個不同 BigInt 排名全長分支驗證

日期：2026-10-12。僅 \`Perl+國語\` Stage 1。不修改 \`main\`、正式曆法 API、Stage 2 或 \`HANDOFF_*\`。

## 第 27 輪的原生驗證結果

GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38286000538

\`CANONICAL_MEMO status=PASS scope=FULL_240_DAY_LEXICOGRAPHIC_BRANCHES\`
實際第 5000 年四月份 \`[40,25,77,98]\`，總計 240 日，
中間 125 位 BigInt 一基排名的**全部 240 次**字典序選擇均由
不共用任何多項式排名器內部狀態的獨立記憶式 Oracle 精確
分割並與索引式解碼器逐位匹配。11.028 秒，VmHWM 147,300 KiB，
147,982 個記憶式計數狀態、142,335 次命中。全量 Perl CI
結果須另外確認後才稱整個工作流全部 PASS。

## 本輪新的數學風險與擴展

上一輪只測了中間一個排名，可能漏掉「字典序前段、尾段、
在 1/2 或其他分位交界時 BigInt 借位」之錯誤。
新增僅在標記 \`[weaving-canonical-multi-rank]\` 時執行的
\`tools/profile_canonical_memo_multi_ranks.pl\`，驗證固定的十四個
**不同**實際 240 日排名：

\`1,2,3,4,\` \`floor(N/10), floor(N/4), floor(N/2),
floor(N/2)+1, floor(3N/4), floor(9N/10), N-3, N-2, N-1, N\`。

每一名次都以真實長度得到完整 240 字詞，並同時檢查：
- \`unrankWeavingPolynomial\` 索引式解碼；
- \`rankWeavingPolynomial\` 重建輸入名次；
- 記憶式精確獨立後綴 Oracle 由當前 BigInt 局部名次逐日計數所有合法標籤、逐步分割，**全部 240 次選擇**逐字核對；
- 各階段分割和等於母前綴數，完整字序結束的剩餘月長全為 0，局部 BigInt 為 1；
- 原始 BigInt 排名不變，並在所有 14 個排名間重用只有 Oracle 私有的快取。

共須完成 **3,360 次**獨立字典序局部分割。
即使全部 PASS，此範圍也**僅**涵蓋四個真實月份 240 日，
不可冒稱第 5000 年整個 45 月／4,244 日皆已證明。

與之前相同的硬限制：子程序 185 秒、RSS 393,216 KiB，
外層 260 秒，超限標記 BLOCKED；獨立 opt-in GitHub job。

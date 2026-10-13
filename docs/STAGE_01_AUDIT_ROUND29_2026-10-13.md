# 第 29 輪：另一組真實四月份 230 日之十四排名完全獨立比對

日期：2026-10-13。工作分支 \`Perl+國語\`，僅 Stage 1；不修改 \`main\`、Stage 2、正式生產入口或 \`HANDOFF_*\`。

## 已通過之原生實證

第 26、27、28 輪的整個 GitHub CI 均 PASS（55 檔，87,928 斷言）：
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38285817993
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38286000538
- https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38286380778

第 28 輪標記工作 \`CANONICAL_MULTI_RANK_CHECK_COMPLETE passed=1 blocked=0 failed=0\`：
原生第 5000 年零起始索引 39..42 的 \`[40,25,77,98]\`，全部 14 個分布在
字典序兩端及分位點的 240 日一基 BigInt 排名、共 3,360 次精確分支決策皆通過。
原生計時 101.174 秒、152,256 KiB VmHWM、152,253 個記憶式狀態。

## 擴展到另一個四月視窗

本輪在**相同年度原生選擇器得到且驗證 SHA-256** 的 45 月長固定向量，
新增第二個相鄰四月視窗：

- 零起始索引 \`38..41\`：\`[88,40,25,77]\`，**230 日**。
- 原視窗 \`39..42\`：\`[40,25,77,98]\`，**240 日**，仍保留作比較。

新的 opt-in CI 工作 \`canonical-window38-multi-rank\` 只有提交含
\`[weaving-canonical-window38]\` 時才執行，呼叫同一
\`tools/profile_canonical_memo_multi_ranks.pl --window-offset 38\`。
原本 \`canonical-multi-rank\` 工作使用既有預設 \`--window-offset 39\`，
可由同時標記兩項觸發並行原生對照。

每個視窗各算 14 個大整數字典序排名（前四名、分位及尾四名）：
每一排名的全部日位次先以獨立的剩餘月長／opened／closed 記憶式
Oracle 將所有合法下一符號分支精確劃分，然後與多項式索引式
\`unrankWeavingPolynomial\` 逐位比對；
\`rankWeavingPolynomial\` 亦須完整重建原排名；
全部月底歸零、局部 BigInt 排名回歸 1，且可變輸入未被污染。

在不增加資源上限之前先以無權重狀態枚舉估算開第四月之前的可達
狀態：新視窗 85,915，舊視窗 74,039；新視窗比較難，但仍可能在
200,000 個記憶式狀態／185 秒／393,216 KiB RSS 的硬界線內。
**估算不是 PASS**。超限必須 BLOCKED，數值錯誤須 FAIL。
不得將 230+240 天的兩個重疊四月局部字序核對稱為整個年度
45 個月／4,244 日的排名證明。

# 第 32 輪：三個真實月份視窗各十四種完整 BigInt 字典序對照

日期：2026-10-13，分支 \`Perl+國語\`。僅 Stage 1 稽核，不修改 \`main\`、正式 API、Stage 2 或 \`HANDOFF_*\`。

## 前次已確認的範圍

第 31 輪原生受控工作：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38375889301

零起始索引 40..43，四月 \`[25,77,98,122]\`，合計 322 日；
**中間排名的全部 322 次決策**皆由獨立記憶式 BigInt Oracle 和索引式
字典序反排名逐字對照，且每步全部合法候選分支之計數和等於母前綴。
\`CANONICAL_MULTI_RANK_CHECK_COMPLETE passed=1 blocked=0 failed=0\`，
48.431 秒，186,325 私有記憶式狀態，360,745 次命中，
VmHWM 206,752 KiB。排名 171 位、全局總數 172 位。

\`t/55_memo_closed_form_cache.t\` 使「全開後綴由組合式即時計算，
不污染私有 BigInt 緩存」成為一般 Stage 1 回歸；須在全套
Perl 原生 CI 完成後才能聲稱整體 PASS。

## 本輪擴展

新增 opt-in GitHub job \`canonical-window40-multi-rank\`，
由提交標記 \`[weaving-canonical-window40-multi]\` 觸發，
驗證相同 322 日的 **14 個不同**原始 BigInt 排名：
前 4、10%、25%、中間之前一名／中間名、75%、90%、
末 4。共 14 × 322 = 4,508 次獨立字典序分支決策，
每次先枚舉合法下一標籤，逐個以獨立記憶式數學模型得出
可行完工總數，按一基名次縮小候選，再和索引式
\`unrankWeavingPolynomial\` 的完整字序逐位比較。
正向 \`rankWeavingPolynomial\` 必須完整還原起始 BigInt，
每個詞在最後一日耗盡全部四個月，局部排名回復 1。

同一提交也明確觸發第 28–29 輪已通過的兩個獨立工作：
- \`[weaving-canonical-multi-rank]\`：視窗 39..42，240 日 × 14 = 3,360 決策；
- \`[weaving-canonical-window38]\`：視窗 38..41，230 日 × 14 = 3,220 決策。

三窗共 **11,088 個**真實日位次 BigInt 分支檢驗。
各 CI job 仍為 185 秒／393,216 KiB RSS、上層超時
260 秒、記憶式狀態上限 200,000；超限明確 BLOCKED，
偏差明確 FAIL，全部通過才標示三窗 PASS。

這是三個重疊的四個月局部字序驗證，**不是**
第 5000 年全部 45 個月／4,244 日的全域字典序證明。

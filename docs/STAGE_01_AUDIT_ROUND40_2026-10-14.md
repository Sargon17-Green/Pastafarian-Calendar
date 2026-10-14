# 第 40 輪：修正三月份首／末名反排名的索引誤判，保留數學核查

日期：2026-10-14。僅 \`Perl+國語\` Stage 1；不得修改 \`main\`、Stage 2、正式曆法 API 或 \`HANDOFF_*\`。

## 第 39 輪實際失敗與根因

原生 CI：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38565669327

四個真實三月份窗口的完整 BigInt 排名驗證在首名開始後
同樣因 \`first 反排名沒有實際建立磁碟索引\` 而退出。
這並非算法未求出首名，也不是排名誤算：

- \`Pastafari::WeavingUnrank::unrankWeavingPolynomial\` 在經全域
  精確計數及排名有效性驗證後，對 \`rank=1\` 可直接把
  各月完整天數依序寫出，對 \`rank=total\` 可逐日選
  最大合法候選，**不需也不應建立磁碟後綴索引**；
- \`Pastafari::WeavingRank::rankWeavingPolynomial\` 對首名
  沒有任何較小合法候選，故候選數和實際索引數都是零；
- 對中間名及末名的正向排名，若有較小候選，仍必須
  保持必需的索引式精確 BigInt 後綴核查。

測試工具 \`profile_canonical_triple_rank_paths.pl\` 曾錯誤地
要求首、末兩個反排名無論快捷路徑都恰好建一個索引；
現改依引擎實際規範：
首名或末名須有正確的 \`first_rank_fastpath\` /
\`last_rank_fastpath\` 且索引建置數為零；內部中位仍須
啟動索引；正向首名零候選零索引，中位與末名則須
實際計算候選及索引。**所有**每日日序位置的獨立
BigInt 分支和核對、完整月數歸零、局部排名回到 1
及正反排名精確一致完全保留。

新增一般輕量回歸 \`t/57_boundary_rank_index_fastpaths.t\`，
三組非對稱／對稱三月向量驗證首末貪婪語義和索引
不用建立的契約，以及內部中位仍能完整往返。

大型三月的獨立私有 memo DFS 在超過 Perl 100 層時
曾刷出大量 \`Deep recursion\`（**非**實際棧溢位）警告。
在測試專用的 \`_count_state\` 內，僅靜音此一
Perl 100 層提示，維持 200,000 狀態安全界線、
原生月份總日數界線、外部 185 秒／393,216 KiB
RSS 監督和全部錯誤分類；不修改數學遞推或結果。

在四個 opt-in 原生 CI 窗口全部 PASS 且 58 檔一般
Perl 回歸 PASS 前，不能宣稱修復已完成。

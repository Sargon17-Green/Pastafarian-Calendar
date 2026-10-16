# 第 43 輪：第 5000 年真實三月窗口 BigInt 區段邊界與四分位獨立字序驗證

日期：2026-10-16。只在 \`Perl+國語\` 的 Stage 1 驗證路徑工作，
不修改 \`main\`、Stage 2、正式曆法 API 或任何 \`HANDOFF_*\`。

## 前一輪原生驗證結果

第 41 輪 11 組 GitHub Actions 全部 PASS：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38586882997

所有 43 個相鄰三月局部窗口，首／中／末名的每一日
都已由獨立記憶式 Oracle 精確分割所有合法下一月份，
與位置多項式索引反排名逐位一致。
一般 Perl 59 檔、88,142 斷言 PASS。

第 42 輪 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38589988538
一般 Perl 60 檔、88,179 斷言 PASS，包含
\`[255,100]\`、\`[100,255]\` 的超 256-bit 二項係數
直算、前沿／記憶式／多項式總數、索引正反排名、
BigInt 所有權及 byte 狀態鍵的 255 上限。

## 本輪新覆蓋

已有首／中／末名可漏掉第二名、倒數第二名和大整數四分位
附近的字典序進退位錯誤。因此在不改任何數學模型下，
為 \`tools/profile_canonical_triple_rank_paths.pl\`
新增嚴格 opt-in 選項 \`--rank-set neighbors\`：
  - \`second=2\`
  - \`lower_quartile=floor(N/4)\`
  - \`upper_quartile=floor(3N/4)\`
  - \`penultimate=N-1\`

原本 \`core\` 為預設，既有 43 個窗口的 CI 合約
與輸出 \`THREE_COMPLETE_INDEPENDENT_RANK_PATHS\`
完全不變。先獨立驗證候選全在精確 BigInt 範圍內、
數值嚴格遞增，然後逐日完整核對：
- 每個合法下一月份的記憶式精確 BigInt 完工數；
- 候選和等於母前綴；
- 由剩餘一基 BigInt 名次獨立決定下一標籤；
- 索引式 \`unrankWeavingPolynomial\` 必須逐日一致；
- 索引式正向 \`rankWeavingPolynomial\` 完全還原名次，
  各月耗盡、局部名次回到 1、BigInt 輸入不變。

新增四個獨立可控工作，窗口起點分布在年初／三分之一／
三分之二／年底：0、14、28、42。
四名 × 四窗 = 16 個額外、完整三月字序精確比較，
其原始日數分別為 342、333、271、325。

提交標記 \`[weaving-triple-neighbor-ranks]\` 才觸發
新工作；每個仍有 185 秒子程序時限、
393216 KiB RSS、16 MiB 私有索引檔大小、
200,000 個記憶式狀態安全界線。
超時為 BLOCKED，數學不符為 FAIL，不准默認 PASS。

即使所有新工作通過，也只驗證真實三月**局部**
名次與已確認的原四月窗口；未驗證完整 45 月 4,244 日
的全年度 BigInt 字典序，也尚未有跨實作 soak。

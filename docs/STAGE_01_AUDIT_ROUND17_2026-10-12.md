# 第一階段第十七輪：真實錨定年份的月份來源與獨立雙月驗證

日期：2026-10-12；僅限 \`Perl+國語\`，不涉及正式曆法 API、Stage 2 或 \`main\`。

## 已有的原生基線

第十六輪 commit \`1eb5d4d2e2c8d4f4ea370a238f30d3a7417155a5\`，
GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38269750837 ，
48 檔／29,656 斷言、\`perl-stage01\` PASS、名稱鎖定 PASS。

## 本輪目的與邊界

早先的 47 月份／252 日效能向量是人工構造的正準有效長度，卻不表示它由實際年份的醬汁與月份選擇器選出。本輪新增獨立、明確標記啟動的 Linux 受控驗證工具 \`tools/profile_canonical_month_selection.pl\`，不啟動整年度反排名。

執行次序：
1. 以 \`FOUNDATION_DAY()\` 為計算日，\`year5000\` 找錨定年份；其已經在基本規範測試中固定為 4,244 日。
2. 以該年的第一日計算 \`sauce\`；透過 \`_choose_month_count\` 和 \`_choose_month_lengths\`，使用**與正式年份結構相同的月份選擇器及印記**取得月數與整份月長陣列。
3. 逐個核對月份長 4..123、數量 3..47、日數合計 4,244，紀錄十進位月長序列 SHA-256 與首尾兩個月長。
4. 針對實際選出的前兩個月及最後兩個月，獨立以組合式 \`C(a+b-2,a-1)\`、規範 \`countWeavings\`、常駐多項式、串流多項式及磁碟索引核對**精確總數**。再以規範指定前綴計數器核對三個引擎對 \`[1]\` 前綴的正確性。
5. 父程序逐次監督子程序實測 RSS／時間；超限輸出 \`BLOCKED\` 並回傳非零退出碼 3，運算錯誤回傳 2。只有完成每項斷言才顯示 \`passed=1\`。

## 受控 GitHub Actions

只有 commit 訊息明確含 \`[weaving-canonical-months]\` 才啟動 \`canonical-month-selection\`。時間與 RSS 預算分別為 180 秒和 393,216 KiB，外層 \`timeout\` 為 235 秒，Job 最多 5 分鐘。這是觀測式 RSS 監督而非硬式記憶體沙箱。原始 Perl 基本測試與名稱鎖定照常運行。

**重要限制：** 首／末雙月精確結果不驗證整個 4,244 日月份交織的排名／反排名，也不構成最高 5,778 日的效能或空間保證。若月份選擇超過預算必須如實列為 BLOCKED。收到原生完整記錄後才能標定 PASS 或分析 BLOCKED。

\`LAST_COMPLETED_STAGE=1\` 不變，不得改動 \`main\`，不得新增或提交 \`HANDOFF_*\` 使用者資料。

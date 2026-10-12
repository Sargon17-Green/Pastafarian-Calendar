# 第 21 輪：前沿式獨立 Oracle 解除真實四月 240 日高 RSS 阻塞

日期：2026-10-12。維持 \`Perl+國語\` Stage 1；不動 \`main\`、正式生產曆法 API、Stage 2 或 \`HANDOFF_*\`。

## 發現與真實 BLOCKED

第 20 輪 native GitHub Actions：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38280176112

在 \`[40,25,77,98]\` 四個真實相鄰月份（240 日）的第一階段，
\`NormativeScroll::countWeavings\` 深度優先完整狀態計數使用的 RSS
於 5.095 秒達 **395,412 KiB**，超出先前的 393,216 KiB 上限。
CI 正確傳回 \`CANONICAL_FOUR status=BLOCKED reason=RSS_LIMIT\`
而不是錯稱為計數失敗或 PASS。上一輪的共享參照安全修正不受此限制影響；
其測試須以完整 \`perl-stage01\` 原生日誌為準。

## 不以增加 RAM 偽裝算法成功

新增只存在於 \`t/lib\` 的
\`Pastafari::WeavingFrontierOracle::countWeavingsFrontier\`：

1. 按每個日位次的合法首次出現／末次出現約束作**正向**狀態轉移。
2. 只保留當前這一層可達狀態，按月份剩餘天數及已首次／已最後出現的最大月份編號合併權重。
3. 最後一種月份首次出現時，獨立以「指定最後一個字元」的多項二項係數公式封閉剩餘後綴；因此不展開大量全開狀態。
4. 只採精確 Math::BigInt；二項係數快取僅本呼叫私有、最多 8,192 項；API 限於 4 月份、每月不超過 255 日，避免作出未驗證的大規模保證。
5. 這個 Oracle 不匯入也不呼叫任何多項式位置矩陣引擎。

新增 \`t/51_frontier_oracle_smallspace.t\`：0..4 月份、月長 1..3 的**完整 121 組**，
分別對照 \`NormativeScroll\` 原始深度優先模型及獨立多項式模型；
另外包括非對稱 4 月份、BigInt 不變性及非法參數。

## 真實 4 月份受控測試之適當核對範圍

\`tools/profile_canonical_four_months.pl\` 改採新前沿 Oracle 計算真實
240 日的精確總數，再對照常駐多項式及串流多項式。

首名與末名的字典序，使用可直接證明的貪婪構造對照多項式解碼器，
毋須載入舊深度優先模型。
中間大整數排名則使用索引式反排名，另外以正向排名還原完全相同 BigInt，
並獨立檢查所有月長及首次／末次順序。
**必須如實區分**：中間名的兩個多項式排名流程仍共享後綴計數核心，
因此不能宣稱已由完全不同的前沿 Oracle 獨立核對中間字典序；
四月份前沿 Oracle 只證明精確總數，而原有小型空間證明仍保留。

保持父程序 **185 秒 / 393,216 KiB** 邊界，發生超限則必須顯示 BLOCKED。
原生 CI 成功後才能宣告新的四月份範圍 PASS。全年度 45 月份
4,244 日和全域 5,778 日仍未得到證明。

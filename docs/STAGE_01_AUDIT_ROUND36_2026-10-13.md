# 第 36 輪：固定真實窗口 41..44 的來源偏移紀錄與選擇器一致性

日期：2026-10-13。僅 \`Perl+國語\` Stage 1，不改 \`main\`、Stage 2、生產曆法 API 或 \`HANDOFF_*\`。

## 原生數值計算已通過

第 35 輪：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38429802521

第 5000 年原生月長 SHA-256 已通過，零起始
\`@year[41..44]\` 是 \`[77,98,122,105]\`，共 402 日；
\`CANONICAL_WINDOW41_CHECK_COMPLETE passed=1 blocked=0 failed=0\`。
前沿 \`countWeavingsFrontier\` 計數 911,419 狀態、最大 6,793
同日狀態；精確總數 234 位，與另外兩種不同多項式 DP 一致。
第一名及最後一名對照直接構造、中間 233 位一基 BigInt
索引反排名與正向排名完全還原成功。
時間 165.952 秒、VmHWM 44,608 KiB。

## 非數學性的紀錄錯誤

程式由 window40 改寫時，原生日誌首行輸出
\`CANONICAL_WINDOW41 phase=INPUT offset=40\`，
雖然**實際索引是 41..44**。這是 metadata／diagnostics 的錯誤，
不影響上述精確結果，卻會混淆證據核查。

本輪將窗口起點統一為單一 \`$window_offset=41\`，
同一變數同時決定陣列切片和日誌 \`offset=%d\`，消除兩處維護漂移。
首行同時由實際切片動態取得日數及月長，不再在日誌中硬編碼。

再次執行原生 CI 的 opt-in \`[weaving-canonical-window41]\`，
其餘 185 秒、393,216 KiB RSS、單檔 16 MiB、上層 260 秒界線
保持不變。原生工作未結束前不可宣稱此輪額外的重跑已 PASS。
此仍僅是四月 402 日局部計數，不是 45 月／4,244 日年度排名證明。

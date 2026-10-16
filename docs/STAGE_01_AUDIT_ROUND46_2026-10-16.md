# 第 46 輪：真實四月 236 日的第二日獨立 BigInt 分割

日期：2026-10-16，工作分支 \`Perl+國語\`，**只在 Stage 1**，
不得修改 \`main\`、正式曆法實作、Stage 2 或任何 \`HANDOFF_*\`。

## 前一輪完整 CI 基線

第 45 輪原生 GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38894667182

分散四月窗口 10（328 日、187 位 BigInt）、28（321 日、178 位）、
36（312 日、175 位），各自的獨立正向前沿精確總數、
常駐與磁碟串流多項式、首末字序直接構造、索引中名正反還原
都已 PASS。一般 Perl 全套與名字鎖驗證也 PASS。

**但**上述中位排名的 328、321、312 日並未有獨立
Oracle 逐日核對所有 BigInt 字典序決策；正反排名往返
共用相近的多項式後綴技術，不能作為完整獨立證明。

## 新的窗口與保守驗證

以 Year 5000 已確認 45 月份 / 4244 日 SHA-256 原始向量，
選取零起始第 \`37..40\` 月份：
**[83,88,40,25]**，恰為 **236 日**。
此窗口不是先前的 230、240、322、402 日相鄰四月實驗。

延伸既有受控 \`tools/profile_canonical_window41_count.pl\`：
- \`--window-offset 37\` 必須驗證真實固定月長；
- 不更動原來 \`--window-offset 41\` 預設，保留所有其他已確認窗口；
- 使用三個獨立或不同的精確 BigInt 總數模型：
  \`countWeavingsFrontier\`、\`countWeavingsPolynomial\`、
  \`countWeavingsPolynomialStream\`；
- 僅在 \`--second-day-partition\` 明確提出且
  \`window-offset=37\` 時，額外使用**另一輪完整獨立前沿**
  精確計算前綴 [1,1] 和 [1,2] 的全部合法完工詞，
  要求兩個正數的和等於完整總數；
- 由完整總數的中間一基 BigInt 名次，獨立以兩個區段
  得出第二天為月 1 或月 2，再和索引反排名的第二個
  字元比較。輸入月份與月份順序也須通過現存驗證；
- 首名／末名的非 DP 直接構造和索引反排名完全一致，
  中間名需索引式雙向排名完全往返，BigInt 不污染。

\`t/56_canonical_embedded_snapshot_integrity.t\` 增加
固定真實窗口 37 的直接斷言；\`t/61_quad_distributed_coverage.t\`
同步加入允許的真實窗口 37，保留先前三個昂貴 job。
另增 \`t/62_quad_day_two_partition_ci_contract.t\`
檢查 opt-in、兩個前綴、對照及安全界線，避免未執行檢查卻報 PASS。

新 CI \`canonical-window37-prefix\` 只由
\`[weaving-window37-prefix]\` 提交標記啟動，
單個子程序保留 185 秒、393216 KiB RSS 硬限制，
外層 260 秒，單檔索引最多 16 MiB；
超時是 BLOCKED，計數不同是 FAIL。

**邊界：**只有 236 日總數、首末字序直接比對、
中間名雙向回轉與**第二日**獨立前綴分割受到本輪驗證；
剩餘第 3..236 日並無整條路徑的獨立逐位 Oracle。
這也不是整年 45 月／4244 日的全域排名證明，
更不是跨實作 soak。

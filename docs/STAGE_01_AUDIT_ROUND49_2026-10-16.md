# 第 49 輪：236 日真實四月份第四日 BigInt 分片

日期 2026-10-16，限定 Perl+國語 Stage 1。不可變更
main、正式曆法、Stage 2、HANDOFF 或其它語言。

第 48 輪 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38898694956
在固定四月窗口 [83,88,40,25] 上，分拆後的四份
正向合法狀態前沿及一份精確 BigInt 彙總均 PASS：
[1,2]、[1,2,1]、[1,2,2]、[1,2,3] 均各自驗證獨立
前沿和因子式後綴完全相同，後三者和等於第一者；
中間全局一基排名的前三天為 [1,2,1]。
前一次第 47 輪原始 185.013 秒 TIME_LIMIT BLOCKED
仍為歷史事實，不得改標成 PASS。
第 48 輪全套 Perl / verify 結果須從原生 CI 另行確認。

本輪以相同的不可變 Year 5000 45 月份/4244 日 SHA
和 236 日四月窗口繼續核對 **第四天**：
- 父前綴 [1,2,1]；
- 三個合法下一候選 [1,2,1,1]、[1,2,1,2]、
  [1,2,1,3]（第四個月尚未首次出現，故標籤 4 非法）。

五個明確 opt-in GitHub 工作各有獨立有界子程序：
parent、1、2、3 各把前綴的獨立 \`countWeavingsFrontier\`
BigInt 與 \`countWeavingSuffixFactored\` 逐項核對；
assembly 用後一個已由前四份獨立前沿對照的精確模型
把三候選完工數相加，必須等於父前綴，並由中位 BigInt
減去較小第二日區段、驗證第三日確為 1，再依字序扣除
較小第四日候選並和索引反排名第四個字元完全相符。

新增 \`--fourth-day-target parent|1|2|3|assembly\`，
只允許窗口索引 37 並且和第二、第三日昂貴 opt-in
互斥。額外 \`t/65_quad_fourth_split_ci_contract.t\`
核對五個 job 不重不漏、原有資源限制和逐字合約。
標記 \`[weaving-window37-fourth-split]\` 啟動。

各進程 185 秒、RSS 393216 KiB，外層 260 秒，
磁碟私有索引文件上限 16 MiB，沒有放寬任何限制。
五份、有界原生 Perl CI、verify 均 PASS 才可稱完成。
這只證明 236 日中間排名的前四天，不是剩下 232 天、
全年度 45 月 / 4244 日或跨實作 Soak。

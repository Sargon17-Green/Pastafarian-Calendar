# 第 50 輪：真實 236 日四月份中間排名第五日的三分支 BigInt 獨立驗證

日期：2026-10-16；僅 Perl+國語 Stage 1。
不得改 main、正式曆法算法、Stage 2、其它語言或 HANDOFF。

第 49 輪原生 CI：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38899788585
五份獨立前沿與精確 BigInt 彙總均 PASS，全部 Perl 66 檔、
88,377 斷言 PASS；母前綴 [1,2,1]，第四日中位排名
選擇 2，故真正全局中位 BigInt 順序的已核對
前四個符號是 [1,2,1,2]。每份受控工作執行
185 秒、393216 KiB RSS 上限、外層 260 秒。

本輪核對第五日：[1,2,1,2] 後的合法子標籤僅為
1、2、3，第四種月份尚未首次出現，不可直接選 4。
保留前幾輪的代數、完整年份 45 月 / 4244 日固定 SHA、
獨立正向前沿總數與常駐／串流位置多項式比較。

五份新 opt-in 工作只在
[weaving-window37-fifth-split] 標記出現時執行：
- parent：[1,2,1,2] 正向獨立合法狀態前沿精確數；
- 1：[1,2,1,2,1] 前沿；
- 2：[1,2,1,2,2] 前沿；
- 3：[1,2,1,2,3] 前沿。
每份前沿數與另一種 countWeavingSuffixFactored
精確 BigInt 前綴後綴結果逐項比較；都不是依靠受測
反排名器的內部私有 DP 自我報告。

- assembly：先由全球中位一基排名扣除第二日較小
前綴 [1,1] 的 BigInt 完工數，再依已證實第三日 1、
第四日 2 扣除較小第四日 1 的前綴區段；
嚴格要求該局部 BigInt 在 [1,2,1,2] 的範圍內。
之後三個合法第五日候選的精確 BigInt 和必須
等於父前綴，字典序選擇必須與磁碟索引式
unrankWeavingPolynomial 的第五個符號完全一致。
五份工作中有任一失敗／被取消／BLOCKED，
不可把第 50 輪標示 PASS。

新參數 --fifth-day-target 只允許
parent、1、2、3、assembly，且只在 offset 37
和其它昂貴 opt-in 模式互斥下使用。
新增 t/66_quad_fifth_split_ci_contract.t，核對五份
工作、唯一性、精確分支和式、第五日字序及原有
185 秒、393216 KiB RSS、單檔 16 MiB、五分鐘
GitHub 最高限額。歷史工作和 BLOCKED 日誌保留。

此處只獨立核對中位 236 日的前五個符號，並非
剩下 231 日或全年 45 月 / 4244 日的字序證明。
跨實作 soak 尚未執行。

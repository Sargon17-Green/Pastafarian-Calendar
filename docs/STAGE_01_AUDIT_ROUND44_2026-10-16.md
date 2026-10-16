# 第 44 輪：全部 43 組真實三月份局部 BigInt 補充名次
日期：2026-10-16；僅 Perl+國語 Stage 1，未更改正式算法、main 或 Stage 2。

第 41 輪 11 個 job 全 PASS：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38586882997。全部 43 個相鄰三月份、首中末各一條全長字典序核對成功。
第 42 輪原生 Perl 60 檔、88,179 斷言 PASS：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38589988538。
第 43 輪四個抽樣視窗 0、14、28、42 的第二、上下四分位、倒數第二名獨立核對皆 PASS：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38890574993；該輪全套 Perl CI 需另查明。

新增 11 個受控 opt-in GitHub 工作，只在 commit message 含 [weaving-all-triple-neighbor-ranks] 時執行。每批順序執行最多四個窗口，起點依次為 0、4、8、12、16、20、24、28、32、36、40，合計恰好覆蓋 0..42。每窗口依同一經已驗證的獨立記憶式 Oracle，對四種 BigInt 排名（2、floor(N/4)、floor(3N/4)、N-1）完整逐日計算全部合法下一月份的精確完工數，確認分支和、局部字典序和索引反排名逐位一致，並檢查最終月長與正向排名還原。

每個窗口的時間為最多 185 秒、RSS 不超過 393216 KiB；每個工作最多 15 分鐘。任何窗口失敗均使整批失敗，不得將受控 BLOCKED 當作 PASS。
新增 t/60_triple_neighbor_ci_coverage.t 驗證 11 批工作對所有 43 個起點各覆蓋一次、條件與每窗口上限。

待 11 組原生測試、verify 和 Perl 全量 CI 全部通過，才能聲稱第 44 輪 PASS。即使全數通過，也不是整年度 45 個月份／4244 日的全域排名證明，亦不是跨實作 soak。

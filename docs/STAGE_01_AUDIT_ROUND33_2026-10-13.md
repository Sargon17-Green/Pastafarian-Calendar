# 第 33 輪：將 322 日十四個排名分為兩個有界原生工作，保留所有驗證

日期：2026-10-13，工作分支 \`Perl+國語\`，僅 Stage 1。不修改 \`main\`、正式曆法 API、Stage 2 或 \`HANDOFF_*\`。

## 實際的 BLOCKED 與其他結果

第 32 輪 GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38376235244

- 一般第一階段測試 **56 檔、87,955 斷言，PASS**。
- 真實 230 日（38..41）及 240 日（39..42）視窗各十四個完整排名的獨立前綴稽核全數 PASS。
- 新增的 322 日（40..43；[25,77,98,122]）十四排名工作：
  前十三個完成全部 322 天的獨立 BigInt 分支稽核，均 PASS，
  第十四個 \`last=N\` 尚未結束時觸及固定 185 秒時限。
  原生日誌顯示
  \`CANONICAL_MULTI_RANK status=BLOCKED reason=TIME_LIMIT elapsed_sec=185.013\`，
  \`observed_peak_RSS_KiB=207956\`。這是**計算資源超時**，
  並非第十四排名的數學反例，不能標記整個十四排名為 PASS。

## 無損分片

\`tools/profile_canonical_memo_multi_ranks.pl\` 明確新增兩種過濾方式
\`--case-filter first-half\` 和 \`--case-filter last-half\`，
並在程式內核對固定的七種標籤順序，完整涵蓋原來十四種且不重複：

- 前半：first、second、third、fourth、p10、p25、pre_middle。
- 後半：middle、p75、p90、near_last3、near_last2、near_last1、last。

改用 GitHub Actions 兩個**獨立受控子工作**執行；
每個子工作均保持原有 185 秒、393,216 KiB RSS、
記憶體 200,000 個私有狀態和外層 260 秒硬時限。
不跳過原有單一排名的任何一日或任一分支數的和式檢查。
原有 \`all\`、\`middle\` 模式保留，先前 230／240 日
十四排名工作仍完整使用 \`all\`。

每個子工作獨立運行相同的年度月長 SHA-256 檢查、
獨立精確計數 Oracle、索引反排名、正向排名及
所有月長歸零／局部排名返回一之判斷。

兩個作業**都**輸出 \`CANONICAL_MULTI_RANK_CHECK_COMPLETE passed=1 blocked=0 failed=0\`
且整套 Perl 與 verify 原生 CI 通過後，才可聲稱
322 日視窗共十四個排名、4,508 次全部字典序選擇 PASS。
三個視窗重疊的 11,088 次局部選擇仍不是全部
45 月／4,244 日全年度的獨立排名驗證。

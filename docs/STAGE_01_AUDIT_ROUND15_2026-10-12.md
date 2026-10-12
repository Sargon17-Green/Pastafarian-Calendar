# 第一階段第十五輪：直方圖回呼與保留輸出的可變性所有權

日期：2026-10-12；分支：`Perl+國語`。僅限 Stage 1 參考運算器及回歸稽核。未更改正式曆法入口、`main`、自然語言目錄或 Stage 2。

## 觀察到的別名風險

在前一版 `Pastafari::WeavingPolynomialStream`，要求 `first_histories` 陣列與逐階段 `histogram_sink` 回呼的雙輸出時，兩者曾指向同一個階段 ARRAY 及內部 Math::BigInt 物件。

因此回呼雖然只是一次外部觀察者，但若修改收到的 BigInt（`badd`、`bsub` 等）或在陣列後面新增元素，可能悄悄污染另一份看似獨立的輸出，破壞後續使用者根據第一份直方圖完成排名稽核的可重入性及值所有權。這不是目前數學轉移等式錯誤，而是介面暴露的可變參照風險。

## 修正

新增私有 `_histogram_sink_snapshot`，只就正準備交付的目前階段複製 ARRAY 及每個已定義 Math::BigInt。空分布、第一個月份、之後所有月份的 callback 都使用自己的快照。呼叫方原本請求的 `first_histories` 繼續得到未遭修改的準確分布；單獨 sink 模式與返回全域 BigInt 計數不改變。

每次回呼額外複製當前階段的 BigInt，故單階段的額外暫態物件數 O(N)。核心仍不強制在 RAM 保存所有月份階段分布。索引磁碟引擎的接收器仍會將自己的快照序列化，暫存檔的持有生命週期不變。

## 回歸驗證

新增 `t/46_stream_sink_ownership.t`：

- 在一個呼叫中同時索取保留的階段直方圖和 sink，故意改寫每階段第一個 BigInt、追加一個陣列元素，再**事後**再次改寫已交付的物件。逐一核對傳統記憶體模型的每個原始值完全保持不變。
- 核對 callback 的 ARRAY 及 BigInt 參照都不與被保留的輸出共用，且每個階段依然只回呼一次。
- 不傳 `first_histories`、只傳會改寫資料的 sink 時，完整精確計數仍不得變動。
- 在第二個月份階段強制讓 callback 擲出指定例外，要求原始例外傳出，並在私人 TMPDIR 檢查全部臨時列檔當場清除而非留到 Perl 程序結束。

基礎測試起點為先前原生 CI：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38258524953，29,249 assertions / 46 files PASS。初次原生驗證：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38264700942，前 46 檔 29,252 斷言通過，但新增測試因輔助函數命名為 Perl 內建 `values` 而無法編譯。其後修正提交 `b4e120aec679b39690e4539ea23a11dac7bfbb09` 改名為 `histogram_as_strings`，未刪改任何語義斷言；完整回歸以此次 GitHub Actions 最終日誌為準。

## 仍未解決的限制

這個修正僅對接收器單次交付的可變性進行防護，不等於最高 5,778 日的時間、磁碟與 BigInt 位元組資源保證，也不證明測試所採用的 252 日月份分布一定源自實際規範年生成器。外部回呼仍能自行保留每階段快照，造成呼叫者選擇性的總 RAM 增長。

`LAST_COMPLETED_STAGE=1` 保持不變。Stage 2 未開始，`main` 未修改，不提交任何 HANDOFF_* 使用者資料。


## 避免相同的測試檔編譯失敗延誤整套回歸

在本輪完整原生跑測試時，早先的 `t/46` 因測試輔助函數恰巧命名為 Perl 內建 `values` 而編譯失敗。過去 CI 語法階段只預編譯 `lib` 與 `t/lib` 裏面的模組，沒有涵蓋頂層 `t/*.t`，使錯誤直到執行完大量較早測試才被發現。

因此擴充現有 `檢查生產及參考模組的語法` 步驟，在實際執行測試前按固定排序，逐一使用 Perl 5.40 原生 `perl -Ilib -It/lib -c` 檢查所有頂層 `t/*.t`。對純測試腳本只是增加前置的編譯驗證，原本 `prove` 全量驗證不變。即使發生語法錯誤，也仍須清楚將原生工作標記為 FAIL，不能藉由跳過測試假裝 PASS。

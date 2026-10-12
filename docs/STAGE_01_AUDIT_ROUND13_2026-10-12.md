# 第 1 階段第十三輪：可選串流式反序直方圖、跨引擎快取隔離及字典序雙向驗證

日期：2026-10-12；工作分支：`Perl+國語`。僅更新 Stage 1 參考模型與原生測試，不改動 `main`、正式生產曆法入口或 Stage 2。

## 選項契約

`Pastafari::WeavingSuffixFactor::countWeavingSuffixFactored` 的第 5 個參數可選用一個雜湊參照：

- `profile_engine => 'resident'`：預設；使用經驗證的完整記憶體二維分布模型。
- `profile_engine => 'stream'`：逐列輸出及讀取二進位臨時檔，以有限 RAM 重新建立後綴反序首次出現位置直方圖。
- 僅在 stream 模式可設定 `max_temp_file_bytes`；此為每個暫存檔而非整體預算。預設 128 MiB，上限 1 GiB。

未知欄位、未知引擎、無效預算及 resident 模式多餘的磁碟預算都必須在開始後綴計算之前明確拒絕。可選引擎不會改變字典序、Math::BigInt 整數值、原始輸入或任何規範日期選擇結果。

## 快取擁有權及配額隔離

所有後綴計數與直方圖的快取鍵都包含原始每月長度、引擎名稱和有效暫存檔容量預算。因此即使呼叫者重用同一個 HASH，已用較寬預算算出的結果也不會讓較小預算略過需要實際執行的磁碟操作。計算成功後才將完整直方圖寫入共享快取，任何例外或容量溢出均不能留下部分結果。快取仍由每次排名／反排名呼叫獨立擁有。

`t/39_stream_profile_factor.t` 在不同模式、同一及不同配額、跨引擎共享 HASH 的條件下對照原始 `WeavingSuffix` 精確後綴；加入 47 月份及 252 日案例、超限拒絕、BigInt 輸入不變性。

## 不改動預設解碼器的可選啟用

`unrankWeavingPolynomial($lengths,$rank,$stats,$options)` 和 `rankWeavingPolynomial($lengths,$word,$stats,$options)` 的第四個可選參數傳入相同引擎契約，未指定時沿用完整記憶體引擎。即使第一名、最後名不需做後綴計數，也預先驗證選項，避免高速捷徑接受錯誤的資料。統計可以記錄串流直方圖建立次數、寫入列數、單檔觀測位元組數。

`t/40_stream_rank_roundtrip.t` 對照原本反排名及完全獨立控制流程的規範 Oracle，並使用新的正向排名器重建相同的一基 BigInt 排名；包括中間排名、邊界排名及 47×4 月份的非極端 188 日雙向往返。不得將二者共同使用的後綴計數核心冒充完全獨立的數學真值模型。

## 原生驗證與資源限制

- 後綴引擎提交 `f96ddd5c75e2ad1f485b35445ef9ae8a7b647170`：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38241799626 ，25,193 斷言／40 檔 PASS；包括 `t/39_stream_profile_factor.t`，無失敗斷言。
- 反排名／正向排名選項 commit / CI：必須另行通過完整 Perl 5.40 原生套件，並確認所有 40 個測試檔；不得只依 syntax OK 宣稱完成。
- 延伸到 47 月份／252 日的雙向排名及最高 5,778 日還需要明確、受控的資源上限。新模型的流式核心只對當前列使用線性數量的 BigInt；若仍要求保存全部月份階段邊際直方圖，直方圖本身仍隨月份及日數成長，不能保證整體為 O(N) 位元組。
- 暫存檔在正常回收及可捕捉例外時由 File::Temp 自動移除；SIGKILL 不保證執行解構，因此重型測量應維持隔離 runner 的臨時目錄和明確監測。
- `LAST_COMPLETED_STAGE=1` 不變。沒有進入 Stage 2、修改 main 或提交 HANDOFF_* 使用者材料。

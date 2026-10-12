# 第一階段第十四輪：逐階段位置分布交付與磁碟索引化

日期：2026-10-12。僅 `Perl+國語` 分支之 Stage 1 參考計算；不動正式 API、`main` 及 Stage 2。

## 問題與範圍

第十二、十三輪使多項式二維狀態矩陣可以在磁碟上逐列暫存，且已用 47 個月／252 日驗證完整雙向 BigInt 排名。然而 `countWeavingsPolynomialStream` 在用於一般反排名時仍將**全部階段**的首次出現位置直方圖放在 RAM。總儲存的 BigInt 物件數約 O(Σ_k N_k)，對 47 月份、5778 日可能遠超單一階段 O(N) 的物件數。

## 第一步：流式接收器

`t/lib/Pastafari/WeavingPolynomialStream.pm` 引入可選第五參數 `$histogram_sink`，必須是 CODE 參照。每當建立完成某個月份階段的精確 BigInt 首次位置直方圖，即回呼 `($stage,@histogram)`。呼叫者可選擇不傳入原先的 `$first_histories`，此時模組不再保存所有階段陣列。沒有回呼時原 API 及數學結果不變。

單一月份的階段 1、雙重輸出、空月份分布、失敗回呼及非法回呼型別均需要測試。`t/41_stream_histogram_callback.t` 對照記憶體模型的每個位置數值；一個回呼例外須直接傳出，不能被當作正常完成。

## 第二步：磁碟索引物件

`t/lib/Pastafari/WeavingProfileDisk.pm` 的 `buildWeavingProfileDisk` 呼叫上述接收器，逐階段以 Storable 寫入一個 `File::Temp` 二進位檔，只在小型索引陣列保留每個階段的檔案位移。任意查詢 `histogram($stage)` 透過 `seek` 與 `fd_retrieve` 讀取所需階段；只在 RAM 保留最近讀入的一份完整直方圖，所有對外回傳的 Math::BigInt 都深複製，避免外部改動污染後續讀取。

限制：索引暫存檔預設最多 128 MiB，每次建構內部矩陣暫存檔也各自受到同樣的每檔限制；不提供整個程序的嚴格磁碟容量上限。正常清理和可捕捉的例外依 `File::Temp(UNLINK=>1)` 回收檔案；SIGKILL 仍無法保證執行 Perl 清理。儲存與讀回各完整階段直方圖對吞吐量有成本；不聲稱它一定比把直方圖放在 RAM 更快。

`t/42_indexed_histogram_store.t` 測試九組月長，含 47×4 與 17×6＋30×5，任意順序階段查詢、緊鄰階段快取、深複製、精確總數、索引及磁碟預算不足、無效階段拒絕。

## 後續集成策略

待兩步的原生 Perl CI 均完成 PASS 後，才能新增明確選項 `profile_engine => 'stream-indexed'` 供 `WeavingSuffixFactor` 讀取磁碟索引。必須將該引擎和有效容量預算納入共用快取命名空間，並在每次反排名呼叫內獨立持有 File::Temp 物件，避免一個呼叫關閉暫存檔後另一個仍試圖使用。預設 resident、現有 stream 的正確性和延伸資源稽核均須維持不變。

請在收到原生完整結果後，把 PASS/FAIL、斷言數、commit、CI 連結補入紀錄，並以實際量測判定是否要擴大到近 5778 日的受控試驗。這一輪並不宣稱最高年長度完成驗證。

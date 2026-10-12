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

## 第三步：可選 `stream-indexed` 引擎（需通過原生回歸）

將選項 `profile_engine => 'stream-indexed'` 加入 `WeavingSuffixFactor`、`WeavingUnrank` 與 `WeavingRank` 的 Stage 1 參考程式。此引擎在首次需要未開啟月份的反序位置分布時建立一次 `WeavingProfileDisk`，之後以相同私有快取持有暫存物件，按剩餘月份階段透過索引檔讀取單一 BigInt 直方圖。

與現有 `resident`、`stream` 模式的快取鍵完全隔離，還包含有效磁碟容量上限，以免不同引擎或不同預算間發生錯誤重用。新引擎對外回傳 BigInt 深複製，不允許直接修改索引中的值。完成整個排名／反排名後，私有快取與它擁有的 File::Temp 物件一同釋放。預設仍是 `resident`，舊串流引擎 `stream` 不變。

`t/43_indexed_suffix_and_rank.t` 測試 47 個月份兩組長度、原始規範後綴計數、共享 HASH 中三種引擎的隔離、小額／大額磁碟配額，以及小空間完整字典序雙向排名。另須在原生 CI 完成之後，才能宣稱此新引擎的語義驗證成功。

注意：索引後綴減少的是所有階段 BigInt 直方圖常駐記憶體，並未限制未開啟月份因子快取、單一 BigInt 位元數、總可用磁碟空間及計算時間。尚未測試 5,778 日上限。正式標記 Stage 1 已完成的狀態不因本研究而改變。


## 原生 47 月份／252 日索引式雙向檢驗與暫存生命週期

提交 `60fb073aae2824a0746eb74b5c9dcde25e2a58a8` 新增獨立工作 `indexed-roundtrip252` 與 `t/44_indexed_lifecycle.t`。受控原生結果：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38255896465 。

索引式全量雙向計算 **PASS**：47 月份、252 日，270 位中間一基排名的解碼與重新排名精確一致。解碼 38.133 秒，往返總計 67.161 秒，VmHWM 24,236 KiB。解碼與正向排名分別只建構一次直方圖索引，各索引佔 1,016,431 位元組；解碼查詢索引 46 次、單階段快取命中 85 次，反向排名查詢 46 次、命中 76 次。未出現資源封頂。

新的暫存生命週期測試檢查 File::Temp 索引在持有物件期間存在、物件最後參照解除後刪除、共享快取確實延長索引生命週期但不污染返回的 BigInt、以及低磁碟預算拒絕部分結果。

**BLOCKED 控制流程補強：** 先前工具在偵測時間或監看 RSS 超限時雖明確輸出 BLOCKED，卻曾以成功退出碼結束。後續修正使 BLOCKED 以專用非零退出碼 3 結束，故 GitHub Actions 不能再把資源未完成誤標為整個實驗成功。新增 `t/45_indexed_runner_blocked.t` 在 Linux 上以真實 1 秒時間限制執行工具，要求 BLOCKED 與非零退出碼。任何未完成都不能用於宣稱數學結果已驗證。

本輪仍沒有證明 5,778 日規範上界的實用資源界線，也尚未驗證這個 252 日月份分布一定由規範年選擇器產生。保持 `LAST_COMPLETED_STAGE=1`，不進入 Stage 2，不動 `main`。

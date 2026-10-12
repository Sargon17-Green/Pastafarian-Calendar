# 第一階段第十一輪：未開啟月份的可重用精確因子及反序直方圖

日期：2026-10-12。僅限 `Perl+國語` 分支之 Stage 1 原生規範稽核。沒有更動 `main` 或生產曆法入口，也沒有開始 Stage 2。

## 原始瓶頸

對任一非首名、非末名的字典序排名，`WeavingUnrank` 過去會在每個新前綴重新計算全部後續月份的二維位置分布。兩組 47 月份中間排名在每個案例 20 秒、RSS 觀測上限 196,608 KiB 的試驗中皆被 TIME_LIMIT 阻擋；不能報稱已成功反排名。見 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38223128775 。

## 精確分解定理

對合法已選前綴 P，令 p=已首次出現月份數，c=依次已完成月份數。剩下兩類：A=已首次出現但尚未結束之 c+1..p 月份，剩餘總日數 T；B=尚未首次出現之 p+1..m 月份，總日數 U。

在 A 的任意合法序列中，最末一日屬於月份 p。A 的內部只需遵守各月份末次出現的先後次序，其合法數量 F_A 是精確的二項式乘積。B 的序列同時遵守首次及末次出現順序。合併 A、B 時，僅須保證 A 最末一日在 B 第 1 個月份的末次出現之前；這與 A 的其餘內部排列無關。

若 B 第 1 月的末次位置為 z，將 T 個有序 A 日插入 B 並令全部 A 日位於該個 B 符號之前，恰有 C(T+z−1,T) 種交織。故：

`F(P)=F_A × Σ_z h_B[z] × C(T+z−1,T)`

其中 h_B[z] 是合法 B 序列中第 1 月最後一次出現於 z 的個數。這個權重分布不依賴 A 的內部剩餘向量，只取決於尚未開啟的月份長度。

## 反轉雙序關係與一次建表

將合法 B 序列同時反轉日次及月份標籤（j↦q+1−j），得到月份長度反序的另一合法 B 序列；原第 1 月的最後位置 z 對應反序最後一月的首次位置 u，且 z=U+1−u。把反序月份逐次插入已有的 `WeavingPolynomial` 二維 D[u,v] 時，每個階段求 Σ_v D[u,v]，便在同一輪多項式計數中收集所有未開啟月份子序列所需的精確 h[u]。

因此建表只需一次全域反序多項式 DP（按算術運算計為 O(m N²)，實際 BigInt 位元成本另計），每次不同 (p,T) 的後綴因子以一維精確二項式加權和取得。已開啟月份的 F_A 仍用獨立、精確二項式乘積；完全不需要重建二維 DP。

同一 `unrankWeavingPolynomial` 呼叫擁有私有快取。鍵含全部原始月份長度、p、T；所有 BigInt 均複製後存取，避免跨日期及跨呼叫可變狀態污染。對 47 個月、最多 5,778 日的資源可行性仍須另行測試，不得僅憑算術次數的多項式界線宣告已完成。

## 原生證據

| 提交與 GitHub Actions | 結果 |
| --- | --- |
| `d907da3a2b7732adab2a2dd0837db2c5fc26731f` — https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38227263253 | 13,370 斷言／34 檔 PASS；首次分解與規範後綴模型一致 |
| `0e6aa1368db43c8e37245e60f57e77f93059f4d8` — https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38227870660 | 13,515 斷言／35 檔 PASS；真正字典序反排名也與原始 Oracle 一致 |
| `59a066615af2894871e9ce3219533574c7e1d375` — https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228345282 | 13,647 斷言／36 檔 PASS；反序直方圖與獨立枚舉、47 月份及快取重用測試通過 |

## 相同預算的中間排名量測

工具 `tools/profile_unrank_middle.pl` 各案獨立 fork 子程序，每例最多 20 秒、監看 RSS 196,608 KiB；測量程式在監控之上另檢查精確月份日數與首次末次次序。`BLOCKED` 代表未完成，不是成功。提交 `926061a4d3f67a83c4dababfd4f31612d5b29e12` 的原生執行：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228970766。

量測的成敗、用時和快取統計須以該執行的最終原生日誌為準。絕不能將尚在執行中的 47 月份案例算作 PASS。記錄 `suffix_calls`、`future_hits`、`future_misses`、`reverse_profile_builds`，以及各案是否含原始規範 Oracle 全量字典序對照。

## 契約與後續問題

- 新實作只放在 `t/lib/Pastafari/`；生產中的 Stage 2 日曆計算仍未開始，`LAST_COMPLETED_STAGE=1` 保持不變。
- 大型反排名還需要證實資源上界；反序直方圖建表一次的 BigInt 記憶體與時間，在最大 5,778 日案例可能仍相當高。
- 應比較分別使用原本後綴 DP、(p,T) 因子快取、反序直方圖的同種負載，並在解碼完成後使用獨立排序與月份計數檢查；不可只依資源數據判定語義正確。
- 若往後需減少每一候選重複驗證整個前綴，可引入明確只供內部使用的狀態介面，但仍應以公開前綴輸入路徑作語義驗證。
- `main` 未修改，`HANDOFF_*` 使用者專用材料沒有提交。

## 未重新解析整段前綴的內部計數介面

提交 `a15ecd76fdcae3a0e33b1878d8d703d01de926b5` 引入 `_countWeavingSuffixFactoredState`。字典序反排名器本來就持有原始合法月份長度、當前剩餘向量及 `opened/closed`，因此嘗試下一月份 j 時，只需暫時扣除該月一日、計算因式分解，再立即恢復該日。候選真正接受時才更新解碼器狀態。無須每個候選重新從頭解析整段前綴、重新為每個標籤建立 Math::BigInt 或重新驗證已驗證的首次／末次次序。

完整公開輸入介面 `countWeavingSuffixFactored` 保留所有長度、標籤、次序與 BigInt 驗證。內部狀態方法以底線開頭、不對外匯出，並以 `t/36_factored_state_interface.t` 從規範 Oracle 選取合法序列的每個中間狀態，與完整前綴輸入路徑逐一比對，且驗證沒有修改傳入的剩餘向量。

此次原生 CI 與包含 47 月份的受控中間排名效能重測為 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38230050324 。其最終 PASS/BLOCKED 狀態必須按照真實原生日誌判定；所使用的上限仍為每案 20 秒、RSS 觀測 196,608 KiB。

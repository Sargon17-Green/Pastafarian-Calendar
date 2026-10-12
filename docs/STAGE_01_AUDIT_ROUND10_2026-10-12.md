# 第 1 階段第十輪：局部字典序尾段捷徑、47 月份中間排名與全開啟閉式

日期：2026-10-12。僅在 `Perl+國語` 分支的 Stage 1 測試專用規範參考中進行；`main`、生產曆法入口與 Stage 2 不變。

## 一、局部區塊尾段捷徑

字典序反排名的任一中間步驟有剩餘排名 r 與目前子樹完工數 T。若 r=1，餘下每次選最小的合法月份；若 r=T，餘下每次選最大的合法月份。這是相對於當前已接受前綴的局部排名，即使原始全域排名不是第一或最後也適用。
所有合法局部轉移均可完成：依序結束已開啟的月份，然後依序開啟和結束尚未開啟的月份。這保證貪婪選擇所取的下一個子樹非空。
實作位於 `t/lib/Pastafari/WeavingUnrank.pm`；`t/30_unrank_local_tail_shortcut.t` 對照原有規範字典序。提交 `1bffc5e0b92a8a718815ea72a96f0d569e29d929`：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38221524075，11,797 個斷言／31 檔 PASS。

## 二、原生中間排名資源量測

加入只在提交訊息含 `[weaving-unrank-middle]` 時執行的 `tools/profile_unrank_middle.pl`，各案例獨立 fork 子程序、監看 VmRSS，每例 20 秒或 196,608 KiB 即中止。BLOCKED 是未完成，不等於 PASS；RSS 週期性觀測不是硬性核心記憶體限額。
原生執行：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222091425，測試 11,800 個斷言／31 檔 PASS，另有以下診斷：

| 月份分布 | 結果 | 計算秒數或觀察時間 | 所觀察程序記憶體 |
| --- | --- | ---: | ---: |
| 4×4 | PASS | 0.045 秒 | 14,648 KiB (VmHWM) |
| 6×4 | PASS | 0.247 秒 | 16,788 KiB (VmHWM) |
| 8×4 | PASS | 0.556 秒 | 14,152 KiB (VmHWM) |
| 47×4（188 日） | BLOCKED：20 秒 | 20.018 秒 | 18,088 KiB (週期性 VmRSS) |
| 17×6＋30×5（252 日） | BLOCKED：20 秒 | 20.022 秒 | 21,780 KiB (週期性 VmRSS) |

上述最後兩例未完成字典序反排名，不能從其資源數據推斷最終記憶體用量；只證明在該次執行的 20 秒預算內未完成。188 日不達年度最短長度，而 252 日的月份分布是否真實由規範年份選擇器產生尚未證實。

## 三、全數月份已開啟的精確閉式計數

設已依規範次序關閉 c 個月份，所有 m 個月份均已首次出現，未關閉月份 c+1..m 的剩餘日數為 r_i>0。令 S_j = Σ(i=c+1..j) r_i。

`F = Π(j=c+2..m) C(S_j-1, r_j-1)`。

證明：最後一個月份 j 的末次出現必位於其子序列末尾，其他 r_j-1 次可從前 S_j-1 個位置中選擇。刪去該月份後，對 j-1 重複。結果是精確整數，不必建立舊有一維 E[v] 尾次位置分布。
提交 `8e59688e666102f7a2771b08b3cd4b64f95cc198` 在 `t/lib/Pastafari/WeavingSuffix.pm` 建立此新路徑。獨立稽核 `t/31_full_open_suffix_closed_form.t` 對照原本規範 DP，並於 47 月份、每月開啟一天後剩餘 3 天時使用對稱性公式 `(141)! / ((3!)^47 × 47!)`，該數共有 148 個十進位位數。
GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222645665，12,542 個斷言／32 檔 PASS。該次完整測試約 163 秒，前一次為約 233 秒；不同 CI 執行環境和負載可能改變觀察值，不宣稱一般化加速百分比。

## 四、待解問題

- 對尚未全部開啟月份的中間排名，仍反覆建構二維完工數模型；47 月份在 20 秒限制下 BLOCKED。
- 需要在受控條件下重測全開啟閉式捷徑是否改善中間排名，並考慮未開啟月份部分的狀態及多項式變換重用。
- 最大 5,778 日、47 月份的非極端排名仍未驗證實用效能及記憶體。
- `LAST_COMPLETED_STAGE=1` 不變，沒有開始 Stage 2，沒有將 `t/lib` 實驗代碼引入生產，也未提交使用者專用 HANDOFF 檔。

## 五、同限額重測

提交 `00905951824f8a85f3fef39bf3e7cc1508a27ffe` 再次以相同原生量測工具、同樣每例 20 秒和 196,608 KiB RSS 觀測限額執行。GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38223128775，12,545 assertions / 32 檔 PASS。

| 分布 | 重測結果 | 秒數 | VmHWM 或觀測 VmRSS |
| --- | --- | ---: | ---: |
| 4×4 | PASS | 0.038 | 14,680 KiB VmHWM |
| 6×4 | PASS | 0.219 | 16,812 KiB VmHWM |
| 8×4 | PASS | 0.507 | 14,180 KiB VmHWM |
| 47×4 | BLOCKED（時間） | 20.016 | 18,080 KiB VmRSS |
| 17×6＋30×5 | BLOCKED（時間） | 20.017 | 21,776 KiB VmRSS |

小例子的耗時略微減少；由於執行分別發生在不同 CI 作業環境，不能由這些數字證明穩定的加速比例。兩個 47 月份案例仍未完成，故全數月份已開啟閉式的效益尚不足以解決一般中間排名的運算成本。

## 六、只剩最後一個月份尚未開啟的進一步閉式

提交 `17a08a98a7c9ead2aa96867d8fb2b5c48eef4894` 將 `t/lib/Pastafari/WeavingSuffix.pm` 的末次順序乘積適用條件從 `opened=m` 擴展為 `opened≥m−1`（且仍有未關閉月份）。若只有最後一月 m 尚未首次出現，因 m−1 月的真正首次出現已位於固定前綴，任何 m 月的第一次出現都晚於它；又沒有更後面的月份須保留首次次序。因此剩餘部分只需依序完成各月份的最後出現。

新增 `t/32_last_unopened_suffix_closed_form.t`，涵蓋 60 組具原本規範 Oracle 的小案例、已有關閉月份的前綴，以及只有第 47 月尚未開啟的 47 月份情況。此擴張是末端局部捷徑，不代表解決全部尚未開啟月份的二維模型瓶頸。

原生驗證：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38223812823，12,738 個斷言／33 個測試檔 PASS，包含 `t/32_last_unopened_suffix_closed_form.t`。本輪驗證沒有發現失敗的斷言或編碼警告。

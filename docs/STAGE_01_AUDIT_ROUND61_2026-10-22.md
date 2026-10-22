# 第 61 輪 Stage 1：四月份「前三月已開」末次序提前閉式

日期：2026-10-22（以色列時間）。僅 Perl+國語 Stage 1，
不得更改 main、正式曆法實作、Stage 2 或 HANDOFF。

## 真實 R60 原生失敗

GitHub Actions：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39611846955

窗口 36 [101,83,88,40] 共 312 日：
R60 hash36-10 用 200000 項 clock 有界快取在 169.839 秒
PASS，完整 312 個字元及所有合法 BigInt 分支均核對；
hash36-08 和 hash36-09 分別在 185.052 和 185.020 秒
TIME_LIMIT BLOCKED，RSS 約 263700 KiB，並非算術矛盾。
歷史 BLOCKED 記錄不得刪改、不得冒稱 R60 全 PASS。
R59 的原生 24 名次中另有 21 個已 PASS，
但是否宣告最終完成仍須 R61 兩份原生 PASS。

## 演算獨立性的數學理由

在四個月份的合法詞，首次出現嚴格依次為 1、2、3、4，
末次出現也嚴格依次為 1、2、3、4。
對任何已出現月份 1、2、3，第四月份尚未出現的前綴：
- 已無首次出現 1、2、3 的限制（已滿足）；
- 首次出現 4 必在後綴內，因它尚未出現；
- 剩餘的唯一約束即各月份末次出現次序。
因此可用原 Oracle 已採用於「四月份全開」狀態的
組合末次序精確閉式，直接計算「前三月已開」狀態，
不必展開整個子樹；未變更任何合法前綴集合或結果。
此數學閉式不使用受測的多項式排名器／排名快取。

僅 opt-in 的 {bounded_cache=>1,early_final_closed_form=>1}
能啟用四月份提前閉式；已有 200000 項 hard cap、
clock、原有剩餘狀態 DFS 和所有其他分支完全不變。
專供 R60 唯二仍超時的 hash36-08、hash36-09；
已 PASS 的 hash36-10 不重跑或更改政策。

新增 t/79_early_last_order_smallspace.t：
於多組非對稱四月份小空間逐一枚舉可到達的
前三月已開狀態，和不帶快取的獨立合法字序
直接枚舉、未啟用新閉式的歷史 Oracle 對照；
斷言選項互斥、範圍和 cache limit 不變。
新增 t/80_r61_early_last_ci_contract.t：
檢查只啟用指定 08/09、原始 GitHub 185 秒、
393216 KiB RSS、五分鐘總時限，以及真實閉式調用診斷。

獨立原生 CI 標記 [weaving-fourmonth-r61-early-last]，
兩個工作各自核對全部 312 日 BigInt 完工區段、
每一合法下一字元計數的完整和、正向/反向排名復原。
任何一份 FAIL 或 BLOCKED 均使 R61 未完成。
完整 Perl 全量和 verify 必須原生 PASS 才算關閉。
這不是 Stage 2 或完整 45 月/4244 日全球 BigInt 順序，
也不是跨語言 Soak。

## R61 Native 回歸修正（保留首個 RED）

首個 R61 GitHub CI https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39732309454：獨立 312 日 08/09 jobs、verify 均 PASS；普通 Perl 跑完 81 檔／88853 斷言時 t/79 僅有一條**測試覆蓋門檻**失敗：實際 34 個合法末月尚未開的狀態，錯誤地要求 >40。所有 34 組新閉式與原生 DFS、獨立枚舉均完全一致，沒有計算反例。

補上兩個不同的非對稱小向量 [4,3,3,2]、[3,4,3,3]，分別新增 19、21 種可到達狀態；因此七組合計精確 **74** 種，保留原 >40 門檻並增加精確 74 的獨立檢查。原有關於選項非法、200000 界線與 GitHub 原生 job 的測試不刪減；加 UTF-8 標準輸出編碼避免測試報告寬字元警告。必須完成再一次原生全套 PASS 後才可關閉。

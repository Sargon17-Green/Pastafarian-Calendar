# 第 1 階段第八輪：指定前綴的多項式完工數與字典序反排名

日期：2026-10-11。本輪僅修改 `Perl+國語` 分支的測試用參考模組及驗證，並沒有開始 Stage 2。

## 初始證據

- 基準 commit `48fcefb5ab3b7331eced1b322bf9499a64f8dfd7`：5,969 assertions / 24 tests，PASS。獨立全局多項式模型已經在 47 月份及 252 日的三組分布上通過計數量測。
- commit `939f6b70d74bdf601ce04d267fdcd983aad745a8`：引入 `t/lib/Pastafari/WeavingSuffix.pm`，根據有效前綴數完工數；GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38166579517，42,603 assertions / 25 files PASS，包含大量完整列舉的合法前綴。
- commit `842d80717da05510d250f09186b0414d44dc1bfd`：持續完整產生小問題的合法序列，僅選擇每一問題不同長度與字典位置的固定前綴進行 CI 比較。GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38166744085，10,823 assertions / 25 files PASS，約 77 秒。完整 42,603 斷言的原生證據仍保留。
- commit `b1153ea394f81c83ee4dde59b97842c2467dd8d5`：加入 `t/lib/Pastafari/WeavingUnrank.pm` 的獨立字典序反排名模型；GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38166939530，11,158 assertions / 26 files PASS，並與原有規範反排名比較。

## 數學構造

給定有效月份前綴，設 p 為已首次出現的最後月份，c 為已依序完成的最後月份，r_j 為月份 j 未使用的日數。已開啟但未完成的月份是 c+1..p；尚未開啟的是 p+1..m。

首先僅用一維 E[v] 統計 c+1..p 的剩餘部分：E[v] 是其中最後一個月份在剩餘序列的第 v 個位置最後出現的計數。所有這些月份的首日已在固定前綴中出現，因此剩餘序列毋須再約束它們的首日次序。

當插入一個已開啟月份的剩餘 k 個日子時，對其最後位置 v 有以下無首日約束的轉移：

`E_new[v] = C(v-1,k-1) × Σ(b<=v-k) E_old[b]`

第一個尚未開啟月份 p+1 也毋須與月份 p 比較首次出現的後綴位置，因為月份 p 的真正首次出現已經位於固定前綴中。因此可直接從 E 轉成首次/末次位置分布 D：

`D_new[u,v] = C(v-u-1,k-2) × Σ(b<=v-k) E_old[b]`，當 k≥2；k=1 時要求 u=v。

後面尚未開啟的月份必須繼續遵守首次及最後出現的次序，因此沿用前一輪已驗證的二維轉移：

`D_new[u,v] = C(v-u-1,k-2) × Σ(a<u,b<=v-k) D_old[a,b]`，當 k≥2；k=1 時 u=v。

最後對所有非零 D[u,v] 求和得到剩餘完工數。若前綴內所有月份均已結束，則直接對剩下尚未開啟的月份使用全域多項式模型。若所有月份都已開啟，則只須合計 E。

## 字典序反排名

每個位置只枚舉已開啟的合法月份及下一個允許首次開啟的月份，按標籤由小至大測試。對各合法候選計算以上前綴完工數；若所需一基排名大於此候選的計數，就減去這個計數並檢查下一候選；否則接受該候選，進入下一日。數值計算全程使用 Math::BigInt 的獨立副本。

這構成多項式次數的精確字典序演算法，但每次候選都要重新計算後綴多項式模型，故未保證對最高 5,778 日的完整曆法輸入有實用的執行時間。

## 合約、資源與後續工作

- 本輪模型僅存於 `t/lib/Pastafari/`，生產曆法仍未生成完整結果，`LAST_COMPLETED_STAGE=1`。
- 約束條件並未被放寬：開啟順序和關閉順序均保留，拒絕不可達前綴及越界排名。
- 建議後續驗證字典序區塊分割恆等式（對合法前綴，所有合法下一月的完工數之和等於母前綴的完工數），並以大型但受控的合法年份長度測試任意排名的記憶體與時間。
- 不得把本模型的 Stage 1 測試通過直接等同於 55 階段的完成。HANDOFF 檔案屬使用者，不提交至 GitHub。`main` 未修改。

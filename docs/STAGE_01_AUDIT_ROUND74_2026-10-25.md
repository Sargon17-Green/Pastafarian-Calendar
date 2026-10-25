# 第七十四輪：五個月份全部 243 個短長度向量的獨立排序與鏡射

日期：2026-10-25（以色列時間）。僅 Perl+國語 Stage 1；
不更動 main、不開啟 Stage 2、不上傳私人 HANDOFF 至 repo。

## R73 關閉的驗收證據

R73 初次提交 6a6efbd64ff11d74cf64bab2d560f60a5f827200
的 Actions 40169835668 雖然五個 Native 及 verify SUCCESS，
但完整 perl-stage01 因自然語言隔離契約 FAIL，故整體 FAILURE。
文檔經繁體中文修正後，HEAD
d25127ef3e3ff2449a9b8f54bc032f52764dd777 在
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40181557502
七份工作全部 SUCCESS，Round 73 以第二次 CI 封存 PASS。

## R74 要驗證的新能力

此前 R67–R73 只對四個月份（或較少月份）做深入
字典序／前綴／鏡射稽核。R74 第一次將同樣要求延伸到
**五個月份**，所有 `[a,b,c,d,e]` 其中每個長度在 1..3
的 **243 個配置**。每片固定第一個月份長度 a=1/2/3，
各覆蓋 81 個向量。

獨立後綴 DFS 依合法首次與末次出現順序計算每個 BigInt
完工數，再由**獨立由前向後推進狀態的 Python DP**核對
全部 243 個固定真值。每片依向量詞典序組合
`a,b,c,d,e=N` 計算 SHA-256：

| 第一月份 a | 向量 | Σ合法詞數 | 真值 SHA-256 |
|---|---:|---:|---|
| 1 | 81 | 3703 | 7081ddef2b4f08c855979a86c0eaf8323491dce1e669d7fc0885ffd2a97faf14 |
| 2 | 81 | 18719 | 1bbf1195a27f99d60e9ce004b7385ff379eec6f115a59927abf446c695f2d126 |
| 3 | 81 | 64121 | 252cc5821cb54d747c57ae131cd33b7dc0bf7ec50126e3ce01e35aacc9693f6f |

合計跨 243 向量的合法字序數為 **86543**，
不是說在單一向量內有這麼多詞。每個向量額外檢查
不同位置分布的插入多項式、獨立 16 項 CLOCK 有界
Memo Oracle、根及選中真實前綴的完工數。

每個配置確定性地選 rank 1、2、floor(N/2)+1、N−1、N
中存在且互異的名次，用自身 DFS 子樹 BigInt 計算真正完整
字詞，對照原生 `rankWeavingPolynomial` 與
`unrankWeavingPolynomial` 的一基名次；然後將整個
五個月合法詞倒序並以 `j→6−j` 補標籤，
依**倒序長度向量的另一份獨立 DFS**重算新排名，
並與原生正反向排名器核對；反轉兩次須完全恢復原詞。

每片獨立 opt-in Native，185 秒及 393216 KiB RSS
父程序守衛、GitHub 5 分鐘、外部 timeout 195 秒。
僅 verify、完整 perl-stage01 及三份 R74 Native
全部 SUCCESS 才可封存。此次五個月局部 QA
不證明 45 個月或 4244 日，也不宣稱跨語言等價。

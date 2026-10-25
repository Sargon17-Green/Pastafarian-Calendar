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
不同位置分布的插入多項式、獨立 DFS 計數，
以及真正完整詞全集導出的前綴頻率表。

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


## R74 追加：全集完整詞反轉雙射（2026-10-25）

此前每個向量以固定少量名次交叉檢驗反轉雙射；現在原生驗證另對
81 個向量的**每條**合法完整字詞直接以首次／末次順序做 DFS
枚舉，與倒序月份長度的另一份完整合法詞全集建立字典序索引，
使用 `j→6−j` 反轉字詞並強制逐個證明存在、單射、滿射、
反轉兩次恆等。三個分片覆蓋 **3703+18719+64121=86543**
條原詞；每個合法詞的（原字序名次、鏡射字序名次）及
長度向量另以 SHA-256 和獨立 Python 完整枚舉結果比對，
並非僅依被測 `rank/unrank` 往返。
SHA256：a=1 `394febf74d55580707217dd411c720747fce913b147401b6c6dba67d728cbc83`；
a=2 `ec13377dccf131fc8e6388012b36b413f058dc6832abfaa5ab245e15a522fc5f`；
a=3 `fff46731a29d59f5f1b1fedfbd0a875963c0ab877f3c89fe2c6001e23a54b356`。
新的 Native 全集檢驗仍由既有 185 秒／393216 KiB 父程序監督，
不擴大資源上限。早先提交與原生 CI QUEUED 不得被改寫為 PASS；
以增加全集檢驗的新提交完整 CI 為該輪最終驗收依據。


## 兩次 Native RED 與根因修復（2026-10-25）

Actions 40192049029（commit fc326609569a05e0fe46c8508221a5ef8d7e3b5b）及
Actions 40192779969（commit 143645a32839f51c664cde475cc8983a0938cb3a）
均為整體 FAILURE：verify 與完整 perl-stage01 均 SUCCESS，
三份 R74 Native 皆在原生執行開頭失敗。日誌指出兩個問題：
首先，早期末次序閉式及整個 `WeavingMemoOracle` 契約只支援
最多四個月份，不可被五個月測試呼叫；其次，循環的局部
`$b` 與 Perl 排序比較器的特殊 `$b` 名稱互相遮蔽。
新修補**不擴大原有四月 Oracle 的契約**，而是逐字枚舉
五個月合法全集，形成真正獨立的前綴頻率表，與 DFS 每個樣本
的前綴完工數比較。局部月份變數改為 `$month_b`。
同時在 t/95 中新增防回歸測試，嚴禁對五個月援引四月 Oracle，
以及遮蔽 sort 比較器。兩次 FAILURE 均保留。
修補後仍須 verify、完整 perl-stage01、三個 Native 同一 HEAD
全部成功，不能將提交本身當作 PASS。

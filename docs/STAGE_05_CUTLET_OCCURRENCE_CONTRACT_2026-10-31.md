# 第 5 階段：有界肉排名稱／肉排內日數投影契約（2026-10-31）

專案 `PC-BRANCH-PERL-GUOYU`；唯一分支 `Perl+國語`。
上階段 Stage4 已由原始碼 SHA `bd0de67daeb8569a62006c7be11009979bc32752` 的
GitHub run `41186935117` 完成 Native 驗收，文檔 HEAD `0beeb9eb753c4db79aba3f591ac9ad35b82ecbf8`。
保持 `LAST_COMPLETED_STAGE=4`；本階段實作不代表 Stage5 PASS。

## 根據、邊界和獨立選擇

規範 `t/lib/Pastafari/NormativeScroll.pm` 的 `calendarDate` 在年區間
`openGateDay < targetDay <= closeGateDay` 中，依已建立的連續肉排
`firstDay..lastDay` 尋找包含目標日的肉排；
第二欄為 `cutlet_name_by_index(chosen.nameIndex)`，
第三欄為 `targetDay - chosen.firstDay + 1`。
第 4 階段已對月份索引／月內日數提供局部語意，因此第 5 階段選擇肉排名稱和肉排內日數。

此獨立原語**不建立**年份、gate 區間、肉排分割、名稱排列，也不執行
`calendarDate`。輸入已經是由外部先行排列的相鄰肉排長度及規範名稱索引；
僅驗證本原語的安全界限、長度和名稱唯一性，**不保證輸入一定能由規範 gate 演算法產生**。
6..17 個肉排、每段正整數（<=5778）、總長 252..5778 是局部上限；
這個有界 domain 的部分測試向量只是投影樣本，不是正式全年日期。

## API

`lib/Pastafari/Monster/CutletOccurrence.pm` 匯出：
`cutlet_occurrence($lengths,$name_indices,$position)`
回傳
`{ cutletIndex => Int, cutletName => Str, dayInCutlet => Math::BigInt }`。
`lengths[i]` 是相鄰第 `i+1` 段的日數；
`name_indices[i]` 是 frozen source language catalog 內 1..17 的不重複索引；
`position` 是 **1-based** 年內位置。
令 `S_i = sum(lengths[0..i])`，取首個 `S_i >= position` 的 `i`，
則 `cutletIndex=i+1`，`cutletName=catalog(name_indices[i])`，
`dayInCutlet=position-(i=0?0:S_(i-1))`。

拒絕未定義、負數、零、非整數、前導零、超界、錯誤資料型別、
不吻合的兩個陣列長度和重複名稱；
允許只讀 `Math::BigInt`，不修改輸入，回傳可變數值不得共享。

## 獨立 Oracle、原生驗收

`t/50_stage05_cutlet_occurrence.t` 從指定段長**逐日展開**
每個段的所有日位置與序號（不用生產的前綴累加判段），以展開順序、目錄
原始索引表和固定中文名稱錨點比對回傳值。至少 6,000 個位置，涵蓋
252/5778 日邊界及 17 段、轉換日、BigInt、拒絕非法輸入、不變性。
不得用被測原語或完整 `calendarDate` 產生預期資料。

GitHub Actions 在**同一個來源 SHA** 驗證 `verify`、`perl-stage01`
及 Stage2/Stage3/Stage4 regression；Stage5 獨立 Native job 使用
Perl >=5.40、`perl -c` 模組及測試、`prove -e 'perl -CS -Ilib -It/lib'`，
`timeout 120s`、`ulimit -v 393216` (384 MiB virtual memory，非 peak RSS)，
退出碼 0、stderr 0 bytes、至少 6,000 個獨立展開位置，
保存 `source.txt`、`perl-version.txt`、`syntax.stderr`、
`test.stdout`、`test.stderr`、`test.exit`、`result.txt` 的 artifact。
只有 completed/log/artifact 完整核驗才能將 `LAST_COMPLETED_STAGE` 改為 5。
無 full-calendar 五欄 PASS、無 main/merge。
